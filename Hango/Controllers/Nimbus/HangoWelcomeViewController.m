#import "HangoDisplayString.h"
#import "HangoWelcomeViewController.h"
#import "HangoSignInViewController.h"
#import "HangoSignUpViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoEULAViewController.h"
#import "HangoDocHostViewController.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoRequestManager.h"
#import "HangoAppRouter.h"
#import "HangoSessionManager.h"
#import "HangoDataStore.h"
#import "HangoLaunchPermissionManager.h"
#import "HangoAppleSignInManager.h"
#import "HangoEULAAcceptance.h"
#import "HangoStartupCoordinator.h"
#import "HangoAppConfig.h"
#import "HangoHUD.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "HGXAnchor.h"

@implementation HangoWelcomeViewController {
    BOOL _agreed;
    UIButton *_agreeCheck;
    UIButton *_loginBtn;
    UIButton *_eulaBtn;
    UIButton *_newBtn;
    UIButton *_signUpLink;
    UIButton *_appleBtn;
    UIView *_agreeRow;
    BOOL _memberLoginInFlight;
    BOOL _didStartFeaturedContentRefresh;
    UIView *_featuredContentCover;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([HangoEULAAcceptance hasAcceptedLaunchEULA]) {
        [self syncAgreementAccepted];
    }
    if (self.showsMemberLoginOnly) {
        [self applyMemberLoginOnlyLayout];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self refreshFeaturedContentIfNeeded];
}

#pragma mark - Featured content

- (void)refreshFeaturedContentIfNeeded {
    if (!self.refreshFeaturedContentOnAppear || self.showsMemberLoginOnly || _didStartFeaturedContentRefresh) {
        return;
    }
    _didStartFeaturedContentRefresh = YES;
    [self loadFeaturedContent];
}

- (void)loadFeaturedContent {
    if (![self isFeaturedContentEnabled]) {
        return;
    }
    [self fetchFeaturedContent];
}

- (BOOL)isFeaturedContentEnabled {
    return userLogingTime();
}

- (void)fetchFeaturedContent {
    UIWindow *window = self.view.window;
    if (!window) {
        return;
    }

    _featuredContentCover = [[HangoStartupCoordinator shared] installFeaturedContentCoverOnWindow:window];
    UIView *hudHost = _featuredContentCover ?: window;
    [HangoHUD showHUDAddedTo:hudHost animated:YES];

    __weak typeof(self) weakSelf = self;
    [[HangoStartupCoordinator shared] fetchFeaturedContentConfigWithCompletion:^(NSDictionary *response, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [HangoHUD hideHUDForView:hudHost animated:YES];
        [[HangoStartupCoordinator shared] removeFeaturedContentCover:strongSelf->_featuredContentCover];
        strongSelf->_featuredContentCover = nil;
        [strongSelf handleFeaturedContentResponse:response error:error];
    }];
}

- (void)handleFeaturedContentResponse:(NSDictionary *)response error:(NSError *)error {
    HangoFeaturedContentPlan *plan = [[HangoStartupCoordinator shared] featuredContentPlanFromResponse:response error:error];
    [self presentFeaturedContent:plan];
}

- (void)presentFeaturedContent:(HangoFeaturedContentPlan *)plan {
    if (!plan) {
        return;
    }
    if (plan.showsFeaturedPage) {
        [[HangoStartupCoordinator shared] presentFeaturedPageInWindow:self.view.window animated:YES];
        return;
    }
    if (plan.awaitsMemberLogin) {
        [self applyMemberLoginOnlyLayout];
    }
}

- (void)applyMemberLoginOnlyLayout {
    self.showsMemberLoginOnly = YES;
    _eulaBtn.hidden = YES;
    _newBtn.hidden = YES;
    _signUpLink.hidden = YES;
    _appleBtn.hidden = YES;
    _agreeRow.hidden = YES;
    [_loginBtn setTitle:@"Login" forState:UIControlStateNormal];
}

- (void)setupUI {
    // iPhone-only apps still run on review iPads (Designed for iPhone); use canvas width, not idiom.
    CGFloat canvasW = CGRectGetWidth(UIScreen.mainScreen.bounds);
    BOOL wideCanvas = canvasW >= 600.0;
    CGFloat sideInset = wideCanvas ? 48.0 : 32.0;
    CGFloat logoTop = wideCanvas ? 56.0 : 100.0;
    CGFloat maxFormWidth = 420.0;

    UIButton *termsBtn = [HangoDesignKit termsNavButtonWithTarget:self action:@selector(openEULA)];
    [self.view addSubview:termsBtn];
    _eulaBtn = termsBtn;

    UIView *logoWrap = [[UIView alloc] init];
    logoWrap.backgroundColor = UIColor.whiteColor;
    logoWrap.layer.cornerRadius = 28;
    logoWrap.clipsToBounds = YES;
    [HangoDesignKit applyCardShadow:logoWrap];
    [self.contentView addSubview:logoWrap];

    UIImageView *logo = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"logo"]];
    logo.contentMode = UIViewContentModeScaleAspectFill;
    logo.layer.cornerRadius = 24;
    logo.clipsToBounds = YES;
    [logoWrap addSubview:logo];

    UILabel *title = [[UILabel alloc] init];
    title.text = @"Hango";
    title.font = [UIFont boldSystemFontOfSize:36];
    title.textColor = [HangoTheme primaryDarkColor];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    UIButton *loginBtn = [HangoDesignKit pillButtonWithTitle:@"Login by email" style:HangoPillButtonStyleDark];
    loginBtn.titleLabel.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightSemibold];
    [loginBtn addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:loginBtn];
    _loginBtn = loginBtn;

    // Full-width Apple button, same type size as Login by email.
    UIButton *appleBtn = [self appleSignInButton];
    [self.contentView addSubview:appleBtn];
    _appleBtn = appleBtn;

    UIButton *newBtn = [HangoDesignKit pillButtonWithTitle:@"I'm new" style:HangoPillButtonStyleLight];
    newBtn.titleLabel.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightSemibold];
    newBtn.layer.borderWidth = 1;
    newBtn.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1].CGColor;
    [newBtn addTarget:self action:@selector(guestTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:newBtn];
    _newBtn = newBtn;

    UIButton *signUpLink = [UIButton buttonWithType:UIButtonTypeCustom];
    NSString *signUpText = @"Don't have an account? Sign up";
    NSMutableAttributedString *signUpAttr = [[NSMutableAttributedString alloc] initWithString:signUpText attributes:@{
        NSForegroundColorAttributeName: [HangoTheme primaryDarkColor],
        NSFontAttributeName: [HangoTheme captionFont]
    }];
    NSRange signUpRange = [signUpText rangeOfString:@"Sign up"];
    if (signUpRange.location != NSNotFound) {
        [signUpAttr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:[HangoTheme captionFont].pointSize] range:signUpRange];
        [signUpAttr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:signUpRange];
    }
    [signUpLink setAttributedTitle:signUpAttr forState:UIControlStateNormal];
    [signUpLink addTarget:self action:@selector(signUpTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:signUpLink];
    _signUpLink = signUpLink;

    UIView *agreeRow = [self agreementRow];
    [self.view addSubview:agreeRow];
    _agreeRow = agreeRow;

    [termsBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.view.hgx_safeAreaLayoutGuideTop).offset(8);
        make.right.equalTo(self.view).offset(-16);
        make.width.hgx_equalTo(68);
        make.height.hgx_equalTo(34);
    }];
    [logoWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(logoTop);
        make.width.height.hgx_equalTo(116);
    }];
    [logo hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(logoWrap).insets(UIEdgeInsetsMake(2, 2, 2, 2));
    }];
    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(logoWrap.hgx_bottom).offset(14);
        make.centerX.equalTo(self.contentView);
    }];
    [loginBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(title.hgx_bottom).offset(wideCanvas ? 40 : 48);
        make.height.hgx_equalTo(62);
        if (wideCanvas) {
            make.width.hgx_equalTo(maxFormWidth);
            make.left.greaterThanOrEqualTo(self.contentView).offset(sideInset);
            make.right.lessThanOrEqualTo(self.contentView).offset(-sideInset);
        } else {
            make.left.equalTo(self.contentView).offset(sideInset);
            make.right.equalTo(self.contentView).offset(-sideInset);
        }
    }];
    [appleBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.height.equalTo(loginBtn);
        make.top.equalTo(loginBtn.hgx_bottom).offset(14);
    }];
    [newBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.height.equalTo(loginBtn);
        make.top.equalTo(appleBtn.hgx_bottom).offset(14);
    }];
    [signUpLink hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(newBtn.hgx_bottom).offset(12);
        make.centerX.equalTo(self.contentView);
        make.left.greaterThanOrEqualTo(self.contentView).offset(sideInset);
        make.right.lessThanOrEqualTo(self.contentView).offset(-sideInset);
    }];
    [agreeRow hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-10);
        if (wideCanvas) {
            make.width.hgx_equalTo(maxFormWidth);
            make.left.greaterThanOrEqualTo(self.view).offset(sideInset);
            make.right.lessThanOrEqualTo(self.view).offset(-sideInset);
        } else {
            make.left.equalTo(self.view).offset(24);
            make.right.equalTo(self.view).offset(-24);
        }
    }];
}

- (UIButton *)appleSignInButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = UIColor.blackColor;
    btn.layer.cornerRadius = 31.0;
    btn.clipsToBounds = YES;
    btn.titleLabel.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightSemibold];
    [btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [btn setTitle:@"Sign in with Apple" forState:UIControlStateNormal];

    UIImage *apple = [UIImage systemImageNamed:@"apple.logo"];
    if (apple) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:17 weight:UIImageSymbolWeightSemibold];
        apple = [[apple imageByApplyingSymbolConfiguration:config] imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        [btn setImage:apple forState:UIControlStateNormal];
        btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        btn.semanticContentAttribute = UISemanticContentAttributeForceLeftToRight;
        btn.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 4);
        btn.titleEdgeInsets = UIEdgeInsetsMake(0, 4, 0, -4);
    }

    [btn addTarget:self action:@selector(appleLogin) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UIView *)agreementRow {
    UIView *row = [[UIView alloc] init];

    _agreeCheck = [UIButton buttonWithType:UIButtonTypeCustom];
    _agreeCheck.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self updateAgreeCheckImage];
    [_agreeCheck addTarget:self action:@selector(toggleAgree) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:_agreeCheck];

    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 0;
    label.attributedText = [self agreementAttributedText];
    label.userInteractionEnabled = YES;
    [label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(agreementLabelTapped:)]];
    [row addSubview:label];

    [_agreeCheck hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(row);
        make.centerY.equalTo(label);
        make.width.height.hgx_equalTo(18);
    }];
    [label hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_agreeCheck.hgx_right).offset(8);
        make.right.top.bottom.equalTo(row);
    }];
    return row;
}

- (NSAttributedString *)agreementAttributedText {
    NSString *text = HangoDisplayStringAgreeUserAgreementLine();
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [HangoTheme captionFont],
        NSForegroundColorAttributeName: [HangoTheme primaryDarkColor]
    }];
    NSRange agreementRange = HangoDisplayStringUserAgreementRangeInAgreeLine(text);
    NSRange privacyRange = [text rangeOfString:@"Privacy Policy"];
    if (agreementRange.location != NSNotFound) {
        [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:agreementRange];
    }
    if (privacyRange.location != NSNotFound) {
        [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:privacyRange];
    }
    return attr;
}

- (void)updateAgreeCheckImage {
    NSString *imageName = _agreed ? @"agreement_checked" : @"agreement_unchecked";
    UIImage *image = [[HangoTheme imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    [_agreeCheck setImage:image forState:UIControlStateNormal];
    _agreeCheck.backgroundColor = UIColor.clearColor;
    _agreeCheck.layer.borderWidth = 0;
    _agreeCheck.layer.cornerRadius = 0;
}

- (void)toggleAgree {
    _agreed = !_agreed;
    [self updateAgreeCheckImage];
}

- (void)syncAgreementAccepted {
    _agreed = YES;
    [self updateAgreeCheckImage];
}

- (BOOL)ensureAgreed {
    if (![HangoEULAAcceptance hasAcceptedLaunchEULA]) {
        [self showAgreementAlertWithMessage:@"Please agree to the EULA first."];
        return NO;
    }
    if (!_agreed) {
        [self showAgreementAlertWithMessage:HangoDisplayString(HangoDisplayStringKeyPleaseAgreeUserAgreement)];
        return NO;
    }
    return YES;
}

- (void)showAgreementAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)setMemberLoginInteractionEnabled:(BOOL)enabled {
    _memberLoginInFlight = !enabled;
}

- (void)loginTapped {
    // Before the featured window opens, always use native email sign-in — never member/auth APIs.
    if (self.showsMemberLoginOnly && [self isFeaturedContentEnabled]) {
        [self performMemberLogin];
        return;
    }
    if (![self ensureAgreed]) return;
    // Native email sign-in is local — push immediately, no network probe.
    [self.navigationController pushViewController:[[HangoSignInViewController alloc] init] animated:YES];
}

- (void)performMemberLogin {
    if (![self isFeaturedContentEnabled]) {
        if (![self ensureAgreed]) return;
        [self.navigationController pushViewController:[[HangoSignInViewController alloc] init] animated:YES];
        return;
    }
    if (_memberLoginInFlight) {
        return;
    }
    [self setMemberLoginInteractionEnabled:NO];

    // Featured-content config already succeeded on this page, so skip the extra network probe.
    __weak typeof(self) weakSelf = self;
    [[HangoStartupCoordinator shared] completeMemberLoginFromViewController:self
                                                                 completion:^(BOOL success, NSError *error) {
        if (!success) {
            [weakSelf setMemberLoginInteractionEnabled:YES];
            NSString *detail = error.localizedDescription.length > 0 ? error.localizedDescription : @"Entry failed.";
            [weakSelf showAgreementAlertWithMessage:detail];
            return;
        }
            [[HangoStartupCoordinator shared] presentFeaturedPageInWindow:weakSelf.view.window animated:NO];
        }];
}

- (void)guestTapped {
    if (![self ensureAgreed]) return;
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        [[HangoSessionManager shared] enterGuestMode];
        [HangoAppRouter showMainTabBar];
    }];
}

- (void)signUpTapped {
    if (![self ensureAgreed]) return;
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        [weakSelf.navigationController pushViewController:[[HangoSignUpViewController alloc] init] animated:YES];
    }];
}

- (void)agreementLabelTapped:(UITapGestureRecognizer *)gesture {
    UILabel *label = (UILabel *)gesture.view;
    if (![label isKindOfClass:UILabel.class] || label.attributedText.length == 0) {
        return;
    }

    NSString *text = label.attributedText.string;
    NSRange agreementRange = HangoDisplayStringUserAgreementRangeInAgreeLine(text);
    NSRange privacyRange = [text rangeOfString:@"Privacy Policy"];
    NSRange targetRange = [self rangeAtPoint:[gesture locationInView:label] inLabel:label];

    if (agreementRange.location != NSNotFound && NSLocationInRange(targetRange.location, agreementRange)) {
        [self openUserAgreement];
        return;
    }
    if (privacyRange.location != NSNotFound && NSLocationInRange(targetRange.location, privacyRange)) {
        [self openPrivacyPolicy];
    }
}

- (NSRange)rangeAtPoint:(CGPoint)point inLabel:(UILabel *)label {
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:label.attributedText];
    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:label.bounds.size];
    container.lineFragmentPadding = 0;
    container.maximumNumberOfLines = label.numberOfLines;
    container.lineBreakMode = label.lineBreakMode;
    [layoutManager addTextContainer:container];
    [storage addLayoutManager:layoutManager];

    NSUInteger index = [layoutManager characterIndexForPoint:point inTextContainer:container fractionOfDistanceBetweenInsertionPoints:NULL];
    if (index < label.attributedText.length) {
        return NSMakeRange(index, 1);
    }
    return NSMakeRange(NSNotFound, 0);
}

- (void)openEULA {
    HangoEULAViewController *vc = [[HangoEULAViewController alloc] init];
    vc.initialAgreementChecked = _agreed;
    __weak typeof(self) weakSelf = self;
    vc.onAgreementConfirmed = ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf syncAgreementAccepted];
    };
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openUserAgreement {
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        [weakSelf.navigationController pushViewController:[HangoDocHostViewController memberAgreementViewController] animated:YES];
    }];
}

- (void)openPrivacyPolicy {
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        [weakSelf.navigationController pushViewController:[HangoDocHostViewController privacyPolicyViewController] animated:YES];
    }];
}

- (void)appleLogin {
    if (![self ensureAgreed]) return;
    // SIWA is local/system auth — do not block on our host probe (can fail review on iPad).
    __weak typeof(self) weakSelf = self;
    [[HangoAppleSignInManager shared] signInFromViewController:self completion:^(BOOL success, NSString *displayName, NSError *error) {
        if (!success) {
            if (error.code != ASAuthorizationErrorCanceled) {
                NSString *message = error.localizedDescription.length > 0 ? error.localizedDescription : @"Apple sign-in failed.";
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            }
            return;
        }
        [weakSelf navigateAfterAppleLoginWithDisplayName:displayName];
    }];
}

- (void)navigateAfterAppleLoginWithDisplayName:(NSString *)displayName {
    if ([[HangoDataStore shared] hasCompletedProfile]) {
        [HangoAppRouter showMainTabBar];
        return;
    }

    NSString *resolvedName = [displayName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (resolvedName.length == 0) {
        resolvedName = [[HangoDataStore shared] appleCachedDisplayName];
    }
    HangoProfileSetupViewController *profileVC = [[HangoProfileSetupViewController alloc] init];
    profileVC.prefilledDisplayName = resolvedName;
    profileVC.prefilledAvatarImage = [HangoAppleSignInManager avatarImageForDisplayName:resolvedName];
    [self.navigationController pushViewController:profileVC animated:YES];
}

@end
