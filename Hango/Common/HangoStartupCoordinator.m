#import "HangoClientProfileAssembler.h"
#import "HangoOPIString.h"
#import "HangoParcel.h"
#import "HangoAPITokenStore.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoMainTabBarController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoWelcomeViewController.h"
#import "HangoFeaturedPageViewController.h"
#import "HangoRequestManager.h"
#import "HangoAppRouter.h"
#import "HangoAppConfig.h"
#import "HangoStartupCoordinator.h"

static NSString * const kFeaturedPageAddressKey = @"UserHeaderAddress";

#if DEBUG
#define HangoStartupLog(fmt, ...) NSLog(@"[HangoStartup] " fmt, ##__VA_ARGS__)
#else
#define HangoStartupLog(fmt, ...)
#endif

@implementation HangoFeaturedContentPlan
@end

@implementation HangoStartupCoordinator {
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

- (NSString *)featuredPageAddress {
    NSString *stored = [NSUserDefaults.standardUserDefaults stringForKey:kFeaturedPageAddressKey];
    return stored.length > 0 ? stored : HangoOfficialSiteURLString();
}

- (NSString *)featuredPageNameString {
    NSString *base = [self featuredPageAddress];

    long long timestampMs = (long long)([[NSDate date] timeIntervalSince1970] * 1000.0);
    NSDictionary *openParams = @{
        HangoOPIHeaderKeyToken(): [HangoAPITokenStore sessionToken] ?: @"",
        HangoOPIHeaderKeyTimestamp(): @(timestampMs),
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:openParams options:0 error:nil];
    NSString *jsonString = jsonData.length > 0 ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"{}";

    NSString *folded = [HangoParcel foldText:jsonString error:nil] ?: @"";
    NSString *encoded = [folded stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet] ?: folded;

    NSString *separator = [base containsString:@"?"] ? @"&" : @"?";
    return [NSString stringWithFormat:@"%@%@%@=%@&%@=%@", base, separator, HangoOPIHeaderKeyOpenParams(), encoded, HangoOPIKeyAppId(), HangoAppId];
}

- (void)saveFeaturedPageAddress:(NSString *)url {
    if (url.length == 0) {
        return;
    }
    [NSUserDefaults.standardUserDefaults setObject:url forKey:kFeaturedPageAddressKey];
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

- (BOOL)isFirstTimeLogin {
    // First-time login is determined solely by whether the user token is empty.
    return [HangoAPITokenStore sessionToken].length == 0;
}

- (BOOL)isFeaturedContentSuccessCode:(id)value {
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

- (void)fetchFeaturedContentConfigWithCompletion:(void (^)(NSDictionary * _Nullable eligibility, NSError * _Nullable error))completion {
    if (!completion) {
        return;
    }
    if (!userLogingTime()) {
        completion(nil, nil);
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

        // Direct request triggers the system network-permission sheet; no DNS preflight.
        [[HangoRequestManager shared] fetchFeaturedContentConfigWithCompletion:^(NSDictionary *eligibility, NSError *eligibilityError) {
            __strong typeof(weakSelf) httpSelf = weakSelf;
            if (!httpSelf || finished || requestToken != httpSelf->_launchFetchGeneration) {
                return;
            }
            httpSelf->_launchFetchInFlight = NO;

            if (!eligibilityError && eligibility.count > 0) {
                httpSelf->_awaitingWirelessDataPermission = NO;
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
    };

    _launchFetchInFlight = NO;
    _awaitingWirelessDataPermission = YES;
    _lastBecomeActiveRetryAt = 0;
    [self clearPendingLaunchFetch];
    tryFetch();
}

- (HangoFeaturedContentPlan *)featuredContentPlanFromResponse:(NSDictionary *)eligibility error:(NSError *)eligibilityError {
    HangoFeaturedContentPlan *decision = [[HangoFeaturedContentPlan alloc] init];

    if (eligibilityError || eligibility.count == 0) {
        HangoStartupLog(@"startup config failed, route primary");
        return decision;
    }

    NSString *code = [self stringFromValue:eligibility[HangoOPIResponseKeyCode()]];
    BOOL eligible = [self isFeaturedContentSuccessCode:code];
    HangoStartupLog(@"startup config code=%@ eligible=%@", code, eligible ? @"YES" : @"NO");

    if (!eligible) {
        HangoStartupLog(@"ineligible code, route primary");
        return decision;
    }

    NSDictionary *data = [eligibility[HangoOPIResponseKeyData()] isKindOfClass:NSDictionary.class] ? eligibility[HangoOPIResponseKeyData()] : eligibility;
    NSString *openValue = [data[HangoOPIResponseKeyOpenValue()] isKindOfClass:NSString.class] ? data[HangoOPIResponseKeyOpenValue()] : nil;
    [self saveFeaturedPageAddress:openValue];
    decision.featuredPageAddress = openValue;

    if ([self isFirstTimeLogin]) {
        HangoStartupLog(@"eligible, no session → member login");
        decision.awaitsMemberLogin = YES;
    } else {
        HangoStartupLog(@"eligible, has session → featured page");
        decision.showsFeaturedPage = YES;
    }
    return decision;
}

- (UIView *)installFeaturedContentCoverOnWindow:(UIWindow *)window {
    if (!window) {
        return nil;
    }
    UIView *existing = [window viewWithTag:0x48414E47];
    if (existing) {
        return existing;
    }
    UIViewController *splash = [self launchSplashViewController];
    UIView *cover = splash.view;
    cover.tag = 0x48414E47;
    cover.frame = window.bounds;
    cover.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [window addSubview:cover];
    return cover;
}

- (void)removeFeaturedContentCover:(UIView *)cover {
    [cover removeFromSuperview];
}

- (UIViewController *)welcomePageRootViewController {
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

    HangoWelcomeViewController *welcome = [[HangoWelcomeViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcome];
    nav.navigationBarHidden = YES;
    return nav;
}

- (UIViewController *)launchSplashViewController {
    return [[UIStoryboard storyboardWithName:@"LaunchScreen" bundle:nil] instantiateInitialViewController];
}

- (void)enterWelcomePageInWindow:(UIWindow *)window {
    window.rootViewController = [self welcomePageRootViewController];
    [window makeKeyAndVisible];
}

- (void)startAppInWindow:(UIWindow *)window {
    if (!window) {
        return;
    }

    // Native A session/guest already decided — no featured-content wait.
    if ([HangoSessionManager shared].isLoggedIn || [HangoSessionManager shared].isGuest) {
        [self enterWelcomePageInWindow:window];
        return;
    }

    if (!userLogingTime()) {
        [self enterWelcomePageInWindow:window];
        return;
    }

    // Keep LaunchScreen up until routing is ready, so Welcome never flashes first.
    window.rootViewController = [self launchSplashViewController];
    [window makeKeyAndVisible];

    __weak typeof(self) weakSelf = self;
    [self fetchFeaturedContentConfigWithCompletion:^(NSDictionary *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        HangoFeaturedContentPlan *plan = [strongSelf featuredContentPlanFromResponse:response error:error];
        [strongSelf applyFeaturedContentPlan:plan toWindow:window];
    }];
}

- (void)applyFeaturedContentPlan:(HangoFeaturedContentPlan *)plan toWindow:(UIWindow *)window {
    if (!window) {
        return;
    }

    if (plan.showsFeaturedPage) {
        HangoFeaturedPageViewController *page = [[HangoFeaturedPageViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:page];
        nav.navigationBarHidden = YES;
        window.rootViewController = nav;
        [window makeKeyAndVisible];
        return;
    }

    HangoWelcomeViewController *welcome = [[HangoWelcomeViewController alloc] init];
    if (plan.awaitsMemberLogin) {
        welcome.showsMemberLoginOnly = YES;
    }
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:welcome];
    nav.navigationBarHidden = YES;
    window.rootViewController = nav;
    [window makeKeyAndVisible];
}

- (UINavigationController *)navigationControllerInWindow:(UIWindow *)window {
    if (!window) {
        return nil;
    }
    UIViewController *root = window.rootViewController;
    if ([root isKindOfClass:UINavigationController.class]) {
        return (UINavigationController *)root;
    }
    if ([root isKindOfClass:UITabBarController.class]) {
        UIViewController *selected = ((UITabBarController *)root).selectedViewController;
        if ([selected isKindOfClass:UINavigationController.class]) {
            return (UINavigationController *)selected;
        }
    }
    return nil;
}

- (void)replaceNavigationStackInWindow:(UIWindow *)window
                    withViewController:(UIViewController *)viewController
                              animated:(BOOL)animated {
    if (!window || !viewController) {
        return;
    }

    UINavigationController *nav = [self navigationControllerInWindow:window];
    if (nav) {
        if (!animated) {
            nav.viewControllers = @[viewController];
            return;
        }
        [nav pushViewController:viewController animated:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            nav.viewControllers = @[viewController];
        });
        return;
    }

    UINavigationController *newNav = [[UINavigationController alloc] initWithRootViewController:viewController];
    newNav.navigationBarHidden = YES;
    if (!animated) {
        window.rootViewController = newNav;
        [window makeKeyAndVisible];
        return;
    }
    [HangoAppRouter setRootViewController:newNav animated:YES];
}

- (void)presentMemberLoginInWindow:(UIWindow *)window animated:(BOOL)animated {
    [HangoAPITokenStore setSessionToken:@""];
    [HangoAPITokenStore setInitialPassword:@""];

    HangoWelcomeViewController *welcome = [[HangoWelcomeViewController alloc] init];
    welcome.showsMemberLoginOnly = YES;
    [self replaceNavigationStackInWindow:window withViewController:welcome animated:animated];
}

- (void)presentFeaturedPageInWindow:(UIWindow *)window animated:(BOOL)animated {
    HangoFeaturedPageViewController *featuredPage = [[HangoFeaturedPageViewController alloc] init];
    [self replaceNavigationStackInWindow:window withViewController:featuredPage animated:animated];
}

- (void)completeMemberLoginFromViewController:(UIViewController *)viewController
                                   completion:(void (^)(BOOL, NSError *))completion {
    if (!userLogingTime()) {
        if (completion) {
            completion(NO, [NSError errorWithDomain:@"HangoStartup"
                                               code:2
                                           userInfo:@{NSLocalizedDescriptionKey: @"Entry unavailable."}]);
        }
        return;
    }

    NSDictionary *params = [HangoClientProfileAssembler signInRequestParameters];
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
