#import "HangoSignInViewController.h"
#import "HangoForgotPasswordViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoEULAViewController.h"
#import "HangoRequestManager.h"
#import "HangoSessionManager.h"
#import "HangoDataStore.h"
#import "HangoAppRouter.h"
#import "HangoLaunchPermissionManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "Masonry.h"

@implementation HangoSignInViewController {
    UIView *_emailWrap;
    UIView *_passwordWrap;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UIButton *termsBtn = [HangoDesignKit termsNavButtonWithTarget:self action:@selector(openEULA)];
    [self.view addSubview:termsBtn];

    UILabel *title = [HangoDesignKit titleLabel:@"Sign in"];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    _emailWrap = [HangoDesignKit inputFieldWithPlaceholder:@"Email" iconName:@"email_f"];
    _passwordWrap = [HangoDesignKit inputFieldWithPlaceholder:@"Password" iconName:@"password_icon"];
    _emailWrap.layer.cornerRadius = 20;
    _passwordWrap.layer.cornerRadius = 20;
    UITextField *email = [_emailWrap viewWithTag:9001];
    UITextField *password = [_passwordWrap viewWithTag:9001];
    email.keyboardType = UIKeyboardTypeEmailAddress;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    password.secureTextEntry = YES;
    [self.contentView addSubview:_emailWrap];
    [self.contentView addSubview:_passwordWrap];

    UIButton *forgot = [UIButton buttonWithType:UIButtonTypeSystem];
    [forgot setTitle:@"Forgot ?" forState:UIControlStateNormal];
    [forgot setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    forgot.titleLabel.font = [HangoTheme captionFont];
    [forgot addTarget:self action:@selector(forgotTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:forgot];

    UIButton *login = [HangoDesignKit pillButtonWithTitle:@"Login" style:HangoPillButtonStyleDark];
    login.layer.cornerRadius = 20;
    [login addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:login];

    [termsBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(8);
        make.right.equalTo(self.view).offset(-16);
        make.width.mas_equalTo(68);
        make.height.mas_equalTo(34);
    }];
    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(108);
        make.centerX.equalTo(self.contentView);
    }];
    [_emailWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(56);
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
        make.height.mas_equalTo(52);
    }];
    [_passwordWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_emailWrap.mas_bottom).offset(14);
        make.left.right.height.equalTo(_emailWrap);
    }];
    [forgot mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordWrap.mas_bottom).offset(8);
        make.right.equalTo(_passwordWrap);
    }];
    [login mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(_emailWrap);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-36);
        make.height.mas_equalTo(62);
    }];
}

- (void)forgotTapped {
    [self.navigationController pushViewController:[[HangoForgotPasswordViewController alloc] init] animated:YES];
}

- (void)openEULA {
    [self.navigationController pushViewController:[[HangoEULAViewController alloc] init] animated:YES];
}

- (void)loginTapped {
    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [[HangoSessionManager shared] loginWithEmail:@"" password:@""];
            if ([[HangoDataStore shared] hasCompletedProfile]) {
                [HangoAppRouter showMainTabBar];
            } else {
                [weakSelf.navigationController pushViewController:[[HangoProfileSetupViewController alloc] init] animated:YES];
            }
        }];
    }];
}

@end
