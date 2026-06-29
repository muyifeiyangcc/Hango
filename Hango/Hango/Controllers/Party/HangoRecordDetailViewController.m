#import "HangoRecordDetailViewController.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoDecoratePhotoViewController.h"
#import "HangoGroupChatViewController.h"
#import "HangoAllPeopleViewController.h"
#import <Masonry/Masonry.h>

@implementation HangoRecordDetailViewController {
    UIScrollView *_photoScroll;
    UILabel *_descLabel;
}

- (void)setupUI {
    self.showsBackButton = YES;
    if (!self.party) self.party = [HangoDataStore shared].upcomingParties.firstObject;

    UIStackView *avatars = [[UIStackView alloc] init];
    avatars.axis = UILayoutConstraintAxisHorizontal;
    avatars.spacing = -12;
    for (NSString *name in self.party.memberAvatarNames) {
        UIImageView *img = [HangoDesignKit avatarWithName:name size:36 bordered:YES];
        [img mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(36); }];
        [avatars addArrangedSubview:img];
    }
    avatars.userInteractionEnabled = YES;
    [avatars addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPeople)]];
    [self.contentView addSubview:avatars];

    _descLabel = [[UILabel alloc] init];
    _descLabel.numberOfLines = 0;
    _descLabel.font = [HangoTheme monoFont];
    _descLabel.textColor = [HangoTheme primaryDarkColor];
    _descLabel.backgroundColor = [HangoTheme mintBubbleColor];
    _descLabel.layer.cornerRadius = 12;
    _descLabel.clipsToBounds = YES;
    _descLabel.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:_descLabel];

    _photoScroll = [[UIScrollView alloc] init];
    _photoScroll.pagingEnabled = YES;
    _photoScroll.showsHorizontalScrollIndicator = NO;
    _photoScroll.decelerationRate = UIScrollViewDecelerationRateFast;
    [self.contentView addSubview:_photoScroll];

    UIButton *upload = [UIButton buttonWithType:UIButtonTypeCustom];
    upload.backgroundColor = UIColor.whiteColor;
    upload.layer.cornerRadius = 28;
    [upload setImage:[HangoTheme imageNamed:@"interface-upload-button-2--arrow-bottom-download-internet-network,-erver-up-upload"] forState:UIControlStateNormal];
    [upload setTitle:@" Upload party photos" forState:UIControlStateNormal];
    [upload setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    upload.titleLabel.font = [UIFont boldSystemFontOfSize:15];
    upload.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    upload.contentEdgeInsets = UIEdgeInsetsMake(0, 16, 0, 0);
    upload.imageEdgeInsets = UIEdgeInsetsMake(0, -4, 0, 8);
    [upload addTarget:self action:@selector(openDecorate) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:upload];

    UIButton *chat = [UIButton buttonWithType:UIButtonTypeCustom];
    chat.backgroundColor = UIColor.whiteColor;
    chat.layer.cornerRadius = 28;
    [chat setImage:[HangoTheme imageNamed:@"mail-chat-bubble-typing-oval--messages-message-bubble-typing-chat"] forState:UIControlStateNormal];
    [chat addTarget:self action:@selector(openGroupChat) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:chat];

    [avatars mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
    }];
    [_descLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatars.mas_bottom).offset(14);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
    }];
    [_photoScroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_descLabel.mas_bottom).offset(18);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(upload.mas_top).offset(-20);
    }];
    [upload mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(20);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.height.mas_equalTo(56);
        make.right.equalTo(chat.mas_left).offset(-12);
    }];
    [chat mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-20);
        make.centerY.width.height.equalTo(upload);
        make.width.mas_equalTo(56);
    }];

    [self loadRecord];
}

- (void)loadRecord {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        self->_descLabel.text = [NSString stringWithFormat:@"  \"%@\"  ", self.party.invitation];
        [self reloadPhotos];
    }];
}

- (void)reloadPhotos {
    for (UIView *v in _photoScroll.subviews) [v removeFromSuperview];
    NSArray *images = @[self.party.coverImageName ?: @"avatar_10", @"avatar_11", @"avatar_12"];
    CGFloat w = CGRectGetWidth(UIScreen.mainScreen.bounds) - 56;
    for (NSInteger i = 0; i < images.count; i++) {
        UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(28 + i * (w + 20), 0, w, CGRectGetHeight(_photoScroll.bounds) > 0 ? CGRectGetHeight(_photoScroll.bounds) : 380)];
        img.image = [HangoTheme avatarImageNamed:images[i]];
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.layer.cornerRadius = 36;
        img.clipsToBounds = YES;
        img.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        [_photoScroll addSubview:img];
    }
    _photoScroll.contentSize = CGSizeMake(28 + images.count * (w + 20), 400);
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self reloadPhotos];
}

- (void)openDecorate {
    HangoDecoratePhotoViewController *vc = [[HangoDecoratePhotoViewController alloc] init];
    vc.party = self.party;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openGroupChat {
    HangoGroupChatViewController *vc = [[HangoGroupChatViewController alloc] init];
    vc.party = self.party;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openPeople {
    HangoAllPeopleViewController *vc = [[HangoAllPeopleViewController alloc] init];
    vc.party = self.party;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
