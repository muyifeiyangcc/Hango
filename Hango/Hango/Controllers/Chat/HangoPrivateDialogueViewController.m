#import "HangoPrivateDialogueViewController.h"
#import "HangoContact.h"
#import "HangoPersona.h"
#import "HangoDialogueItem.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoSessionManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoDialogueInputBar.h"
#import "HangoReportDetailViewController.h"
#import "HangoVoiceNoteManager.h"
#import "HangoHUD.h"
#import "Masonry.h"
#import "HangoImageViewer.h"

@implementation HangoPrivateDialogueViewController {
    UITableView *_tableView;
    HangoDialogueInputBar *_inputBar;
    NSArray<HangoDialogueItem *> *_dialogueItems;
    MASConstraint *_inputBarBottomConstraint;
    MASConstraint *_inputBarHeightConstraint;
    NSString *_playingOutgoingVoicePath;
    __weak UIView *_playingVoiceBubbleView;
}

static const CGFloat HangoPrivateDialogueAvatarSize = 50.0;

- (NSString *)formattedItemTime {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"HH:mm";
    });
    return [formatter stringFromDate:[NSDate date]];
}

- (NSInteger)resolvedAudioDurationForItem:(HangoDialogueItem *)msg {
    if (msg.audioDuration > 0) {
        return msg.audioDuration;
    }
    NSString *digits = [[msg.content componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
    return MAX(digits.integerValue, 1);
}

- (CGFloat)voiceBubbleWidthForItem:(HangoDialogueItem *)msg {
    CGFloat screenWidth = CGRectGetWidth(self.view.bounds);
    if (screenWidth <= 0) {
        screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    }
    return [HangoDesignKit voiceBubbleWidthForDuration:[self resolvedAudioDurationForItem:msg] screenWidth:screenWidth];
}

- (void)setupUI {
    self.showsBackButton = YES;
    if (!self.contact) {
        self.contact = [HangoDataStore shared].contacts.firstObject;
    }

    UIImageView *avatar = [HangoDesignKit avatarWithName:self.contact.avatarName size:HangoPrivateDialogueAvatarSize bordered:NO];
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

    _inputBar = [[HangoDialogueInputBar alloc] init];
    __weak typeof(self) weakSelf = self;
    _inputBar.onSend = ^(NSString *text) {
        [weakSelf appendOutgoingTextItem:text];
    };
    _inputBar.onVoiceSend = ^(NSInteger duration, NSString *audioFilePath) {
        [weakSelf appendOutgoingAudioItemWithDuration:duration audioFilePath:audioFilePath];
    };
    _inputBar.onModeChanged = ^(BOOL voiceMode) {
        [weakSelf updateInputBarForVoiceMode:voiceMode];
    };
    [self.contentView addSubview:_inputBar];

    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(4);
        make.left.equalTo(self.contentView).offset(48);
        make.width.height.mas_equalTo(HangoPrivateDialogueAvatarSize);
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

    [self loadDialogueItems];
    [self registerKeyboardNotifications];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [[HangoVoiceNoteManager shared] cancelRecording];
    [self stopOutgoingVoiceRipple];
    [HangoVoiceNoteManager.shared stopPlayback];
}

- (void)appendOutgoingTextItem:(NSString *)text {
    if (text.length == 0) {
        return;
    }

    HangoPersona *persona = [HangoSessionManager shared].currentPersona ?: [HangoDataStore shared].currentPersona;
    HangoDialogueItem *msg = [[HangoDialogueItem alloc] init];
    msg.itemId = [[NSUUID UUID] UUIDString];
    msg.senderName = persona.name;
    msg.senderAvatarName = persona.avatarName;
    msg.content = text;
    msg.timeText = [self formattedItemTime];
    msg.itemType = HangoDialogueItemTypeText;
    msg.isOutgoing = YES;

    [[HangoDataStore shared] appendDialogueItem:msg toConversationId:self.contact.contactId];
    NSMutableArray<HangoDialogueItem *> *updated = _dialogueItems ? _dialogueItems.mutableCopy : [NSMutableArray array];
    [updated addObject:msg];
    _dialogueItems = updated.copy;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_dialogueItems.count - 1 inSection:0];
    [_tableView performBatchUpdates:^{
        [self->_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestItemAnimated:YES];
    }];
}

- (void)appendOutgoingAudioItemWithDuration:(NSInteger)duration audioFilePath:(NSString *)audioFilePath {
    HangoPersona *persona = [HangoSessionManager shared].currentPersona ?: [HangoDataStore shared].currentPersona;
    HangoDialogueItem *msg = [[HangoDialogueItem alloc] init];
    msg.itemId = [[NSUUID UUID] UUIDString];
    msg.senderName = persona.name;
    msg.senderAvatarName = persona.avatarName;
    msg.content = [NSString stringWithFormat:@"%lds", (long)MAX(duration, 1)];
    msg.timeText = [self formattedItemTime];
    msg.itemType = HangoDialogueItemTypeAudio;
    msg.isOutgoing = YES;
    msg.audioDuration = MAX(duration, 1);
    msg.audioFilePath = audioFilePath;

    [[HangoDataStore shared] appendDialogueItem:msg toConversationId:self.contact.contactId];
    NSMutableArray<HangoDialogueItem *> *updated = _dialogueItems ? _dialogueItems.mutableCopy : [NSMutableArray array];
    [updated addObject:msg];
    _dialogueItems = updated.copy;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:_dialogueItems.count - 1 inSection:0];
    [_tableView performBatchUpdates:^{
        [self->_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestItemAnimated:YES];
    }];
}

- (void)updateInputBarForVoiceMode:(BOOL)voiceMode {
    [_inputBarHeightConstraint setOffset:voiceMode ? 132 : 56];
    [UIView animateWithDuration:0.22 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self.view layoutIfNeeded];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestItemAnimated:NO];
    }];
}

- (void)scrollToLatestItemAnimated:(BOOL)animated {
    if (_dialogueItems.count == 0) {
        return;
    }
    NSIndexPath *last = [NSIndexPath indexPathForRow:_dialogueItems.count - 1 inSection:0];
    [_tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:animated];
}

- (void)registerKeyboardNotifications {
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(voicePlaybackStateDidChange:) name:HangoVoicePlaybackStateDidChangeNotification object:nil];
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

- (void)stopOutgoingVoiceRipple {
    UIView *bubbleView = _playingVoiceBubbleView;
    _playingVoiceBubbleView = nil;
    _playingOutgoingVoicePath = nil;
    if (bubbleView && bubbleView.window) {
        [HangoDesignKit stopVoicePlaybackRippleOnView:bubbleView];
    }
}

- (void)startOutgoingVoiceRippleOnBubble:(UIView *)bubble {
    if (!bubble) {
        return;
    }
    _playingVoiceBubbleView = bubble;
    [HangoDesignKit startVoicePlaybackRippleOnView:bubble color:UIColor.whiteColor];
}

- (void)applyOutgoingVoiceRippleIfNeededForItem:(HangoDialogueItem *)msg bubble:(UIView *)bubble {
    if (!msg.isOutgoing || msg.itemType != HangoDialogueItemTypeAudio || msg.audioFilePath.length == 0) {
        return;
    }
    if (![msg.audioFilePath isEqualToString:_playingOutgoingVoicePath]) {
        return;
    }
    if (!HangoVoiceNoteManager.shared.isPlaying) {
        return;
    }
    _playingVoiceBubbleView = bubble;
    [HangoDesignKit startVoicePlaybackRippleOnView:bubble color:UIColor.whiteColor];
}

- (void)voicePlaybackStateDidChange:(NSNotification *)notification {
    BOOL playing = [notification.userInfo[HangoVoicePlaybackPlayingKey] boolValue];
    if (playing) {
        return;
    }
    [self stopOutgoingVoiceRipple];
}

- (void)updateInputBarBottomOffset:(CGFloat)offset notificationInfo:(NSDictionary *)info {
    NSTimeInterval duration = [info[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationOptions options = ([info[UIKeyboardAnimationCurveUserInfoKey] integerValue] << 16);
    [_inputBarBottomConstraint setOffset:offset];
    [UIView animateWithDuration:duration delay:0 options:options animations:^{
        [self.view layoutIfNeeded];
    } completion:^(__unused BOOL finished) {
        [self scrollToLatestItemAnimated:NO];
    }];
}

- (void)loadDialogueItems {
    _dialogueItems = [[HangoDataStore shared] dialogueItemsForConversationId:self.contact.contactId];
    [_tableView reloadData];
    [self scrollToLatestItemAnimated:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dialogueItems.count;
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

    HangoDialogueItem *msg = _dialogueItems[indexPath.row];
    BOOL outgoing = msg.isOutgoing;

    UIImageView *avatar = [HangoDesignKit avatarWithName:msg.senderAvatarName size:HangoPrivateDialogueAvatarSize bordered:NO];
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

    if (msg.itemType == HangoDialogueItemTypeImage) {
        UIImageView *img = [[UIImageView alloc] initWithImage:[HangoTheme avatarImageNamed:msg.content]];
        img.layer.cornerRadius = 12;
        img.clipsToBounds = YES;
        img.layer.borderWidth = 4;
        img.layer.borderColor = UIColor.whiteColor.CGColor;
        img.contentMode = UIViewContentModeScaleAspectFill;
        img.userInteractionEnabled = YES;
        img.tag = indexPath.row;
        [img addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageItemTapped:)]];
        [cell.contentView addSubview:img];

        if (outgoing) {
            [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.equalTo(cell.contentView).offset(8);
                make.right.equalTo(cell.contentView).offset(-16);
                make.width.height.mas_equalTo(HangoPrivateDialogueAvatarSize);
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
                make.width.height.mas_equalTo(HangoPrivateDialogueAvatarSize);
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
    bubble.backgroundColor = msg.itemType == HangoDialogueItemTypeAudio ? [HangoTheme primaryDarkColor] : UIColor.whiteColor;
    [cell.contentView addSubview:bubble];

    if (msg.itemType == HangoDialogueItemTypeAudio) {
        bubble.userInteractionEnabled = msg.audioFilePath.length > 0;
        bubble.tag = indexPath.row;
        bubble.clipsToBounds = NO;
        if (msg.audioFilePath.length > 0) {
            [bubble addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(voiceDialogueItemTapped:)]];
        }

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
            make.width.height.mas_equalTo(HangoPrivateDialogueAvatarSize);
        }];
        [sender mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar.mas_bottom).offset(2);
            make.centerX.equalTo(avatar);
        }];
        [bubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar);
            make.right.equalTo(avatar.mas_left).offset(-8);
            if (msg.itemType == HangoDialogueItemTypeAudio) {
                make.width.mas_equalTo([self voiceBubbleWidthForItem:msg]);
                make.height.mas_equalTo(40);
            } else {
                make.width.lessThanOrEqualTo(cell.contentView).multipliedBy(0.62);
                make.height.mas_greaterThanOrEqualTo(40);
            }
        }];
        [time mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bubble.mas_bottom).offset(4);
            make.right.equalTo(bubble);
            make.bottom.equalTo(cell.contentView).offset(-8);
        }];
        if (outgoing) {
            [self applyOutgoingVoiceRippleIfNeededForItem:msg bubble:bubble];
        }
    } else {
        [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(cell.contentView).offset(8);
            make.left.equalTo(cell.contentView).offset(16);
            make.width.height.mas_equalTo(HangoPrivateDialogueAvatarSize);
        }];
        [sender mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar.mas_bottom).offset(2);
            make.centerX.equalTo(avatar);
        }];
        [bubble mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(avatar);
            make.left.equalTo(avatar.mas_right).offset(8);
            if (msg.itemType == HangoDialogueItemTypeAudio) {
                make.width.mas_equalTo([self voiceBubbleWidthForItem:msg]);
                make.height.mas_equalTo(40);
            } else {
                make.width.lessThanOrEqualTo(cell.contentView).multipliedBy(0.62);
                make.height.mas_greaterThanOrEqualTo(40);
            }
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
    HangoDialogueItem *msg = _dialogueItems[indexPath.row];
    return msg.itemType == HangoDialogueItemTypeImage ? 184 : 112;
}

- (void)voiceDialogueItemTapped:(UITapGestureRecognizer *)recognizer {
    UIView *bubble = recognizer.view;
    if (bubble.tag < 0 || bubble.tag >= _dialogueItems.count) {
        return;
    }

    HangoDialogueItem *msg = _dialogueItems[bubble.tag];
    if (msg.itemType != HangoDialogueItemTypeAudio || msg.audioFilePath.length == 0) {
        return;
    }

    if (msg.isOutgoing) {
        [self stopOutgoingVoiceRipple];
        _playingOutgoingVoicePath = msg.audioFilePath;
        [self startOutgoingVoiceRippleOnBubble:bubble];
    }
    [HangoVoiceNoteManager.shared playAudioAtPath:msg.audioFilePath];
}

- (void)imageItemTapped:(UITapGestureRecognizer *)recognizer {
    UIImageView *imageView = (UIImageView *)recognizer.view;
    if (![imageView isKindOfClass:UIImageView.class] || imageView.tag < 0 || imageView.tag >= _dialogueItems.count) {
        return;
    }

    HangoDialogueItem *msg = _dialogueItems[imageView.tag];
    UIImage *image = [HangoTheme avatarImageNamed:msg.content];
    if (!image) {
        return;
    }

    [HangoImageViewer showImage:image fromSourceView:imageView];
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

    UIButton *blockBtn = [self actionSheetButtonWithTitle:@"Deny"
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
    if (self.contact.isDenied) {
        return;
    }
    NSString *message = [NSString stringWithFormat:@"Are you sure you want to add %@ to the deny list?", self.contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add to Deny List?"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    NSString *contactId = self.contact.contactId;
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [[HangoDataStore shared] blockContactWithId:contactId];
            [MBProgressHUD showSuccessMessage:@"Blocked successfully"];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
