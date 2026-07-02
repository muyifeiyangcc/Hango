#import "HangoSignInViewController.h"
#import "HangoForgotPasswordViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoRequestManager.h"
#import "HangoSessionManager.h"
#import "HangoDataStore.h"
#import "HangoAppRouter.h"
#import "HangoLaunchPermissionManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HGXAnchor.h"

@implementation HangoSignInViewController {
    UIView *_emailWrap;
    UIView *_passwordWrap;
}

- (void)setupUI {
    self.showsBackButton = YES;

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

    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.view.hgx_safeAreaLayoutGuideTop).offset(108);
        make.centerX.equalTo(self.contentView);
    }];
    [_emailWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(title.hgx_bottom).offset(56);
        make.left.equalTo(self.contentView).offset(32);
        make.right.equalTo(self.contentView).offset(-32);
        make.height.hgx_equalTo(52);
    }];
    [_passwordWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_emailWrap.hgx_bottom).offset(14);
        make.left.right.height.equalTo(_emailWrap);
    }];
    [forgot hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_passwordWrap.hgx_bottom).offset(8);
        make.right.equalTo(_passwordWrap);
    }];
    [login hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.equalTo(_emailWrap);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-36);
        make.height.hgx_equalTo(62);
    }];
}

- (void)forgotTapped {
    [self.navigationController pushViewController:[[HangoForgotPasswordViewController alloc] init] animated:YES];
}

- (void)loginTapped {
    UITextField *emailField = [_emailWrap viewWithTag:9001];
    UITextField *passwordField = [_passwordWrap viewWithTag:9001];
    NSString *email = [emailField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *password = passwordField.text ?: @"";

    if ([email rangeOfString:@"@"].location == NSNotFound) {
        [self showAlertWithText:@"Please enter a valid email address."];
        return;
    }
    if (password.length == 0) {
        [self showAlertWithText:@"Please enter your password."];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [HangoLaunchPermissionManager ensureNetworkAccessFromViewController:self completion:^(BOOL allowed) {
        if (!allowed) return;
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            NSError *error = nil;
            if (![[HangoSessionManager shared] loginWithEmail:email password:password error:&error]) {
                [weakSelf showAlertWithText:error.localizedDescription ?: @"Login failed."];
                return;
            }
            if ([[HangoDataStore shared] hasCompletedProfile]) {
                [HangoAppRouter showMainTabBar];
            } else {
                [weakSelf.navigationController pushViewController:[[HangoProfileSetupViewController alloc] init] animated:YES];
            }
        }];
    }];
}

- (void)showAlertWithText:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
