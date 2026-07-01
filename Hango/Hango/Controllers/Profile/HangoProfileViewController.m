#import "HangoProfileViewController.h"
#import "HangoPersona.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoAppRouter.h"
#import "HangoWalletViewController.h"
#import "HangoHostedPartiesViewController.h"
#import "HangoWebPageViewController.h"
#import "HangoDenyListViewController.h"
#import "HangoProfileSetupViewController.h"
#import "HangoDeleteAccountViewController.h"
#import "Masonry.h"

@implementation HangoProfileViewController {
    UIImageView *_avatarView;
    UILabel *_nameLabel;
    UILabel *_idLabel;
    UILabel *_walletLabel;
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
    UIImage *editIcon = [HangoTheme imageNamed:@"编辑资料"];
    [editBtn setImage:editIcon forState:UIControlStateNormal];
    editBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [editBtn addTarget:self action:@selector(editProfile) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:editBtn];

    UIView *stats = [HangoDesignKit statsPanelView];
    [self.contentView addSubview:stats];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = UIColor.whiteColor;
    [stats addSubview:divider];

    UIButton *walletBox = [self walletStatBox];
    _walletLabel = [walletBox viewWithTag:200];
    [stats addSubview:walletBox];

    UIButton *partiesBox = [self statBoxWithTitle:@"My Parties" action:@selector(openParties)];
    _partiesLabel = [partiesBox viewWithTag:200];
    [stats addSubview:partiesBox];

    UIStackView *menu = [[UIStackView alloc] init];
    menu.axis = UILayoutConstraintAxisVertical;
    menu.spacing = 10;
    [self.contentView addSubview:menu];

    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"隐私政策" title:@"Privacy Policy" target:self action:@selector(openPrivacyPolicy)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"用户同意" title:@"Member Agreement" target:self action:@selector(openUserAgreement)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"黑名单" title:@"Deny List" target:self action:@selector(openDenyList)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"退出登录" title:@"Logout" target:self action:@selector(logout)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"删除账号" title:@"Delete account" target:self action:@selector(deleteAccount)]];

    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.left.equalTo(self.contentView).offset(20);
        make.width.height.mas_equalTo(72);
    }];
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView).offset(12);
        make.left.equalTo(_avatarView.mas_right).offset(14);
        make.right.lessThanOrEqualTo(editBtn.mas_left).offset(-8);
    }];
    [_idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nameLabel.mas_bottom).offset(6);
        make.left.equalTo(_nameLabel);
    }];
    [editBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_avatarView);
        make.right.equalTo(self.contentView).offset(-20);
        make.width.height.mas_equalTo(36);
    }];
    [stats mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(92);
    }];
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(stats);
        make.width.mas_equalTo(1);
        make.height.mas_equalTo(52);
    }];
    [walletBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(stats);
        make.width.equalTo(stats).multipliedBy(0.5);
    }];
    [partiesBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(stats);
        make.width.equalTo(stats).multipliedBy(0.5);
    }];
    [menu mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(stats.mas_bottom).offset(18);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
}

- (UIButton *)walletStatBox {
    UIButton *box = [UIButton buttonWithType:UIButtonTypeCustom];
    [box addTarget:self action:@selector(openWallet) forControlEvents:UIControlEventTouchUpInside];

    UIImageView *sparkleIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"钻石图标"]];
    sparkleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [box addSubview:sparkleIcon];

    UILabel *value = [[UILabel alloc] init];
    value.tag = 200;
    value.font = [UIFont monospacedSystemFontOfSize:26 weight:UIFontWeightBold];
    value.textColor = [HangoTheme primaryDarkColor];
    [box addSubview:value];

    UILabel *label = [[UILabel alloc] init];
    label.text = @"Wallet";
    label.font = [HangoTheme captionFont];
    label.textColor = [HangoTheme secondaryTextColor];
    [box addSubview:label];

    [sparkleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(box).offset(22);
        make.centerY.equalTo(box);
        make.width.height.mas_equalTo(36);
    }];
    [value mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sparkleIcon.mas_right).offset(10);
        make.top.equalTo(box).offset(20);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(value);
        make.top.equalTo(value.mas_bottom).offset(2);
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
    [value mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(box);
        make.top.equalTo(box).offset(20);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(box);
        make.top.equalTo(value.mas_bottom).offset(2);
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
        self->_walletLabel.text = @(persona.sparkleBalance).stringValue;
        self->_partiesLabel.text = [result[@"partyCount"] stringValue];
    }];
}

- (void)editProfile {
    HangoProfileSetupViewController *vc = [[HangoProfileSetupViewController alloc] init];
    vc.editingExistingProfile = YES;
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)openWallet { [self.navigationController pushViewController:[[HangoWalletViewController alloc] init] animated:YES]; }
- (void)openParties { [self.navigationController pushViewController:[[HangoHostedPartiesViewController alloc] init] animated:YES]; }

- (void)openPrivacyPolicy {
    [self.navigationController pushViewController:[HangoWebPageViewController privacyPolicyViewController] animated:YES];
}

- (void)openUserAgreement {
    [self.navigationController pushViewController:[HangoWebPageViewController memberAgreementViewController] animated:YES];
}

- (void)openDenyList { [self.navigationController pushViewController:[[HangoDenyListViewController alloc] init] animated:YES]; }

- (void)logout {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Logout"
                                                                   message:@"Are you sure you want to log out?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Logout" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [[HangoSessionManager shared] logout];
            [HangoAppRouter showWelcome];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)deleteAccount {
    HangoDeleteAccountViewController *vc = [[HangoDeleteAccountViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
