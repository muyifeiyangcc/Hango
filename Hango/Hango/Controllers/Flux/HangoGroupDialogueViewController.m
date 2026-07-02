#import "HangoGroupDialogueViewController.h"
#import "HangoParty.h"
#import "HangoContact.h"
#import "HangoDialogueItem.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoDialogueInputBar.h"
#import "HangoAllPeopleViewController.h"
#import "HangoPermissionManager.h"
#import "HangoVoiceNoteManager.h"
#import "HGXAnchor.h"
#import "HangoImageViewer.h"

static NSString * const kHangoGroupPhotoCellId = @"HangoGroupPhotoCell";
static CGFloat const kHangoGroupDialogueAvatarSize = 50.0;
static CGFloat const kHangoGroupHeaderAvatarSize = 40.0;
static CGFloat const kHangoGroupPhotoCornerRadius = 16.0;
static CGFloat const kHangoGroupPhotoCarouselHeight = 112.0;
static CGFloat const kHangoGroupPhotoWidthRatio = 0.44;
static CGFloat const kHangoGroupPhotoFocusedHeightRatio = 1.0;
static CGFloat const kHangoGroupPhotoSideHeightRatio = 0.88;

@interface HangoGroupPhotoCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, assign) BOOL photoFocused;
- (void)setPhotoFocused:(BOOL)focused animated:(BOOL)animated;
@end

@implementation HangoGroupPhotoCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = UIColor.clearColor;

        _photoView = [[UIImageView alloc] init];
        _photoView.contentMode = UIViewContentModeScaleAspectFill;
        _photoView.clipsToBounds = YES;
        _photoView.layer.cornerRadius = kHangoGroupPhotoCornerRadius;
        _photoView.backgroundColor = UIColor.whiteColor;
        [self.contentView addSubview:_photoView];

        [_photoView hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.contentView);
            make.height.equalTo(self.contentView).multipliedBy(kHangoGroupPhotoSideHeightRatio);
        }];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.photoFocused = NO;
}

- (void)setPhotoFocused:(BOOL)focused animated:(BOOL)animated {
    if (self.photoFocused == focused) {
        return;
    }
    self.photoFocused = focused;
    CGFloat ratio = focused ? kHangoGroupPhotoFocusedHeightRatio : kHangoGroupPhotoSideHeightRatio;
    [_photoView hgx_remakeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.contentView);
        make.height.equalTo(self.contentView).multipliedBy(ratio);
    }];
    void (^updates)(void) = ^{
        [self.contentView layoutIfNeeded];
    };
    if (animated) {
        [UIView animateWithDuration:0.18 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:updates completion:nil];
    } else {
        updates();
    }
}

@end

@interface HangoGroupDialogueViewController () <UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation HangoGroupDialogueViewController {
    UIStackView *_avatarStack;
    UILabel *_extraMemberBadge;
    UITableView *_tableView;
    UICollectionView *_photoCarousel;
    NSArray<UIImage *> *_photoImages;
    NSInteger _focusedPhotoIndex;
    HGXConstraint *_photoCarouselHeightConstraint;
    HGXConstraint *_photoCarouselTopConstraint;
    HangoDialogueInputBar *_inputBar;
    UIView *_inputBarBackground;
    NSArray<HangoDialogueItem *> *_dialogueItems;
    HGXConstraint *_inputBarBottomConstraint;
    HGXConstraint *_inputBarHeightConstraint;
    NSString *_playingOutgoingVoicePath;
    __weak UIView *_playingVoiceBubbleView;
}

- (NSString *)formattedItemTime {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"hh:mm a";
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
    CGFloat horizontalReserved = 16.0 + kHangoGroupDialogueAvatarSize + 8.0 + 16.0;
    return [HangoDesignKit voiceBubbleWidthForDuration:[self resolvedAudioDurationForItem:msg]
                                            screenWidth:screenWidth
                                     horizontalReserved:horizontalReserved];
}

- (NSArray<NSString *> *)avatarNamesForHeader {
    HangoDataStore *store = [HangoDataStore shared];
    NSInteger maxVisible = [self totalMemberCount] <= 5 ? 5 : 4;
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if (self.party.hostAvatarName.length > 0 &&
        ![store isDeniedPersonWithName:self.party.hostName avatarName:self.party.hostAvatarName]) {
        [names addObject:self.party.hostAvatarName];
    }
    for (NSString *name in [store visibleMemberAvatarNamesForParty:self.party]) {
        if (names.count >= maxVisible) {
            break;
        }
        if (![names containsObject:name]) {
            [names addObject:name];
        }
    }
    return names.copy;
}

- (NSInteger)totalMemberCount {
    HangoDataStore *store = [HangoDataStore shared];
    NSInteger count = 0;
    if (![store isDeniedPersonWithName:self.party.hostName avatarName:self.party.hostAvatarName]) {
        count = 1;
    }
    for (NSString *name in [store visibleMemberAvatarNamesForParty:self.party]) {
        if (name.length > 0) {
            count += 1;
        }
    }
    count += MAX(self.party.extraMemberCount, 0);
    return count;
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
    if (!self.party) {
        self.party = [HangoDataStore shared].upcomingParties.firstObject;
    }

    _avatarStack = [[UIStackView alloc] init];
    _avatarStack.axis = UILayoutConstraintAxisHorizontal;
    _avatarStack.alignment = UIStackViewAlignmentCenter;
    _avatarStack.spacing = -14;
    HangoDataStore *store = [HangoDataStore shared];
    NSArray<NSString *> *headerAvatarNames = [self avatarNamesForHeader];
    BOOL hostIncluded = self.party.hostAvatarName.length > 0 &&
        ![store isDeniedPersonWithName:self.party.hostName avatarName:self.party.hostAvatarName];
    for (NSInteger i = 0; i < (NSInteger)headerAvatarNames.count; i++) {
        NSString *avatarName = headerAvatarNames[i];
        NSString *senderName = avatarName;
        if (hostIncluded && i == 0) {
            senderName = self.party.hostName;
        } else {
            for (HangoContact *contact in [store contactsForParty:self.party]) {
                if ([contact.avatarName isEqualToString:avatarName]) {
                    senderName = contact.name;
                    break;
                }
            }
        }
        UIImageView *img = [HangoDesignKit avatarForSenderName:senderName senderAvatarName:avatarName size:kHangoGroupHeaderAvatarSize bordered:YES];
        [img hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.width.height.hgx_equalTo(kHangoGroupHeaderAvatarSize);
        }];
        [_avatarStack addArrangedSubview:img];
    }

    NSInteger remaining = [self totalMemberCount] - _avatarStack.arrangedSubviews.count;
    if (remaining > 0 && [self totalMemberCount] > 5) {
        UIView *badgeWrap = [[UIView alloc] init];
        badgeWrap.backgroundColor = UIColor.clearColor;
        [badgeWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.width.height.hgx_equalTo(kHangoGroupHeaderAvatarSize);
        }];

        UIImageView *lastAvatar = [HangoDesignKit avatarWithName:self.party.memberAvatarNames.lastObject ?: self.party.hostAvatarName
                                                            size:kHangoGroupHeaderAvatarSize
                                                        bordered:YES];
        [badgeWrap addSubview:lastAvatar];
        [lastAvatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.edges.equalTo(badgeWrap);
        }];

        UIView *overlay = [[UIView alloc] init];
        overlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
        overlay.layer.cornerRadius = kHangoGroupHeaderAvatarSize / 2.0;
        overlay.clipsToBounds = YES;
        [badgeWrap addSubview:overlay];
        [overlay hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.edges.equalTo(badgeWrap);
        }];

        _extraMemberBadge = [[UILabel alloc] init];
        _extraMemberBadge.text = [NSString stringWithFormat:@"+%ld", (long)remaining];
        _extraMemberBadge.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightBold];
        _extraMemberBadge.textColor = UIColor.whiteColor;
        _extraMemberBadge.textAlignment = NSTextAlignmentCenter;
        [badgeWrap addSubview:_extraMemberBadge];
        [_extraMemberBadge hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.center.equalTo(badgeWrap);
        }];
        [_avatarStack addArrangedSubview:badgeWrap];
    }

    _avatarStack.userInteractionEnabled = NO;
    [self.contentView addSubview:_avatarStack];

    UIButton *more = [UIButton buttonWithType:UIButtonTypeCustom];
    [more setTitle:@"..." forState:UIControlStateNormal];
    [more setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    more.titleLabel.font = [UIFont boldSystemFontOfSize:22];
    [more addTarget:self action:@selector(openPeople) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:more];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 12;

    _photoCarousel = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _photoCarousel.backgroundColor = UIColor.clearColor;
    _photoCarousel.showsHorizontalScrollIndicator = NO;
    _photoCarousel.decelerationRate = UIScrollViewDecelerationRateFast;
    _photoCarousel.contentInset = UIEdgeInsetsZero;
    _photoCarousel.dataSource = (id<UICollectionViewDataSource>)self;
    _photoCarousel.delegate = (id<UICollectionViewDelegate>)self;
    [_photoCarousel registerClass:HangoGroupPhotoCell.class forCellWithReuseIdentifier:kHangoGroupPhotoCellId];
    [self.contentView addSubview:_photoCarousel];

    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.estimatedRowHeight = 112;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    _inputBarBackground = [[UIView alloc] init];
    _inputBarBackground.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:_inputBarBackground];

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
    [self.view addSubview:_inputBar];

    [_avatarStack hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.centerX.equalTo(self.contentView);
        make.height.hgx_equalTo(kHangoGroupHeaderAvatarSize);
    }];
    [more hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(_avatarStack);
        make.right.equalTo(self.contentView).offset(-16);
        make.width.height.hgx_equalTo(36);
    }];
    [_photoCarousel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        self->_photoCarouselTopConstraint = make.top.equalTo(_avatarStack.hgx_bottom).offset(0);
        make.left.right.equalTo(self.contentView);
        self->_photoCarouselHeightConstraint = make.height.hgx_equalTo(0);
    }];
    [_inputBarBackground hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(_inputBar.hgx_top).offset(-8);
    }];
    [_inputBar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        self->_inputBarBottomConstraint = make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom);
        self->_inputBarHeightConstraint = make.height.hgx_equalTo(56);
    }];
    [_tableView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_photoCarousel.hgx_bottom).offset(8);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(_inputBar.hgx_top);
    }];

    [self registerKeyboardNotifications];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(deniedContactsDidChange) name:HangoDeniedContactsDidChangeNotification object:nil];
    [self reloadPhotos];
    [self loadDialogueItems];
}

- (void)deniedContactsDidChange {
    if (!self.isViewLoaded) {
        return;
    }
    if ([[HangoDataStore shared] isPartyHostDenied:self.party]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self reloadPhotos];
    [self loadDialogueItems];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadPhotos];
    [self loadDialogueItems];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [[HangoVoiceNoteManager shared] cancelRecording];
    [self stopOutgoingVoiceRipple];
    [HangoVoiceNoteManager.shared stopPlayback];
}

- (void)reloadPhotos {
    _photoImages = [[HangoDataStore shared] partyRecordPhotoImagesForPartyId:self.party.partyId];
    BOOL hasPhotos = _photoImages.count > 0;
    _photoCarousel.hidden = !hasPhotos;
    [_photoCarouselHeightConstraint setOffset:hasPhotos ? kHangoGroupPhotoCarouselHeight : 0];
    [_photoCarouselTopConstraint setOffset:hasPhotos ? 12 : 0];

    if (!hasPhotos) {
        [_photoCarousel reloadData];
        return;
    }

    _focusedPhotoIndex = _photoImages.count - 1;
    [_photoCarousel reloadData];
    [_photoCarousel layoutIfNeeded];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:_focusedPhotoIndex inSection:0];
    [_photoCarousel scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    [self applyFocusedStateToVisiblePhotoCellsAnimated:NO];
}

- (CGFloat)groupPhotoItemWidthForCarousel:(UICollectionView *)collectionView {
    return CGRectGetWidth(collectionView.bounds) * kHangoGroupPhotoWidthRatio;
}

- (NSInteger)focusedPhotoIndexForCarousel {
    if (_photoImages.count == 0) {
        return 0;
    }
    [_photoCarousel layoutIfNeeded];
    CGFloat centerX = _photoCarousel.contentOffset.x + CGRectGetWidth(_photoCarousel.bounds) * 0.5;
    NSInteger closestIndex = 0;
    CGFloat minDistance = CGFLOAT_MAX;
    for (NSInteger i = 0; i < (NSInteger)_photoImages.count; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        UICollectionViewLayoutAttributes *attributes = [_photoCarousel layoutAttributesForItemAtIndexPath:indexPath];
        if (!attributes) {
            continue;
        }
        CGFloat distance = fabs(CGRectGetMidX(attributes.frame) - centerX);
        if (distance < minDistance) {
            minDistance = distance;
            closestIndex = i;
        }
    }
    return closestIndex;
}

- (void)syncFocusedPhotoAnimated:(BOOL)animated {
    NSInteger index = [self focusedPhotoIndexForCarousel];
    _focusedPhotoIndex = index;
    [self applyFocusedStateToVisiblePhotoCellsAnimated:animated];
}

- (void)applyFocusedStateToVisiblePhotoCellsAnimated:(BOOL)animated {
    for (HangoGroupPhotoCell *cell in _photoCarousel.visibleCells) {
        NSIndexPath *indexPath = [_photoCarousel indexPathForCell:cell];
        if (!indexPath) {
            continue;
        }
        [cell setPhotoFocused:(indexPath.item == _focusedPhotoIndex) animated:animated];
    }
}

- (void)loadDialogueItems {
    _dialogueItems = [[HangoDataStore shared] dialogueItemsForPartyId:self.party.partyId];
    [_tableView reloadData];
    [self scrollToLatestItemAnimated:NO];
}

- (void)appendOutgoingTextItem:(NSString *)text {
    if (![self requireLoginForAction]) {
        return;
    }
    if (text.length == 0) {
        return;
    }

    HangoDialogueItem *msg = [[HangoDialogueItem alloc] init];
    msg.itemId = [[NSUUID UUID] UUIDString];
    msg.senderName = [HangoDataStore shared].currentPersona.name;
    msg.senderAvatarName = [HangoDataStore shared].currentPersona.avatarName;
    msg.content = text;
    msg.timeText = [self formattedItemTime];
    msg.itemType = HangoDialogueItemTypeText;
    msg.isOutgoing = YES;

    [[HangoDataStore shared] appendPartyDialogueItem:msg partyId:self.party.partyId];
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
    HangoDialogueItem *msg = [[HangoDialogueItem alloc] init];
    msg.itemId = [[NSUUID UUID] UUIDString];
    msg.senderName = [HangoDataStore shared].currentPersona.name;
    msg.senderAvatarName = [HangoDataStore shared].currentPersona.avatarName;
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

    [[HangoDataStore shared] appendPartyDialogueItem:msg partyId:self.party.partyId];
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
    _inputBarBackground.hidden = voiceMode;
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
        [self scrollToLatestItemAnimated:NO];
    }];
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoImages.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HangoGroupPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kHangoGroupPhotoCellId forIndexPath:indexPath];
    cell.photoView.image = _photoImages[indexPath.item];
    [cell setPhotoFocused:(indexPath.item == _focusedPhotoIndex) animated:NO];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = [self groupPhotoItemWidthForCarousel:collectionView];
    CGFloat height = CGRectGetHeight(collectionView.bounds);
    return CGSizeMake(width, MAX(height, 1));
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    CGFloat itemWidth = width * kHangoGroupPhotoWidthRatio;
    CGFloat inset = MAX((width - itemWidth) / 2.0, 0);
    return UIEdgeInsetsMake(0, inset, 0, inset);
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView != _photoCarousel) {
        return;
    }
    NSInteger index = [self focusedPhotoIndexForCarousel];
    if (index == _focusedPhotoIndex) {
        return;
    }
    _focusedPhotoIndex = index;
    [self applyFocusedStateToVisiblePhotoCellsAnimated:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView != _photoCarousel || decelerate) {
        return;
    }
    [self syncFocusedPhotoAnimated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (scrollView != _photoCarousel) {
        return;
    }
    [self syncFocusedPhotoAnimated:YES];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (scrollView != _photoCarousel) {
        return;
    }
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_photoCarousel.collectionViewLayout;
    CGFloat itemWidth = [self groupPhotoItemWidthForCarousel:_photoCarousel];
    CGFloat spacing = layout.minimumLineSpacing;
    if (itemWidth <= 0 || _photoImages.count == 0) {
        return;
    }
    NSInteger index = (NSInteger)lround(targetContentOffset->x / (itemWidth + spacing));
    index = MAX(0, MIN(index, (NSInteger)_photoImages.count - 1));
    targetContentOffset->x = index * (itemWidth + spacing);
    _focusedPhotoIndex = index;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applyFocusedStateToVisiblePhotoCellsAnimated:YES];
    });
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dialogueItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"groupDialogue"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"groupDialogue"];
    }
    cell.backgroundColor = UIColor.clearColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    for (UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }

    HangoDialogueItem *msg = _dialogueItems[indexPath.row];
    BOOL outgoing = msg.isOutgoing;

    UIImageView *avatar = [HangoDesignKit avatarForDialogueItem:msg size:kHangoGroupDialogueAvatarSize bordered:NO];
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
                make.width.height.hgx_equalTo(kHangoGroupDialogueAvatarSize);
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
                make.width.height.hgx_equalTo(kHangoGroupDialogueAvatarSize);
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
    if (msg.itemType == HangoDialogueItemTypeAudio) {
        bubble.backgroundColor = [HangoTheme primaryDarkColor];
    } else {
        bubble.backgroundColor = UIColor.whiteColor;
    }
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
            make.width.height.hgx_equalTo(kHangoGroupDialogueAvatarSize);
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
        [self applyOutgoingVoiceRippleIfNeededForItem:msg bubble:bubble];
    } else {
        [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(cell.contentView).offset(8);
            make.left.equalTo(cell.contentView).offset(16);
            make.width.height.hgx_equalTo(kHangoGroupDialogueAvatarSize);
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

- (void)openPeople {
    HangoAllPeopleViewController *vc = [[HangoAllPeopleViewController alloc] init];
    vc.party = self.party;
    [self.navigationController pushViewController:vc animated:YES];
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

- (void)appendOutgoingImageItemWithImagePath:(NSString *)imagePath {
    if (![self requireLoginForAction]) {
        return;
    }
    if (imagePath.length == 0) {
        return;
    }

    HangoDialogueItem *msg = [[HangoDialogueItem alloc] init];
    msg.itemId = [[NSUUID UUID] UUIDString];
    msg.senderName = [HangoDataStore shared].currentPersona.name;
    msg.senderAvatarName = [HangoDataStore shared].currentPersona.avatarName;
    msg.content = imagePath;
    msg.timeText = [self formattedItemTime];
    msg.itemType = HangoDialogueItemTypeImage;
    msg.isOutgoing = YES;

    [[HangoDataStore shared] appendPartyDialogueItem:msg partyId:self.party.partyId];
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

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    [picker dismissViewControllerAnimated:YES completion:^{
        if (!image || self.party.partyId.length == 0) {
            return;
        }
        NSString *imagePath = [[HangoDataStore shared] savePartyRecordPhotoImage:image partyId:self.party.partyId];
        if (imagePath.length == 0) {
            return;
        }
        [self appendOutgoingImageItemWithImagePath:imagePath];
        [self reloadPhotos];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
