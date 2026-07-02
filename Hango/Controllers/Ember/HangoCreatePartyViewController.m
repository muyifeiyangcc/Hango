#import "HangoCreatePartyViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoInvitePartyContactsViewController.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

static NSString * const kInvitationPlaceholder = @"Enter your invitation content";
static const NSInteger kPickerOverlayTag = 9902;
static const NSInteger kPickerValueLabelTag = 9001;

typedef NS_ENUM(NSInteger, HangoPartyPickerKind) {
    HangoPartyPickerKindTime = 0,
    HangoPartyPickerKindDate
};

@interface HangoCreatePartyViewController () <UITextViewDelegate, UIGestureRecognizerDelegate>
@end

@implementation HangoCreatePartyViewController {
    UIView *_timeWrap;
    UIView *_dateWrap;
    UIView *_locationWrap;
    UITextView *_invitationView;
    UIScrollView *_inviteesScroll;
    UIStackView *_inviteesStack;
    UIButton *_addInviteeButton;
    NSMutableArray<HangoContact *> *_invitedContacts;
    BOOL _invitationIsPlaceholder;
    NSDate *_partyDateTime;
    HangoPartyPickerKind _activePickerKind;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _invitedContacts = [NSMutableArray array];
    _partyDateTime = [self normalizedFuturePartyDateTimeFromDate:[NSDate date]];
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Create a party"];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.showsVerticalScrollIndicator = NO;
    scroll.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.contentView addSubview:scroll];
    UIView *container = [[UIView alloc] init];
    [scroll addSubview:container];

    UILabel *timeLabel = [self sectionLabel:@"Party Time"];
    _timeWrap = [self labeledPickerFieldWithPrefix:@"Time:" value:[self formattedTimeText] compact:NO];
    [_timeWrap addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTimePicker)]];

    _dateWrap = [self labeledPickerFieldWithPrefix:@"Date:" value:[self formattedDateText] compact:YES];
    [_dateWrap addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showDatePicker)]];

    UILabel *locLabel = [self sectionLabel:@"Party Location"];
    _locationWrap = [self plainFieldWithPlaceholder:@"Enter the location of the party"];

    UILabel *invLabel = [self sectionLabel:@"Invitation Content"];
    _invitationView = [[UITextView alloc] init];
    _invitationView.backgroundColor = UIColor.whiteColor;
    _invitationView.layer.cornerRadius = 14;
    _invitationView.font = [HangoTheme bodyFont];
    _invitationView.textColor = [HangoTheme secondaryTextColor];
    _invitationView.text = kInvitationPlaceholder;
    _invitationView.delegate = self;
    _invitationIsPlaceholder = YES;
    _invitationView.textContainerInset = UIEdgeInsetsMake(12, 10, 12, 10);
    [HangoDesignKit applyCardShadow:_invitationView];

    UILabel *inviteesLabel = [self sectionLabel:@"Invite Contacts"];
    _inviteesScroll = [[UIScrollView alloc] init];
    _inviteesScroll.showsHorizontalScrollIndicator = NO;
    _inviteesStack = [[UIStackView alloc] init];
    _inviteesStack.axis = UILayoutConstraintAxisHorizontal;
    _inviteesStack.spacing = 10;
    _inviteesStack.alignment = UIStackViewAlignmentCenter;
    [_inviteesScroll addSubview:_inviteesStack];
    [_inviteesStack hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(_inviteesScroll);
        make.height.equalTo(_inviteesScroll);
    }];

    _addInviteeButton = [self inviteAddButton];
    [_addInviteeButton addTarget:self action:@selector(addInviteesTapped) forControlEvents:UIControlEventTouchUpInside];
    [_inviteesStack addArrangedSubview:_addInviteeButton];

    UIButton *sendButton = [HangoDesignKit pillButtonWithTitle:@"Send Party Invites" style:HangoPillButtonStyleDark];
    sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [sendButton addTarget:self action:@selector(sendPartyInvites) forControlEvents:UIControlEventTouchUpInside];

    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
        make.left.greaterThanOrEqualTo(self.contentView).offset(56);
        make.right.lessThanOrEqualTo(self.contentView).offset(-20);
    }];
    [scroll hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(title.hgx_bottom).offset(16);
        make.left.right.bottom.equalTo(self.contentView);
    }];
    [container hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.width.equalTo(scroll);
    }];

    NSArray *views = @[timeLabel, _timeWrap, _dateWrap, locLabel, _locationWrap, invLabel, _invitationView, inviteesLabel, _inviteesScroll, sendButton];
    UIView *prev = nil;
    for (UIView *v in views) {
        [container addSubview:v];
        [v hgx_makeConstraints:^(HGXConstraintMaker *make) {
            if (v == _dateWrap) {
                make.top.equalTo(_timeWrap);
                make.left.equalTo(_timeWrap.hgx_right).offset(12);
                make.right.equalTo(container).offset(-20);
                make.width.equalTo(_timeWrap);
                make.height.hgx_equalTo(48);
            } else if (v == _timeWrap) {
                make.top.equalTo(timeLabel.hgx_bottom).offset(8);
                make.left.equalTo(container).offset(20);
                make.right.equalTo(container.hgx_centerX).offset(-6);
                make.height.hgx_equalTo(48);
            } else {
                make.left.equalTo(container).offset(20);
                make.right.equalTo(container).offset(-20);
                if (prev) {
                    CGFloat gap = 16;
                    if (v == sendButton) {
                        gap = 32;
                    } else if (v == _timeWrap) {
                        gap = 0;
                    } else if (v == inviteesLabel) {
                        gap = 8;
                    }
                    make.top.equalTo(prev.hgx_bottom).offset(gap);
                } else {
                    make.top.equalTo(container);
                }
                if (v == _locationWrap) {
                    make.height.hgx_equalTo(48);
                } else if (v == _invitationView) {
                    make.height.hgx_equalTo(120);
                } else if (v == sendButton) {
                    make.height.hgx_equalTo(56);
                    make.bottom.equalTo(container).offset(-40);
                } else if (v == _inviteesScroll) {
                    make.height.hgx_equalTo(56);
                }
            }
        }];
        if (v != _dateWrap) {
            prev = v;
        }
    }
}

#pragma mark - UI helpers

- (UILabel *)sectionLabel:(NSString *)text {
    UILabel *label = [[UILabel alloc] init];
    label.text = text;
    label.font = [UIFont boldSystemFontOfSize:17];
    label.textColor = [HangoTheme primaryDarkColor];
    return label;
}

- (NSString *)formattedTimeText {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"hh:mma";
    return [formatter stringFromDate:self.partyDateTime];
}

- (NSString *)formattedDateText {
    return [self dateTextFromDate:self.partyDateTime];
}

- (NSDate *)partyDateTime {
    return _partyDateTime ?: [NSDate date];
}

- (BOOL)isPartyDateToday {
    return [NSCalendar.currentCalendar isDate:self.partyDateTime inSameDayAsDate:[NSDate date]];
}

- (NSDate *)normalizedFuturePartyDateTimeFromDate:(NSDate *)date {
    NSDate *now = [NSDate date];
    if ([date compare:now] == NSOrderedDescending) {
        return date;
    }

    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *components = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute)
                                               fromDate:now];
    components.minute += 1;
    components.second = 0;
    components.nanosecond = 0;
    return [calendar dateFromComponents:components] ?: now;
}

- (NSDate *)timeOnlyDateFromFullDate:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute)
                                               fromDate:date];
    components.year = 2000;
    components.month = 1;
    components.day = 1;
    return [calendar dateFromComponents:components] ?: date;
}

- (NSString *)dateTextFromDate:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *components = [calendar components:NSCalendarUnitDay fromDate:date];
    NSInteger day = components.day;
    NSString *suffix = @"th";
    if (day % 100 < 11 || day % 100 > 13) {
        switch (day % 10) {
            case 1: suffix = @"st"; break;
            case 2: suffix = @"nd"; break;
            case 3: suffix = @"rd"; break;
            default: break;
        }
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    formatter.dateFormat = @"MMM";
    NSString *month = [formatter stringFromDate:date];
    formatter.dateFormat = @"yyyy";
    NSString *year = [formatter stringFromDate:date];
    return [NSString stringWithFormat:@"%@ %ld%@ %@", month, (long)day, suffix, year];
}

- (UIView *)labeledPickerFieldWithPrefix:(NSString *)prefix value:(NSString *)value compact:(BOOL)compact {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.whiteColor;
    wrap.layer.cornerRadius = 14;
    wrap.userInteractionEnabled = YES;
    [HangoDesignKit applyCardShadow:wrap];

    UILabel *prefixLabel = [[UILabel alloc] init];
    prefixLabel.text = prefix;
    prefixLabel.font = [UIFont boldSystemFontOfSize:compact ? 13 : 15];
    prefixLabel.textColor = [HangoTheme primaryDarkColor];
    [wrap addSubview:prefixLabel];

    UILabel *valueLabel = [[UILabel alloc] init];
    valueLabel.text = value;
    valueLabel.font = compact
        ? [UIFont monospacedSystemFontOfSize:11 weight:UIFontWeightMedium]
        : [HangoTheme monoFont];
    valueLabel.textColor = [HangoTheme primaryDarkColor];
    valueLabel.tag = kPickerValueLabelTag;
    valueLabel.numberOfLines = 1;
    if (compact) {
        valueLabel.adjustsFontSizeToFitWidth = YES;
        valueLabel.minimumScaleFactor = 0.7;
        valueLabel.lineBreakMode = NSLineBreakByClipping;
    }
    [wrap addSubview:valueLabel];

    [prefixLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(wrap).offset(compact ? 8 : 12);
        make.centerY.equalTo(wrap);
    }];
    [prefixLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [prefixLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [valueLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(prefixLabel.hgx_right).offset(compact ? 2 : 4);
        make.right.equalTo(wrap).offset(compact ? -6 : -10);
        make.centerY.equalTo(wrap);
    }];
    [valueLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    return wrap;
}

- (void)updatePickerLabels {
    UILabel *timeLabel = [_timeWrap viewWithTag:kPickerValueLabelTag];
    UILabel *dateLabel = [_dateWrap viewWithTag:kPickerValueLabelTag];
    timeLabel.text = [self formattedTimeText];
    dateLabel.text = [self formattedDateText];
}

- (void)mergeTimeFromDate:(NSDate *)timeDate {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                                   fromDate:self.partyDateTime];
    NSDateComponents *timeComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute)
                                                     fromDate:timeDate];
    dateComponents.hour = timeComponents.hour;
    dateComponents.minute = timeComponents.minute;
    _partyDateTime = [calendar dateFromComponents:dateComponents] ?: timeDate;
    _partyDateTime = [self normalizedFuturePartyDateTimeFromDate:_partyDateTime];
}

- (void)mergeDateFromDate:(NSDate *)date {
    NSCalendar *calendar = NSCalendar.currentCalendar;
    NSDateComponents *timeComponents = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute)
                                                     fromDate:self.partyDateTime];
    NSDateComponents *dateComponents = [calendar components:(NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)
                                                   fromDate:date];
    dateComponents.hour = timeComponents.hour;
    dateComponents.minute = timeComponents.minute;
    _partyDateTime = [calendar dateFromComponents:dateComponents] ?: date;
    _partyDateTime = [self normalizedFuturePartyDateTimeFromDate:_partyDateTime];
}

- (NSDate *)timeOnlyDateFromPartyDateTime {
    return [self timeOnlyDateFromFullDate:self.partyDateTime];
}

#pragma mark - Picker

- (void)showTimePicker {
    [self showPickerWithKind:HangoPartyPickerKindTime title:@"Select Time"];
}

- (void)showDatePicker {
    [self showPickerWithKind:HangoPartyPickerKindDate title:@"Select Date"];
}

- (void)showPickerWithKind:(HangoPartyPickerKind)kind title:(NSString *)title {
    if ([self.view viewWithTag:kPickerOverlayTag]) {
        return;
    }

    _activePickerKind = kind;

    UIView *overlay = [[UIView alloc] init];
    overlay.tag = kPickerOverlayTag;
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPicker)];
    dismissTap.delegate = self;
    [overlay addGestureRecognizer:dismissTap];
    [self.view addSubview:overlay];

    UIView *sheet = [HangoDesignKit bottomSheetWithTitle:title];
    sheet.tag = 9903;
    [overlay addSubview:sheet];

    UIDatePicker *picker = [[UIDatePicker alloc] init];
    picker.datePickerMode = (kind == HangoPartyPickerKindTime) ? UIDatePickerModeTime : UIDatePickerModeDate;
    picker.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    if (@available(iOS 13.4, *)) {
        picker.preferredDatePickerStyle = UIDatePickerStyleWheels;
    }

    NSDate *now = [NSDate date];
    NSCalendar *calendar = NSCalendar.currentCalendar;
    if (kind == HangoPartyPickerKindDate) {
        picker.minimumDate = [calendar startOfDayForDate:now];
        picker.date = self.partyDateTime;
    } else {
        NSDate *partyTime = [self timeOnlyDateFromPartyDateTime];
        if ([self isPartyDateToday]) {
            NSDate *minTime = [self timeOnlyDateFromFullDate:now];
            picker.minimumDate = minTime;
            picker.date = ([partyTime compare:minTime] == NSOrderedAscending) ? minTime : partyTime;
        } else {
            picker.minimumDate = nil;
            picker.date = partyTime;
        }
    }
    [sheet addSubview:picker];

    UIButton *cancelButton = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleOutline];
    cancelButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    cancelButton.layer.cornerRadius = 22;
    [cancelButton addTarget:self action:@selector(dismissPicker) forControlEvents:UIControlEventTouchUpInside];

    UIButton *doneButton = [HangoDesignKit pillButtonWithTitle:@"Done" style:HangoPillButtonStyleDark];
    doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    doneButton.layer.cornerRadius = 22;
    [doneButton addTarget:self action:@selector(confirmPicker) forControlEvents:UIControlEventTouchUpInside];

    [sheet addSubview:cancelButton];
    [sheet addSubview:doneButton];

    [overlay hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [sheet hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(overlay);
    }];
    [picker hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(sheet).offset(56);
        make.left.right.equalTo(sheet);
        make.height.hgx_equalTo(216);
    }];
    [cancelButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(picker.hgx_bottom).offset(8);
        make.left.equalTo(sheet).offset(24);
        make.height.hgx_equalTo(44);
        make.bottom.equalTo(overlay.hgx_safeAreaLayoutGuideBottom).offset(-20);
    }];
    [doneButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(cancelButton);
        make.left.equalTo(cancelButton.hgx_right).offset(12);
        make.right.equalTo(sheet).offset(-24);
        make.width.equalTo(cancelButton);
        make.height.equalTo(cancelButton);
    }];
}

- (void)confirmPicker {
    UIView *overlay = [self.view viewWithTag:kPickerOverlayTag];
    UIDatePicker *picker = nil;
    for (UIView *subview in overlay.subviews) {
        if (subview.tag != 9903) {
            continue;
        }
        for (UIView *child in subview.subviews) {
            if ([child isKindOfClass:UIDatePicker.class]) {
                picker = (UIDatePicker *)child;
                break;
            }
        }
    }
    if (!picker) {
        [self dismissPicker];
        return;
    }

    if (_activePickerKind == HangoPartyPickerKindTime) {
        [self mergeTimeFromDate:picker.date];
    } else {
        [self mergeDateFromDate:picker.date];
    }
    [self updatePickerLabels];
    [self dismissPicker];
}

- (void)dismissPicker {
    [[self.view viewWithTag:kPickerOverlayTag] removeFromSuperview];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    UIView *sheet = [self.view viewWithTag:9903];
    if (sheet && [touch.view isDescendantOfView:sheet]) {
        return NO;
    }
    return YES;
}

- (UIView *)plainFieldWithPlaceholder:(NSString *)placeholder {
    UIView *wrap = [[UIView alloc] init];
    wrap.backgroundColor = UIColor.whiteColor;
    wrap.layer.cornerRadius = 14;
    [HangoDesignKit applyCardShadow:wrap];

    UITextField *field = [[UITextField alloc] init];
    field.placeholder = placeholder;
    field.font = [HangoTheme bodyFont];
    field.textColor = [HangoTheme primaryDarkColor];
    field.tag = 9001;
    [wrap addSubview:field];
    [field hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(wrap).insets(UIEdgeInsetsMake(0, 14, 0, 14));
    }];
    return wrap;
}

- (UIButton *)inviteAddButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [HangoTheme primaryDarkColor];
    button.layer.cornerRadius = 28;
    button.clipsToBounds = YES;

    UIImage *plusIcon = [UIImage systemImageNamed:@"plus"];
    if (plusIcon) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightBold];
        plusIcon = [plusIcon imageByApplyingSymbolConfiguration:config];
        plusIcon = [plusIcon imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal];
        [button setImage:plusIcon forState:UIControlStateNormal];
    } else {
        [button setTitle:@"+" forState:UIControlStateNormal];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    }
    [button hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.width.height.hgx_equalTo(56);
    }];
    return button;
}

- (void)reloadInviteesRow {
    for (UIView *view in _inviteesStack.arrangedSubviews.copy) {
        if (view != _addInviteeButton) {
            [_inviteesStack removeArrangedSubview:view];
            [view removeFromSuperview];
        }
    }

    for (HangoContact *contact in _invitedContacts) {
        UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
        avatarButton.accessibilityIdentifier = contact.contactId;
        UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:56 bordered:NO];
        avatar.userInteractionEnabled = NO;
        [avatarButton addSubview:avatar];
        [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.edges.equalTo(avatarButton);
            make.width.height.hgx_equalTo(56);
        }];
        [avatarButton addTarget:self action:@selector(removeInviteeTapped:) forControlEvents:UIControlEventTouchUpInside];
        [_inviteesStack addArrangedSubview:avatarButton];
    }

    [_inviteesStack layoutIfNeeded];
    _inviteesScroll.contentSize = CGSizeMake(_inviteesStack.bounds.size.width, 56);
}

#pragma mark - Actions

- (void)addInviteesTapped {
    if (![self requireLoginForAction]) {
        return;
    }
    HangoInvitePartyContactsViewController *picker = [[HangoInvitePartyContactsViewController alloc] init];
    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    for (HangoContact *contact in _invitedContacts) {
        [ids addObject:contact.contactId];
    }
    picker.selectedContactIds = ids.copy;
    __weak typeof(self) weakSelf = self;
    picker.onComplete = ^(NSArray<HangoContact *> *selectedContacts) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf->_invitedContacts removeAllObjects];
        [strongSelf->_invitedContacts addObjectsFromArray:selectedContacts];
        [strongSelf reloadInviteesRow];
    };
    [self.navigationController pushViewController:picker animated:YES];
}

- (void)removeInviteeTapped:(UIButton *)sender {
    NSString *contactId = sender.accessibilityIdentifier;
    if (contactId.length == 0) {
        return;
    }
    NSUInteger index = [_invitedContacts indexOfObjectPassingTest:^BOOL(HangoContact *obj, NSUInteger idx, BOOL *stop) {
        return [obj.contactId isEqualToString:contactId];
    }];
    if (index != NSNotFound) {
        [_invitedContacts removeObjectAtIndex:index];
        [self reloadInviteesRow];
    }
}

- (NSString *)invitationText {
    if (_invitationIsPlaceholder || _invitationView.text.length == 0) {
        return @"";
    }
    return _invitationView.text;
}

- (void)sendPartyInvites {
    if (![self requireLoginForAction]) {
        return;
    }
    if ([self.partyDateTime compare:[NSDate date]] != NSOrderedDescending) {
        [self showAlertWithText:@"Please select a future date and time."];
        return;
    }

    UITextField *location = [_locationWrap viewWithTag:9001];
    NSString *locationText = [location.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (locationText.length == 0) {
        [self showAlertWithText:@"Please enter the party location."];
        return;
    }

    NSString *invitationText = [[self invitationText] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (invitationText.length == 0) {
        [self showAlertWithText:@"Please enter your invitation content."];
        return;
    }

    NSMutableArray<NSString *> *inviteeIds = [NSMutableArray array];
    for (HangoContact *contact in _invitedContacts) {
        [inviteeIds addObject:contact.contactId];
    }

    NSString *timeText = [self formattedTimeText];
    NSString *dateText = [self formattedDateText];

    __weak typeof(self) weakSelf = self;
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES operation:^id {
        return [[HangoDataStore shared] createPartyWithTime:timeText
                                                       date:dateText
                                                   location:locationText
                                                 invitation:invitationText
                                                  inviteeIds:inviteeIds.copy];
    } completion:^(__unused id party, __unused NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf.navigationController popViewControllerAnimated:YES];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [MBProgressHUD showSuccessMessage:@"Created successfully"];
        });
    }];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (_invitationIsPlaceholder) {
        textView.text = @"";
        textView.textColor = [HangoTheme primaryDarkColor];
        _invitationIsPlaceholder = NO;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        textView.text = kInvitationPlaceholder;
        textView.textColor = [HangoTheme secondaryTextColor];
        _invitationIsPlaceholder = YES;
    }
}

- (void)showAlertWithText:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
