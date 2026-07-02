#import "HangoDisplayString.h"
#import "HangoProfileViewController.h"
#import "HangoPersona.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoAppRouter.h"
#import "HangovalueViewController.h"
#import "HangoHostedPartiesViewController.h"
#import "HangoWebPageViewController.h"
#import "HangoDenyListViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoDeleteAccountViewController.h"
#import "HGXAnchor.h"

@implementation HangoProfileViewController {
    UIImageView *_avatarView;
    UILabel *_nameLabel;
    UILabel *_idLabel;
    UILabel *_valueLabel;
    UILabel *_partiesLabel;
}

- (void)viewDidLoad {
    self.tabIndex = HangoTabIndexProfile;
    [super viewDidLoad];
}

- (void)setupUI {
    [super setupUI];

    _avatarView = [HangoDesignKit avatarWithName:@"edit_avatar" size:72 bordered:YES];
    [self.contentView addSubview:_avatarView];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont monospacedSystemFontOfSize:24 weight:UIFontWeightBold];
    _nameLabel.textColor = [HangoTheme primaryDarkColor];
    [self.contentView addSubview:_nameLabel];

    _idLabel = [[UILabel alloc] init];
    _idLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    _idLabel.textColor = [HangoTheme secondaryTextColor];
    [self.contentView addSubview:_idLabel];

    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *editIcon = [HangoTheme imageNamed:@"edit_profile_icon"];
    [editBtn setImage:editIcon forState:UIControlStateNormal];
    editBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [editBtn addTarget:self action:@selector(editProfile) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:editBtn];

    UIView *stats = [HangoDesignKit statsPanelView];
    [self.contentView addSubview:stats];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = UIColor.whiteColor;
    [stats addSubview:divider];

    UIButton *valueBox = [self valueStatBox];
    _valueLabel = [valueBox viewWithTag:200];
    [stats addSubview:valueBox];

    UIButton *partiesBox = [self statBoxWithTitle:@"My Parties" action:@selector(openParties)];
    _partiesLabel = [partiesBox viewWithTag:200];
    [stats addSubview:partiesBox];

    UIStackView *menu = [[UIStackView alloc] init];
    menu.axis = UILayoutConstraintAxisVertical;
    menu.spacing = 10;
    [self.contentView addSubview:menu];

    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"privacy_policy_icon" title:@"Privacy Policy" target:self action:@selector(openPrivacyPolicy)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"user_agreement_icon" title:HangoDisplayString(HangoDisplayStringKeyUserAgreement) target:self action:@selector(openUserAgreement)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"deny_list_icon" title:HangoDisplayString(HangoDisplayStringKeyBlacklist) target:self action:@selector(openDenyList)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"logout_icon" title:@"Logout" target:self action:@selector(logout)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"delete_account_icon" title:@"Delete account" target:self action:@selector(deleteAccount)]];

    [_avatarView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.left.equalTo(self.contentView).offset(20);
        make.width.height.hgx_equalTo(72);
    }];
    [_nameLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_avatarView).offset(12);
        make.left.equalTo(_avatarView.hgx_right).offset(14);
        make.right.lessThanOrEqualTo(editBtn.hgx_left).offset(-8);
    }];
    [_idLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_nameLabel.hgx_bottom).offset(6);
        make.left.equalTo(_nameLabel);
    }];
    [editBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(_avatarView);
        make.right.equalTo(self.contentView).offset(-20);
        make.width.height.hgx_equalTo(36);
    }];
    [stats hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_avatarView.hgx_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.hgx_equalTo(92);
    }];
    [divider hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.centerY.equalTo(stats);
        make.width.hgx_equalTo(1);
        make.height.hgx_equalTo(52);
    }];
    [valueBox hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.top.bottom.equalTo(stats);
        make.width.equalTo(stats).multipliedBy(0.5);
    }];
    [partiesBox hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.top.bottom.equalTo(stats);
        make.width.equalTo(stats).multipliedBy(0.5);
    }];
    [menu hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(stats.hgx_bottom).offset(18);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
}

- (UIButton *)valueStatBox {
    UIButton *box = [UIButton buttonWithType:UIButtonTypeCustom];
    [box addTarget:self action:@selector(openvalue) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *sparkleIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"sparkle_icon"]];
    sparkleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [box addSubview:sparkleIcon];

    UILabel *value = [[UILabel alloc] init];
    value.tag = 200;
    value.font = [UIFont monospacedSystemFontOfSize:26 weight:UIFontWeightBold];
    value.textColor = [HangoTheme primaryDarkColor];
    [box addSubview:value];

    UILabel *label = [[UILabel alloc] init];
    label.text = HangoDisplayString(HangoDisplayStringKeyValueShort);
    label.font = [HangoTheme captionFont];
    label.textColor = [HangoTheme secondaryTextColor];
    [box addSubview:label];

    [sparkleIcon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(box).offset(22);
        make.centerY.equalTo(box);
        make.width.height.hgx_equalTo(36);
    }];
    [value hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(sparkleIcon.hgx_right).offset(10);
        make.top.equalTo(box).offset(20);
    }];
    [label hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(value);
        make.top.equalTo(value.hgx_bottom).offset(2);
    }];
    return box;
}

- (UIButton *)statBoxWithTitle:(NSString *)title action:(SEL)action {
    UIButton *box = [UIButton buttonWithType:UIButtonTypeCustom];
    [box addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UILabel *value = [[UILabel alloc] init];
    value.tag = 200;
    value.font = [UIFont monospacedSystemFontOfSize:26 weight:UIFontWeightBold];
    value.textColor = [HangoTheme primaryDarkColor];
    value.textAlignment = NSTextAlignmentCenter;
    [box addSubview:value];
    UILabel *label = [[UILabel alloc] init];
    label.text = title;
    label.font = [HangoTheme captionFont];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [HangoTheme secondaryTextColor];
    [box addSubview:label];
    [value hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(box);
        make.top.equalTo(box).offset(20);
    }];
    [label hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(box);
        make.top.equalTo(value.hgx_bottom).offset(2);
    }];
    return box;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshProfile];
}

- (void)refreshProfile {
    [[HangoRequestManager shared] requestWithDelay:0.5 inView:self.view showsHUD:NO operation:^id {
        HangoDataStore *store = [HangoDataStore shared];
        return @{
            @"persona": store.currentPersona,
            @"partyCount": @(store.hostedParties.count),
        };
    } completion:^(NSDictionary *result, NSError *error) {
        HangoPersona *persona = result[@"persona"];
        if (!persona) {
            return;
        }
        self->_avatarView.image = [HangoTheme avatarImageForPersona:persona];
        self->_nameLabel.text = persona.name;
        self->_idLabel.text = [NSString stringWithFormat:@"ID: %@", persona.personaId];
        self->_valueLabel.text = @(persona.sparkleBalance).stringValue;
        self->_partiesLabel.text = [result[@"partyCount"] stringValue];
    }];
}

- (void)editProfile {
    if (![self requireLoginForAction]) {
        return;
    }
    HangoProfileSetupViewController *vc = [[HangoProfileSetupViewController alloc] init];
    vc.editingExistingProfile = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)openvalue {
    if (![self requireLoginForAction]) {
        return;
    }
    [self.navigationController pushViewController:[[HangovalueViewController alloc] init] animated:YES];
}
- (void)openParties {
    if (![self requireLoginForAction]) {
        return;
    }
    [self.navigationController pushViewController:[[HangoHostedPartiesViewController alloc] init] animated:YES];
}

- (void)openPrivacyPolicy {
    [self.navigationController pushViewController:[HangoWebPageViewController privacyPolicyViewController] animated:YES];
}

- (void)openUserAgreement {
    [self.navigationController pushViewController:[HangoWebPageViewController memberAgreementViewController] animated:YES];
}

- (void)openDenyList {
    if (![self requireLoginForAction]) {
        return;
    }
    [self.navigationController pushViewController:[[HangoDenyListViewController alloc] init] animated:YES];
}

- (void)logout {
    if ([HangoSessionManager shared].isGuest) {
        [[HangoSessionManager shared] exitGuestMode];
        [HangoAppRouter showAuthEntry];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logout"
                                                                   message:@"Are you sure you want to log out?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [[HangoSessionManager shared] logout];
            [HangoAppRouter showAuthEntry];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteAccount {
    if (![self requireLoginForAction]) {
        return;
    }
    HangoDeleteAccountViewController *vc = [[HangoDeleteAccountViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
