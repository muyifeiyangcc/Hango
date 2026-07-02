#import "HangoEditProfileViewController.h"
#import "HangoPersona.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

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

    _avatarView = [HangoDesignKit avatarWithName:@"edit_avatar" size:100 bordered:YES];
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

    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
    }];
    [_avatarView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(title.hgx_bottom).offset(24);
        make.centerX.equalTo(self.contentView);
        make.width.height.hgx_equalTo(100);
    }];
    [_nameWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_avatarView.hgx_bottom).offset(24);
        make.left.equalTo(self.contentView).offset(28);
        make.right.equalTo(self.contentView).offset(-28);
        make.height.hgx_equalTo(52);
    }];
    [_emailWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_nameWrap.hgx_bottom).offset(12);
        make.left.right.height.equalTo(_nameWrap);
    }];
    [_bioView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_emailWrap.hgx_bottom).offset(12);
        make.left.right.equalTo(_nameWrap);
        make.height.hgx_equalTo(100);
    }];
    [save hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.equalTo(_nameWrap);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-36);
        make.height.hgx_equalTo(62);
    }];

    [self loadProfile];
}

- (void)loadProfile {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:NO completion:^{
        HangoPersona *persona = [HangoDataStore shared].currentPersona;
        self->_avatarView.image = [HangoTheme avatarImageForPersona:persona];
        UITextField *name = [self->_nameWrap viewWithTag:9001];
        UITextField *email = [self->_emailWrap viewWithTag:9001];
        name.text = persona.name;
        email.text = persona.email;
        self->_bioView.text = persona.bio;
        self->_bioView.textColor = [HangoTheme primaryDarkColor];
    }];
}

- (void)save {
    if (![self requireLoginForAction]) {
        return;
    }
    UITextField *name = [_nameWrap viewWithTag:9001];
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES completion:^{
        [[HangoSessionManager shared] updateProfileWithName:name.text avatarName:nil bio:self->_bioView.text];
        [MBProgressHUD showSuccessMessage:@"Profile updated"];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
