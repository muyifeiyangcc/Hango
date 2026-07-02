#import "HangoPartyCardView.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoHUD.h"
#import "HangoGuestGuard.h"
#import "UIView+HangoViewController.h"
#import "HGXAnchor.h"

static NSString * const kHangoPartyAcceptIconPending = @"party_pending";
static NSString * const kHangoPartyAcceptIconAccepted = @"party_accepted";
static const NSTimeInterval kHangoPartyAcceptLoadingDuration = 0.3;
static const CGFloat kHangoPartyAcceptButtonWidth = 88.0;
static const CGFloat kHangoPartyAcceptButtonHeight = 40.0;
static const CGFloat kHangoPartyInviteHorizontalInset = 16.0;
static const CGFloat kHangoPartyInviteTextInsetH = 14.0;
static const CGFloat kHangoPartyInviteTextInsetV = 10.0;
static const CGFloat kHangoPartyCardCornerRadius = 20.0;
static const CGFloat kHangoPartyCardVerticalInset = 20.0;
static const CGFloat kHangoPartyTimeTopSpacing = 10.0;
static const CGFloat kHangoPartyContentTopSpacing = 15.0;
static const CGFloat kHangoPartyAddressTopSpacing = 15.0;
static const CGFloat kHangoPartyAvatarsTopSpacing = 20.0;

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
    self.layer.cornerRadius = kHangoPartyCardCornerRadius;
    self.clipsToBounds = YES;

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

    UIView *inviteBubble = [[UIView alloc] init];
    inviteBubble.backgroundColor = [HangoTheme mintBubbleColor];
    inviteBubble.layer.cornerRadius = 10;
    inviteBubble.clipsToBounds = YES;
    [self addSubview:inviteBubble];

    UILabel *invite = [[UILabel alloc] init];
    invite.text = party.invitation;
    invite.font = [HangoTheme monoFont];
    invite.textColor = [HangoTheme primaryDarkColor];
    invite.numberOfLines = 0;
    invite.lineBreakMode = NSLineBreakByWordWrapping;
    [inviteBubble addSubview:invite];

    UIImageView *pin = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"location_pin_icon"]];
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
    [HangoDesignKit populatePartyMemberAvatarsInStack:avatars party:party size:30];
    [self addSubview:avatars];

    if (showsAcceptButton && !party.isHosted) {
        [self setupAcceptButton];
        [self addSubview:self.acceptButton];
    }

    [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self).offset(kHangoPartyCardVerticalInset);
        make.left.equalTo(self).offset(kHangoPartyInviteHorizontalInset);
        make.width.height.hgx_equalTo(44);
    }];
    [name hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(avatar);
        make.left.equalTo(avatar.hgx_right).offset(10);
    }];
    [time hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(avatar.hgx_bottom).offset(kHangoPartyTimeTopSpacing);
        make.left.equalTo(avatar);
    }];
    [inviteBubble hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(time.hgx_bottom).offset(kHangoPartyContentTopSpacing);
        make.left.equalTo(self).offset(kHangoPartyInviteHorizontalInset);
        make.right.equalTo(self).offset(-kHangoPartyInviteHorizontalInset);
    }];
    [invite hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(inviteBubble).offset(kHangoPartyInviteTextInsetV);
        make.left.equalTo(inviteBubble).offset(kHangoPartyInviteTextInsetH);
        make.right.equalTo(inviteBubble).offset(-kHangoPartyInviteTextInsetH);
        make.bottom.equalTo(inviteBubble).offset(-kHangoPartyInviteTextInsetV);
    }];
    [pin hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(inviteBubble.hgx_bottom).offset(kHangoPartyAddressTopSpacing);
        make.left.equalTo(inviteBubble);
        make.width.height.hgx_equalTo(14);
    }];
    [location hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(pin);
        make.left.equalTo(pin.hgx_right).offset(4);
    }];
    [avatars hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(location.hgx_bottom).offset(kHangoPartyAvatarsTopSpacing);
        make.left.equalTo(inviteBubble);
        make.bottom.equalTo(self).offset(-kHangoPartyCardVerticalInset);
    }];
    if (self.acceptButton) {
        [self.acceptButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.right.equalTo(self).offset(-kHangoPartyInviteHorizontalInset);
            make.centerY.equalTo(avatars);
            make.width.hgx_equalTo(self.acceptButtonWidth);
            make.height.hgx_equalTo(self.acceptButtonHeight);
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
    if (![HangoGuestGuard requireLogin]) {
        return;
    }
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
