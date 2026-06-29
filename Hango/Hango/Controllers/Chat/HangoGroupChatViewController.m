#import "HangoGroupChatViewController.h"
#import "HangoParty.h"
#import "HangoContact.h"
#import "HangoChatMessage.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoChatInputBar.h"
#import "HangoAllPeopleViewController.h"
#import "HangoReportViewController.h"
#import "HangoDecoratePhotoViewController.h"
#import <Masonry/Masonry.h>

@implementation HangoGroupChatViewController {
    UITableView *_tableView;
    HangoChatInputBar *_inputBar;
    NSArray<HangoChatMessage *> *_messages;
    MASConstraint *_inputBarHeightConstraint;
}

- (void)setupUI {
    self.showsBackButton = YES;
    if (!self.party) self.party = [HangoDataStore shared].upcomingParties.firstObject;

    UIStackView *avatars = [[UIStackView alloc] init];
    avatars.axis = UILayoutConstraintAxisHorizontal;
    avatars.spacing = -8;
    for (NSString *name in self.party.memberAvatarNames) {
        UIImageView *img = [[UIImageView alloc] initWithImage:[HangoTheme avatarImageNamed:name]];
        img.layer.cornerRadius = 16;
        img.clipsToBounds = YES;
        img.contentMode = UIViewContentModeScaleAspectFill;
        [img mas_makeConstraints:^(MASConstraintMaker *make) { make.width.height.mas_equalTo(32); }];
        [avatars addArrangedSubview:img];
    }
    avatars.userInteractionEnabled = YES;
    [avatars addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openPeople)]];
    [self.contentView addSubview:avatars];

    UIButton *more = [UIButton buttonWithType:UIButtonTypeCustom];
    [more setTitle:@"..." forState:UIControlStateNormal];
    [more setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    [more addTarget:self action:@selector(openReport) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:more];

    UIScrollView *album = [[UIScrollView alloc] init];
    album.showsHorizontalScrollIndicator = NO;
    CGFloat x = 16;
    for (HangoAlbumItem *item in [HangoDataStore shared].albumItems) {
        UIView *card = [HangoDesignKit albumCardWithImageName:item.imageName dateText:item.dateText];
        card.frame = CGRectMake(x, 0, 72, 88);
        [album addSubview:card];
        x += 80;
    }
    album.contentSize = CGSizeMake(x, 88);
    [self.contentView addSubview:album];

    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    [self.contentView addSubview:_tableView];

    _inputBar = [[HangoChatInputBar alloc] init];
    __weak typeof(self) weakSelf = self;
    _inputBar.onSend = ^(NSString *text) {
        [[HangoRequestManager shared] requestWithDelay:0.5 inView:weakSelf.view completion:^{
            HangoChatMessage *msg = [[HangoChatMessage alloc] init];
            msg.messageId = [[NSUUID UUID] UUIDString];
            msg.senderName = [HangoDataStore shared].currentUser.name;
            msg.content = text;
            msg.timeText = @"Now";
            msg.messageType = HangoChatMessageTypeText;
            msg.isOutgoing = YES;
            [[HangoDataStore shared] appendPartyMessage:msg partyId:weakSelf.party.partyId];
            [weakSelf loadMessages];
        }];
    };
    _inputBar.onVoiceSend = ^(NSInteger duration) {
        [weakSelf appendOutgoingAudioMessageWithDuration:duration];
    };
    _inputBar.onModeChanged = ^(BOOL voiceMode) {
        [weakSelf updateInputBarForVoiceMode:voiceMode];
    };
    _inputBar.onPhoto = ^{ [weakSelf openDecorate]; };
    [self.contentView addSubview:_inputBar];

    [avatars mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(48);
        make.centerX.equalTo(self.contentView);
    }];
    [more mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(avatars);
        make.right.equalTo(self.contentView).offset(-16);
    }];
    [album mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatars.mas_bottom).offset(10);
        make.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(92);
    }];
    [_inputBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        self->_inputBarHeightConstraint = make.height.mas_equalTo(56);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(album.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(_inputBar.mas_top);
    }];

    [self loadMessages];
}

- (void)appendOutgoingAudioMessageWithDuration:(NSInteger)duration {
    HangoChatMessage *msg = [[HangoChatMessage alloc] init];
    msg.messageId = [[NSUUID UUID] UUIDString];
    msg.senderName = [HangoDataStore shared].currentUser.name;
    msg.senderAvatarName = [HangoDataStore shared].currentUser.avatarName;
    msg.content = [NSString stringWithFormat:@"%lds", (long)MAX(duration, 1)];
    msg.timeText = @"Now";
    msg.messageType = HangoChatMessageTypeAudio;
    msg.isOutgoing = YES;
    msg.audioDuration = MAX(duration, 1);

    [[HangoDataStore shared] appendPartyMessage:msg partyId:self.party.partyId];
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

- (void)loadMessages {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [[HangoDataStore shared] messagesForPartyId:self.party.partyId];
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
    if (!cell) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
    cell.backgroundColor = UIColor.clearColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    HangoChatMessage *msg = _messages[indexPath.row];
    UIView *bubble = [[UIView alloc] init];
    bubble.layer.cornerRadius = 14;
    bubble.backgroundColor = msg.isOutgoing ? [HangoTheme primaryDarkColor] : UIColor.whiteColor;
    [cell.contentView addSubview:bubble];

    UILabel *text = [[UILabel alloc] init];
    text.font = [HangoTheme monoFont];
    text.textColor = msg.isOutgoing ? UIColor.whiteColor : [HangoTheme primaryDarkColor];
    text.numberOfLines = 0;
    [bubble addSubview:text];

    UIImageView *voiceIcon = nil;
    if (msg.messageType == HangoChatMessageTypeAudio) {
        voiceIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"chat_voice_icon_white"]];
        voiceIcon.contentMode = UIViewContentModeScaleAspectFit;
        [bubble addSubview:voiceIcon];
        text.text = msg.content;
    } else {
        text.text = msg.content;
    }

    UILabel *meta = [[UILabel alloc] init];
    meta.text = [NSString stringWithFormat:@"%@ · %@", msg.senderName, msg.timeText];
    meta.font = [HangoTheme captionFont];
    meta.textColor = [HangoTheme secondaryTextColor];
    [cell.contentView addSubview:meta];

    [bubble mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(6);
        make.width.lessThanOrEqualTo(cell.contentView).multipliedBy(0.72);
        if (msg.messageType == HangoChatMessageTypeAudio) {
            make.width.mas_greaterThanOrEqualTo(78);
            make.height.mas_greaterThanOrEqualTo(40);
        }
        if (msg.isOutgoing) {
            make.right.equalTo(cell.contentView).offset(-16);
        } else {
            make.left.equalTo(cell.contentView).offset(16);
        }
    }];
    if (voiceIcon) {
        [voiceIcon mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(bubble).offset(12);
            make.centerY.equalTo(bubble);
            make.width.height.mas_equalTo(18);
        }];
        [text mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(voiceIcon.mas_right).offset(8);
            make.right.equalTo(bubble).offset(-14);
            make.centerY.equalTo(bubble);
        }];
    } else {
        [text mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(bubble).insets(UIEdgeInsetsMake(10, 12, 10, 12));
        }];
    }
    [meta mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(bubble.mas_bottom).offset(4);
        make.bottom.equalTo(cell.contentView).offset(-4);
        if (msg.isOutgoing) {
            make.right.equalTo(bubble);
        } else {
            make.left.equalTo(bubble);
        }
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 88;
}

- (void)openPeople {
    HangoAllPeopleViewController *vc = [[HangoAllPeopleViewController alloc] init];
    vc.party = self.party;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openReport {
    HangoReportViewController *vc = [[HangoReportViewController alloc] init];
    vc.contact = [[HangoDataStore shared].contacts firstObject];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openDecorate {
    HangoDecoratePhotoViewController *vc = [[HangoDecoratePhotoViewController alloc] init];
    vc.party = self.party;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
