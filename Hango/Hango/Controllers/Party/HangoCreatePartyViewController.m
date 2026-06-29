#import "HangoCreatePartyViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoAllPeopleViewController.h"
#import <MBProgressHUD+JDragon/MBProgressHUD+JDragon.h>
#import <Masonry/Masonry.h>

@implementation HangoCreatePartyViewController {
    UIView *_timeWrap;
    UIView *_dateWrap;
    UIView *_locationWrap;
    UITextView *_invitationView;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Create a party"];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsVerticalScrollIndicator = NO;
    [self.contentView addSubview:scroll];
    UIView *container = [[UIView alloc] init];
    [scroll addSubview:container];

    UILabel *timeLabel = [self sectionLabel:@"Party Time"];
    _timeWrap = [self fieldWrapWithPlaceholder:@"06:00 PM"];
    _dateWrap = [self fieldWrapWithPlaceholder:@"Nov 20th 2025"];

    UILabel *locLabel = [self sectionLabel:@"Party Location"];
    _locationWrap = [self fieldWrapWithPlaceholder:@"Enter the location of the party"];

    UILabel *invLabel = [self sectionLabel:@"Invitation Content"];
    _invitationView = [[UITextView alloc] init];
    _invitationView.backgroundColor = UIColor.whiteColor;
    _invitationView.layer.cornerRadius = 14;
    _invitationView.font = [HangoTheme bodyFont];
    _invitationView.textColor = [HangoTheme secondaryTextColor];
    _invitationView.text = @"Enter your invitation content";
    _invitationView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
    [HangoDesignKit applyCardShadow:_invitationView];

    UILabel *friendsLabel = [self sectionLabel:@"Invite Friends"];
    UIStackView *friends = [[UIStackView alloc] init];
    friends.axis = UILayoutConstraintAxisHorizontal;
    friends.spacing = 8;
    UIButton *add = [HangoDesignKit circleButtonWithImageName:@"artboard_4" size:48];
    [friends addArrangedSubview:add];
    for (HangoContact *c in [HangoDataStore shared].contacts) {
        UIImageView *img = [HangoDesignKit avatarWithName:c.avatarName size:48 bordered:NO];
        [friends addArrangedSubview:img];
        if (friends.arrangedSubviews.count > 5) break;
    }

    UIButton *post = [HangoDesignKit pillButtonWithTitle:@"Post Party Invites" style:HangoPillButtonStyleDark];
    [post addTarget:self action:@selector(postParty) forControlEvents:UIControlEventTouchUpInside];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
    }];
    [scroll mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(16);
        make.left.right.bottom.equalTo(self.contentView);
    }];
    [container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.width.equalTo(scroll);
    }];

    NSArray *views = @[timeLabel, _timeWrap, _dateWrap, locLabel, _locationWrap, invLabel, _invitationView, friendsLabel, friends, post];
    UIView *prev = nil;
    for (UIView *v in views) {
        [container addSubview:v];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            if (v == _dateWrap) {
                make.top.equalTo(_timeWrap);
                make.left.equalTo(_timeWrap.mas_right).offset(12);
                make.right.equalTo(container).offset(-20);
                make.width.equalTo(_timeWrap);
                make.height.mas_equalTo(48);
            } else if (v == _timeWrap) {
                make.top.equalTo(timeLabel.mas_bottom).offset(8);
                make.left.equalTo(container).offset(20);
                make.right.equalTo(container.mas_centerX).offset(-6);
                make.height.mas_equalTo(48);
            } else {
                make.left.equalTo(container).offset(20);
                make.right.equalTo(container).offset(-20);
                if (prev) {
                    CGFloat gap = (v == post) ? 32 : 16;
                    if (v == _timeWrap) gap = 0;
                    make.top.equalTo(prev.mas_bottom).offset(gap);
                } else {
                    make.top.equalTo(container);
                }
                if (v == _locationWrap) make.height.mas_equalTo(48);
                else if (v == _invitationView) make.height.mas_equalTo(100);
                else if (v == post) {
                    make.height.mas_equalTo(56);
                    make.bottom.equalTo(container).offset(-40);
                } else if (v == friends) make.height.mas_equalTo(48);
            }
        }];
        if (v != _dateWrap) prev = v;
    }
}

- (UILabel *)sectionLabel:(NSString *)text {
    UILabel *l = [[UILabel alloc] init];
    l.text = text;
    l.font = [UIFont boldSystemFontOfSize:16];
    l.textColor = [HangoTheme primaryDarkColor];
    return l;
}

- (UIView *)fieldWrapWithPlaceholder:(NSString *)placeholder {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.whiteColor;
    wrap.layer.cornerRadius = 14;
    [HangoDesignKit applyCardShadow:wrap];

    UITextField *f = [[UITextField alloc] init];
    f.placeholder = placeholder;
    f.font = [HangoTheme bodyFont];
    f.textColor = [HangoTheme primaryDarkColor];
    f.tag = 9001;
    [wrap addSubview:f];
    [f mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(wrap).insets(UIEdgeInsetsMake(0, 14, 0, 14));
    }];
    return wrap;
}

- (void)postParty {
    UITextField *time = [_timeWrap viewWithTag:9001];
    UITextField *date = [_dateWrap viewWithTag:9001];
    UITextField *location = [_locationWrap viewWithTag:9001];
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [[HangoDataStore shared] createPartyWithTime:time.text ?: @"06:00 PM"
                                                       date:date.text ?: @"Nov 20th 2025"
                                                   location:location.text ?: @"My place"
                                                 invitation:self->_invitationView.text ?: @"Join my party!"
                                                  friendIds:@[]];
    } completion:^(__unused id party, __unused NSError *error) {
        [MBProgressHUD showSuccessMessage:@"Party posted"];
        HangoAllPeopleViewController *vc = [[HangoAllPeopleViewController alloc] init];
        vc.party = [HangoDataStore shared].hostedParties.firstObject;
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

@end
