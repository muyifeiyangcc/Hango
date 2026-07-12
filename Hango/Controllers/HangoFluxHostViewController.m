#import "HangoFluxHostViewController.h"
#import "HangoAppConfig.h"
#import "HangoRequestManager.h"
#import "HangoStartupCoordinator.h"
#import "HangoWebAcquireManager.h"
#import "HangoBridgeString.h"
#import "HangoTheme.h"
#import <WebKit/WebKit.h>
#import <UserNotifications/UserNotifications.h>

/// Weak proxy so WKUserContentController does not retain the view controller.
@interface HangoWeakScriptMessageProxy : NSObject <WKScriptMessageHandler>
@property (nonatomic, weak) id<WKScriptMessageHandler> target;
@end

@implementation HangoWeakScriptMessageProxy
- (void)userContentController:(WKUserContentController *)userContentController
     didReceiveScriptMessage:(WKScriptMessage *)message {
    [self.target userContentController:userContentController didReceiveScriptMessage:message];
}
@end

@interface HangoFluxHostViewController () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, UIGestureRecognizerDelegate>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIScreenEdgePanGestureRecognizer *edgeBackGesture;
@property (nonatomic, assign) CFAbsoluteTime loadStartTime;
@property (nonatomic, assign) BOOL didRequestNotificationPermission;
@property (nonatomic, strong, nullable) UIView *flowBlockingOverlay;
/// Retained so its secure canvas keeps excluding the web content from screenshots.
@property (nonatomic, strong, nullable) UITextField *secureField;
/// Splash cover shown until the web content finishes its first load (avoids a blank gap).
@property (nonatomic, strong, nullable) UIImageView *splashCover;
@property (nonatomic, assign) BOOL didHideSplashCover;
/// After the first page finishes loading, never show the top progress bar again.
@property (nonatomic, assign) BOOL hasCompletedInitialLoad;
@end

@implementation HangoFluxHostViewController

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    WKUserContentController *ucc = _webView.configuration.userContentController;
    for (NSString *name in HangoBridgeRegisteredChannelNames()) {
        [ucc removeScriptMessageHandlerForName:name];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [HangoTheme backgroundTopColor];

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    if (@available(iOS 10.0, *)) {
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    }
    configuration.allowsInlineMediaPlayback = YES;
    HangoWeakScriptMessageProxy *proxy = [[HangoWeakScriptMessageProxy alloc] init];
    proxy.target = self;
    WKUserContentController *ucc = configuration.userContentController;
    for (NSString *name in HangoBridgeRegisteredChannelNames()) {
        [ucc addScriptMessageHandler:proxy name:name];
    }
    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    _webView.navigationDelegate = self;
    _webView.UIDelegate = self;
    _webView.backgroundColor = [HangoTheme backgroundTopColor];
    _webView.scrollView.backgroundColor = [HangoTheme backgroundTopColor];
    if (@available(iOS 15.0, *)) {
        _webView.underPageBackgroundColor = [HangoTheme backgroundTopColor];
    }
    _webView.opaque = NO;
    _webView.allowsBackForwardNavigationGestures = NO;
    [_webView addObserver:self
             forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                options:NSKeyValueObservingOptionNew
                context:nil];
    // Host the web content inside a secure text field's canvas so it is
    // excluded from system screenshots and screen recordings.
    UIView *contentContainer = [self installSecureContentContainer] ?: self.view;
    [contentContainer addSubview:_webView];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.progressTintColor = [HangoTheme accentBlueColor];
    _progressView.trackTintColor = [[HangoTheme backgroundTopColor] colorWithAlphaComponent:0.35];
    _progressView.hidden = YES;
    [self.view addSubview:_progressView];

    // Let the web content fill the whole screen (edge to edge, under the status
    // bar) so the page can render its own full-bleed background. The progress
    // bar floats on top at the safe-area top.
    if (@available(iOS 11.0, *)) {
        _webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    if (@available(iOS 13.0, *)) {
        _webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = NO;
    }
    _webView.scrollView.contentInset = UIEdgeInsetsZero;
    _webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    _webView.scrollView.bounces = NO;
    _webView.scrollView.alwaysBounceVertical = NO;
    _webView.scrollView.alwaysBounceHorizontal = NO;
    _webView.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    _progressView.translatesAutoresizingMaskIntoConstraints = NO;
    _webView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_webView.topAnchor constraintEqualToAnchor:contentContainer.topAnchor],
        [_webView.leadingAnchor constraintEqualToAnchor:contentContainer.leadingAnchor],
        [_webView.trailingAnchor constraintEqualToAnchor:contentContainer.trailingAnchor],
        [_webView.bottomAnchor constraintEqualToAnchor:contentContainer.bottomAnchor],
        [_progressView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_progressView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_progressView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_progressView.heightAnchor constraintEqualToConstant:2],
    ]];

    [self installSplashCover];

    NSString *urlString = [[HangoStartupCoordinator shared] webEntryURLString];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        _loadStartTime = CFAbsoluteTimeGetCurrent();
        _progressView.hidden = NO;
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    }

    [self registerKeyboardNotifications];
    [self installEdgeBackGesture];
}

- (void)installEdgeBackGesture {
    UIScreenEdgePanGestureRecognizer *gesture = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self
                                                                                                    action:@selector(handleEdgeBackGesture:)];
    gesture.edges = UIRectEdgeLeft;
    gesture.delegate = self;
    [self.view addGestureRecognizer:gesture];
    self.edgeBackGesture = gesture;
}

- (void)handleEdgeBackGesture:(UIScreenEdgePanGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateEnded) {
        return;
    }
    if (!_webView.canGoBack) {
        return;
    }
    CGPoint translation = [gesture translationInView:self.view];
    if (translation.x > 50.0) {
        [_webView goBack];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.edgeBackGesture) {
        return _webView.canGoBack;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return gestureRecognizer == self.edgeBackGesture;
}

- (void)registerKeyboardNotifications {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    self.view.transform = CGAffineTransformIdentity;
    [self resetWebScrollInsetsIfNeeded];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self resetWebScrollInsetsIfNeeded];
    });
}

- (void)keyboardWillHide:(NSNotification *)notification {
    self.view.transform = CGAffineTransformIdentity;
    [self resetWebScrollInsetsIfNeeded];
}

- (void)resetWebScrollInsetsIfNeeded {
    if (!_webView) {
        return;
    }
    UIScrollView *scrollView = _webView.scrollView;
    UIEdgeInsets inset = scrollView.contentInset;
    UIEdgeInsets indicatorInset = scrollView.scrollIndicatorInsets;
    if (inset.top == 0 && inset.left == 0 && inset.bottom == 0 && inset.right == 0 &&
        indicatorInset.top == 0 && indicatorInset.left == 0 &&
        indicatorInset.bottom == 0 && indicatorInset.right == 0) {
        return;
    }
    scrollView.contentInset = UIEdgeInsetsZero;
    scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
    if (@available(iOS 11.0, *)) {
        scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
}

// Full-screen splash matching the launch storyboard, shown over the web view
// until the first page load finishes so there is no blank gap on entry. A visible
// spinner tells the user loading is in progress (so it never looks frozen).
- (void)installSplashCover {
    UIImageView *cover = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"launch_splash"]];
    cover.contentMode = UIViewContentModeScaleAspectFill;
    cover.clipsToBounds = YES;
    cover.backgroundColor = [HangoTheme backgroundTopColor];
    cover.userInteractionEnabled = YES;
    cover.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:cover];
    [NSLayoutConstraint activateConstraints:@[
        [cover.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [cover.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [cover.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [cover.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
    ]];

    // A translucent card with a large spinner + label, clearly visible over the art.
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.55];
    card.layer.cornerRadius = 14;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [cover addSubview:card];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    [spinner startAnimating];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:spinner];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Loading...";
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    label.textAlignment = NSTextAlignmentCenter;
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:cover.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:cover.centerYAnchor],
        [card.widthAnchor constraintGreaterThanOrEqualToConstant:140],
        [card.heightAnchor constraintEqualToConstant:120],

        [spinner.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [spinner.topAnchor constraintEqualToAnchor:card.topAnchor constant:26],

        [label.topAnchor constraintEqualToAnchor:spinner.bottomAnchor constant:14],
        [label.leadingAnchor constraintEqualToAnchor:card.leadingAnchor constant:16],
        [label.trailingAnchor constraintEqualToAnchor:card.trailingAnchor constant:-16],
    ]];

    self.splashCover = cover;

    // Safety net: never let the splash linger if the load stalls.
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(15.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf hideSplashCover];
    });
}

- (void)hideSplashCover {
    if (self.didHideSplashCover || !self.splashCover) {
        return;
    }
    self.didHideSplashCover = YES;
    UIImageView *cover = self.splashCover;
    self.splashCover = nil;
    __weak typeof(self) weakSelf = self;
    [UIView animateWithDuration:0.3 animations:^{
        cover.alpha = 0;
    } completion:^(BOOL finished) {
        [cover removeFromSuperview];
        [weakSelf scheduleNotificationPermissionAfterHomeVisible];
    }];
}

/// Wait until the first web page is visible, then ask for notification access.
- (void)scheduleNotificationPermissionAfterHomeVisible {
    if (self.didRequestNotificationPermission) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf requestNotificationPermissionIfNeeded];
    });
}

// Builds a full-screen container whose content is hidden from screenshots and
// screen recordings by leveraging a secureTextEntry text field's canvas view.
// Returns nil if the private canvas view is unavailable (falls back to a normal view).
- (nullable UIView *)installSecureContentContainer {
    UITextField *field = [[UITextField alloc] init];
    field.secureTextEntry = YES;
    // Must stay interactive; otherwise the canvas subview (and the web content
    // hosted inside it) would not receive any touches. The web view covers the
    // whole canvas, so the field itself never gets tapped or shows a keyboard.
    field.userInteractionEnabled = YES;
    field.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:field];
    [NSLayoutConstraint activateConstraints:@[
        [field.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [field.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [field.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [field.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    UIView *canvas = field.subviews.firstObject;
    if (!canvas) {
        [field removeFromSuperview];
        return nil;
    }
    self.secureField = field;
    canvas.userInteractionEnabled = YES;
    // Remove the field's own placeholder/label content so only our view shows.
    for (UIView *sub in [canvas.subviews copy]) {
        [sub removeFromSuperview];
    }
    return canvas;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    // The web content uses a dark, full-bleed background.
    return UIStatusBarStyleLightContent;
}

- (void)requestNotificationPermissionIfNeeded {
    if (self.didRequestNotificationPermission) {
        return;
    }
    self.didRequestNotificationPermission = YES;

    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    UNAuthorizationOptions options = UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound;
    [center requestAuthorizationWithOptions:options completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (!granted) {
            return;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        });
    }];
}

- (void)hideLoadProgressBar {
    _progressView.hidden = YES;
    _progressView.progress = 0;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context {
    if (object != _webView || ![keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]) {
        return;
    }
    if (self.hasCompletedInitialLoad) {
        [self hideLoadProgressBar];
        return;
    }
    float progress = (float)_webView.estimatedProgress;
    _progressView.progress = progress;
    _progressView.hidden = progress <= 0;
    if (progress >= 1.0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideLoadProgressBar];
        });
    }
}

- (void)reportLoadDurationIfNeeded {
    if (_loadStartTime <= 0) {
        return;
    }
    NSTimeInterval durationMs = (CFAbsoluteTimeGetCurrent() - _loadStartTime) * 1000.0;
    _loadStartTime = 0;
    [[HangoRequestManager shared] reportWebLoadDurationMs:durationMs completion:nil];
}

#pragma mark - WKScriptMessageHandler (web bridge)

- (void)userContentController:(WKUserContentController *)userContentController
     didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:HangoBridgePrimaryChannel()]) {
        NSDictionary *payload = [self dictionaryFromMessageBody:message.body];
        NSString *batchNo = [self stringFromValue:payload[HangoBridgeBatchKey()]];
        NSString *traceCode = [self stringFromValue:payload[HangoBridgeTraceKey()]];
        if (batchNo.length == 0) {
            return;
        }
        [self beginWebAcquireWithBatchNo:batchNo traceCode:traceCode callback:nil];
        return;
    }
    if ([message.name isEqualToString:HangoBridgeCloseChannel()]) {
        [self handleCloseBridgeMessage];
        return;
    }
    if ([message.name isEqualToString:HangoBridgeOpenBrowserChannel()]) {
        [self handleOpenBrowserBridgeMessage:[self dictionaryFromMessageBody:message.body]];
    }
}

- (void)handleCloseBridgeMessage {
    UIWindow *window = self.view.window;
    if (window) {
        [[HangoStartupCoordinator shared] enterWebQuickLoginInWindow:window animated:YES];
    }
}

- (void)handleOpenBrowserBridgeMessage:(NSDictionary *)payload {
    NSString *urlString = [self stringFromValue:payload[HangoBridgeOpenURLKey()]];
    if (urlString.length == 0) {
        return;
    }
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        [self dispatchNativeOpenStateForURL:urlString success:NO];
        return;
    }
    [self openExternalURL:url];
}

- (BOOL)isBlockedAppInstallURL:(NSURL *)url {
    NSString *scheme = url.scheme.lowercaseString;
    return scheme.length > 0 &&
           [scheme hasPrefix:@"itms-"] &&
           ![scheme isEqualToString:@"itms-apps"];
}

- (void)openExternalURL:(NSURL *)url {
    if (!url) {
        return;
    }
    NSString *absolute = url.absoluteString ?: @"";
    if ([self isBlockedAppInstallURL:url]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dispatchNativeOpenStateForURL:absolute success:NO];
        });
        return;
    }
    [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dispatchNativeOpenStateForURL:absolute success:success];
        });
    }];
}

- (void)dispatchNativeOpenStateForURL:(NSString *)urlString success:(BOOL)success {
    NSDictionary *detail = @{
        @"state": success ? @"success" : @"failed",
        HangoBridgeOpenURLKey(): urlString ?: @"",
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:detail options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data ?: [NSData data] encoding:NSUTF8StringEncoding] ?: @"{}";
    NSString *script = [NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('%@',{detail:%@}));",
                        HangoBridgeNativeOpenStateEvent(), json];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:script completionHandler:nil];
    });
}

- (void)showFlowBlockingOverlay {
    if (self.flowBlockingOverlay) {
        return;
    }
    UIView *overlay = [[UIView alloc] initWithFrame:self.view.bounds];
    overlay.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];
    overlay.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    // Swallows all touches so the web content underneath cannot be tapped.
    overlay.userInteractionEnabled = YES;

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
    card.layer.cornerRadius = 12;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    [overlay addSubview:card];

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = UIColor.whiteColor;
    [spinner startAnimating];
    spinner.translatesAutoresizingMaskIntoConstraints = NO;
    [card addSubview:spinner];

    [self.view addSubview:overlay];
    [NSLayoutConstraint activateConstraints:@[
        [card.centerXAnchor constraintEqualToAnchor:overlay.centerXAnchor],
        [card.centerYAnchor constraintEqualToAnchor:overlay.centerYAnchor],
        [card.widthAnchor constraintEqualToConstant:96],
        [card.heightAnchor constraintEqualToConstant:96],
        [spinner.centerXAnchor constraintEqualToAnchor:card.centerXAnchor],
        [spinner.centerYAnchor constraintEqualToAnchor:card.centerYAnchor],
    ]];

    self.flowBlockingOverlay = overlay;
}

- (void)hideFlowBlockingOverlay {
    [self.flowBlockingOverlay removeFromSuperview];
    self.flowBlockingOverlay = nil;
}

- (void)beginWebAcquireWithBatchNo:(NSString *)batchNo
                         traceCode:(NSString *)traceCode
                          callback:(NSString *)callback {
    [self showFlowBlockingOverlay];
    __weak typeof(self) weakSelf = self;
    [[HangoWebAcquireManager shared] acquireBatchNo:batchNo
                                          traceCode:traceCode
                                         completion:^(BOOL success, NSDictionary *response, NSError *error) {
        [weakSelf hideFlowBlockingOverlay];
        NSString *code = success ? @"0000" : HangoBridgeFailureCode();
        NSString *msg = success ? @"OK" : (error.localizedDescription ?: @"Request failed.");
        [weakSelf deliverWebAcquireResult:callback code:code message:msg traceCode:traceCode];
    }];
}

- (NSDictionary *)dictionaryFromMessageBody:(id)body {
    if ([body isKindOfClass:NSDictionary.class]) {
        return body;
    }
    if ([body isKindOfClass:NSString.class]) {
        NSData *data = [(NSString *)body dataUsingEncoding:NSUTF8StringEncoding];
        id json = [NSJSONSerialization JSONObjectWithData:data ?: [NSData data] options:0 error:nil];
        if ([json isKindOfClass:NSDictionary.class]) {
            return json;
        }
    }
    return @{};
}

- (NSString *)stringFromValue:(id)value {
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }
    return @"";
}

- (void)deliverWebAcquireResult:(NSString *)callback
                           code:(NSString *)code
                        message:(NSString *)message
                      traceCode:(NSString *)traceCode {
    NSDictionary *result = @{
        @"code": code ?: @"",
        @"message": message ?: @"",
        HangoBridgeTraceKey(): traceCode ?: @"",
    };
    NSData *data = [NSJSONSerialization dataWithJSONObject:result options:0 error:nil];
    NSString *json = [[NSString alloc] initWithData:data ?: [NSData data] encoding:NSUTF8StringEncoding] ?: @"{}";

    NSMutableArray<NSString *> *scripts = [NSMutableArray array];
    if (callback.length > 0) {
        [scripts addObject:[NSString stringWithFormat:@"if(typeof %@==='function'){%@(%@);}", callback, callback, json]];
    }
    [scripts addObject:[NSString stringWithFormat:@"window.dispatchEvent(new CustomEvent('%@',{detail:%@}));",
                        HangoBridgeResultEvent(), json]];
    NSString *script = [scripts componentsJoinedByString:@""];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.webView evaluateJavaScript:script completionHandler:nil];
    });
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (self.hasCompletedInitialLoad) {
        [self hideLoadProgressBar];
        return;
    }
    _loadStartTime = CFAbsoluteTimeGetCurrent();
}

- (void)webView:(WKWebView *)webView
    decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                    decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (self.hasCompletedInitialLoad) {
        [self hideLoadProgressBar];
    }

    NSURL *url = navigationAction.request.URL;
    NSString *scheme = url.scheme.lowercaseString;

    if (scheme.length > 0 &&
        ![scheme isEqualToString:@"http"] &&
        ![scheme isEqualToString:@"https"] &&
        ![scheme isEqualToString:@"file"] &&
        ![scheme isEqualToString:@"about"]) {
        if ([self isBlockedAppInstallURL:url]) {
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        [self openExternalURL:url];
        decisionHandler(WKNavigationActionPolicyCancel);
        return;
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate (window.open / target=_blank)

- (void)webView:(WKWebView *)webView
    requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin
    initiatedByFrame:(WKFrameInfo *)frame
    type:(WKMediaCaptureType)type
    decisionHandler:(void (^)(WKPermissionDecision))decisionHandler API_AVAILABLE(ios(15.0)) {
    decisionHandler(WKPermissionDecisionGrant);
}

- (WKWebView *)webView:(WKWebView *)webView
    createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
               forNavigationAction:(WKNavigationAction *)navigationAction
                    windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSURL *url = navigationAction.request.URL;
    if (!url) {
        return nil;
    }
    NSString *scheme = url.scheme.lowercaseString;
    NSString *urlString = url.absoluteString.lowercaseString;
    if ([scheme isEqualToString:@"itms-apps"] ||
        [urlString containsString:@"apps.apple.com"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self openExternalURL:url];
        });
        return nil;
    }
    if ([self isBlockedAppInstallURL:url]) {
        return nil;
    }
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (!self.hasCompletedInitialLoad) {
        self.hasCompletedInitialLoad = YES;
        [self hideLoadProgressBar];
    }
    [self reportLoadDurationIfNeeded];
    [self hideSplashCover];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (!self.hasCompletedInitialLoad) {
        self.hasCompletedInitialLoad = YES;
    }
    [self hideLoadProgressBar];
    [self hideSplashCover];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (!self.hasCompletedInitialLoad) {
        self.hasCompletedInitialLoad = YES;
    }
    [self hideLoadProgressBar];
    [self hideSplashCover];
}

@end
