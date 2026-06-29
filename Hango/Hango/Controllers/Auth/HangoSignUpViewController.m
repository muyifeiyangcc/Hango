#import "HangoSignUpViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoRequestManager.h"
#import "HangoSessionManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <Masonry/Masonry.h>

@implementation HangoSignUpViewController {
    UIView *_emailWrap;
    UIView *_passwordWrap;
    UIView *_confirmWrap;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Sign up"];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    _emailWrap = [HangoDesignKit inputFieldWithPlaceholder:@"Email" iconName:@"email_f"];
    _passwordWrap = [HangoDesignKit inputFieldWithPlaceholder:@"Password" iconName:@"password_icon"];
    _confirmWrap = [HangoDesignKit inputFieldWithPlaceholder:@"Enter the password again" iconName:@"password_icon"];
    _emailWrap.layer.cornerRadius = 20;
    _passwordWrap.layer.cornerRadius = 20;
    _confirmWrap.layer.cornerRadius = 20;

    UITextField *email = [_emailWrap viewWithTag:9001];
    UITextField *password = [_passwordWrap viewWithTag:9001];
    UITextField *confirm = [_confirmWrap viewWithTag:9001];
    email.keyboardType = UIKeyboardTypeEmailAddress;
    email.autocapitalizationType = UITextAutocapitalizationTypeNone;
    password.secureTextEntry = YES;
    confirm.secureTextEntry = YES;

    [self.contentView addSubview:_emailWrap];
    [self.contentView addSubview:_passwordWrap];
    [self.contentView addSubview:_confirmWrap];

    UIButton *signUpBtn = [HangoDesignKit pillButtonWithTitle:@"Sign up" style:HangoPillButtonStyleDark];
    signUpBtn.layer.cornerRadius = 20;
    [signUpBtn addTarget:self action:@selector(registerTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:signUpBtn];

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
    [_confirmWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_passwordWrap.mas_bottom).offset(14);
        make.left.right.height.equalTo(_emailWrap);
    }];
    [signUpBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(_emailWrap);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-36);
        make.height.mas_equalTo(62);
    }];
}

- (void)registerTapped {
    UITextField *emailField = [_emailWrap viewWithTag:9001];
    NSString *email = [emailField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if ([email rangeOfString:@"@"].location == NSNotFound) {
        [self showAlertWithMessage:@"Please enter a valid email address."];
        return;
    }

    UITextField *passwordField = [_passwordWrap viewWithTag:9001];
    UITextField *confirmField = [_confirmWrap viewWithTag:9001];
    NSString *password = passwordField.text ?: @"";
    NSString *confirm = confirmField.text ?: @"";
    if (![password isEqualToString:confirm]) {
        [self showAlertWithMessage:@"Passwords do not match."];
        return;
    }

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [[HangoSessionManager shared] registerWithEmail:email password:password];
        [self.navigationController pushViewController:[[HangoProfileSetupViewController alloc] init] animated:YES];
    }];
}

- (void)showAlertWithMessage:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
