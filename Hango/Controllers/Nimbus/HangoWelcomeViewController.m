#import "HangoDisplayString.h"
#import "HangoWelcomeViewController.h"
#import "HangoSignInViewController.h"
#import "HangoSignUpViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoEULAViewController.h"
#import "HangoWebPageViewController.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoRequestManager.h"
#import "HangoAppRouter.h"
#import "HangoSessionManager.h"
#import "HangoDataStore.h"
#import "HangoLaunchPermissionManager.h"
#import "HangoAppleSignInManager.h"
#import "HangoEULAAcceptance.h"
#import "HangoLaunchManager.h"
#import <AuthenticationServices/AuthenticationServices.h>
#import "HGXAnchor.h"

@implementation HangoWelcomeViewController {
    BOOL _agreed;
    UIButton *_agreeCheck;
    UIButton *_newBtn;
    UIButton *_onboardingLoginBtn;
    BOOL _onboardingLoginInFlight;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([HangoEULAAcceptance hasAcceptedLaunchEULA]) {
        [self syncAgreementAccepted];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _newBtn.hidden = self.onboardingMode;
}

- (void)setupUI {
    if (self.onboardingMode) {
        [self setupOnboardingUI];
        return;
    }

    UIButton *termsBtn = [HangoDesignKit termsNavButtonWithTarget:self action:@selector(openEULA)];
    [self.view addSubview:termsBtn];

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

    UIView *divider = [self dividerRowWithText:@"Other login methods"];
    [self.contentView addSubview:divider];

    UIButton *appleBtn = [self appleSignInButton];
    [self.contentView addSubview:appleBtn];

    UIView *agreeRow = [self agreementRow];
    [self.contentView addSubview:agreeRow];

    [termsBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.view.hgx_safeAreaLayoutGuideTop).offset(8);
        make.right.equalTo(self.view).offset(-16);
        make.width.hgx_equalTo(68);
        make.height.hgx_equalTo(34);
    }];
    [logoWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(132);
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
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
        make.top.equalTo(title.hgx_bottom).offset(52);
        make.height.hgx_equalTo(62);
    }];
    [newBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.height.equalTo(loginBtn);
        make.top.equalTo(loginBtn.hgx_bottom).offset(14);
    }];
    [signUpLink hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(newBtn.hgx_bottom).offset(10);
        make.centerX.equalTo(self.contentView);
    }];
    [divider hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(signUpLink.hgx_bottom).offset(30);
        make.left.right.equalTo(loginBtn);
        make.height.hgx_equalTo(20);
    }];
    [appleBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(divider.hgx_bottom).offset(16);
        make.centerX.equalTo(self.contentView);
        make.width.height.hgx_equalTo(56);
    }];
    [agreeRow hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-10);
    }];
}

#pragma mark - Onboarding (Quick Login)

- (void)setupOnboardingUI {
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

    UIButton *loginBtn = [self onboardingLoginButton];
    _onboardingLoginBtn = loginBtn;
    [self.contentView addSubview:loginBtn];

    [logoWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView).offset(-70);
        make.width.height.hgx_equalTo(116);
    }];
    [logo hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(logoWrap).insets(UIEdgeInsetsMake(2, 2, 2, 2));
    }];
    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(logoWrap.hgx_bottom).offset(16);
        make.centerX.equalTo(self.contentView);
    }];
    [loginBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(title.hgx_bottom).offset(100);
        make.width.equalTo(self.contentView).multipliedBy(2.0 / 3.0);
        make.height.hgx_equalTo(56);
    }];
}

- (UIButton *)onboardingLoginButton {
    UIColor *mainColor = [HangoTheme accentBlueColor];
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:@"Login" forState:UIControlStateNormal];
    [btn setTitleColor:mainColor forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont monospacedSystemFontOfSize:17 weight:UIFontWeightSemibold];
    btn.backgroundColor = UIColor.clearColor;
    btn.layer.borderWidth = 1.5;
    btn.layer.borderColor = mainColor.CGColor;
    btn.layer.cornerRadius = 28;
    [btn addTarget:self action:@selector(onboardingLoginTapped) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)onboardingLoginTapped {
    if (_onboardingLoginInFlight) {
        return;
    }
    [self performOnboarding];
}

- (void)setOnboardingLoginInteractionEnabled:(BOOL)enabled {
    _onboardingLoginInFlight = !enabled;
    _onboardingLoginBtn.enabled = enabled;
    _onboardingLoginBtn.alpha = enabled ? 1.0 : 0.55;
}

- (UIView *)dividerRowWithText:(NSString *)text {
    UIView *row = [[UIView alloc] init];
    UIView *leftLine = [self dividerLine];
    UIView *rightLine = [self dividerLine];
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [HangoTheme captionFont];
    label.textColor = [HangoTheme secondaryTextColor];
    label.textAlignment = NSTextAlignmentCenter;
    [row addSubview:leftLine];
    [row addSubview:label];
    [row addSubview:rightLine];
    [leftLine hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.centerY.equalTo(row);
        make.right.equalTo(label.hgx_left).offset(-10);
        make.height.hgx_equalTo(1);
    }];
    [label hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(row);
    }];
    [rightLine hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.centerY.equalTo(row);
        make.left.equalTo(label.hgx_right).offset(10);
        make.height.hgx_equalTo(1);
    }];
    return row;
}

- (UIView *)dividerLine {
    UIView *line = [[UIView alloc] init];
    line.backgroundColor = [UIColor colorWithWhite:0.72 alpha:0.8];
    return line;
}

- (UIButton *)appleSignInButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    btn.backgroundColor = UIColor.blackColor;
    btn.layer.cornerRadius = 28;
    btn.clipsToBounds = YES;
    UIImage *apple = [self whiteAppleIconImage];
    if (apple) {
        [btn setImage:apple forState:UIControlStateNormal];
    }
    [btn addTarget:self action:@selector(appleLogin) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (UIImage *)whiteAppleIconImage {
    UIImage *icon = [UIImage systemImageNamed:@"apple.logo"];
    if (!icon) {
        return nil;
    }
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:24 weight:UIImageSymbolWeightSemibold];
    icon = [icon imageByApplyingSymbolConfiguration:config];
    return [icon imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
}

- (UIView *)agreementRow {
    UIView *row = [[UIView alloc] init];

    _agreeCheck = [UIButton buttonWithType:UIButtonTypeCustom];
    _agreed = NO;
    _agreeCheck.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self updateAgreeCheckImage];
    [_agreeCheck addTarget:self action:@selector(toggleAgree) forControlEvents:UIControlEventTouchUpInside];
    [row addSubview:_agreeCheck];

    UILabel *label = [[UILabel alloc] init];
    label.numberOfLines = 2;
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

- (void)loginTapped {
    if (![self ensureAgreed]) return;
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        if (weakSelf.onboardingMode) {
            [weakSelf performOnboarding];
            return;
        }
        [weakSelf.navigationController pushViewController:[[HangoSignInViewController alloc] init] animated:YES];
    }];
}

- (void)performOnboarding {
    if (_onboardingLoginInFlight) {
        return;
    }
    [self setOnboardingLoginInteractionEnabled:NO];

    __weak typeof(self) weakSelf = self;
    [[HangoLaunchManager shared] completeWebEntryFromViewController:self
                                                        completion:^(BOOL success, NSError *error) {
        if (!success) {
            [weakSelf setOnboardingLoginInteractionEnabled:YES];
            NSString *detail = error.localizedDescription.length > 0 ? error.localizedDescription : @"Entry failed.";
            [weakSelf showAgreementAlertWithMessage:detail];
            return;
        }
        [[HangoLaunchManager shared] enterWebInWindow:weakSelf.view.window animated:YES];
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
        [weakSelf.navigationController pushViewController:[HangoWebPageViewController memberAgreementViewController] animated:YES];
    }];
}

- (void)openPrivacyPolicy {
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        [weakSelf.navigationController pushViewController:[HangoWebPageViewController privacyPolicyViewController] animated:YES];
    }];
}

- (void)appleLogin {
    if (![self ensureAgreed]) return;
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        if (weakSelf.onboardingMode) {
            [weakSelf performOnboarding];
            return;
        }
        [[HangoAppleSignInManager shared] signInFromViewController:weakSelf completion:^(BOOL success, NSError *error) {
            if (!success) {
                if (error.code != ASAuthorizationErrorCanceled) {
                    NSString *message = error.localizedDescription.length > 0 ? error.localizedDescription : @"Apple sign-in failed.";
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
                    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                    [weakSelf presentViewController:alert animated:YES completion:nil];
                }
                return;
            }
            [weakSelf navigateAfterAppleLogin];
        }];
    }];
}

- (void)navigateAfterAppleLogin {
    if ([[HangoDataStore shared] hasCompletedProfile]) {
        [HangoAppRouter showMainTabBar];
        return;
    }

    NSString *displayName = [[HangoDataStore shared] appleCachedDisplayName];
    HangoProfileSetupViewController *profileVC = [[HangoProfileSetupViewController alloc] init];
    profileVC.prefilledDisplayName = displayName;
    profileVC.prefilledAvatarImage = [HangoAppleSignInManager avatarImageForDisplayName:displayName];
    [self.navigationController pushViewController:profileVC animated:YES];
}

@end
