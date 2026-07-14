#import "HangoLaunchEnvironmentHelper.h"
#import "HangoOPIString.h"
#import "HangoAESHelper.h"
#import "HangoHUD.h"
#import "HangoTheme.h"
#import "HangoAPITokenStore.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoMainTabBarController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoWelcomeViewController.h"
#import "HangoFluxHostViewController.h"
#import "HangoRequestManager.h"
#import "HangoAppRouter.h"
#import "HangoAppConfig.h"
#import "HangoStartupCoordinator.h"

static NSString * const kHangoWebURLKey = @"HangoWebURL";

#if DEBUG
#define HangoStartupLog(fmt, ...) NSLog(@"[HangoStartup] " fmt, ##__VA_ARGS__)
#else
#define HangoStartupLog(fmt, ...)
#endif

@implementation HangoLaunchDecision
@end

@implementation HangoStartupCoordinator {
    BOOL _quickLoginTransitionAnimated;
    void (^_launchFetchBlock)(void);
    NSUInteger _launchFetchGeneration;
    BOOL _launchFetchInFlight;
    BOOL _awaitingWirelessDataPermission;
    CFAbsoluteTime _lastBecomeActiveRetryAt;
}

static const NSTimeInterval kHangoLaunchRetryInterval = 2.0;
static const NSTimeInterval kHangoLaunchDNSRetryInterval = 4.0;
static const NSTimeInterval kHangoLaunchPermissionSettleDelay = 4.0;
static const NSTimeInterval kHangoLaunchBecomeActiveDebounce = 3.0;
static const NSTimeInterval kHangoLaunchRequestWatchdog = 12.0;
static const NSTimeInterval kHangoLaunchMaxWallTime = 75.0;
static const NSInteger kHangoLaunchMaxNetworkRetries = 20;
static const NSInteger kHangoLaunchMaxDNSRetriesAfterPermission = 6;

+ (instancetype)shared {
    static HangoStartupCoordinator *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HangoStartupCoordinator alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)hasSession {
    return [HangoAPITokenStore sessionToken].length > 0;
}

- (void)saveSessionToken:(NSString *)token {
    [HangoAPITokenStore setSessionToken:token];
}

- (NSString *)webURLString {
    NSString *stored = [NSUserDefaults.standardUserDefaults stringForKey:kHangoWebURLKey];
    return stored.length > 0 ? stored : HangoWebsiteURLString();
}

- (NSString *)webEntryURLString {
    NSString *base = [self webURLString];

    long long timestampMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    NSDictionary *openParams = @{
        HangoOPIWebKeyToken(): [HangoAPITokenStore sessionToken] ?: @"",
        HangoOPIWebKeyTimestamp(): @(timestampMs),
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:openParams options:0 error:nil];
    NSString *jsonString = jsonData.length > 0 ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"{}";

    NSString *encrypted = [HangoAESHelper encryptString:jsonString error:nil] ?: @"";
    NSString *encoded = [encrypted stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] ?: encrypted;

    NSString *separator = [base containsString:@"?"] ? @"&" : @"?";
    return [NSString stringWithFormat:@"%@%@%@=%@&%@=%@", base, separator, HangoOPIWebKeyOpenParams(), encoded, HangoOPIKeyAppId(), HangoAppId];
}

- (void)storeWebURL:(NSString *)url {
    if (url.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setObject:url forKey:kHangoWebURLKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (NSString *)stringFromValue:(id)value {
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return nil;
}

- (BOOL)hasReachedPortalGateEpoch:(NSTimeInterval)epoch {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    return now >= epoch;
}

- (BOOL)isFirstTimeLogin {
    // First-time login is determined solely by whether the user token is empty.
    return [HangoAPITokenStore sessionToken].length == 0;
}

- (BOOL)isLaunchEligibleCode:(id)value {
    NSString *code = [self stringFromValue:value];
    return [code isEqualToString:HangoOPISuccessCode()];
}

- (BOOL)isRetryableLaunchNetworkError:(NSError *)error {
    if (!error) {
        return NO;
    }
    if ([error.domain isEqualToString:NSURLErrorDomain]) {
        switch (error.code) {
            case NSURLErrorNotConnectedToInternet:
            case NSURLErrorNetworkConnectionLost:
            case NSURLErrorDataNotAllowed:
            case NSURLErrorTimedOut:
            case NSURLErrorCannotFindHost:
            case NSURLErrorCannotConnectToHost:
            case NSURLErrorDNSLookupFailed:
            case NSURLErrorInternationalRoamingOff:
                return YES;
            default:
                break;
        }
    }
    return NO;
}

- (BOOL)isNetworkPathSatisfiedInError:(NSError *)error {
    for (NSError *node = error; node != nil; node = node.userInfo[NSUnderlyingErrorKey]) {
        id pathReport = node.userInfo[@"_NSURLErrorNWPathKey"];
        if (![pathReport isKindOfClass:NSString.class]) {
            continue;
        }
        NSString *path = (NSString *)pathReport;
        if ([path rangeOfString:@"unsatisfied" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return NO;
        }
        if ([path rangeOfString:@"satisfied" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isNetworkPermissionDeniedInError:(NSError *)error {
    for (NSError *node = error; node != nil; node = node.userInfo[NSUnderlyingErrorKey]) {
        id pathReport = node.userInfo[@"_NSURLErrorNWPathKey"];
        if ([pathReport isKindOfClass:NSString.class] && [pathReport rangeOfString:@"Denied" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isStaleDNSAfterPermissionGrantError:(NSError *)error {
    if (![self isRetryableLaunchNetworkError:error]) {
        return NO;
    }
    if (error.code != NSURLErrorCannotFindHost && error.code != NSURLErrorDNSLookupFailed) {
        return NO;
    }
    return [self isNetworkPathSatisfiedInError:error];
}

- (NSTimeInterval)retryDelayForLaunchError:(NSError *)error {
    if ([self isStaleDNSAfterPermissionGrantError:error]) {
        return kHangoLaunchDNSRetryInterval;
    }
    if ([self isNetworkPermissionDeniedInError:error]) {
        return kHangoLaunchRetryInterval;
    }
    return kHangoLaunchRetryInterval;
}

- (void)scheduleLaunchFetchRetryWithDelay:(NSTimeInterval)delay block:(void (^)(void))block {
    if (!block) {
        return;
    }
    _launchFetchBlock = block;
    NSUInteger generation = _launchFetchGeneration;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (generation != self->_launchFetchGeneration || !self->_launchFetchBlock) {
            return;
        }
        self->_launchFetchBlock();
    });
}

- (void)clearPendingLaunchFetch {
    _launchFetchGeneration += 1;
    _launchFetchBlock = nil;
    _launchFetchInFlight = NO;
}

- (void)handleApplicationDidBecomeActive {
    if (!_launchFetchBlock || !_awaitingWirelessDataPermission) {
        return;
    }
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    if (_lastBecomeActiveRetryAt > 0 && (now - _lastBecomeActiveRetryAt) < kHangoLaunchBecomeActiveDebounce) {
        return;
    }
    _lastBecomeActiveRetryAt = now;
    HangoStartupLog(@"network permission likely granted, retry startup config after settle delay");
    _launchFetchGeneration += 1;
    _launchFetchInFlight = NO;
    [[HangoRequestManager shared] cancelLaunchRequest];
    [[HangoRequestManager shared] resetNetworkSessionForLaunchRetry];
    void (^retryBlock)(void) = _launchFetchBlock;
    [self scheduleLaunchFetchRetryWithDelay:kHangoLaunchPermissionSettleDelay block:retryBlock];
}

- (void)fetchLaunchEligibilityStayingOnSplashWithCompletion:(void (^)(NSDictionary * _Nullable eligibility, NSError * _Nullable error))completion {
    if (!completion) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    __block NSInteger attempt = 0;
    __block NSInteger dnsSatisfiedFailures = 0;
    __block BOOL finished = NO;
    __block void (^tryFetch)(void);
    __block void (^finishWithResult)(NSDictionary *, NSError *);
    finishWithResult = ^(NSDictionary *eligibility, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || finished) {
            return;
        }
        finished = YES;
        [strongSelf clearPendingLaunchFetch];
        completion(eligibility, error);
    };

    CFAbsoluteTime startedAt = CFAbsoluteTimeGetCurrent();
    tryFetch = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || finished) {
            return;
        }
        if (strongSelf->_launchFetchInFlight) {
            return;
        }

        NSTimeInterval elapsed = CFAbsoluteTimeGetCurrent() - startedAt;
        if (elapsed >= kHangoLaunchMaxWallTime) {
            HangoStartupLog(@"startup config timeout, route primary");
            finishWithResult(nil, [NSError errorWithDomain:@"HangoStartup"
                                                      code:-1
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Launch request timed out."}]);
            return;
        }

        strongSelf->_launchFetchBlock = tryFetch;
        strongSelf->_launchFetchInFlight = YES;
        NSUInteger requestToken = ++strongSelf->_launchFetchGeneration;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kHangoLaunchRequestWatchdog * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) watchdogSelf = weakSelf;
            if (!watchdogSelf || finished || requestToken != watchdogSelf->_launchFetchGeneration) {
                return;
            }
            if (!watchdogSelf->_launchFetchInFlight) {
                return;
            }
            HangoStartupLog(@"startup request watchdog fired, retry on splash");
            watchdogSelf->_launchFetchGeneration += 1;
            watchdogSelf->_launchFetchInFlight = NO;
            [[HangoRequestManager shared] cancelLaunchRequest];
            [[HangoRequestManager shared] resetNetworkSessionForLaunchRetry];
            [watchdogSelf scheduleLaunchFetchRetryWithDelay:1.0 block:tryFetch];
        });

        [[HangoRequestManager shared] preflightDNSForAPIHostWithCompletion:^(BOOL dnsResolved) {
            __strong typeof(weakSelf) innerSelf = weakSelf;
            if (!innerSelf || finished || requestToken != innerSelf->_launchFetchGeneration) {
                return;
            }
            if (!dnsResolved) {
                innerSelf->_awaitingWirelessDataPermission = YES;
                innerSelf->_launchFetchInFlight = NO;
                attempt += 1;
                if (attempt >= kHangoLaunchMaxNetworkRetries) {
                    HangoStartupLog(@"DNS preflight exhausted, route primary");
                    finishWithResult(nil, [NSError errorWithDomain:@"HangoStartup"
                                                              code:-2
                                                          userInfo:@{NSLocalizedDescriptionKey: @"DNS lookup failed."}]);
                    return;
                }
                HangoStartupLog(@"DNS not ready yet (attempt %ld), stay on splash", (long)attempt);
                [[HangoRequestManager shared] resetNetworkSessionForLaunchRetry];
                [innerSelf scheduleLaunchFetchRetryWithDelay:kHangoLaunchDNSRetryInterval block:tryFetch];
                return;
            }

            innerSelf->_awaitingWirelessDataPermission = NO;
            [[HangoRequestManager shared] fetchLaunchEligibilityWithCompletion:^(NSDictionary *eligibility, NSError *eligibilityError) {
            __strong typeof(weakSelf) httpSelf = weakSelf;
            if (!httpSelf || finished || requestToken != httpSelf->_launchFetchGeneration) {
                return;
            }
            httpSelf->_launchFetchInFlight = NO;

            if (!eligibilityError && eligibility.count > 0) {
                finishWithResult(eligibility, nil);
                return;
            }

            if ([httpSelf isNetworkPermissionDeniedInError:eligibilityError]) {
                httpSelf->_awaitingWirelessDataPermission = YES;
            }

            BOOL canRetry = [httpSelf isRetryableLaunchNetworkError:eligibilityError] && attempt < kHangoLaunchMaxNetworkRetries;
            if ([httpSelf isStaleDNSAfterPermissionGrantError:eligibilityError]) {
                dnsSatisfiedFailures += 1;
                if (dnsSatisfiedFailures >= kHangoLaunchMaxDNSRetriesAfterPermission) {
                    HangoStartupLog(@"DNS still failing after permission, route primary");
                    finishWithResult(eligibility, eligibilityError);
                    return;
                }
            }
            if (canRetry) {
                attempt += 1;
                NSTimeInterval delay = [httpSelf retryDelayForLaunchError:eligibilityError];
                if ([httpSelf isStaleDNSAfterPermissionGrantError:eligibilityError]) {
                    HangoStartupLog(@"startup DNS cache stale after permission (attempt %ld), refresh session", (long)attempt);
                    [[HangoRequestManager shared] resetNetworkSessionForLaunchRetry];
                    delay = kHangoLaunchDNSRetryInterval;
                } else if ([httpSelf isNetworkPermissionDeniedInError:eligibilityError]) {
                    HangoStartupLog(@"waiting for network permission (attempt %ld), stay on splash", (long)attempt);
                } else {
                    HangoStartupLog(@"waiting for network (attempt %ld), stay on splash", (long)attempt);
                }
                [httpSelf scheduleLaunchFetchRetryWithDelay:delay block:tryFetch];
                return;
            }

            finishWithResult(eligibility, eligibilityError);
        }];
        }];
    };

    _launchFetchInFlight = NO;
    _awaitingWirelessDataPermission = YES;
    _lastBecomeActiveRetryAt = 0;
    [self clearPendingLaunchFetch];
    tryFetch();
}

- (void)resolveLaunchDecisionWithCompletion:(void (^)(HangoLaunchDecision *))completion {
    if (!completion) {
        return;
    }

    // Before portal gate epoch: force primary route without calling startup config API.
    if (![self hasReachedPortalGateEpoch:HangoPortalGateEpoch()]) {
        HangoStartupLog(@"before gate epoch, route primary");
        HangoLaunchDecision *decision = [[HangoLaunchDecision alloc] init];
        decision.route = HangoLaunchRouteNative;
        completion(decision);
        return;
    }

    HangoStartupLog(@"fetching startup config on splash");
    [self fetchLaunchEligibilityStayingOnSplashWithCompletion:^(NSDictionary *eligibility, NSError *eligibilityError) {
        HangoStartupLog(@"startup config response=%@ error=%@", eligibility, eligibilityError);

        HangoLaunchDecision *decision = [[HangoLaunchDecision alloc] init];

        if (eligibilityError || eligibility.count == 0) {
            HangoStartupLog(@"startup config failed, route primary");
            decision.route = HangoLaunchRouteNative;
            completion(decision);
            return;
        }

        NSString *code = [self stringFromValue:eligibility[HangoOPIResponseKeyCode()]];
        BOOL eligible = [self isLaunchEligibleCode:code];
        HangoStartupLog(@"startup config code=%@ eligible=%@", code, eligible ? @"YES" : @"NO");

        if (!eligible) {
            HangoStartupLog(@"ineligible code, route primary");
            decision.route = HangoLaunchRouteNative;
            completion(decision);
            return;
        }

        NSDictionary *data = [eligibility[HangoOPIResponseKeyData()] isKindOfClass:NSDictionary.class] ? eligibility[HangoOPIResponseKeyData()] : eligibility;
        NSString *openValue = [data[HangoOPIResponseKeyOpenValue()] isKindOfClass:NSString.class] ? data[HangoOPIResponseKeyOpenValue()] : nil;
        [self storeWebURL:openValue];
        decision.webURLString = openValue;

        if ([self isFirstTimeLogin]) {
            HangoStartupLog(@"eligible, no session → onboarding");
            decision.route = HangoLaunchRouteOnboarding;
        } else {
            HangoStartupLog(@"eligible, has session → alternate");
            decision.route = HangoLaunchRouteWeb;
        }
        completion(decision);
    }];
}

- (void)resolveLaunchDecisionAndApplyToWindow:(UIWindow *)window {
    if (!window) {
        return;
    }

    BOOL pastPortalGate = [self hasReachedPortalGateEpoch:HangoPortalGateEpoch()];
    if (pastPortalGate) {
        // Stay on splash with a spinner until startup config finishes.
        [self showLaunchSplashWaitingIndicatorInWindow:window];
    }

    __weak typeof(self) weakSelf = self;
    [self resolveLaunchDecisionWithCompletion:^(HangoLaunchDecision *decision) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        if (pastPortalGate) {
            [strongSelf hideLaunchSplashWaitingIndicatorInWindow:window];
        }
        [strongSelf applyLaunchDecision:decision toWindow:window];
    }];
}

- (UIViewController *)nativeRootViewController {
    if ([HangoSessionManager shared].isLoggedIn) {
        if ([[HangoDataStore shared] hasCompletedProfile]) {
            HangoMainTabBarController *tab = [HangoMainTabBarController mainTabBarController];
            tab.selectedIndex = HangoTabIndexHome;
            return tab;
        }
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[HangoProfileSetupViewController alloc] init]];
        nav.navigationBarHidden = YES;
        return nav;
    }

    if ([HangoSessionManager shared].isGuest) {
        HangoMainTabBarController *tab = [HangoMainTabBarController mainTabBarController];
        tab.selectedIndex = HangoTabIndexHome;
        return tab;
    }

    return [HangoAppRouter authEntryViewController];
}

- (UINavigationController *)onboardingNavigationController {
    HangoWelcomeViewController *welcome = [[HangoWelcomeViewController alloc] init];
    welcome.onboardingMode = YES;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcome];
    nav.navigationBarHidden = YES;
    return nav;
}

- (UIViewController *)launchSplashViewController {
    UIViewController *loading = [[UIViewController alloc] init];
    loading.view.backgroundColor = [HangoTheme backgroundTopColor];

    UIImageView *splash = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"launch_splash"]];
    splash.contentMode = UIViewContentModeScaleAspectFill;
    splash.clipsToBounds = YES;
    splash.translatesAutoresizingMaskIntoConstraints = NO;
    [loading.view addSubview:splash];

    [NSLayoutConstraint activateConstraints:@[
        [splash.topAnchor constraintEqualToAnchor:loading.view.topAnchor],
        [splash.bottomAnchor constraintEqualToAnchor:loading.view.bottomAnchor],
        [splash.leadingAnchor constraintEqualToAnchor:loading.view.leadingAnchor],
        [splash.trailingAnchor constraintEqualToAnchor:loading.view.trailingAnchor],
    ]];
    return loading;
}

- (void)showLaunchSplashWaitingIndicatorInWindow:(UIWindow *)window {
    UIView *container = window.rootViewController.view;
    if (!container) {
        return;
    }
    if ([container viewWithTag:0x48414E47]) {
        return;
    }
    [HangoHUD showHUDAddedTo:container animated:YES];
}

- (void)hideLaunchSplashWaitingIndicatorInWindow:(UIWindow *)window {
    UIView *container = window.rootViewController.view;
    if (!container) {
        return;
    }
    [HangoHUD hideHUDForView:container animated:YES];
}

- (void)showLaunchSplashInWindow:(UIWindow *)window {
    window.rootViewController = [self launchSplashViewController];
    [window makeKeyAndVisible];
}

- (void)enterNativeInWindow:(UIWindow *)window {
    window.rootViewController = [self nativeRootViewController];
    [window makeKeyAndVisible];
}

- (void)enterWebQuickLoginInWindow:(UIWindow *)window animated:(BOOL)animated {
    [HangoAPITokenStore setSessionToken:@""];
    [HangoAPITokenStore setInitialPassword:@""];

    _quickLoginTransitionAnimated = animated;

    __weak typeof(self) weakSelf = self;
    void (^showOnboarding)(void) = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        UINavigationController *nav = [strongSelf onboardingNavigationController];
        if (!strongSelf->_quickLoginTransitionAnimated) {
            window.rootViewController = nav;
            [window makeKeyAndVisible];
            return;
        }
        [HangoAppRouter setRootViewController:nav animated:YES];
    };

    showOnboarding();
}

- (void)enterWebInWindow:(UIWindow *)window animated:(BOOL)animated {
    HangoFluxHostViewController *fluxHost = [[HangoFluxHostViewController alloc] init];
    if (!animated) {
        window.rootViewController = fluxHost;
        [window makeKeyAndVisible];
        return;
    }
    [HangoAppRouter setRootViewController:fluxHost animated:YES];
}

- (void)applyLaunchDecision:(HangoLaunchDecision *)decision toWindow:(UIWindow *)window {
    switch (decision.route) {
        case HangoLaunchRouteNative:
            [self enterNativeInWindow:window];
            break;
        case HangoLaunchRouteWeb:
            window.rootViewController = [[HangoFluxHostViewController alloc] init];
            [window makeKeyAndVisible];
            break;
        case HangoLaunchRouteOnboarding:
            window.rootViewController = [self onboardingNavigationController];
            [window makeKeyAndVisible];
            break;
    }
}

- (void)completeWebEntryFromViewController:(UIViewController *)viewController
                                completion:(void (^)(BOOL, NSError *))completion {
    NSDictionary *params = [HangoLaunchEnvironmentHelper loginRequestPayload];
    HangoStartupLog(@"auth request submitted");

    [[HangoRequestManager shared] submitAuthWithParameters:params
                                                    inView:viewController.view
                                                  showsHUD:YES
                                                completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(NO, error);
            }
            return;
        }

        NSDictionary *data = [response[HangoOPIResponseKeyData()] isKindOfClass:NSDictionary.class] ? response[HangoOPIResponseKeyData()] : response;
        NSString *token = [data[HangoOPIResponseKeyToken()] isKindOfClass:NSString.class] ? data[HangoOPIResponseKeyToken()] : nil;
        if (token.length == 0) {
            NSError *tokenError = [NSError errorWithDomain:@"HangoStartup"
                                                      code:1
                                                  userInfo:@{NSLocalizedDescriptionKey: @"Entry failed. Please try again."}];
            if (completion) {
                completion(NO, tokenError);
            }
            return;
        }

        [self saveSessionToken:token];

        // First-time new users also receive an initial password from the server.
        NSString *password = [data[HangoOPIResponseKeyPassword()] isKindOfClass:NSString.class] ? data[HangoOPIResponseKeyPassword()] : nil;
        if (password.length > 0) {
            [HangoAPITokenStore setInitialPassword:password];
        }

        if (completion) {
            completion(YES, nil);
        }
    }];
}

@end
