#import "HangoForgotPasswordViewController.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoHUD.h"
#import "Masonry.h"

@implementation HangoForgotPasswordViewController {
    UIView *_emailWrap;
    UIView *_passwordWrap;
    UIView *_confirmWrap;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Forgot password"];
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

    UIButton *saveBtn = [HangoDesignKit pillButtonWithTitle:@"Save" style:HangoPillButtonStyleDark];
    saveBtn.layer.cornerRadius = 20;
    [saveBtn addTarget:self action:@selector(submitTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:saveBtn];

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
    [saveBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(_emailWrap);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-36);
        make.height.mas_equalTo(62);
    }];
}

- (void)submitTapped {
    UITextField *passwordField = [_passwordWrap viewWithTag:9001];
    UITextField *confirmField = [_confirmWrap viewWithTag:9001];
    NSString *password = passwordField.text ?: @"";
    NSString *confirm = confirmField.text ?: @"";
    if (![password isEqualToString:confirm]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:@"Passwords do not match." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES completion:^{
        [MBProgressHUD showSuccessMessage:@"Password saved"];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
