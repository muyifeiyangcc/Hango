#import "HangoWelcomeViewController.h"
#import "HangoSignInViewController.h"
#import "HangoSignUpViewController.h"
#import "HangoEULAViewController.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoRequestManager.h"
#import "HangoAppRouter.h"
#import "HangoSessionManager.h"
#import <Masonry/Masonry.h>

@implementation HangoWelcomeViewController {
    BOOL _agreed;
    UIButton *_agreeCheck;
}

- (void)setupUI {
    UIButton *eulaBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    eulaBtn.backgroundColor = [UIColor colorWithWhite:1 alpha:0.55];
    eulaBtn.layer.cornerRadius = 16;
    [eulaBtn setTitle:@"EULA" forState:UIControlStateNormal];
    [eulaBtn setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    eulaBtn.titleLabel.font = [HangoTheme captionFont];
    [eulaBtn addTarget:self action:@selector(openEULA) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:eulaBtn];

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
    [newBtn addTarget:self action:@selector(signUpTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:newBtn];

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

    [eulaBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.right.equalTo(self.view).offset(-16);
        make.width.mas_equalTo(68);
        make.height.mas_equalTo(34);
    }];
    [logoWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.top.equalTo(self.contentView).offset(132);
        make.width.height.mas_equalTo(116);
    }];
    [logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(logoWrap).insets(UIEdgeInsetsMake(2, 2, 2, 2));
    }];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(logoWrap.mas_bottom).offset(14);
        make.centerX.equalTo(self.contentView);
    }];
    [loginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
        make.top.equalTo(title.mas_bottom).offset(52);
        make.height.mas_equalTo(62);
    }];
    [newBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.height.equalTo(loginBtn);
        make.top.equalTo(loginBtn.mas_bottom).offset(14);
    }];
    [signUpLink mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(newBtn.mas_bottom).offset(10);
        make.centerX.equalTo(self.contentView);
    }];
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(signUpLink.mas_bottom).offset(30);
        make.left.right.equalTo(loginBtn);
        make.height.mas_equalTo(20);
    }];
    [appleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(divider.mas_bottom).offset(16);
        make.centerX.equalTo(self.contentView);
        make.width.height.mas_equalTo(56);
    }];
    [agreeRow mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-10);
    }];
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
    [leftLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.centerY.equalTo(row);
        make.right.equalTo(label.mas_left).offset(-10);
        make.height.mas_equalTo(1);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(row);
    }];
    [rightLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.centerY.equalTo(row);
        make.left.equalTo(label.mas_right).offset(10);
        make.height.mas_equalTo(1);
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
    [label addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openEULA)]];
    [row addSubview:label];

    [_agreeCheck mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(row);
        make.centerY.equalTo(label);
        make.width.height.mas_equalTo(18);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_agreeCheck.mas_right).offset(8);
        make.right.top.bottom.equalTo(row);
    }];
    return row;
}

- (NSAttributedString *)agreementAttributedText {
    NSString *text = @"Agree with User Agreement and Privacy Policy";
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text attributes:@{
        NSFontAttributeName: [HangoTheme captionFont],
        NSForegroundColorAttributeName: [HangoTheme primaryDarkColor]
    }];
    NSRange userRange = [text rangeOfString:@"User Agreement"];
    NSRange privacyRange = [text rangeOfString:@"Privacy Policy"];
    if (userRange.location != NSNotFound) {
        [attr addAttribute:NSUnderlineStyleAttributeName value:@(NSUnderlineStyleSingle) range:userRange];
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

- (BOOL)ensureAgreed {
    if (_agreed) {
        return YES;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Please agree to the User Agreement and Privacy Policy." preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    return NO;
}

- (void)loginTapped {
    if (![self ensureAgreed]) return;
    [self.navigationController pushViewController:[[HangoSignInViewController alloc] init] animated:YES];
}

- (void)signUpTapped {
    if (![self ensureAgreed]) return;
    [self.navigationController pushViewController:[[HangoSignUpViewController alloc] init] animated:YES];
}

- (void)openEULA {
    [self.navigationController pushViewController:[[HangoEULAViewController alloc] init] animated:YES];
}

- (void)appleLogin {
    if (![self ensureAgreed]) return;
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [[HangoSessionManager shared] loginWithEmail:@"" password:@""];
        [HangoAppRouter showMainTabBar];
    }];
}

@end
