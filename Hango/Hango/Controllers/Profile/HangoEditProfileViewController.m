#import "HangoEditProfileViewController.h"
#import "HangoUser.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <MBProgressHUD+JDragon/MBProgressHUD+JDragon.h>
#import <Masonry/Masonry.h>

@implementation HangoEditProfileViewController {
    UIView *_nameWrap;
    UIView *_emailWrap;
    UITextView *_bioView;
    UIImageView *_avatarView;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Profile"];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    _avatarView = [HangoDesignKit avatarWithName:@"avatar_1" size:100 bordered:YES];
    [self.contentView addSubview:_avatarView];

    _nameWrap = [HangoDesignKit inputFieldWithPlaceholder:@"Name" iconName:@"interface-user-single--close-geometric-human-person-single-up-user"];
    _emailWrap = [HangoDesignKit inputFieldWithPlaceholder:@"Email" iconName:@"email_f"];
    UITextField *email = [_emailWrap viewWithTag:9001];
    email.keyboardType = UIKeyboardTypeEmailAddress;

    _bioView = [[UITextView alloc] init];
    _bioView.backgroundColor = UIColor.whiteColor;
    _bioView.layer.cornerRadius = 14;
    _bioView.font = [HangoTheme bodyFont];
    _bioView.textContainerInset = UIEdgeInsetsMake(14, 12, 14, 12);
    [HangoDesignKit applyCardShadow:_bioView];

    [self.contentView addSubview:_nameWrap];
    [self.contentView addSubview:_emailWrap];
    [self.contentView addSubview:_bioView];

    UIButton *save = [HangoDesignKit pillButtonWithTitle:@"Save" style:HangoPillButtonStyleDark];
    [save addTarget:self action:@selector(save) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:save];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
    }];
    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(24);
        make.centerX.equalTo(self.contentView);
        make.width.height.mas_equalTo(100);
    }];
    [_nameWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView.mas_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(28);
        make.right.equalTo(self.contentView).offset(-28);
        make.height.mas_equalTo(52);
    }];
    [_emailWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nameWrap.mas_bottom).offset(12);
        make.left.right.height.equalTo(_nameWrap);
    }];
    [_bioView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_emailWrap.mas_bottom).offset(12);
        make.left.right.equalTo(_nameWrap);
        make.height.mas_equalTo(100);
    }];
    [save mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(_nameWrap);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-36);
        make.height.mas_equalTo(62);
    }];

    [self loadProfile];
}

- (void)loadProfile {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        HangoUser *user = [HangoDataStore shared].currentUser;
        self->_avatarView.image = [HangoTheme avatarImageForUser:user];
        UITextField *name = [self->_nameWrap viewWithTag:9001];
        UITextField *email = [self->_emailWrap viewWithTag:9001];
        name.text = user.name;
        email.text = user.email;
        self->_bioView.text = user.bio;
        self->_bioView.textColor = [HangoTheme primaryDarkColor];
    }];
}

- (void)save {
    UITextField *name = [_nameWrap viewWithTag:9001];
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [[HangoSessionManager shared] updateProfileWithName:name.text avatarName:nil bio:self->_bioView.text];
        [MBProgressHUD showSuccessMessage:@"Profile updated"];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
