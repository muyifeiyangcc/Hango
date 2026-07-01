#import "HangoPartyCardView.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoHUD.h"
#import "Masonry.h"

static NSString * const kHangoPartyAcceptIconPending = @"未接受聚会";
static NSString * const kHangoPartyAcceptIconAccepted = @"已接受聚会";
static const NSTimeInterval kHangoPartyAcceptLoadingDuration = 0.3;
static const CGFloat kHangoPartyAcceptButtonWidth = 88.0;
static const CGFloat kHangoPartyAcceptButtonHeight = 40.0;

@interface HangoPartyCardView ()
@property (nonatomic, copy) NSString *partyId;
@property (nonatomic, assign) BOOL isAccepted;
@property (nonatomic, assign) BOOL isAcceptLoading;
@property (nonatomic, strong) UIButton *acceptButton;
@property (nonatomic, assign) CGFloat acceptButtonWidth;
@property (nonatomic, assign) CGFloat acceptButtonHeight;
@end

@implementation HangoPartyCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [HangoDesignKit applyCardShadow:self];
    }
    return self;
}

- (void)configureWithParty:(HangoParty *)party {
    [self configureWithParty:party showsAcceptButton:YES];
}

- (void)configureWithParty:(HangoParty *)party showsAcceptButton:(BOOL)showsAcceptButton {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.acceptButton = nil;
    self.isAcceptLoading = NO;
    self.partyId = party.partyId;
    self.isAccepted = [[HangoDataStore shared] isPartyAccepted:party.partyId];
    self.backgroundColor = UIColor.whiteColor;
    self.layer.cornerRadius = 18;

    NSString *avatarName = [HangoTheme partyDisplayAvatarNameForHostName:party.hostName fallbackAvatarName:party.hostAvatarName];
    UIImageView *avatar = [HangoDesignKit avatarWithName:avatarName size:44 bordered:YES];
    if (party.isHosted && ![HangoTheme isRealPersonAvatarName:party.hostName]) {
        UIImage *userImage = [HangoTheme avatarImageForPersona:HangoDataStore.shared.currentPersona];
        if (userImage) {
            avatar.image = userImage;
        }
    }
    [self addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = party.hostName;
    name.font = [UIFont boldSystemFontOfSize:17];
    name.textColor = [HangoTheme primaryDarkColor];
    [self addSubview:name];

    UILabel *time = [[UILabel alloc] init];
    time.text = [NSString stringWithFormat:@"%@ %@", party.timeText, party.dateText];
    time.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    time.textColor = [HangoTheme secondaryTextColor];
    [self addSubview:time];

    UILabel *invite = [[UILabel alloc] init];
    invite.text = [NSString stringWithFormat:@"  %@  ", party.invitation];
    invite.font = [HangoTheme monoFont];
    invite.textColor = [HangoTheme primaryDarkColor];
    invite.numberOfLines = 0;
    invite.lineBreakMode = NSLineBreakByWordWrapping;
    invite.backgroundColor = [HangoTheme mintBubbleColor];
    invite.layer.cornerRadius = 10;
    invite.clipsToBounds = YES;
    [self addSubview:invite];

    UIImageView *pin = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"地址图标"]];
    pin.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:pin];

    UILabel *location = [[UILabel alloc] init];
    location.text = party.location;
    location.font = [HangoTheme captionFont];
    location.textColor = [HangoTheme secondaryTextColor];
    [self addSubview:location];

    UIStackView *avatars = [[UIStackView alloc] init];
    avatars.axis = UILayoutConstraintAxisHorizontal;
    avatars.spacing = -10;
    for (NSString *memberName in party.memberAvatarNames) {
        NSString *memberAvatarName = [HangoTheme resolvedPartyAvatarName:memberName];
        UIImageView *img = [HangoDesignKit avatarWithName:memberAvatarName size:30 bordered:YES];
        [img mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(30); }];
        [avatars addArrangedSubview:img];
    }
    if (party.extraMemberCount > 0) {
        UILabel *extra = [[UILabel alloc] init];
        extra.text = [NSString stringWithFormat:@"+%ld", (long)party.extraMemberCount];
        extra.font = [UIFont boldSystemFontOfSize:11];
        extra.textAlignment = NSTextAlignmentCenter;
        extra.backgroundColor = [HangoTheme accentBlueColor];
        extra.textColor = [HangoTheme primaryDarkColor];
        extra.layer.cornerRadius = 15;
        extra.clipsToBounds = YES;
        extra.layer.borderWidth = 2;
        extra.layer.borderColor = UIColor.whiteColor.CGColor;
        [extra mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(30); }];
        [avatars addArrangedSubview:extra];
    }
    [self addSubview:avatars];

    if (showsAcceptButton && !party.isHosted) {
        [self setupAcceptButton];
        [self addSubview:self.acceptButton];
    }

    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(self).offset(14);
        make.width.height.mas_equalTo(44);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatar).offset(2);
        make.left.equalTo(avatar.mas_right).offset(10);
    }];
    [time mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(name.mas_bottom).offset(2);
        make.left.equalTo(name);
    }];
    [invite mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatar.mas_bottom).offset(12);
        make.left.equalTo(self).offset(14);
        make.right.equalTo(self).offset(-14);
        make.height.mas_greaterThanOrEqualTo(44);
    }];
    [pin mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(invite.mas_bottom).offset(10);
        make.left.equalTo(invite);
        make.width.height.mas_equalTo(14);
    }];
    [location mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(pin);
        make.left.equalTo(pin.mas_right).offset(4);
    }];
    [avatars mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(pin.mas_bottom).offset(12);
        make.left.equalTo(invite);
        make.bottom.equalTo(self).offset(-14);
    }];
    if (self.acceptButton) {
        [self.acceptButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).offset(-14);
            make.centerY.equalTo(avatars);
            make.width.mas_equalTo(self.acceptButtonWidth);
            make.height.mas_equalTo(self.acceptButtonHeight);
        }];
    }
}

- (void)setupAcceptButton {
    self.acceptButtonWidth = kHangoPartyAcceptButtonWidth;
    self.acceptButtonHeight = kHangoPartyAcceptButtonHeight;

    self.acceptButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.acceptButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.acceptButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    self.acceptButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self updateAcceptButtonImage];
    [self.acceptButton addTarget:self action:@selector(acceptTapped) forControlEvents:UIControlEventTouchUpInside];
}

- (UIImage *)acceptIconForAccepted:(BOOL)accepted {
    NSString *name = accepted ? kHangoPartyAcceptIconAccepted : kHangoPartyAcceptIconPending;
    return [HangoTheme imageNamed:name];
}

- (void)updateAcceptButtonImage {
    UIImage *icon = [self acceptIconForAccepted:self.isAccepted];
    UIImage *scaledIcon = [self scaledAcceptIcon:icon];
    [self.acceptButton setImage:[scaledIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.acceptButton setImage:[scaledIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateHighlighted];
}

- (UIImage *)scaledAcceptIcon:(UIImage *)icon {
    if (!icon) {
        return nil;
    }
    CGSize size = CGSizeMake(kHangoPartyAcceptButtonWidth, kHangoPartyAcceptButtonHeight);
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = NO;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull context) {
        CGFloat scale = MIN(size.width / icon.size.width, size.height / icon.size.height);
        CGFloat width = icon.size.width * scale;
        CGFloat height = icon.size.height * scale;
        CGRect rect = CGRectMake((size.width - width) / 2.0, (size.height - height) / 2.0, width, height);
        [icon drawInRect:rect];
    }];
}

- (void)acceptTapped {
    if (self.isAcceptLoading || self.partyId.length == 0) {
        return;
    }

    self.isAcceptLoading = YES;
    self.acceptButton.enabled = NO;
    [MBProgressHUD showActivityMessageInWindow:@""];

    BOOL accepting = !self.isAccepted;
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kHangoPartyAcceptLoadingDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }

        BOOL success = [[HangoDataStore shared] setPartyAccepted:accepting forPartyId:strongSelf.partyId];
        strongSelf.isAcceptLoading = NO;
        strongSelf.acceptButton.enabled = YES;

        if (!success) {
            return;
        }

        strongSelf.isAccepted = accepting;
        [strongSelf updateAcceptButtonImage];
        [MBProgressHUD showSuccessMessage:accepting ? @"Accepted successfully" : @"Unaccepted successfully"];
    });
}

@end
