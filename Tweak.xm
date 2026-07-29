#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>

static BOOL RMFreeIAPEnabled = YES;
static NSString * const RMEnabledKey = @"rm_hook_free_iap_enabled";
static BOOL RMHookInstalled = NO;
static BOOL RMUIInstalled = NO;
static IMP RMOrigPurchaseImp = NULL;
static UIView *RMMenuView = nil;
static UIButton *RMBallButton = nil;
static id RMMenuController = nil;

@interface DGPurchaseManager : NSObject
- (void)purchase:(id)productIdentifier;
- (void)complete:(id)transaction retry:(BOOL)retry;
@end

@interface RMFakePayment : NSObject
@property(nonatomic, copy) NSString *productIdentifier;
@end
@implementation RMFakePayment
@end

@interface RMFakeTransaction : NSObject
@property(nonatomic, strong) RMFakePayment *payment;
@property(nonatomic, copy) NSString *transactionIdentifier;
- (NSInteger)transactionState;
- (NSError *)error;
@end
@implementation RMFakeTransaction
- (NSInteger)transactionState { return SKPaymentTransactionStatePurchased; }
- (NSError *)error { return nil; }
@end

static void RMLog(NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSLog(@"[RM-IAP] %@", msg);
}

static void RMSaveEnabled(BOOL enabled) {
    RMFreeIAPEnabled = enabled;
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:RMEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    RMLog(@"Free IAP = %@", enabled ? @"ON" : @"OFF");
}

static NSString *RMProductIDFromObject(id productIdentifier) {
    if ([productIdentifier isKindOfClass:NSString.class]) return productIdentifier;
    if ([productIdentifier respondsToSelector:@selector(productIdentifier)]) {
        id pid = nil;
        @try { pid = [productIdentifier valueForKey:@"productIdentifier"]; } @catch (__unused NSException *e) {}
        if ([pid isKindOfClass:NSString.class]) return pid;
    }
    if ([productIdentifier respondsToSelector:@selector(description)]) return [productIdentifier description];
    return @"rm.fake.product";
}

static RMFakeTransaction *RMMakeFakeTransaction(id productIdentifier) {
    NSString *pid = RMProductIDFromObject(productIdentifier);
    if (pid.length == 0) pid = @"rm.fake.product";
    RMFakePayment *payment = [RMFakePayment new];
    payment.productIdentifier = pid;
    RMFakeTransaction *tx = [RMFakeTransaction new];
    tx.payment = payment;
    tx.transactionIdentifier = [NSString stringWithFormat:@"RMFREE-%lld-%u", (long long)[NSDate.date timeIntervalSince1970], arc4random_uniform(1000000)];
    return tx;
}

static void RMReplacedPurchase(id self, SEL _cmd, id productIdentifier) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigPurchaseImp) ((void (*)(id, SEL, id))RMOrigPurchaseImp)(self, _cmd, productIdentifier);
        return;
    }
    RMFakeTransaction *tx = RMMakeFakeTransaction(productIdentifier);
    RMLog(@"intercept purchase pid=%@ tx=%@", tx.payment.productIdentifier, tx.transactionIdentifier);
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            if ([self respondsToSelector:@selector(complete:retry:)]) {
                ((void (*)(id, SEL, id, BOOL))objc_msgSend)(self, @selector(complete:retry:), tx, NO);
            } else if (RMOrigPurchaseImp) {
                RMLog(@"complete:retry: missing, fallback original");
                ((void (*)(id, SEL, id))RMOrigPurchaseImp)(self, _cmd, productIdentifier);
            }
        } @catch (NSException *e) {
            RMLog(@"exception in fake complete: %@", e);
            if (RMOrigPurchaseImp) ((void (*)(id, SEL, id))RMOrigPurchaseImp)(self, _cmd, productIdentifier);
        }
    });
}

static void RMInstallHook(void) {
    if (RMHookInstalled) return;
    Class cls = objc_getClass("DGPurchaseManager");
    if (!cls) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RMInstallHook(); });
        return;
    }
    Method m = class_getInstanceMethod(cls, @selector(purchase:));
    if (!m) { RMLog(@"DGPurchaseManager purchase: not found"); return; }
    MSHookMessageEx(cls, @selector(purchase:), (IMP)RMReplacedPurchase, &RMOrigPurchaseImp);
    RMHookInstalled = YES;
    RMLog(@"hooked -[DGPurchaseManager purchase:]");
}

@interface RMHookMenuController : NSObject
@end
@implementation RMHookMenuController
- (void)ballTap:(id)sender { RMMenuView.hidden = !RMMenuView.hidden; }
- (void)switchChanged:(UISwitch *)sender { RMSaveEnabled(sender.on); }
- (void)panBall:(UIPanGestureRecognizer *)gr {
    UIView *view = RMBallButton;
    UIView *parent = view.superview;
    if (!view || !parent) return;
    if (gr.state == UIGestureRecognizerStateBegan || gr.state == UIGestureRecognizerStateChanged || gr.state == UIGestureRecognizerStateEnded) {
        CGPoint t = [gr translationInView:parent];
        CGPoint c = view.center;
        c.x += t.x; c.y += t.y;
        view.center = c;
        [gr setTranslation:CGPointZero inView:parent];
    }
}
@end

static UIWindow *RMFindHostWindow(void) {
    UIWindow *key = UIApplication.sharedApplication.keyWindow;
    if (key) return key;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (![scene isKindOfClass:UIWindowScene.class]) continue;
            UIWindowScene *ws = (UIWindowScene *)scene;
            for (UIWindow *w in ws.windows) if (w.isKeyWindow) return w;
            if (ws.windows.firstObject) return ws.windows.firstObject;
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

static void RMInstallFloatingMenu(void) {
    if (RMUIInstalled) return;
    UIWindow *host = RMFindHostWindow();
    if (!host || !host.rootViewController || !host.rootViewController.view) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RMInstallFloatingMenu(); });
        return;
    }
    UIView *root = host.rootViewController.view;
    RMMenuController = [RMHookMenuController new];
    RMBallButton = [UIButton buttonWithType:UIButtonTypeCustom];
    RMBallButton.frame = CGRectMake(18, 170, 58, 58);
    [RMBallButton setTitle:@"IAP" forState:UIControlStateNormal];
    [RMBallButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    RMBallButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    RMBallButton.backgroundColor = [UIColor colorWithRed:0.09 green:0.50 blue:0.95 alpha:0.88];
    RMBallButton.layer.cornerRadius = 29;
    RMBallButton.layer.masksToBounds = YES;
    RMBallButton.layer.zPosition = 999999;
    [RMBallButton addTarget:RMMenuController action:@selector(ballTap:) forControlEvents:UIControlEventTouchUpInside];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:RMMenuController action:@selector(panBall:)];
    [RMBallButton addGestureRecognizer:pan];
    RMMenuView = [[UIView alloc] initWithFrame:CGRectMake(86, 170, 210, 112)];
    RMMenuView.backgroundColor = [UIColor colorWithRed:0.04 green:0.04 blue:0.05 alpha:0.86];
    RMMenuView.layer.cornerRadius = 14;
    RMMenuView.layer.zPosition = 999998;
    RMMenuView.hidden = YES;
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(14, 10, 180, 24)];
    title.text = @"Royal Match Hook"; title.textColor = UIColor.whiteColor; title.font = [UIFont boldSystemFontOfSize:15];
    UILabel *row = [[UILabel alloc] initWithFrame:CGRectMake(14, 50, 120, 28)];
    row.text = @"Free IAP"; row.textColor = UIColor.whiteColor; row.font = [UIFont systemFontOfSize:14];
    UISwitch *sw = [[UISwitch alloc] initWithFrame:CGRectMake(142, 45, 54, 32)];
    sw.on = RMFreeIAPEnabled; [sw addTarget:RMMenuController action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    UILabel *hint = [[UILabel alloc] initWithFrame:CGRectMake(14, 82, 185, 18)];
    hint.text = @"ON: fake local purchased"; hint.textColor = UIColor.lightGrayColor; hint.font = [UIFont systemFontOfSize:11];
    [RMMenuView addSubview:title]; [RMMenuView addSubview:row]; [RMMenuView addSubview:sw]; [RMMenuView addSubview:hint];
    [root addSubview:RMMenuView]; [root addSubview:RMBallButton];
    objc_setAssociatedObject(root, @selector(RMInstallFloatingMenu), RMMenuController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    RMUIInstalled = YES;
    RMLog(@"floating menu installed on host window");
}

__attribute__((constructor)) static void RMEntry(void) {
    @autoreleasepool {
        NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
        if ([ud objectForKey:RMEnabledKey] == nil) { [ud setBool:YES forKey:RMEnabledKey]; [ud synchronize]; }
        RMFreeIAPEnabled = [ud boolForKey:RMEnabledKey];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
            RMInstallHook(); RMInstallFloatingMenu();
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RMInstallHook(); RMInstallFloatingMenu(); });
        RMLog(@"tweak loaded");
    }
}
