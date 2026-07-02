#import "HangoDisplayString.h"
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
#import "HangoPermissionManager.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"
#import "HangoImageViewer.h"

@interface HangoPrivateDialogueViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation HangoPrivateDialogueViewController {
    UITableView *_tableView;
    HangoDialogueInputBar *_inputBar;
    NSArray<HangoDialogueItem *> *_dialogueItems;
    HGXConstraint *_inputBarBottomConstraint;
    HGXConstraint *_inputBarHeightConstraint;
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
    if (msg.audioFilePath.length > 0) {
        NSInteger fileDuration = [[HangoVoiceNoteManager shared] audioDurationForFileAtPath:msg.audioFilePath];
        if (fileDuration > 0) {
            return fileDuration;
        }
    }
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
    CGFloat horizontalReserved = 16.0 + HangoPrivateDialogueAvatarSize + 8.0 + 16.0;
    return [HangoDesignKit voiceBubbleWidthForDuration:[self resolvedAudioDurationForItem:msg]
                                            screenWidth:screenWidth
                                     horizontalReserved:horizontalReserved];
}

- (UIImage *)imageForDialogueContent:(NSString *)content {
    if (content.length == 0) {
        return nil;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:content]) {
        return [UIImage imageWithContentsOfFile:content];
    }
    return [HangoTheme avatarImageNamed:content];
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
    _inputBar.onPhoto = ^{
        [weakSelf openPhotoPicker];
    };
    [self.contentView addSubview:_inputBar];

    [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(4);
        make.left.equalTo(self.contentView).offset(48);
        make.width.height.hgx_equalTo(HangoPrivateDialogueAvatarSize);
    }];
    [name hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(avatar);
        make.left.equalTo(avatar.hgx_right).offset(8);
        make.right.lessThanOrEqualTo(more.hgx_left).offset(-8);
    }];
    [more hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(avatar);
        make.right.equalTo(self.contentView).offset(-16);
        make.width.height.hgx_equalTo(36);
    }];
    [_inputBar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.equalTo(self.contentView);
        self->_inputBarBottomConstraint = make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom);
        self->_inputBarHeightConstraint = make.height.hgx_equalTo(56);
    }];
    [_tableView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(avatar.hgx_bottom).offset(10);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(_inputBar.hgx_top);
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
    if (![self requireLoginForAction]) {
        return;
    }
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
    if (![self requireLoginForAction]) {
        return;
    }
    HangoPersona *persona = [HangoSessionManager shared].currentPersona ?: [HangoDataStore shared].currentPersona;
    HangoDialogueItem *msg = [[HangoDialogueItem alloc] init];
    msg.itemId = [[NSUUID UUID] UUIDString];
    msg.senderName = persona.name;
    msg.senderAvatarName = persona.avatarName;
    msg.timeText = [self formattedItemTime];
    msg.itemType = HangoDialogueItemTypeAudio;
    msg.isOutgoing = YES;
    msg.audioFilePath = audioFilePath;

    NSInteger resolvedDuration = MAX(duration, 1);
    if (audioFilePath.length > 0) {
        NSInteger fileDuration = [[HangoVoiceNoteManager shared] audioDurationForFileAtPath:audioFilePath];
        if (fileDuration > 0) {
            resolvedDuration = fileDuration;
        }
    }
    msg.audioDuration = resolvedDuration;
    msg.content = [NSString stringWithFormat:@"%lds", (long)resolvedDuration];

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

- (void)appendOutgoingImageItemWithImagePath:(NSString *)imagePath {
    if (![self requireLoginForAction]) {
        return;
    }
    if (imagePath.length == 0) {
        return;
    }

    HangoPersona *persona = [HangoSessionManager shared].currentPersona ?: [HangoDataStore shared].currentPersona;
    HangoDialogueItem *msg = [[HangoDialogueItem alloc] init];
    msg.itemId = [[NSUUID UUID] UUIDString];
    msg.senderName = persona.name;
    msg.senderAvatarName = persona.avatarName;
    msg.content = imagePath;
    msg.timeText = [self formattedItemTime];
    msg.itemType = HangoDialogueItemTypeImage;
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

- (void)updateInputBarForVoiceMode:(BOOL)voiceMode {
    [_inputBarHeightConstraint setOffset:voiceMode ? 160 : 56];
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

    UIImageView *avatar = [HangoDesignKit avatarForDialogueItem:msg size:HangoPrivateDialogueAvatarSize bordered:NO];
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
        UIImageView *img = [[UIImageView alloc] initWithImage:[self imageForDialogueContent:msg.content]];
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
            [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(cell.contentView).offset(8);
                make.right.equalTo(cell.contentView).offset(-16);
                make.width.height.hgx_equalTo(HangoPrivateDialogueAvatarSize);
            }];
            [sender hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(avatar.hgx_bottom).offset(2);
                make.centerX.equalTo(avatar);
            }];
            [img hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(avatar);
                make.right.equalTo(avatar.hgx_left).offset(-8);
                make.width.height.hgx_equalTo(120);
            }];
            [time hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(img.hgx_bottom).offset(4);
                make.right.equalTo(img);
                make.bottom.equalTo(cell.contentView).offset(-8);
            }];
        } else {
            [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(cell.contentView).offset(8);
                make.left.equalTo(cell.contentView).offset(16);
                make.width.height.hgx_equalTo(HangoPrivateDialogueAvatarSize);
            }];
            [sender hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(avatar.hgx_bottom).offset(2);
                make.centerX.equalTo(avatar);
            }];
            [img hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(avatar);
                make.left.equalTo(avatar.hgx_right).offset(8);
                make.width.height.hgx_equalTo(120);
            }];
            [time hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.top.equalTo(img.hgx_bottom).offset(4);
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
        [bubble setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [bubble setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        if (msg.audioFilePath.length > 0) {
            [bubble addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(voiceDialogueItemTapped:)]];
        }

        UIImageView *voiceIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"chat_voice_icon_white"]];
        voiceIcon.contentMode = UIViewContentModeScaleAspectFit;
        [voiceIcon setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [bubble addSubview:voiceIcon];

        NSInteger audioSeconds = [self resolvedAudioDurationForItem:msg];
        UILabel *duration = [[UILabel alloc] init];
        duration.text = [NSString stringWithFormat:@"%lds", (long)audioSeconds];
        duration.font = [HangoTheme monoFont];
        duration.textColor = UIColor.whiteColor;
        [duration setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [duration setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [bubble addSubview:duration];

        [voiceIcon hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.equalTo(bubble).offset(12);
            make.centerY.equalTo(bubble);
            make.width.height.hgx_equalTo(18);
        }];
        [duration hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.equalTo(voiceIcon.hgx_right).offset(8);
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
        [text hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.edges.equalTo(bubble).insets(UIEdgeInsetsMake(10, 12, 10, 12));
        }];
    }

    if (outgoing) {
        [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(cell.contentView).offset(8);
            make.right.equalTo(cell.contentView).offset(-16);
            make.width.height.hgx_equalTo(HangoPrivateDialogueAvatarSize);
        }];
        [sender hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(avatar.hgx_bottom).offset(2);
            make.centerX.equalTo(avatar);
        }];
        [bubble hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(avatar);
            make.right.equalTo(avatar.hgx_left).offset(-8);
            if (msg.itemType == HangoDialogueItemTypeAudio) {
                make.width.hgx_equalTo([self voiceBubbleWidthForItem:msg]);
                make.left.greaterThanOrEqualTo(cell.contentView).offset(16);
                make.height.hgx_equalTo(40);
            } else {
                make.width.lessThanOrEqualTo(cell.contentView).multipliedBy(0.62);
                make.height.hgx_greaterThanOrEqualTo(40);
            }
        }];
        [time hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(bubble.hgx_bottom).offset(4);
            make.right.equalTo(bubble);
            make.bottom.equalTo(cell.contentView).offset(-8);
        }];
        if (outgoing) {
            [self applyOutgoingVoiceRippleIfNeededForItem:msg bubble:bubble];
        }
    } else {
        [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(cell.contentView).offset(8);
            make.left.equalTo(cell.contentView).offset(16);
            make.width.height.hgx_equalTo(HangoPrivateDialogueAvatarSize);
        }];
        [sender hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(avatar.hgx_bottom).offset(2);
            make.centerX.equalTo(avatar);
        }];
        [bubble hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(avatar);
            make.left.equalTo(avatar.hgx_right).offset(8);
            if (msg.itemType == HangoDialogueItemTypeAudio) {
                make.width.hgx_equalTo([self voiceBubbleWidthForItem:msg]);
                make.right.lessThanOrEqualTo(cell.contentView).offset(-16);
                make.height.hgx_equalTo(40);
            } else {
                make.width.lessThanOrEqualTo(cell.contentView).multipliedBy(0.62);
                make.height.hgx_greaterThanOrEqualTo(40);
            }
        }];
        [time hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(bubble.hgx_bottom).offset(4);
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
    UIImage *image = [self imageForDialogueContent:msg.content];
    if (!image) {
        return;
    }

    [HangoImageViewer showImage:image fromSourceView:imageView];
}

- (void)openPhotoPicker {
    if (![self requireLoginForAction]) {
        return;
    }
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        return;
    }
    [HangoPermissionManager presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                          fromViewController:self
                                                    delegate:self];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        if (!image || self.contact.contactId.length == 0) {
            return;
        }
        NSString *imagePath = [[HangoDataStore shared] saveConversationDialogueImage:image conversationId:self.contact.contactId];
        if (imagePath.length == 0) {
            return;
        }
        [self appendOutgoingImageItemWithImagePath:imagePath];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)openMoreMenu {
    if (![self requireLoginForAction]) {
        return;
    }
    if ([self.view viewWithTag:9901]) {
        return;
    }
    [HangoDesignKit presentReportBlockActionSheetInView:self.view reportAction:^{
        [self reportTapped];
    } blockAction:^{
        [self blockTapped];
    }];
}

- (void)dismissMoreMenu {
    [HangoDesignKit dismissReportBlockActionSheetInView:self.view];
}

- (void)reportTapped {
    HangoReportDetailViewController *vc = [[HangoReportDetailViewController alloc] init];
    vc.contact = self.contact;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)blockTapped {
    if (self.contact.isDenied) {
        return;
    }
    NSString *message = [NSString stringWithFormat:HangoDisplayString(HangoDisplayStringKeyBlockConfirmFormat), self.contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:HangoDisplayString(HangoDisplayStringKeyBlockQuestion)
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    NSString *contactId = self.contact.contactId;
    [alert addAction:[UIAlertAction actionWithTitle:HangoDisplayString(HangoDisplayStringKeyBlock) style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [[HangoDataStore shared] blockContactWithId:contactId];
            [MBProgressHUD showSuccessMessage:HangoDisplayString(HangoDisplayStringKeyBlockedSuccessfully)];
            [weakSelf.navigationController popViewControllerAnimated:YES];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
