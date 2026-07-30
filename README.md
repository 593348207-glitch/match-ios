# RoyalIAPHook for Royal Match 37314

Rootless jailbreak tweak for `com.dreamgames.royalmatch`.

## Build

Push to GitHub, then open Actions -> Build rootless deb -> Run workflow.
Download artifact `RoyalIAPHook-rootless-deb`.

## Cleanup old broken package on device

```bash
dpkg --remove --force-remove-reinstreq com.ctf.royal.iaphook.rootless 2>/dev/null || true
dpkg --remove --force-remove-reinstreq com.ctf.royal.iaphook 2>/dev/null || true
rm -f /var/jb/Library/MobileSubstrate/DynamicLibraries/RoyalIAPHook.dylib
rm -f /var/jb/Library/MobileSubstrate/DynamicLibraries/RoyalIAPHook.plist
sbreload || killall -9 SpringBoard
```

## Logs

```bash
log stream --predicate 'process == "RoyalMatch" OR eventMessage CONTAINS "RM-IAP"' --style compact
```

## Default state

The floating ball is visible, the menu is collapsed, and the Free IAP switch is OFF by default. Tap the IAP ball and enable it manually when needed.

## 1.0.9 fix

The hook now sets DGPurchaseManager.startPurchaseCalled=YES before complete:retry:NO, matching the native success path and preventing the purchase spinner from waiting forever.

## 1.0.9 probe

Adds IL2CPP runtime class/method enumeration for purchase, shop package, inventory, verifier, reward, booster, coin and UserGameData symbols. Probe output is written to `Documents/RoyalMatchIAPHook.log`.
