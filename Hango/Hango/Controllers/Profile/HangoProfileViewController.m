#import "HangoProfileViewController.h"
#import "HangoUser.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoAppRouter.h"
#import "HangoWalletViewController.h"
#import "HangoHostedPartiesViewController.h"
#import "HangoEULAViewController.h"
#import "HangoBlacklistViewController.h"
#import "HangoEditProfileViewController.h"
#import "HangoDeleteAccountViewController.h"
#import <Masonry/Masonry.h>

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

    _avatarView = [HangoDesignKit avatarWithName:@"avatar_1" size:68 bordered:YES];
    [self.contentView addSubview:_avatarView];

    _nameLabel = [[UILabel alloc] init];
    _nameLabel.font = [UIFont boldSystemFontOfSize:24];
    _nameLabel.textColor = [HangoTheme primaryDarkColor];
    [self.contentView addSubview:_nameLabel];

    _idLabel = [[UILabel alloc] init];
    _idLabel.font = [HangoTheme captionFont];
    _idLabel.textColor = [HangoTheme secondaryTextColor];
    [self.contentView addSubview:_idLabel];

    UIButton *editBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [editBtn setImage:[HangoTheme imageNamed:@"artboard_57"] forState:UIControlStateNormal];
    [editBtn addTarget:self action:@selector(editProfile) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:editBtn];

    UIView *stats = [HangoDesignKit statsPanelView];
    [self.contentView addSubview:stats];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = UIColor.whiteColor;
    [stats addSubview:divider];

    UIButton *walletBox = [self statBoxWithTitle:@"Wallet" action:@selector(openWallet)];
    _walletLabel = [walletBox viewWithTag:200];
    [stats addSubview:walletBox];

    UIButton *partiesBox = [self statBoxWithTitle:@"My Parties" action:@selector(openParties)];
    _partiesLabel = [partiesBox viewWithTag:200];
    [stats addSubview:partiesBox];

    UIStackView *menu = [[UIStackView alloc] init];
    menu.axis = UILayoutConstraintAxisVertical;
    menu.spacing = 10;
    [self.contentView addSubview:menu];

    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"artboard_53" title:@"Privacy Policy" target:self action:@selector(openEULA)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"interface-user-single--close-geometric-human-person-single-up-user" title:@"User Agreement" target:self action:@selector(openEULA)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"interface-user-multiple--close-geometric-human-multiple-person-up-user (6)" title:@"Blacklist" target:self action:@selector(openBlacklist)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"artboard_54" title:@"Logout" target:self action:@selector(logout)]];
    [menu addArrangedSubview:[HangoDesignKit menuRowWithIcon:@"interface-delete-bin-2--remove-delete-empty-bin-trash-garbage" title:@"Delete account" target:self action:@selector(deleteAccount)]];

    [_avatarView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(16);
        make.left.equalTo(self.contentView).offset(20);
        make.width.height.mas_equalTo(68);
    }];
    [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView).offset(10);
        make.left.equalTo(_avatarView.mas_right).offset(14);
    }];
    [_idLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_nameLabel.mas_bottom).offset(4);
        make.left.equalTo(_nameLabel);
    }];
    [editBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_avatarView);
        make.right.equalTo(self.contentView).offset(-20);
        make.width.height.mas_equalTo(36);
    }];
    [stats mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_avatarView.mas_bottom).offset(18);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(88);
    }];
    [divider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.equalTo(stats);
        make.width.mas_equalTo(1);
        make.height.mas_equalTo(48);
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
        make.top.equalTo(stats.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];
}

- (UIButton *)statBoxWithTitle:(NSString *)title action:(SEL)action {
    UIButton *box = [UIButton buttonWithType:UIButtonTypeCustom];
    [box addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UILabel *value = [[UILabel alloc] init];
    value.tag = 200;
    value.font = [UIFont boldSystemFontOfSize:26];
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
        make.top.equalTo(box).offset(14);
    }];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(box);
        make.bottom.equalTo(box).offset(-12);
    }];
    return box;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshProfile];
}

- (void)refreshProfile {
    [[HangoRequestManager shared] requestWithDelay:0.5 inView:self.view operation:^id {
        return [HangoDataStore shared].currentUser;
    } completion:^(HangoUser *user, NSError *error) {
        self->_avatarView.image = [HangoTheme avatarImageForUser:user];
        self->_nameLabel.text = user.name;
        self->_idLabel.text = [NSString stringWithFormat:@"ID: %@", user.userId];
        self->_walletLabel.text = [NSString stringWithFormat:@"💎 %@", @(user.diamondBalance)];
        self->_partiesLabel.text = @(user.hostedPartyCount).stringValue;
    }];
}

- (void)editProfile { [self.navigationController pushViewController:[[HangoEditProfileViewController alloc] init] animated:YES]; }
- (void)openWallet { [self.navigationController pushViewController:[[HangoWalletViewController alloc] init] animated:YES]; }
- (void)openParties { [self.navigationController pushViewController:[[HangoHostedPartiesViewController alloc] init] animated:YES]; }
- (void)openEULA { [self.navigationController pushViewController:[[HangoEULAViewController alloc] init] animated:YES]; }
- (void)openBlacklist { [self.navigationController pushViewController:[[HangoBlacklistViewController alloc] init] animated:YES]; }

- (void)logout {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [[HangoSessionManager shared] logout];
        [HangoAppRouter showWelcome];
    }];
}

- (void)deleteAccount {
    [self.navigationController pushViewController:[[HangoDeleteAccountViewController alloc] init] animated:YES];
}

@end
