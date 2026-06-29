#import "HangoPartyCardView.h"
#import "HangoParty.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <Masonry/Masonry.h>

@implementation HangoPartyCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [HangoDesignKit applyCardShadow:self];
    }
    return self;
}

- (void)configureWithParty:(HangoParty *)party {
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    self.backgroundColor = UIColor.whiteColor;
    self.layer.cornerRadius = 18;

    UIImageView *avatar = [HangoDesignKit avatarWithName:party.hostAvatarName size:44 bordered:YES];
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
    invite.numberOfLines = 2;
    invite.backgroundColor = [HangoTheme mintBubbleColor];
    invite.layer.cornerRadius = 10;
    invite.clipsToBounds = YES;
    [self addSubview:invite];

    UIImageView *pin = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"artboard_49"]];
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
    for (NSString *avatarName in party.memberAvatarNames) {
        UIImageView *img = [HangoDesignKit avatarWithName:avatarName size:30 bordered:YES];
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

    UIButton *receive = [UIButton buttonWithType:UIButtonTypeCustom];
    [receive setTitle:@"Receive" forState:UIControlStateNormal];
    [HangoDesignKit applyReceiveButtonStyle:receive];
    [receive addTarget:self action:@selector(receiveTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:receive];

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
        make.left.equalTo(invite);
        make.bottom.equalTo(self).offset(-14);
    }];
    [receive mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self).offset(-14);
        make.centerY.equalTo(avatars);
        make.width.mas_equalTo(86);
        make.height.mas_equalTo(36);
    }];
}

- (void)receiveTapped {
    if (self.onReceive) self.onReceive();
}

@end
