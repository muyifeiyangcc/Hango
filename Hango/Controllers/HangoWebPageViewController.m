#import "HangoDisplayString.h"
#import "HangoWebPageViewController.h"
#import "HangoAppConfig.h"
#import "HangoTheme.h"
#import "HGXAnchor.h"
#import <WebKit/WebKit.h>

@interface HangoWebPageViewController () <WKNavigationDelegate, UIScrollViewDelegate>
@property (nonatomic, copy) NSString *pageURLString;
@property (nonatomic, copy) NSString *pageTitle;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, assign) BOOL hasCompletedInitialLoad;
@end

@implementation HangoWebPageViewController

+ (NSString *)pageBackgroundStyleScript {
    return @"(function() {"
    "  var gradient = 'linear-gradient(180deg, #B8E8FA 0%, #E0F7FA 100%)';"
    "  var css = 'html, body, #app, main, .legal-page, .agreement, .protocol, .hango-app-shell { overflow-x: hidden !important; width: 100% !important; max-width: 100% !important; min-height: 100% !important; background: ' + gradient + ' !important; background-color: #B8E8FA !important; } .legal-heading, .T_title, .bt { color: #7f1146 !important; } .legal-content, .T_content { color: #000 !important; background: transparent !important; }';"
    "  var style = document.getElementById('hango-page-style');"
    "  if (!style) {"
    "    style = document.createElement('style');"
    "    style.id = 'hango-page-style';"
    "    (document.head || document.documentElement).appendChild(style);"
    "  }"
    "  style.innerHTML = css;"
    "  document.documentElement.style.background = gradient;"
    "  document.documentElement.style.backgroundColor = '#B8E8FA';"
    "  if (document.body) {"
    "    document.body.style.background = gradient;"
    "    document.body.style.backgroundColor = '#B8E8FA';"
    "  }"
    "})();";
}

- (void)applyPageBackgroundStyles {
    [_webView evaluateJavaScript:[self.class pageBackgroundStyleScript] completionHandler:nil];
}

+ (instancetype)memberAgreementViewController {
    HangoWebPageViewController *vc = [[HangoWebPageViewController alloc] init];
    vc.pageURLString = HangoPersonaAgreementURLString;
    vc.pageTitle = HangoDisplayString(HangoDisplayStringKeyUserAgreement);
    return vc;
}

+ (instancetype)privacyPolicyViewController {
    HangoWebPageViewController *vc = [[HangoWebPageViewController alloc] init];
    vc.pageURLString = HangoPrivacyPolicyURLString;
    vc.pageTitle = @"Privacy Policy";
    return vc;
}

- (void)dealloc {
    [_webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
}

- (void)setupUI {
    self.showsBackButton = YES;
    self.navTitleText = self.pageTitle;

    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    NSString *pageStyleScript = [self.class pageBackgroundStyleScript];
    WKUserScript *startScript = [[WKUserScript alloc] initWithSource:pageStyleScript
                                                       injectionTime:WKUserScriptInjectionTimeAtDocumentStart
                                                    forMainFrameOnly:YES];
    WKUserScript *endScript = [[WKUserScript alloc] initWithSource:pageStyleScript
                                                     injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                                  forMainFrameOnly:YES];
    [configuration.userContentController addUserScript:startScript];
    [configuration.userContentController addUserScript:endScript];

    _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
    UIColor *pageBackgroundColor = [HangoTheme backgroundTopColor];
    _webView.backgroundColor = pageBackgroundColor;
    _webView.scrollView.backgroundColor = pageBackgroundColor;
    if (@available(iOS 15.0, *)) {
        _webView.underPageBackgroundColor = pageBackgroundColor;
    }
    _webView.opaque = NO;
    _webView.navigationDelegate = self;
    _webView.scrollView.alwaysBounceHorizontal = NO;
    _webView.scrollView.showsHorizontalScrollIndicator = NO;
    _webView.scrollView.directionalLockEnabled = YES;
    _webView.scrollView.delegate = self;
    [_webView addObserver:self
               forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                  options:NSKeyValueObservingOptionNew
                  context:nil];
    [self.contentView addSubview:_webView];

    _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _progressView.progressTintColor = [HangoTheme accentBlueColor];
    _progressView.trackTintColor = [[HangoTheme backgroundTopColor] colorWithAlphaComponent:0.35];
    _progressView.hidden = YES;
    _progressView.progress = 0;
    [self.contentView addSubview:_progressView];

    [_progressView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(44);
        make.left.right.equalTo(self.contentView);
        make.height.hgx_equalTo(2);
    }];
    [_webView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_progressView.hgx_bottom);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    NSURL *url = [NSURL URLWithString:self.pageURLString];
    if (url) {
        [self showProgressBar];
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (void)showProgressBar {
    _progressView.hidden = NO;
    _progressView.progress = 0;
}

- (void)hideProgressBar {
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
        [self hideProgressBar];
        return;
    }

    float progress = (float)_webView.estimatedProgress;
    _progressView.progress = progress;
    _progressView.hidden = progress <= 0;

    if (progress >= 1.0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideProgressBar];
        });
    }
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (self.hasCompletedInitialLoad) {
        [self hideProgressBar];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    [self applyPageBackgroundStyles];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (!self.hasCompletedInitialLoad) {
        self.hasCompletedInitialLoad = YES;
        [self hideProgressBar];
    }
    [self applyPageBackgroundStyles];
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (!self.hasCompletedInitialLoad) {
        self.hasCompletedInitialLoad = YES;
    }
    [self hideProgressBar];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (!self.hasCompletedInitialLoad) {
        self.hasCompletedInitialLoad = YES;
    }
    [self hideProgressBar];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != _webView.scrollView) {
        return;
    }
    if (scrollView.contentOffset.x != 0) {
        scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y);
    }
}

@end
