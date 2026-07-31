#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>
#import <dlfcn.h>

static BOOL RMFreeIAPEnabled = NO;
static NSString * const RMEnabledKey = @"rm_hook_free_iap_enabled_v103";
static BOOL RMHookInstalled = NO;
static BOOL RMUIInstalled = NO;
static IMP RMOrigPurchaseImp = NULL;
static IMP RMOrigFailImp = NULL;
static IMP RMOrigTimeoutImp = NULL;
static IMP RMOrigConsumeImp = NULL;
static IMP RMOrigFinishImp = NULL;
static void (*RMOrigUnityOnPurchaseFail)(void *self, const void *method) = NULL;
static void (*RMOrigUnitySendPurchaseFail)(void *self, void *config, void *purchaseResult, bool isRoyalFavorFromMoreLives, const void *method) = NULL;
static void (*RMOrigUnityOnVerificationResult)(void *self, void *purchaseResult, const void *method) = NULL;
static bool (*RMOrigUnityPurchaseResultIsSuccess)(void *self, const void *method) = NULL;
static void (*RMUnitySendPurchaseSuccessFn)(void *self, void *config, void *purchaseResult, bool isRoyalFavorFromMoreLives, const void *method) = NULL;
static const void *RMUnitySendPurchaseSuccessMethodInfo = NULL;
static void (*RMOrigUnitySendPurchaseSuccess)(void *self, void *config, void *purchaseResult, bool isRoyalFavorFromMoreLives, const void *method) = NULL;
static void (*RMOrigRoyalPassOnPurchaseSuccess)(void *self, void *config, void *purchaseResult, const void *method) = NULL;
static void (*RMOrigWeeklyPassOnPurchaseSuccess)(void *self, void *config, void *purchaseResult, const void *method) = NULL;
static void (*RMOrigRoyalPassDialogPurchaseStrategySuccess)(void *self, const void *method) = NULL;
static void (*RMOrigWeeklyPassDialogPurchaseStrategySuccess)(void *self, const void *method) = NULL;
static void (*RMUserInventoryAddCoinsFn)(void *self, int delta, bool shouldUpdateMissionProgress, const void *method) = NULL;
static void (*RMUserInventoryAddBoosterFn)(void *self, int boosterType, int delta, const void *method) = NULL;
static void (*RMUserInventoryAddTimeFn)(void *self, int boosterType, int deltaSeconds, const void *method) = NULL;
static void (*RMUserInventoryAddInGameBoosterTimeFn)(void *self, int boosterType, int deltaSeconds, const void *method) = NULL;
static void *(*RMUserManagerGetCurrentUserFn)(const void *method) = NULL;
static int (*RMShopPackageGetTotalCoinsWithBonusFn)(void *config, const void *method) = NULL;
static void (*RMUserInventoryUpdateRoyalPassIsGoldFn)(void *self, bool isGold, const void *method) = NULL;
static void (*RMWeeklyPassHelperSetPurchasedFn)(void *self, const void *method) = NULL;
static void (*RMWeeklyPassProgressSetPurchasedFn)(void *self, bool isPurchased, const void *method) = NULL;
static const void *RMUserInventoryAddCoinsMethodInfo = NULL;
static const void *RMUserInventoryAddBoosterMethodInfo = NULL;
static const void *RMUserInventoryAddTimeMethodInfo = NULL;
static const void *RMUserInventoryAddInGameBoosterTimeMethodInfo = NULL;
static const void *RMUserManagerGetCurrentUserMethodInfo = NULL;
static const void *RMShopPackageGetTotalCoinsWithBonusMethodInfo = NULL;
static const void *RMUserInventoryUpdateRoyalPassIsGoldMethodInfo = NULL;
static const void *RMWeeklyPassHelperSetPurchasedMethodInfo = NULL;
static const void *RMWeeklyPassProgressSetPurchasedMethodInfo = NULL;
static void (*RMOrigUserInventoryUpdateCoins)(void *self, int newCoins, const void *method) = NULL;
static void (*RMOrigUserInventorySetCoins)(void *self, int value, const void *method) = NULL;
static void (*RMOrigUserInventoryUpdateInGameInventory)(void *self, int64_t value, const void *method) = NULL;
static void (*RMOrigUserInventoryUpdatePreLevelInventory)(void *self, int64_t value, const void *method) = NULL;
static void (*RMOrigUserInventoryUpdateRemainingBoosterTimes)(void *self, int64_t value, const void *method) = NULL;
static void (*RMOrigUserInventoryUpdateRocketEndTime)(void *self, int value, const void *method) = NULL;
static void (*RMOrigUserInventoryUpdateTntEndTime)(void *self, int value, const void *method) = NULL;
static void (*RMOrigUserInventoryUpdateLightballEndTime)(void *self, int value, const void *method) = NULL;
static void (*RMOrigUserInventoryUpdateRoyalPassIsGold)(void *self, bool isGold, const void *method) = NULL;
static void (*RMOrigWeeklyPassProgressSetIsPurchased)(void *self, bool isPurchased, const void *method) = NULL;
static int32_t RMMaxCoins = 0;
static int64_t RMMaxInGameInventory = 0;
static int64_t RMMaxPreLevelInventory = 0;
static int64_t RMMaxRemainingBoosterTimes = 0;
static int32_t RMMaxRocketEndTime = 0;
static int32_t RMMaxTntEndTime = 0;
static int32_t RMMaxLightballEndTime = 0;
static NSTimeInterval RMGrantProtectUntil = 0;
static BOOL RMRoyalPassGranted = NO;
static BOOL RMWeeklyPassGranted = NO;
static NSUInteger RMPurchaseSequence = 0;
static NSUInteger RMLastGrantSequence = 0;
static BOOL RMUnityGrantHooksInstalled = NO;
static UIView *RMMenuView = nil;
static UIButton *RMBallButton = nil;
static id RMMenuController = nil;

@interface DGPurchaseManager : NSObject
- (void)purchase:(id)productIdentifier;
- (void)complete:(id)transaction retry:(BOOL)retry;
- (void)setStartPurchaseCalled:(BOOL)called;
- (void)setFetchThisProductToPurchase:(id)productIdentifier;
- (BOOL)startPurchaseCalled;
- (id)fetchThisProductToPurchase;
- (id)delegate;
- (BOOL)consume:(id)transaction;
- (BOOL)finish:(id)transaction;
- (void)setPurchaseQueryTimedOut:(BOOL)timedOut;
- (id)timer;
- (void)setTimer:(id)timer;
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

static NSString *RMLogPath(void) {
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *doc = dirs.firstObject;
    if (doc.length == 0) doc = @"/var/mobile/Documents";
    return [doc stringByAppendingPathComponent:@"RoyalMatchIAPHook.log"];
}

static void RMAppendFileLog(NSString *line) {
    @try {
        NSString *path = RMLogPath();
        NSString *out = [line stringByAppendingString:@"\n"];
        NSData *data = [out dataUsingEncoding:NSUTF8StringEncoding];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [data writeToFile:path atomically:YES];
            return;
        }
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (fh) {
            [fh seekToEndOfFile];
            [fh writeData:data];
            [fh closeFile];
        }
    } @catch (__unused NSException *e) {}
}

static void RMLog(NSString *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    NSString *msg = [[NSString alloc] initWithFormat:fmt arguments:ap];
    va_end(ap);
    NSString *line = [NSString stringWithFormat:@"[%@] [RM-IAP] %@", [NSDate date], msg];
    NSLog(@"%@", line);
    RMAppendFileLog(line);
}

typedef const void *(*RM_il2cpp_domain_get_t)(void);
typedef const void **(*RM_il2cpp_domain_get_assemblies_t)(const void *domain, size_t *size);
typedef const void *(*RM_il2cpp_assembly_get_image_t)(const void *assembly);
typedef const char *(*RM_il2cpp_image_get_name_t)(const void *image);
typedef size_t (*RM_il2cpp_image_get_class_count_t)(const void *image);
typedef const void *(*RM_il2cpp_image_get_class_t)(const void *image, size_t index);
typedef const char *(*RM_il2cpp_class_get_name_t)(const void *klass);
typedef const char *(*RM_il2cpp_class_get_namespace_t)(const void *klass);
typedef const void *(*RM_il2cpp_class_get_methods_t)(const void *klass, void **iter);
typedef const char *(*RM_il2cpp_method_get_name_t)(const void *method);
typedef uint32_t (*RM_il2cpp_method_get_param_count_t)(const void *method);

static BOOL RMKeywordHit(NSString *s) {
    if (s.length == 0) return NO;
    NSString *l = s.lowercaseString;
    NSArray *keys = @[@"purchase", @"shoppackage", @"inventorypackage", @"usergamedata", @"verification", @"verifier", @"rewardtype", @"booster", @"nativepayment", @"iap", @"coins"];
    for (NSString *k in keys) if ([l containsString:k]) return YES;
    return NO;
}

static void RMProbeIl2CppRuntime(void) {
    @try {
        RMLog(@"[IL2CPP] probe start");
        RM_il2cpp_domain_get_t domain_get = (RM_il2cpp_domain_get_t)dlsym(RTLD_DEFAULT, "il2cpp_domain_get");
        RM_il2cpp_domain_get_assemblies_t domain_get_assemblies = (RM_il2cpp_domain_get_assemblies_t)dlsym(RTLD_DEFAULT, "il2cpp_domain_get_assemblies");
        RM_il2cpp_assembly_get_image_t assembly_get_image = (RM_il2cpp_assembly_get_image_t)dlsym(RTLD_DEFAULT, "il2cpp_assembly_get_image");
        RM_il2cpp_image_get_name_t image_get_name = (RM_il2cpp_image_get_name_t)dlsym(RTLD_DEFAULT, "il2cpp_image_get_name");
        RM_il2cpp_image_get_class_count_t image_get_class_count = (RM_il2cpp_image_get_class_count_t)dlsym(RTLD_DEFAULT, "il2cpp_image_get_class_count");
        RM_il2cpp_image_get_class_t image_get_class = (RM_il2cpp_image_get_class_t)dlsym(RTLD_DEFAULT, "il2cpp_image_get_class");
        RM_il2cpp_class_get_name_t class_get_name = (RM_il2cpp_class_get_name_t)dlsym(RTLD_DEFAULT, "il2cpp_class_get_name");
        RM_il2cpp_class_get_namespace_t class_get_namespace = (RM_il2cpp_class_get_namespace_t)dlsym(RTLD_DEFAULT, "il2cpp_class_get_namespace");
        RM_il2cpp_class_get_methods_t class_get_methods = (RM_il2cpp_class_get_methods_t)dlsym(RTLD_DEFAULT, "il2cpp_class_get_methods");
        RM_il2cpp_method_get_name_t method_get_name = (RM_il2cpp_method_get_name_t)dlsym(RTLD_DEFAULT, "il2cpp_method_get_name");
        RM_il2cpp_method_get_param_count_t method_get_param_count = (RM_il2cpp_method_get_param_count_t)dlsym(RTLD_DEFAULT, "il2cpp_method_get_param_count");

        if (!domain_get || !domain_get_assemblies || !assembly_get_image || !image_get_name || !image_get_class_count || !image_get_class || !class_get_name || !class_get_namespace || !class_get_methods || !method_get_name) {
            RMLog(@"[IL2CPP] missing api domain=%p assemblies=%p asm_image=%p image_name=%p class_count=%p image_class=%p class_name=%p class_ns=%p class_methods=%p method_name=%p", domain_get, domain_get_assemblies, assembly_get_image, image_get_name, image_get_class_count, image_get_class, class_get_name, class_get_namespace, class_get_methods, method_get_name);
            return;
        }

        const void *domain = domain_get();
        size_t asmCount = 0;
        const void **assemblies = domain_get_assemblies(domain, &asmCount);
        RMLog(@"[IL2CPP] domain=%p assemblies=%zu", domain, asmCount);
        NSUInteger classHits = 0;
        NSUInteger methodHits = 0;
        NSUInteger maxLines = 650;

        for (size_t ai = 0; ai < asmCount && (classHits + methodHits) < maxLines; ai++) {
            const void *image = assembly_get_image(assemblies[ai]);
            if (!image) continue;
            const char *imageNameC = image_get_name(image);
            NSString *imageName = imageNameC ? [NSString stringWithUTF8String:imageNameC] : @"";
            size_t classCount = image_get_class_count(image);
            for (size_t ci = 0; ci < classCount && (classHits + methodHits) < maxLines; ci++) {
                const void *klass = image_get_class(image, ci);
                if (!klass) continue;
                const char *cn = class_get_name(klass);
                const char *ns = class_get_namespace(klass);
                NSString *className = cn ? [NSString stringWithUTF8String:cn] : @"";
                NSString *nsName = ns ? [NSString stringWithUTF8String:ns] : @"";
                NSString *fullClass = nsName.length ? [NSString stringWithFormat:@"%@.%@", nsName, className] : className;
                BOOL classMatch = RMKeywordHit(fullClass);
                if (classMatch) {
                    RMLog(@"[IL2CPP] class image=%@ ns=%@ class=%@", imageName, nsName, className);
                    classHits++;
                }
                void *iter = NULL;
                const void *method = NULL;
                while ((method = class_get_methods(klass, &iter)) && (classHits + methodHits) < maxLines) {
                    const char *mn = method_get_name(method);
                    NSString *methodName = mn ? [NSString stringWithUTF8String:mn] : @"";
                    if (classMatch || RMKeywordHit(methodName)) {
                        uint32_t argc = method_get_param_count ? method_get_param_count(method) : 0;
                        RMLog(@"[IL2CPP] method %@::%@ argc=%u method=%p", fullClass, methodName, argc, method);
                        methodHits++;
                    }
                }
            }
        }
        RMLog(@"[IL2CPP] probe done classHits=%lu methodHits=%lu", (unsigned long)classHits, (unsigned long)methodHits);
    } @catch (NSException *e) {
        RMLog(@"[IL2CPP] probe exception: %@", e);
    }
}

static void RMSaveEnabled(BOOL enabled) {
    RMFreeIAPEnabled = enabled;
    [[NSUserDefaults standardUserDefaults] setBool:enabled forKey:RMEnabledKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    RMLog(@"Free IAP = %@", enabled ? @"ON" : @"OFF");
}


typedef const void *(*RM_il2cpp_class_from_name_t)(const void *image, const char *namespaze, const char *name);
typedef const void *(*RM_il2cpp_class_get_method_from_name_t)(const void *klass, const char *name, int argsCount);

static void *RMMethodPointer(const void *methodInfo) {
    if (!methodInfo) return NULL;
    return *((void **)methodInfo);
}

static const void *RMFindImageByName(NSString *targetImageName) {
    RM_il2cpp_domain_get_t domain_get = (RM_il2cpp_domain_get_t)dlsym(RTLD_DEFAULT, "il2cpp_domain_get");
    RM_il2cpp_domain_get_assemblies_t domain_get_assemblies = (RM_il2cpp_domain_get_assemblies_t)dlsym(RTLD_DEFAULT, "il2cpp_domain_get_assemblies");
    RM_il2cpp_assembly_get_image_t assembly_get_image = (RM_il2cpp_assembly_get_image_t)dlsym(RTLD_DEFAULT, "il2cpp_assembly_get_image");
    RM_il2cpp_image_get_name_t image_get_name = (RM_il2cpp_image_get_name_t)dlsym(RTLD_DEFAULT, "il2cpp_image_get_name");
    if (!domain_get || !domain_get_assemblies || !assembly_get_image || !image_get_name) return NULL;
    const void *domain = domain_get();
    size_t count = 0;
    const void **assemblies = domain_get_assemblies(domain, &count);
    for (size_t i = 0; i < count; i++) {
        const void *image = assembly_get_image(assemblies[i]);
        const char *name = image ? image_get_name(image) : NULL;
        if (name && [targetImageName isEqualToString:[NSString stringWithUTF8String:name]]) return image;
    }
    return NULL;
}

static const void *RMResolveIl2CppMethodInfo(const char *namespaze, const char *className, const char *methodName, int argc) {
    RM_il2cpp_class_from_name_t class_from_name = (RM_il2cpp_class_from_name_t)dlsym(RTLD_DEFAULT, "il2cpp_class_from_name");
    RM_il2cpp_class_get_method_from_name_t class_get_method_from_name = (RM_il2cpp_class_get_method_from_name_t)dlsym(RTLD_DEFAULT, "il2cpp_class_get_method_from_name");
    if (!class_from_name || !class_get_method_from_name) {
        RMLog(@"[UNITYHOOK] missing class/method resolver class_from_name=%p get_method=%p", class_from_name, class_get_method_from_name);
        return NULL;
    }
    const void *image = RMFindImageByName(@"Assembly-CSharp.dll");
    if (!image) { RMLog(@"[UNITYHOOK] Assembly-CSharp.dll image not found"); return NULL; }
    const void *klass = class_from_name(image, namespaze, className);
    if (!klass) { RMLog(@"[UNITYHOOK] class not found %s.%s", namespaze, className); return NULL; }
    const void *method = class_get_method_from_name(klass, methodName, argc);
    if (!method) { RMLog(@"[UNITYHOOK] method not found %s.%s::%s/%d", namespaze, className, methodName, argc); return NULL; }
    void *ptr = RMMethodPointer(method);
    RMLog(@"[UNITYHOOK] resolved %s.%s::%s/%d methodInfo=%p ptr=%p", namespaze, className, methodName, argc, method, ptr);
    return method;
}

static void *RMResolveIl2CppMethodPointer(const char *namespaze, const char *className, const char *methodName, int argc) {
    const void *method = RMResolveIl2CppMethodInfo(namespaze, className, methodName, argc);
    return RMMethodPointer(method);
}

static void RMForcePurchaseResultSuccess(void *purchaseResult, const char *reason) {
    if (!purchaseResult) {
        RMLog(@"[UNITYHOOK] cannot force PurchaseResult success reason=%s result=NULL", reason);
        return;
    }
    int32_t *statusPtr = (int32_t *)purchaseResult;
    int32_t oldStatus = *statusPtr;
    *statusPtr = 3; // Royal.Infrastructure.Services.Native.Purchase.PurchaseStatus.VerificationSuccess
    int64_t *timePtr = (int64_t *)((uint8_t *)purchaseResult + 0x8);
    if (*timePtr == 0) *timePtr = (int64_t)([NSDate.date timeIntervalSince1970] * 1000.0);
    void *txString = *((void **)((uint8_t *)purchaseResult + 0x10));
    void *errString = *((void **)((uint8_t *)purchaseResult + 0x20));
    RMLog(@"[UNITYHOOK] forced PurchaseResult.status %d->3 reason=%s result=%p time=%lld tx=%p err=%p", oldStatus, reason, purchaseResult, (long long)*timePtr, txString, errString);
}

static void *RMCurrentUserInventory(void);
static void RMGrantRewardsFromShopConfig(void *config, void *purchaseResult, const char *reason);
static void RMUnitySendPurchaseSuccessHook(void *self, void *config, void *purchaseResult, bool isRoyalFavorFromMoreLives, const void *method);

static void RMUnityOnPurchaseFailHook(void *self, const void *method) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigUnityOnPurchaseFail) RMOrigUnityOnPurchaseFail(self, method);
        return;
    }
    RMLog(@"[UNITYHOOK] suppressed PurchaseStrategy.OnPurchaseFail self=%p", self);
    return;
}

static void RMUnitySendPurchaseFailHook(void *self, void *config, void *purchaseResult, bool isRoyalFavorFromMoreLives, const void *method) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigUnitySendPurchaseFail) RMOrigUnitySendPurchaseFail(self, config, purchaseResult, isRoyalFavorFromMoreLives, method);
        return;
    }
    RMLog(@"[UNITYHOOK] intercepted PurchaseStrategy.SendPurchaseFail self=%p config=%p result=%p royalFavor=%d", self, config, purchaseResult, isRoyalFavorFromMoreLives ? 1 : 0);
    RMForcePurchaseResultSuccess(purchaseResult, "SendPurchaseFail");
    if (RMOrigUnitySendPurchaseSuccess || RMUnitySendPurchaseSuccessFn) {
        RMLog(@"[UNITYHOOK] converted PurchaseStrategy.SendPurchaseFail -> SendPurchaseSuccess self=%p", self);
        RMUnitySendPurchaseSuccessHook(self, config, purchaseResult, isRoyalFavorFromMoreLives, RMUnitySendPurchaseSuccessMethodInfo ? RMUnitySendPurchaseSuccessMethodInfo : method);
        return;
    }
    RMGrantRewardsFromShopConfig(config, purchaseResult, "SendPurchaseFail-no-success-fn");
    RMLog(@"[UNITYHOOK] suppressed PurchaseStrategy.SendPurchaseFail without SendPurchaseSuccess fallback self=%p", self);
    return;
}

static void RMUnityOnVerificationResultHook(void *self, void *purchaseResult, const void *method) {
    if (RMFreeIAPEnabled) RMForcePurchaseResultSuccess(purchaseResult, "PurchaseManager.OnVerificationResult");
    if (RMOrigUnityOnVerificationResult) RMOrigUnityOnVerificationResult(self, purchaseResult, method);
}

static int32_t RMReadI32(void *base, ptrdiff_t off) {
    if (!base) return 0;
    return *((int32_t *)((uint8_t *)base + off));
}

static BOOL RMReadBool(void *base, ptrdiff_t off) {
    if (!base) return NO;
    return *((bool *)((uint8_t *)base + off)) ? YES : NO;
}

static void RMWriteBool(void *base, ptrdiff_t off, BOOL value) {
    if (!base) return;
    *((bool *)((uint8_t *)base + off)) = value ? true : false;
}

static void RMGrantRoyalPassOnInventory(void *inventory, const char *reason) {
    if (!inventory) { RMLog(@"[PASS] RoyalPass inventory unavailable reason=%s", reason); return; }
    BOOL oldGold = RMReadBool(inventory, 0x68 + 0x18);
    int64_t oldBits = *((int64_t *)((uint8_t *)inventory + 0x68));
    if (RMUserInventoryUpdateRoyalPassIsGoldFn && RMUserInventoryUpdateRoyalPassIsGoldMethodInfo) {
        RMUserInventoryUpdateRoyalPassIsGoldFn(inventory, true, RMUserInventoryUpdateRoyalPassIsGoldMethodInfo);
        RMLog(@"[PASS] RoyalPass UpdateRoyalPassIsGold(TRUE) reason=%s oldGold=%d bits=0x%llx", reason, oldGold ? 1 : 0, (long long)oldBits);
    } else {
        *((int64_t *)((uint8_t *)inventory + 0x68)) = oldBits | 1LL;
        RMWriteBool(inventory, 0x68 + 0x18, YES);
        RMLog(@"[PASS] RoyalPass raw grant reason=%s oldGold=%d bits=0x%llx->0x%llx", reason, oldGold ? 1 : 0, (long long)oldBits, (long long)(oldBits | 1LL));
    }
    RMRoyalPassGranted = YES;
    RMGrantProtectUntil = [NSDate.date timeIntervalSince1970] + 900.0;
}

static void RMGrantWeeklyPassWithManager(void *weeklyPassManager, const char *reason) {
    void *helper = weeklyPassManager ? *((void **)((uint8_t *)weeklyPassManager + 0x38)) : NULL;
    void *progress = weeklyPassManager ? *((void **)((uint8_t *)weeklyPassManager + 0x78)) : NULL;
    BOOL granted = NO;
    if (helper && RMWeeklyPassHelperSetPurchasedFn && RMWeeklyPassHelperSetPurchasedMethodInfo) {
        RMWeeklyPassHelperSetPurchasedFn(helper, RMWeeklyPassHelperSetPurchasedMethodInfo);
        RMLog(@"[PASS] WeeklyPass Helper.SetWeeklyPassPurchased reason=%s manager=%p helper=%p", reason, weeklyPassManager, helper);
        granted = YES;
    }
    if (progress && RMWeeklyPassProgressSetPurchasedFn && RMWeeklyPassProgressSetPurchasedMethodInfo) {
        RMWeeklyPassProgressSetPurchasedFn(progress, true, RMWeeklyPassProgressSetPurchasedMethodInfo);
        RMLog(@"[PASS] WeeklyPass Progress.SetIsPurchased(TRUE) reason=%s manager=%p progress=%p", reason, weeklyPassManager, progress);
        granted = YES;
    }
    if (!granted) RMLog(@"[PASS] WeeklyPass grant unavailable reason=%s manager=%p helper=%p progress=%p helperFn=%p progressFn=%p", reason, weeklyPassManager, helper, progress, RMWeeklyPassHelperSetPurchasedFn, RMWeeklyPassProgressSetPurchasedFn);
    RMWeeklyPassGranted = granted ? YES : RMWeeklyPassGranted;
    if (granted) RMGrantProtectUntil = [NSDate.date timeIntervalSince1970] + 900.0;
}

static void RMGrantPassFromConfig(void *config, const char *reason) {
    if (!config) return;
    BOOL isRoyalPass = RMReadBool(config, 0xA0);
    BOOL isWeeklyPass = RMReadBool(config, 0xAE);
    if (isRoyalPass) RMGrantRoyalPassOnInventory(RMCurrentUserInventory(), reason);
    if (isWeeklyPass) RMLog(@"[PASS] WeeklyPass config detected reason=%s; waiting for manager-backed hook", reason);
    if (isRoyalPass || isWeeklyPass) {
        RMLog(@"[PASS] config flags reason=%s config=%p royal=%d weekly=%d", reason, config, isRoyalPass ? 1 : 0, isWeeklyPass ? 1 : 0);
    }
}

static void RMUpdateInventoryMax(void *inventory, const char *reason) {
    if (!inventory) return;
    int32_t coins = RMReadI32(inventory, 0x10);
    int64_t inGame = *((int64_t *)((uint8_t *)inventory + 0x28));
    int64_t preLevel = *((int64_t *)((uint8_t *)inventory + 0x30));
    int32_t rocketEnd = RMReadI32(inventory, 0x38);
    int32_t tntEnd = RMReadI32(inventory, 0x3C);
    int32_t lightEnd = RMReadI32(inventory, 0x40);
    int64_t remaining = *((int64_t *)((uint8_t *)inventory + 0x48));
    if (coins > RMMaxCoins) RMMaxCoins = coins;
    if (inGame > RMMaxInGameInventory) RMMaxInGameInventory = inGame;
    if (preLevel > RMMaxPreLevelInventory) RMMaxPreLevelInventory = preLevel;
    if (rocketEnd > RMMaxRocketEndTime) RMMaxRocketEndTime = rocketEnd;
    if (tntEnd > RMMaxTntEndTime) RMMaxTntEndTime = tntEnd;
    if (lightEnd > RMMaxLightballEndTime) RMMaxLightballEndTime = lightEnd;
    if (remaining > RMMaxRemainingBoosterTimes) RMMaxRemainingBoosterTimes = remaining;
    RMLog(@"[GRANT] inventory max reason=%s inv=%p coins=%d inGame=%lld preLevel=%lld rocketEnd=%d tntEnd=%d lightEnd=%d remaining=%lld", reason, inventory, RMMaxCoins, (long long)RMMaxInGameInventory, (long long)RMMaxPreLevelInventory, RMMaxRocketEndTime, RMMaxTntEndTime, RMMaxLightballEndTime, (long long)RMMaxRemainingBoosterTimes);
}

static BOOL RMShouldProtectGrantedInventory(void) {
    return RMFreeIAPEnabled || [NSDate.date timeIntervalSince1970] < RMGrantProtectUntil;
}

static void *RMCurrentUserInventory(void) {
    @try {
        if (!RMUserManagerGetCurrentUserFn || !RMUserManagerGetCurrentUserMethodInfo) {
            RMUserManagerGetCurrentUserMethodInfo = RMResolveIl2CppMethodInfo("Royal.Player.Context.Units", "UserManager", "get_CurrentUser", 0);
            RMUserManagerGetCurrentUserFn = (void *(*)(const void *))RMMethodPointer(RMUserManagerGetCurrentUserMethodInfo);
            RMLog(@"[GRANT] resolved UserManager.get_CurrentUser fn=%p methodInfo=%p", RMUserManagerGetCurrentUserFn, RMUserManagerGetCurrentUserMethodInfo);
        }
        void *user = RMUserManagerGetCurrentUserFn ? RMUserManagerGetCurrentUserFn(RMUserManagerGetCurrentUserMethodInfo) : NULL;
        void *inventory = user ? *((void **)((uint8_t *)user + 0x20)) : NULL;
        RMLog(@"[GRANT] current user=%p inventory=%p", user, inventory);
        return inventory;
    } @catch (NSException *e) {
        RMLog(@"[GRANT] current inventory exception: %@", e);
        return NULL;
    }
}

static void RMGrantBoosterAmount(void *inventory, int boosterType, int amount, const char *name) {
    if (!inventory || amount <= 0) return;
    if (RMUserInventoryAddBoosterFn) {
        RMUserInventoryAddBoosterFn(inventory, boosterType, amount, RMUserInventoryAddBoosterMethodInfo);
        RMLog(@"[GRANT] AddBooster %s type=%d amount=%d", name, boosterType, amount);
    } else {
        RMLog(@"[GRANT] AddBooster missing %s type=%d amount=%d", name, boosterType, amount);
    }
}

static void RMGrantBoosterMinutes(void *inventory, int boosterType, int minutes, BOOL inGame, const char *name) {
    if (!inventory || minutes <= 0) return;
    int seconds = minutes * 60;
    if (inGame && RMUserInventoryAddInGameBoosterTimeFn) {
        RMUserInventoryAddInGameBoosterTimeFn(inventory, boosterType, seconds, RMUserInventoryAddInGameBoosterTimeMethodInfo);
        RMLog(@"[GRANT] AddInGameBoosterTime %s type=%d minutes=%d", name, boosterType, minutes);
    } else if (!inGame && RMUserInventoryAddTimeFn) {
        RMUserInventoryAddTimeFn(inventory, boosterType, seconds, RMUserInventoryAddTimeMethodInfo);
        RMLog(@"[GRANT] AddTime %s type=%d minutes=%d", name, boosterType, minutes);
    } else {
        RMLog(@"[GRANT] booster time fn missing %s type=%d minutes=%d inGame=%d", name, boosterType, minutes, inGame ? 1 : 0);
    }
}

static void RMGrantRewardsFromShopConfig(void *config, void *purchaseResult, const char *reason) {
    if (!RMFreeIAPEnabled) return;
    if (!config) { RMLog(@"[GRANT] no config reason=%s result=%p", reason, purchaseResult); return; }
    if (RMPurchaseSequence != 0 && RMLastGrantSequence == RMPurchaseSequence) {
        RMLog(@"[GRANT] skip duplicate seq=%lu reason=%s config=%p result=%p", (unsigned long)RMPurchaseSequence, reason, config, purchaseResult);
        return;
    }
    void *inventory = RMCurrentUserInventory();
    if (!inventory) { RMLog(@"[GRANT] inventory unavailable reason=%s config=%p result=%p", reason, config, purchaseResult); return; }
    RMGrantPassFromConfig(config, reason);

    int coins = RMReadI32(config, 0x48);
    if (RMShopPackageGetTotalCoinsWithBonusFn && RMShopPackageGetTotalCoinsWithBonusMethodInfo) {
        int total = RMShopPackageGetTotalCoinsWithBonusFn(config, RMShopPackageGetTotalCoinsWithBonusMethodInfo);
        if (total > coins) coins = total;
    }
    int hammerAmount = RMReadI32(config, 0x4C);
    int hammerMinutes = RMReadI32(config, 0x50);
    int cannonAmount = RMReadI32(config, 0x54);
    int cannonMinutes = RMReadI32(config, 0x58);
    int arrowAmount = RMReadI32(config, 0x5C);
    int arrowMinutes = RMReadI32(config, 0x60);
    int jesterAmount = RMReadI32(config, 0x64);
    int jesterMinutes = RMReadI32(config, 0x68);
    int rocketAmount = RMReadI32(config, 0x6C);
    int rocketMinutes = RMReadI32(config, 0x70);
    int tntAmount = RMReadI32(config, 0x74);
    int tntMinutes = RMReadI32(config, 0x78);
    int lightAmount = RMReadI32(config, 0x7C);
    int elixirAmount = RMReadI32(config, 0x80);
    int lightMinutes = RMReadI32(config, 0x84);
    int lifeMinutes = RMReadI32(config, 0x88);

    RMLog(@"[GRANT] start seq=%lu reason=%s config=%p result=%p coins=%d rocket=%d/%dm tnt=%d/%dm light=%d/%dm hammer=%d/%dm arrow=%d/%dm cannon=%d/%dm jester=%d/%dm elixir=%d lifeMin=%d", (unsigned long)RMPurchaseSequence, reason, config, purchaseResult, coins, rocketAmount, rocketMinutes, tntAmount, tntMinutes, lightAmount, lightMinutes, hammerAmount, hammerMinutes, arrowAmount, arrowMinutes, cannonAmount, cannonMinutes, jesterAmount, jesterMinutes, elixirAmount, lifeMinutes);

    RMUpdateInventoryMax(inventory, "before-grant");
    if (coins > 0 && RMUserInventoryAddCoinsFn) {
        RMUserInventoryAddCoinsFn(inventory, coins, true, RMUserInventoryAddCoinsMethodInfo);
        RMLog(@"[GRANT] AddCoins delta=%d", coins);
    }
    RMGrantBoosterAmount(inventory, 1, rocketAmount, "Rocket");
    RMGrantBoosterAmount(inventory, 2, tntAmount, "Tnt");
    RMGrantBoosterAmount(inventory, 3, lightAmount, "LightBall");
    RMGrantBoosterAmount(inventory, 4, hammerAmount, "Hammer");
    RMGrantBoosterAmount(inventory, 5, arrowAmount, "Arrow");
    RMGrantBoosterAmount(inventory, 6, cannonAmount, "Cannon");
    RMGrantBoosterAmount(inventory, 7, jesterAmount, "JesterHat");
    RMGrantBoosterMinutes(inventory, 1, rocketMinutes, NO, "Rocket");
    RMGrantBoosterMinutes(inventory, 2, tntMinutes, NO, "Tnt");
    RMGrantBoosterMinutes(inventory, 3, lightMinutes, NO, "LightBall");
    RMGrantBoosterMinutes(inventory, 4, hammerMinutes, YES, "Hammer");
    RMGrantBoosterMinutes(inventory, 5, arrowMinutes, YES, "Arrow");
    RMGrantBoosterMinutes(inventory, 6, cannonMinutes, YES, "Cannon");
    RMGrantBoosterMinutes(inventory, 7, jesterMinutes, YES, "JesterHat");

    RMUpdateInventoryMax(inventory, "after-grant");
    RMGrantProtectUntil = [NSDate.date timeIntervalSince1970] + 600.0;
    RMLastGrantSequence = RMPurchaseSequence;
    RMLog(@"[GRANT] done seq=%lu protectUntil=%.0f", (unsigned long)RMLastGrantSequence, RMGrantProtectUntil);
}

static void RMUnitySendPurchaseSuccessHook(void *self, void *config, void *purchaseResult, bool isRoyalFavorFromMoreLives, const void *method) {
    if (RMFreeIAPEnabled) {
        RMForcePurchaseResultSuccess(purchaseResult, "PurchaseStrategy.SendPurchaseSuccess");
        RMGrantRewardsFromShopConfig(config, purchaseResult, "SendPurchaseSuccess");
    }
    if (RMOrigUnitySendPurchaseSuccess) RMOrigUnitySendPurchaseSuccess(self, config, purchaseResult, isRoyalFavorFromMoreLives, method);
}

static void RMRoyalPassOnPurchaseSuccessHook(void *self, void *config, void *purchaseResult, const void *method) {
    if (RMFreeIAPEnabled) {
        RMLog(@"[PASS] RoyalPassPurchaseStrategy.OnPurchaseSuccess self=%p config=%p result=%p", self, config, purchaseResult);
        RMForcePurchaseResultSuccess(purchaseResult, "RoyalPassPurchaseStrategy.OnPurchaseSuccess");
        RMGrantRewardsFromShopConfig(config, purchaseResult, "RoyalPassStrategy.OnPurchaseSuccess");
        RMGrantRoyalPassOnInventory(RMCurrentUserInventory(), "RoyalPassStrategy.OnPurchaseSuccess");
    }
    if (RMOrigRoyalPassOnPurchaseSuccess) RMOrigRoyalPassOnPurchaseSuccess(self, config, purchaseResult, method);
}

static void RMWeeklyPassOnPurchaseSuccessHook(void *self, void *config, void *purchaseResult, const void *method) {
    if (RMFreeIAPEnabled) {
        RMLog(@"[PASS] WeeklyPassPurchaseStrategy.OnPurchaseSuccess self=%p config=%p result=%p", self, config, purchaseResult);
        RMForcePurchaseResultSuccess(purchaseResult, "WeeklyPassPurchaseStrategy.OnPurchaseSuccess");
        RMGrantRewardsFromShopConfig(config, purchaseResult, "WeeklyPassStrategy.OnPurchaseSuccess");
        void *popup = self ? *((void **)((uint8_t *)self + 0x20)) : NULL;
        void *manager = popup ? *((void **)((uint8_t *)popup + 0xF0)) : NULL;
        RMGrantWeeklyPassWithManager(manager, "WeeklyPassStrategy.OnPurchaseSuccess");
    }
    if (RMOrigWeeklyPassOnPurchaseSuccess) RMOrigWeeklyPassOnPurchaseSuccess(self, config, purchaseResult, method);
}

static void RMRoyalPassDialogPurchaseStrategySuccessHook(void *self, const void *method) {
    if (RMFreeIAPEnabled) {
        void *manager = self ? *((void **)((uint8_t *)self + 0x118)) : NULL;
        RMLog(@"[PASS] RoyalPassPurchaseDialog.PurchaseStrategySuccess self=%p manager=%p", self, manager);
        RMGrantRoyalPassOnInventory(RMCurrentUserInventory(), "RoyalPassDialog.PurchaseStrategySuccess");
    }
    if (RMOrigRoyalPassDialogPurchaseStrategySuccess) RMOrigRoyalPassDialogPurchaseStrategySuccess(self, method);
}

static void RMWeeklyPassDialogPurchaseStrategySuccessHook(void *self, const void *method) {
    if (RMFreeIAPEnabled) {
        void *manager = self ? *((void **)((uint8_t *)self + 0xB8)) : NULL;
        RMLog(@"[PASS] WeeklyPassPurchaseDialog.PurchaseStrategySuccess self=%p manager=%p", self, manager);
        RMGrantWeeklyPassWithManager(manager, "WeeklyPassDialog.PurchaseStrategySuccess");
    }
    if (RMOrigWeeklyPassDialogPurchaseStrategySuccess) RMOrigWeeklyPassDialogPurchaseStrategySuccess(self, method);
}


static bool RMUnityPurchaseResultIsSuccessHook(void *self, const void *method) {
    if (RMFreeIAPEnabled && self) {
        static NSUInteger logCount = 0;
        int32_t oldStatus = *((int32_t *)self);
        if (oldStatus != 3) {
            RMForcePurchaseResultSuccess(self, "PurchaseResult.get_IsSuccess");
            if (logCount < 20) {
                RMLog(@"[UNITYHOOK] forced PurchaseResult.IsSuccess=YES self=%p oldStatus=%d", self, oldStatus);
                logCount++;
            }
        }
        return true;
    }
    if (RMOrigUnityPurchaseResultIsSuccess) return RMOrigUnityPurchaseResultIsSuccess(self, method);
    return self && *((int32_t *)self) == 3;
}


static void RMUserInventoryUpdateCoinsHook(void *self, int newCoins, const void *method) {
    if (RMShouldProtectGrantedInventory() && newCoins < RMMaxCoins) {
        RMLog(@"[NOROLLBACK] UpdateCoins clamp %d -> %d", newCoins, RMMaxCoins);
        newCoins = RMMaxCoins;
    }
    if (RMOrigUserInventoryUpdateCoins) RMOrigUserInventoryUpdateCoins(self, newCoins, method);
    RMUpdateInventoryMax(self, "UpdateCoins");
}

static void RMUserInventorySetCoinsHook(void *self, int value, const void *method) {
    if (RMShouldProtectGrantedInventory() && value < RMMaxCoins) {
        RMLog(@"[NOROLLBACK] set_Coins clamp %d -> %d", value, RMMaxCoins);
        value = RMMaxCoins;
    }
    if (RMOrigUserInventorySetCoins) RMOrigUserInventorySetCoins(self, value, method);
    RMUpdateInventoryMax(self, "set_Coins");
}

static void RMUserInventoryUpdateInGameInventoryHook(void *self, int64_t value, const void *method) {
    if (RMShouldProtectGrantedInventory() && value < RMMaxInGameInventory) {
        RMLog(@"[NOROLLBACK] UpdateInGameInventory clamp %lld -> %lld", (long long)value, (long long)RMMaxInGameInventory);
        value = RMMaxInGameInventory;
    }
    if (RMOrigUserInventoryUpdateInGameInventory) RMOrigUserInventoryUpdateInGameInventory(self, value, method);
    RMUpdateInventoryMax(self, "UpdateInGameInventory");
}

static void RMUserInventoryUpdatePreLevelInventoryHook(void *self, int64_t value, const void *method) {
    if (RMShouldProtectGrantedInventory() && value < RMMaxPreLevelInventory) {
        RMLog(@"[NOROLLBACK] UpdatePreLevelInventory clamp %lld -> %lld", (long long)value, (long long)RMMaxPreLevelInventory);
        value = RMMaxPreLevelInventory;
    }
    if (RMOrigUserInventoryUpdatePreLevelInventory) RMOrigUserInventoryUpdatePreLevelInventory(self, value, method);
    RMUpdateInventoryMax(self, "UpdatePreLevelInventory");
}

static void RMUserInventoryUpdateRemainingBoosterTimesHook(void *self, int64_t value, const void *method) {
    if (RMShouldProtectGrantedInventory() && value < RMMaxRemainingBoosterTimes) {
        RMLog(@"[NOROLLBACK] UpdateRemainingBoosterTimes clamp %lld -> %lld", (long long)value, (long long)RMMaxRemainingBoosterTimes);
        value = RMMaxRemainingBoosterTimes;
    }
    if (RMOrigUserInventoryUpdateRemainingBoosterTimes) RMOrigUserInventoryUpdateRemainingBoosterTimes(self, value, method);
    RMUpdateInventoryMax(self, "UpdateRemainingBoosterTimes");
}

static void RMUserInventoryUpdateRocketEndTimeHook(void *self, int value, const void *method) {
    if (RMShouldProtectGrantedInventory() && value < RMMaxRocketEndTime) { RMLog(@"[NOROLLBACK] UpdateRocketEndTime clamp %d -> %d", value, RMMaxRocketEndTime); value = RMMaxRocketEndTime; }
    if (RMOrigUserInventoryUpdateRocketEndTime) RMOrigUserInventoryUpdateRocketEndTime(self, value, method);
    RMUpdateInventoryMax(self, "UpdateRocketEndTime");
}

static void RMUserInventoryUpdateTntEndTimeHook(void *self, int value, const void *method) {
    if (RMShouldProtectGrantedInventory() && value < RMMaxTntEndTime) { RMLog(@"[NOROLLBACK] UpdateTntEndTime clamp %d -> %d", value, RMMaxTntEndTime); value = RMMaxTntEndTime; }
    if (RMOrigUserInventoryUpdateTntEndTime) RMOrigUserInventoryUpdateTntEndTime(self, value, method);
    RMUpdateInventoryMax(self, "UpdateTntEndTime");
}

static void RMUserInventoryUpdateLightballEndTimeHook(void *self, int value, const void *method) {
    if (RMShouldProtectGrantedInventory() && value < RMMaxLightballEndTime) { RMLog(@"[NOROLLBACK] UpdateLightballEndTime clamp %d -> %d", value, RMMaxLightballEndTime); value = RMMaxLightballEndTime; }
    if (RMOrigUserInventoryUpdateLightballEndTime) RMOrigUserInventoryUpdateLightballEndTime(self, value, method);
    RMUpdateInventoryMax(self, "UpdateLightballEndTime");
}

static void RMUserInventoryUpdateRoyalPassIsGoldHook(void *self, bool isGold, const void *method) {
    if (RMShouldProtectGrantedInventory() && RMRoyalPassGranted && !isGold) {
        RMLog(@"[NOROLLBACK] UpdateRoyalPassIsGold clamp false -> true self=%p", self);
        isGold = true;
    }
    if (RMOrigUserInventoryUpdateRoyalPassIsGold) RMOrigUserInventoryUpdateRoyalPassIsGold(self, isGold, method);
}

static void RMWeeklyPassProgressSetIsPurchasedHook(void *self, bool isPurchased, const void *method) {
    if (RMShouldProtectGrantedInventory() && RMWeeklyPassGranted && !isPurchased) {
        RMLog(@"[NOROLLBACK] WeeklyPassProgress.SetIsPurchased clamp false -> true self=%p", self);
        isPurchased = true;
    }
    if (RMOrigWeeklyPassProgressSetIsPurchased) RMOrigWeeklyPassProgressSetIsPurchased(self, isPurchased, method);
}

static void RMHookIl2CppFunction(const char *ns, const char *klass, const char *name, int argc, void *hook, void **orig, NSString *label) {
    void *ptr = RMResolveIl2CppMethodPointer(ns, klass, name, argc);
    if (ptr && orig && !*orig) {
        MSHookFunction(ptr, hook, orig);
        RMLog(@"[UNITYHOOK] hooked %@ ptr=%p", label, ptr);
    }
}

static void RMInstallUnityGrantHooks(void) {
    if (RMUnityGrantHooksInstalled) return;
    @try {
        RMUserInventoryAddCoinsMethodInfo = RMResolveIl2CppMethodInfo("Royal.Player.Context.Data.Persistent", "UserInventory", "AddCoins", 2);
        RMUserInventoryAddCoinsFn = (void (*)(void *, int, bool, const void *))RMMethodPointer(RMUserInventoryAddCoinsMethodInfo);
        RMUserInventoryAddBoosterMethodInfo = RMResolveIl2CppMethodInfo("Royal.Player.Context.Data.Persistent", "UserInventory", "AddBooster", 2);
        RMUserInventoryAddBoosterFn = (void (*)(void *, int, int, const void *))RMMethodPointer(RMUserInventoryAddBoosterMethodInfo);
        RMUserInventoryAddTimeMethodInfo = RMResolveIl2CppMethodInfo("Royal.Player.Context.Data.Persistent", "UserInventory", "AddTime", 2);
        RMUserInventoryAddTimeFn = (void (*)(void *, int, int, const void *))RMMethodPointer(RMUserInventoryAddTimeMethodInfo);
        RMUserInventoryAddInGameBoosterTimeMethodInfo = RMResolveIl2CppMethodInfo("Royal.Player.Context.Data.Persistent", "UserInventory", "AddInGameBoosterTime", 2);
        RMUserInventoryAddInGameBoosterTimeFn = (void (*)(void *, int, int, const void *))RMMethodPointer(RMUserInventoryAddInGameBoosterTimeMethodInfo);
        RMShopPackageGetTotalCoinsWithBonusMethodInfo = RMResolveIl2CppMethodInfo("Royal.Scenes.Home.Ui.Sections.Shop.Package", "ShopPackageConfig", "get_TotalCoinsWithBonus", 0);
        RMShopPackageGetTotalCoinsWithBonusFn = (int (*)(void *, const void *))RMMethodPointer(RMShopPackageGetTotalCoinsWithBonusMethodInfo);
        RMUserInventoryUpdateRoyalPassIsGoldMethodInfo = RMResolveIl2CppMethodInfo("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateRoyalPassIsGold", 1);
        RMUserInventoryUpdateRoyalPassIsGoldFn = (void (*)(void *, bool, const void *))RMMethodPointer(RMUserInventoryUpdateRoyalPassIsGoldMethodInfo);
        RMWeeklyPassHelperSetPurchasedMethodInfo = RMResolveIl2CppMethodInfo("Royal.Scenes.Home.Ui.Dialogs.WeeklyPass.Scripts", "WeeklyPassHelper", "SetWeeklyPassPurchased", 0);
        RMWeeklyPassHelperSetPurchasedFn = (void (*)(void *, const void *))RMMethodPointer(RMWeeklyPassHelperSetPurchasedMethodInfo);
        RMWeeklyPassProgressSetPurchasedMethodInfo = RMResolveIl2CppMethodInfo("Royal.Player.Context.Data.Persistent", "WeeklyPassProgress", "SetIsPurchased", 1);
        RMWeeklyPassProgressSetPurchasedFn = (void (*)(void *, bool, const void *))RMMethodPointer(RMWeeklyPassProgressSetPurchasedMethodInfo);
        RMLog(@"[GRANT] resolved fns AddCoins=%p AddBooster=%p AddTime=%p AddInGameTime=%p TotalCoins=%p RoyalPassGold=%p WeeklyHelper=%p WeeklyProgress=%p", RMUserInventoryAddCoinsFn, RMUserInventoryAddBoosterFn, RMUserInventoryAddTimeFn, RMUserInventoryAddInGameBoosterTimeFn, RMShopPackageGetTotalCoinsWithBonusFn, RMUserInventoryUpdateRoyalPassIsGoldFn, RMWeeklyPassHelperSetPurchasedFn, RMWeeklyPassProgressSetPurchasedFn);

        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateCoins", 1, (void *)&RMUserInventoryUpdateCoinsHook, (void **)&RMOrigUserInventoryUpdateCoins, @"UserInventory.UpdateCoins");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "set_Coins", 1, (void *)&RMUserInventorySetCoinsHook, (void **)&RMOrigUserInventorySetCoins, @"UserInventory.set_Coins");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateInGameInventory", 1, (void *)&RMUserInventoryUpdateInGameInventoryHook, (void **)&RMOrigUserInventoryUpdateInGameInventory, @"UserInventory.UpdateInGameInventory");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdatePreLevelInventory", 1, (void *)&RMUserInventoryUpdatePreLevelInventoryHook, (void **)&RMOrigUserInventoryUpdatePreLevelInventory, @"UserInventory.UpdatePreLevelInventory");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateRemainingBoosterTimes", 1, (void *)&RMUserInventoryUpdateRemainingBoosterTimesHook, (void **)&RMOrigUserInventoryUpdateRemainingBoosterTimes, @"UserInventory.UpdateRemainingBoosterTimes");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateRocketEndTime", 1, (void *)&RMUserInventoryUpdateRocketEndTimeHook, (void **)&RMOrigUserInventoryUpdateRocketEndTime, @"UserInventory.UpdateRocketEndTime");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateTntEndTime", 1, (void *)&RMUserInventoryUpdateTntEndTimeHook, (void **)&RMOrigUserInventoryUpdateTntEndTime, @"UserInventory.UpdateTntEndTime");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateLightballEndTime", 1, (void *)&RMUserInventoryUpdateLightballEndTimeHook, (void **)&RMOrigUserInventoryUpdateLightballEndTime, @"UserInventory.UpdateLightballEndTime");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "UserInventory", "UpdateRoyalPassIsGold", 1, (void *)&RMUserInventoryUpdateRoyalPassIsGoldHook, (void **)&RMOrigUserInventoryUpdateRoyalPassIsGold, @"UserInventory.UpdateRoyalPassIsGold");
        RMHookIl2CppFunction("Royal.Player.Context.Data.Persistent", "WeeklyPassProgress", "SetIsPurchased", 1, (void *)&RMWeeklyPassProgressSetIsPurchasedHook, (void **)&RMOrigWeeklyPassProgressSetIsPurchased, @"WeeklyPassProgress.SetIsPurchased");
        RMUnityGrantHooksInstalled = YES;
    } @catch (NSException *e) {
        RMLog(@"[GRANT] install exception: %@", e);
    }
}

static void RMInstallUnityFailHooks(void) {
    @try {
        RMLog(@"[UNITYHOOK] install start");
        void *onFail = RMResolveIl2CppMethodPointer("Royal.Scenes.Home.Ui.Sections.Shop", "PurchaseStrategy", "OnPurchaseFail", 0);
        if (onFail && !RMOrigUnityOnPurchaseFail) {
            MSHookFunction(onFail, (void *)&RMUnityOnPurchaseFailHook, (void **)&RMOrigUnityOnPurchaseFail);
            RMLog(@"[UNITYHOOK] hooked PurchaseStrategy.OnPurchaseFail ptr=%p", onFail);
        }
        void *sendFail = RMResolveIl2CppMethodPointer("Royal.Scenes.Home.Ui.Sections.Shop", "PurchaseStrategy", "SendPurchaseFail", 3);
        if (sendFail && !RMOrigUnitySendPurchaseFail) {
            MSHookFunction(sendFail, (void *)&RMUnitySendPurchaseFailHook, (void **)&RMOrigUnitySendPurchaseFail);
            RMLog(@"[UNITYHOOK] hooked PurchaseStrategy.SendPurchaseFail ptr=%p", sendFail);
        }
        RMUnitySendPurchaseSuccessMethodInfo = RMResolveIl2CppMethodInfo("Royal.Scenes.Home.Ui.Sections.Shop", "PurchaseStrategy", "SendPurchaseSuccess", 3);
        RMUnitySendPurchaseSuccessFn = (void (*)(void *, void *, void *, bool, const void *))RMMethodPointer(RMUnitySendPurchaseSuccessMethodInfo);
        if (RMUnitySendPurchaseSuccessFn) RMLog(@"[UNITYHOOK] resolved PurchaseStrategy.SendPurchaseSuccess fn=%p methodInfo=%p", RMUnitySendPurchaseSuccessFn, RMUnitySendPurchaseSuccessMethodInfo);
        if (RMUnitySendPurchaseSuccessFn && !RMOrigUnitySendPurchaseSuccess) {
            MSHookFunction((void *)RMUnitySendPurchaseSuccessFn, (void *)&RMUnitySendPurchaseSuccessHook, (void **)&RMOrigUnitySendPurchaseSuccess);
            RMLog(@"[UNITYHOOK] hooked PurchaseStrategy.SendPurchaseSuccess ptr=%p", RMUnitySendPurchaseSuccessFn);
        }

        void *onVerificationResult = RMResolveIl2CppMethodPointer("Royal.Infrastructure.Services.Native.Purchase", "PurchaseManager", "OnVerificationResult", 1);
        if (onVerificationResult && !RMOrigUnityOnVerificationResult) {
            MSHookFunction(onVerificationResult, (void *)&RMUnityOnVerificationResultHook, (void **)&RMOrigUnityOnVerificationResult);
            RMLog(@"[UNITYHOOK] hooked PurchaseManager.OnVerificationResult ptr=%p", onVerificationResult);
        }
        void *isSuccess = RMResolveIl2CppMethodPointer("Royal.Infrastructure.Services.Native.Purchase", "PurchaseResult", "get_IsSuccess", 0);
        if (isSuccess && !RMOrigUnityPurchaseResultIsSuccess) {
            MSHookFunction(isSuccess, (void *)&RMUnityPurchaseResultIsSuccessHook, (void **)&RMOrigUnityPurchaseResultIsSuccess);
            RMLog(@"[UNITYHOOK] hooked PurchaseResult.get_IsSuccess ptr=%p", isSuccess);
        }
        RMHookIl2CppFunction("Royal.Scenes.Home.Ui.Dialogs.RoyalPass", "RoyalPassPurchaseStrategy", "OnPurchaseSuccess", 2, (void *)&RMRoyalPassOnPurchaseSuccessHook, (void **)&RMOrigRoyalPassOnPurchaseSuccess, @"RoyalPassPurchaseStrategy.OnPurchaseSuccess");
        RMHookIl2CppFunction("Royal.Scenes.Home.Ui.Dialogs.WeeklyPass.Scripts", "WeeklyPassPurchaseStrategy", "OnPurchaseSuccess", 2, (void *)&RMWeeklyPassOnPurchaseSuccessHook, (void **)&RMOrigWeeklyPassOnPurchaseSuccess, @"WeeklyPassPurchaseStrategy.OnPurchaseSuccess");
        RMHookIl2CppFunction("Royal.Scenes.Home.Ui.Dialogs.RoyalPass", "RoyalPassPurchaseDialog", "PurchaseStrategySuccess", 0, (void *)&RMRoyalPassDialogPurchaseStrategySuccessHook, (void **)&RMOrigRoyalPassDialogPurchaseStrategySuccess, @"RoyalPassPurchaseDialog.PurchaseStrategySuccess");
        RMHookIl2CppFunction("Royal.Scenes.Home.Ui.Dialogs.WeeklyPass.Scripts", "WeeklyPassPurchaseDialog", "PurchaseStrategySuccess", 0, (void *)&RMWeeklyPassDialogPurchaseStrategySuccessHook, (void **)&RMOrigWeeklyPassDialogPurchaseStrategySuccess, @"WeeklyPassPurchaseDialog.PurchaseStrategySuccess");
        RMInstallUnityGrantHooks();
        RMLog(@"[UNITYHOOK] install done");
    } @catch (NSException *e) {
        RMLog(@"[UNITYHOOK] install exception: %@", e);
    }
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


static id RMProductIDFromTransaction(id transaction) {
    if (!transaction) return nil;
    @try {
        if ([transaction respondsToSelector:@selector(payment)]) {
            id payment = ((id (*)(id, SEL))objc_msgSend)(transaction, @selector(payment));
            if (payment && [payment respondsToSelector:@selector(productIdentifier)]) {
                id pid = ((id (*)(id, SEL))objc_msgSend)(payment, @selector(productIdentifier));
                if ([pid isKindOfClass:NSString.class]) return pid;
            }
        }
    } @catch (NSException *e) {
        RMLog(@"product from transaction exception: %@", e);
    }
    return nil;
}

static id RMCurrentProductIDFromManager(id manager) {
    @try {
        if ([manager respondsToSelector:@selector(fetchThisProductToPurchase)]) {
            id pid = ((id (*)(id, SEL))objc_msgSend)(manager, @selector(fetchThisProductToPurchase));
            if (pid) return pid;
        }
    } @catch (NSException *e) {
        RMLog(@"fetch current product exception: %@", e);
    }
    return @"rm.fake.product";
}

static void RMPrepareManagerForSuccess(id manager, id productIdentifier) {
    if ([manager respondsToSelector:@selector(setFetchThisProductToPurchase:)]) {
        ((void (*)(id, SEL, id))objc_msgSend)(manager, @selector(setFetchThisProductToPurchase:), productIdentifier);
        RMLog(@"setFetchThisProductToPurchase:%@", RMProductIDFromObject(productIdentifier));
    }
    if ([manager respondsToSelector:@selector(setStartPurchaseCalled:)]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(manager, @selector(setStartPurchaseCalled:), YES);
        RMLog(@"setStartPurchaseCalled:YES");
    }
    if ([manager respondsToSelector:@selector(startPurchaseCalled)]) {
        BOOL called = ((BOOL (*)(id, SEL))objc_msgSend)(manager, @selector(startPurchaseCalled));
        RMLog(@"startPurchaseCalled now=%@", called ? @"YES" : @"NO");
    }
}

static void RMResetManagerAfterAck(id manager) {
    @try {
        if ([manager respondsToSelector:@selector(timer)]) {
            id timer = ((id (*)(id, SEL))objc_msgSend)(manager, @selector(timer));
            if (timer && [timer respondsToSelector:@selector(invalidate)]) {
                ((void (*)(id, SEL))objc_msgSend)(timer, @selector(invalidate));
                RMLog(@"timer invalidated");
            }
        }
        if ([manager respondsToSelector:@selector(setTimer:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(manager, @selector(setTimer:), nil);
            RMLog(@"setTimer:nil");
        }
        if ([manager respondsToSelector:@selector(setPurchaseQueryTimedOut:)]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(manager, @selector(setPurchaseQueryTimedOut:), NO);
            RMLog(@"setPurchaseQueryTimedOut:NO");
        }
        if ([manager respondsToSelector:@selector(setFetchThisProductToPurchase:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(manager, @selector(setFetchThisProductToPurchase:), nil);
            RMLog(@"setFetchThisProductToPurchase:nil");
        }
        if ([manager respondsToSelector:@selector(setStartPurchaseCalled:)]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(manager, @selector(setStartPurchaseCalled:), NO);
            RMLog(@"setStartPurchaseCalled:NO");
        }
    } @catch (NSException *e) {
        RMLog(@"reset manager exception: %@", e);
    }
}

static void RMCompleteWithProduct(id manager, id productIdentifier, NSString *reason) {
    RMFakeTransaction *tx = RMMakeFakeTransaction(productIdentifier);
    RMPurchaseSequence++;
    RMLog(@"%@ seq=%lu pid=%@ tx=%@", reason, (unsigned long)RMPurchaseSequence, tx.payment.productIdentifier, tx.transactionIdentifier);
    RMPrepareManagerForSuccess(manager, productIdentifier);

    Class resultClass = objc_getClass("DGPurchaseResult");
    id result = nil;
    if (resultClass) {
        result = ((id (*)(id, SEL))objc_msgSend)((id)resultClass, @selector(alloc));
        if ([result respondsToSelector:@selector(init:retry:)]) {
            result = ((id (*)(id, SEL, id, BOOL))objc_msgSend)(result, @selector(init:retry:), tx, NO);
        } else {
            RMLog(@"DGPurchaseResult init:retry: missing");
            result = nil;
        }
    } else {
        RMLog(@"DGPurchaseResult class missing");
    }

    id delegate = nil;
    if ([manager respondsToSelector:@selector(delegate)]) {
        delegate = ((id (*)(id, SEL))objc_msgSend)(manager, @selector(delegate));
    }

    if (delegate && result && [delegate respondsToSelector:@selector(didPurchase:)]) {
        ((void (*)(id, SEL, id))objc_msgSend)(delegate, @selector(didPurchase:), result);
        RMLog(@"called delegate didPurchase: reason=%@ delegate=%@", reason, delegate);
        RMResetManagerAfterAck(manager);
        return;
    }

    RMLog(@"direct delegate unavailable, fallback complete:retry: delegate=%@ result=%@", delegate, result);
    if ([manager respondsToSelector:@selector(complete:retry:)]) {
        ((void (*)(id, SEL, id, BOOL))objc_msgSend)(manager, @selector(complete:retry:), tx, NO);
        RMLog(@"fallback called complete:retry:NO reason=%@", reason);
    }
}

static void RMReplacedPurchase(id self, SEL _cmd, id productIdentifier) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigPurchaseImp) ((void (*)(id, SEL, id))RMOrigPurchaseImp)(self, _cmd, productIdentifier);
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            RMCompleteWithProduct(self, productIdentifier, @"intercept purchase");
        } @catch (NSException *e) {
            RMLog(@"exception in fake purchase complete: %@", e);
            if (RMOrigPurchaseImp) ((void (*)(id, SEL, id))RMOrigPurchaseImp)(self, _cmd, productIdentifier);
        }
    });
}


static void RMReplacedFail(id self, SEL _cmd, id transaction, BOOL retry) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigFailImp) ((void (*)(id, SEL, id, BOOL))RMOrigFailImp)(self, _cmd, transaction, retry);
        return;
    }
    id pid = RMProductIDFromTransaction(transaction);
    if (!pid) pid = RMCurrentProductIDFromManager(self);
    RMLog(@"suppressed fail:retry:%@ -> success pid=%@", retry ? @"YES" : @"NO", RMProductIDFromObject(pid));
    dispatch_async(dispatch_get_main_queue(), ^{
        @try { RMCompleteWithProduct(self, pid, @"fail-to-success fallback"); }
        @catch (NSException *e) { RMLog(@"exception in fail fallback: %@", e); }
    });
}

static void RMReplacedPurchaseQueryTimedOut(id self, SEL _cmd, id timer) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigTimeoutImp) ((void (*)(id, SEL, id))RMOrigTimeoutImp)(self, _cmd, timer);
        return;
    }
    id pid = RMCurrentProductIDFromManager(self);
    RMLog(@"suppressed purchase timeout -> success pid=%@", RMProductIDFromObject(pid));
    dispatch_async(dispatch_get_main_queue(), ^{
        @try { RMCompleteWithProduct(self, pid, @"timeout-to-success fallback"); }
        @catch (NSException *e) { RMLog(@"exception in timeout fallback: %@", e); }
    });
}


static BOOL RMIsFakeTransaction(id transaction) {
    return transaction && [transaction isKindOfClass:objc_getClass("RMFakeTransaction")];
}

static BOOL RMReplacedConsume(id self, SEL _cmd, id transaction) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigConsumeImp) return ((BOOL (*)(id, SEL, id))RMOrigConsumeImp)(self, _cmd, transaction);
        return NO;
    }
    RMLog(@"consume ACK forced YES transaction=%@ fake=%@", transaction, RMIsFakeTransaction(transaction) ? @"YES" : @"NO");
    RMResetManagerAfterAck(self);
    return YES;
}

static BOOL RMReplacedFinish(id self, SEL _cmd, id transaction) {
    if (!RMFreeIAPEnabled) {
        if (RMOrigFinishImp) return ((BOOL (*)(id, SEL, id))RMOrigFinishImp)(self, _cmd, transaction);
        return NO;
    }
    RMLog(@"finish ACK forced YES transaction=%@ fake=%@", transaction, RMIsFakeTransaction(transaction) ? @"YES" : @"NO");
    RMResetManagerAfterAck(self);
    return YES;
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
    if (class_getInstanceMethod(cls, @selector(fail:retry:))) {
        MSHookMessageEx(cls, @selector(fail:retry:), (IMP)RMReplacedFail, &RMOrigFailImp);
        RMLog(@"hooked -[DGPurchaseManager fail:retry:]");
    }
    if (class_getInstanceMethod(cls, @selector(purchaseQueryTimedOut:))) {
        MSHookMessageEx(cls, @selector(purchaseQueryTimedOut:), (IMP)RMReplacedPurchaseQueryTimedOut, &RMOrigTimeoutImp);
        RMLog(@"hooked -[DGPurchaseManager purchaseQueryTimedOut:]");
    }
    if (class_getInstanceMethod(cls, @selector(consume:))) {
        MSHookMessageEx(cls, @selector(consume:), (IMP)RMReplacedConsume, &RMOrigConsumeImp);
        RMLog(@"hooked -[DGPurchaseManager consume:]");
    }
    if (class_getInstanceMethod(cls, @selector(finish:))) {
        MSHookMessageEx(cls, @selector(finish:), (IMP)RMReplacedFinish, &RMOrigFinishImp);
        RMLog(@"hooked -[DGPurchaseManager finish:]");
    }
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
    hint.text = @"OFF by default; enable manually"; hint.textColor = UIColor.lightGrayColor; hint.font = [UIFont systemFontOfSize:11];
    [RMMenuView addSubview:title]; [RMMenuView addSubview:row]; [RMMenuView addSubview:sw]; [RMMenuView addSubview:hint];
    [root addSubview:RMMenuView]; [root addSubview:RMBallButton];
    objc_setAssociatedObject(root, @selector(RMInstallFloatingMenu), RMMenuController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    RMUIInstalled = YES;
    RMLog(@"floating menu installed on host window");
}

__attribute__((constructor)) static void RMEntry(void) {
    @autoreleasepool {
        NSUserDefaults *ud = NSUserDefaults.standardUserDefaults;
        if ([ud objectForKey:RMEnabledKey] == nil) { [ud setBool:NO forKey:RMEnabledKey]; [ud synchronize]; }
        RMFreeIAPEnabled = [ud boolForKey:RMEnabledKey];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:^(__unused NSNotification *note) {
            RMInstallHook(); RMInstallFloatingMenu();
        }];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RMInstallHook(); RMInstallFloatingMenu(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RMProbeIl2CppRuntime(); });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(13 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ RMInstallUnityFailHooks(); });
        RMLog(@"tweak loaded log=%@", RMLogPath());
    }
}
