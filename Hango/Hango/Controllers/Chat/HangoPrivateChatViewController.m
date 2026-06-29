#import "HangoPrivateChatViewController.h"
#import "HangoContact.h"
#import "HangoUser.h"
#import "HangoChatMessage.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoSessionManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoChatInputBar.h"
#import "HangoReportDetailViewController.h"
#import <MBProgressHUD+JDragon/MBProgressHUD+JDragon.h>
#import <Masonry/Masonry.h>
#import <YBImageBrowser/YBImageBrowser.h>

@implementation HangoPrivateChatViewController {
    UITableView *_tableView;
    HangoChatInputBar *_inputBar;
    NSArray<HangoChatMessage *> *_messages;
    MASConstraint *_inputBarBottomConstraint;
    MASConstraint *_inputBarHeightConstraint;
}

static const CGFloat HangoPrivateChatAvatarSize = 50.0;

- (void)setupUI {
    self.showsBackButton = YES;
    if (!self.contact) {
        self.contact = [HangoDataStore shared].contacts.firstObject;
    }

    UIImageView *avatar = [HangoDesignKit avatarWithName:self.contact.avatarName size:HangoPrivateChatAvatarSize bordered:NO];
    [self.contentView addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = self.contact.name;
    name.font = [UIFont boldSystemFontOfSize:16];
    name.textColor = [HangoTheme primaryDarkColor];
    [self.contentView addSubview:name];

    UIButton *more = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *moreIcon = [UIImage systemImageNamed:@"ellipsis"];
    if (moreIcon) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:18 weight:UIImageSymbolWeightBold];
        moreIcon = [moreIcon imageByApplyingSymbolConfiguration:config];
        [more setImage:[moreIcon imageWithTintColor:[HangoTheme primaryDarkColor] renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        [more setTitle:@"..." forState:UIControlStateNormal];
        [more setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    }
    [more addTarget:self action:@selector(openMoreMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:more];

    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.estimatedRowHeight = 112;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    _inputBar = [[HangoChatInputBar alloc] init];
    __weak typeof(self) weakSelf = self;
    _inputBar.onSend = ^(NSString *text) {
        [weakSelf appendOutgoingTextMessage:text];
    };
    _inputBar.onVoiceSend = ^(NSInteger duration) {
        [weakSelf appendOutgoingAudioMessageWithDuration:duration];
    };
    _inputBar.onModeChanged = ^(BOOL voiceMode) {
        [weakSelf updateInputBarForVoiceMode:voiceMode];
    };
    [self.contentView addSubview:_inputBar];

    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(4);
        make.left.equalTo(self.contentView).offset(48);
        make.width.height.mas_equalTo(HangoPrivateChatAvatarSize);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(avatar);
        make.left.equalTo(avatar.mas_right).offset(8);
        make.right.lessThanOrEqualTo(more.mas_left).offset(-8);
    }];
    [more mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(avatar);
        make.right.equalTo(self.contentView).offset(-16);
        make.width.height.mas_equalTo(36);
    }];
    [_inputBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView);
        self->_inputBarBottomConstraint = make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        self->_inputBarHeightConstraint = make.height.mas_equalTo(56);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatar.mas_bottom).offset(10);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(_inputBar.mas_top);
    }];

    [self loadMessages];
    [self registerKeyboardNotifications];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)appendOutgoingTextMessage:(NSString *)text {
    if (text.length == 0) {
        return;
    }

    HangoUser *user = [HangoSessionManager shared].currentUser ?: [HangoDataStore shared].currentUser;
    HangoChatMessage *msg = [[HangoChatMessage alloc] init];
    msg.messageId = [[NSUUID UUID] UUIDString];
    msg.senderName = user.name;
    msg.senderAvatarName = user.avatarName;
    msg.content = text;
    msg.timeText = @"Now";
    msg.messageType = HangoChatMessageTypeText;
    msg.isOutgoing = YES;

    [[HangoDataStore shared] appendMessage:msg toConversationId:self.contact.contactId];
    NSMutableArray<HangoChatMessage *> *updated = _messages ? _messages.mutableCopy : [NSMutableArray array];
    [updated addObject:msg];
    _messages = updated.copy;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_messages.count - 1 inSection:0];
    [_tableView performBatchUpdates:^{
        [self->_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestMessageAnimated:YES];
    }];
}

- (void)appendOutgoingAudioMessageWithDuration:(NSInteger)duration {
    HangoUser *user = [HangoSessionManager shared].currentUser ?: [HangoDataStore shared].currentUser;
    HangoChatMessage *msg = [[HangoChatMessage alloc] init];
    msg.messageId = [[NSUUID UUID] UUIDString];
    msg.senderName = user.name;
    msg.senderAvatarName = user.avatarName;
    msg.content = [NSString stringWithFormat:@"%lds", (long)MAX(duration, 1)];
    msg.timeText = @"Now";
    msg.messageType = HangoChatMessageTypeAudio;
    msg.isOutgoing = YES;
    msg.audioDuration = MAX(duration, 1);

    [[HangoDataStore shared] appendMessage:msg toConversationId:self.contact.contactId];
    NSMutableArray<HangoChatMessage *> *updated = _messages ? _messages.mutableCopy : [NSMutableArray array];
    [updated addObject:msg];
    _messages = updated.copy;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_messages.count - 1 inSection:0];
    [_tableView performBatchUpdates:^{
        [self->_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestMessageAnimated:YES];
    }];
}

- (void)updateInputBarForVoiceMode:(BOOL)voiceMode {
    [_inputBarHeightConstraint setOffset:voiceMode ? 132 : 56];
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view layoutIfNeeded];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestMessageAnimated:NO];
    }];
}

- (void)scrollToLatestMessageAnimated:(BOOL)animated {
    if (_messages.count == 0) {
        return;
    }
    NSIndexPath *last = [NSIndexPath indexPathForRow:_messages.count - 1 inSection:0];
    [_tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)registerKeyboardNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary *info = notification.userInfo;
    CGRect keyboardFrame = [info[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInView = [self.view convertRect:keyboardFrame fromView:nil];
    CGFloat overlap = MAX(0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(keyboardFrameInView));
    CGFloat safeBottom = self.view.safeAreaInsets.bottom;
    [self updateInputBarBottomOffset:-MAX(0, overlap - safeBottom) notificationInfo:info];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self updateInputBarBottomOffset:0 notificationInfo:notification.userInfo];
}

- (void)updateInputBarBottomOffset:(CGFloat)offset notificationInfo:(NSDictionary *)info {
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    [_inputBarBottomConstraint setOffset:offset];
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        [self.view layoutIfNeeded];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestMessageAnimated:NO];
    }];
}

- (void)loadMessages {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [[HangoDataStore shared] messagesForConversationId:self.contact.contactId];
    } completion:^(id result, NSError *error) {
        self->_messages = result;
        [self->_tableView reloadData];
        [self scrollToLatestMessageAnimated:NO];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"c"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
    }
    cell.backgroundColor = UIColor.clearColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    for (UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }

    HangoChatMessage *msg = _messages[indexPath.row];
    BOOL outgoing = msg.isOutgoing;

    UIImageView *avatar = [HangoDesignKit avatarWithName:msg.senderAvatarName size:HangoPrivateChatAvatarSize bordered:NO];
    [cell.contentView addSubview:avatar];

    UILabel *sender = [[UILabel alloc] init];
    sender.text = msg.senderName;
    sender.font = [HangoTheme captionFont];
    sender.textColor = [HangoTheme secondaryTextColor];
    [cell.contentView addSubview:sender];

    UILabel *time = [[UILabel alloc] init];
    time.text = msg.timeText;
    time.font = [HangoTheme captionFont];
    time.textColor = [HangoTheme secondaryTextColor];
    [cell.contentView addSubview:time];

    if (msg.messageType == HangoChatMessageTypeImage) {
        UIImageView *img = [[UIImageView alloc] initWithImage:[HangoTheme avatarImageNamed:msg.content]];
        img.layer.cornerRadius = 12;
        img.clipsToBounds = YES;
        img.layer.borderWidth = 4;
        img.layer.borderColor = UIColor.whiteColor.CGColor;
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.userInteractionEnabled = YES;
        img.tag = indexPath.row;
        [img addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageMessageTapped:)]];
        [cell.contentView addSubview:img];

        if (outgoing) {
            [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(cell.contentView).offset(8);
                make.right.equalTo(cell.contentView).offset(-16);
                make.width.height.mas_equalTo(HangoPrivateChatAvatarSize);
            }];
            [sender mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(avatar.mas_bottom).offset(2);
                make.centerX.equalTo(avatar);
            }];
            [img mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(avatar);
                make.right.equalTo(avatar.mas_left).offset(-8);
                make.width.height.mas_equalTo(120);
            }];
            [time mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(img.mas_bottom).offset(4);
                make.right.equalTo(img);
                make.bottom.equalTo(cell.contentView).offset(-8);
            }];
        } else {
            [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(cell.contentView).offset(8);
                make.left.equalTo(cell.contentView).offset(16);
                make.width.height.mas_equalTo(HangoPrivateChatAvatarSize);
            }];
            [sender mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(avatar.mas_bottom).offset(2);
                make.centerX.equalTo(avatar);
            }];
            [img mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(avatar);
                make.left.equalTo(avatar.mas_right).offset(8);
                make.width.height.mas_equalTo(120);
            }];
            [time mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(img.mas_bottom).offset(4);
                make.left.equalTo(img);
                make.bottom.equalTo(cell.contentView).offset(-8);
            }];
        }
        return cell;
    }

    UIView *bubble = [[UIView alloc] init];
    bubble.layer.cornerRadius = 14;
    bubble.backgroundColor = msg.messageType == HangoChatMessageTypeAudio ? [HangoTheme primaryDarkColor] : UIColor.whiteColor;
    [cell.contentView addSubview:bubble];

    if (msg.messageType == HangoChatMessageTypeAudio) {
        UIImageView *voiceIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"chat_voice_icon_white"]];
        voiceIcon.contentMode = UIViewContentModeScaleAspectFit;
        [bubble addSubview:voiceIcon];

        UILabel *duration = [[UILabel alloc] init];
        duration.text = msg.content;
        duration.font = [HangoTheme monoFont];
        duration.textColor = UIColor.whiteColor;
        [bubble addSubview:duration];

        [voiceIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(bubble).offset(12);
            make.centerY.equalTo(bubble);
            make.width.height.mas_equalTo(18);
        }];
        [duration mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(voiceIcon.mas_right).offset(8);
            make.right.equalTo(bubble).offset(-12);
            make.centerY.equalTo(bubble);
        }];
    } else {
        UILabel *text = [[UILabel alloc] init];
        text.text = msg.content;
        text.font = [HangoTheme monoFont];
        text.textColor = [HangoTheme primaryDarkColor];
        text.numberOfLines = 0;
        [bubble addSubview:text];
        [text mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(bubble).insets(UIEdgeInsetsMake(10, 12, 10, 12));
        }];
    }

    if (outgoing) {
        [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cell.contentView).offset(8);
            make.right.equalTo(cell.contentView).offset(-16);
            make.width.height.mas_equalTo(HangoPrivateChatAvatarSize);
        }];
        [sender mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar.mas_bottom).offset(2);
            make.centerX.equalTo(avatar);
        }];
        [bubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar);
            make.right.equalTo(avatar.mas_left).offset(-8);
            make.width.lessThanOrEqualTo(cell.contentView).multipliedBy(0.62);
            make.height.mas_greaterThanOrEqualTo(40);
        }];
        [time mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bubble.mas_bottom).offset(4);
            make.right.equalTo(bubble);
            make.bottom.equalTo(cell.contentView).offset(-8);
        }];
    } else {
        [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cell.contentView).offset(8);
            make.left.equalTo(cell.contentView).offset(16);
            make.width.height.mas_equalTo(HangoPrivateChatAvatarSize);
        }];
        [sender mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar.mas_bottom).offset(2);
            make.centerX.equalTo(avatar);
        }];
        [bubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar);
            make.left.equalTo(avatar.mas_right).offset(8);
            make.width.lessThanOrEqualTo(cell.contentView).multipliedBy(0.62);
            make.height.mas_greaterThanOrEqualTo(40);
        }];
        [time mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bubble.mas_bottom).offset(4);
            make.left.equalTo(bubble);
            make.bottom.equalTo(cell.contentView).offset(-8);
        }];
    }

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    HangoChatMessage *msg = _messages[indexPath.row];
    return msg.messageType == HangoChatMessageTypeImage ? 184 : 112;
}

- (void)imageMessageTapped:(UITapGestureRecognizer *)recognizer {
    UIImageView *imageView = (UIImageView *)recognizer.view;
    if (![imageView isKindOfClass:UIImageView.class] || imageView.tag < 0 || imageView.tag >= _messages.count) {
        return;
    }

    HangoChatMessage *msg = _messages[imageView.tag];
    UIImage *image = [HangoTheme avatarImageNamed:msg.content];
    if (!image) {
        return;
    }

    YBIBImageData *data = [YBIBImageData new];
    data.image = ^UIImage * _Nullable{
        return image;
    };
    data.projectiveView = imageView;

    YBImageBrowser *browser = [YBImageBrowser new];
    browser.dataSourceArray = @[data];
    browser.currentPage = 0;
    [browser show];
}

- (UIButton *)actionSheetButtonWithTitle:(NSString *)title backgroundColor:(UIColor *)backgroundColor titleColor:(UIColor *)titleColor height:(CGFloat)height {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:title forState:UIControlStateNormal];
    [button setTitleColor:titleColor forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightSemibold];
    button.backgroundColor = backgroundColor;
    button.layer.cornerRadius = height / 2.0;
    button.clipsToBounds = YES;
    return button;
}

- (void)openMoreMenu {
    if ([self.view viewWithTag:9901]) {
        return;
    }

    static const CGFloat kActionButtonHeight = 52.0;
    static const CGFloat kWideButtonRatio = 0.78;
    static const CGFloat kCancelButtonRatio = 0.56;

    UIView *overlay = [[UIView alloc] init];
    overlay.tag = 9901;
    overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15];
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMoreMenu)];
    [overlay addGestureRecognizer:dismissTap];
    [self.view addSubview:overlay];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1.0 alpha:1.0];
    card.layer.cornerRadius = 28;
    card.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [overlay addSubview:card];

    UIButton *reportBtn = [self actionSheetButtonWithTitle:@"Report"
                                           backgroundColor:[UIColor colorWithRed:0.98 green:0.55 blue:0.18 alpha:1.0]
                                                titleColor:UIColor.whiteColor
                                                    height:kActionButtonHeight];
    [reportBtn addTarget:self action:@selector(reportTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *blockBtn = [self actionSheetButtonWithTitle:@"Block"
                                          backgroundColor:[HangoTheme primaryDarkColor]
                                               titleColor:UIColor.whiteColor
                                                   height:kActionButtonHeight];
    [blockBtn addTarget:self action:@selector(blockTapped) forControlEvents:UIControlEventTouchUpInside];

    UIButton *cancelBtn = [self actionSheetButtonWithTitle:@"Cancel"
                                           backgroundColor:[HangoTheme accentBlueColor]
                                                titleColor:UIColor.whiteColor
                                                    height:kActionButtonHeight];
    [cancelBtn addTarget:self action:@selector(dismissMoreMenu) forControlEvents:UIControlEventTouchUpInside];

    [card addSubview:reportBtn];
    [card addSubview:blockBtn];
    [card addSubview:cancelBtn];

    [overlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(overlay);
    }];
    [reportBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(28);
        make.centerX.equalTo(card);
        make.width.equalTo(card).multipliedBy(kWideButtonRatio);
        make.height.mas_equalTo(kActionButtonHeight);
    }];
    [blockBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(reportBtn.mas_bottom).offset(14);
        make.centerX.width.height.equalTo(reportBtn);
    }];
    [cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(blockBtn.mas_bottom).offset(14);
        make.centerX.equalTo(card);
        make.width.equalTo(card).multipliedBy(kCancelButtonRatio);
        make.height.mas_equalTo(kActionButtonHeight);
        make.bottom.equalTo(overlay.mas_safeAreaLayoutGuideBottom).offset(-24);
    }];
}

- (void)dismissMoreMenu {
    [[self.view viewWithTag:9901] removeFromSuperview];
}

- (void)reportTapped {
    [self dismissMoreMenu];
    HangoReportDetailViewController *vc = [[HangoReportDetailViewController alloc] init];
    vc.contact = self.contact;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)blockTapped {
    [self dismissMoreMenu];
    __weak typeof(self) weakSelf = self;
    NSString *contactId = self.contact.contactId;
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [[HangoDataStore shared] blockContactWithId:contactId];
        [MBProgressHUD showSuccessMessage:@"Blocked successfully"];
        [weakSelf.navigationController popViewControllerAnimated:YES];
    }];
}

@end
