#import "HangoDisplayString.h"
#import "HangoRecordDetailViewController.h"
#import "HangoParty.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoDecoratePhotoViewController.h"
#import "HangoGroupDialogueViewController.h"
#import "HangoReportDetailViewController.h"
#import "HangoRequestManager.h"
#import "HangoHUD.h"
#import "HangoPermissionManager.h"
#import "HGXAnchor.h"

static NSString * const kHangoRecordPhotoCellId = @"HangoRecordPhotoCell";
static CGFloat const kHangoRecordPhotoCornerRadius = 24.0;
static CGFloat const kHangoRecordPhotoWidthRatio = 0.72;
static CGFloat const kHangoRecordPhotoCarouselTopInset = 20.0;
static CGFloat const kHangoRecordPhotoRegionBottomGap = 32.0;
static CGFloat const kHangoRecordPhotoAspectRatio = 1.30;
static CGFloat const kHangoRecordPhotoFocusedHeightRatio = 1.0;
static CGFloat const kHangoRecordPhotoSideHeightRatio = 0.82;

@interface HangoRecordPhotoCell : UICollectionViewCell
@property (nonatomic, strong) UIImageView *photoView;
@property (nonatomic, strong) UIButton *moreButton;
@property (nonatomic, assign) BOOL photoFocused;
- (void)setPhotoFocused:(BOOL)focused animated:(BOOL)animated;
@end

@implementation HangoRecordPhotoCell {
    UIView *_photoClipContainer;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.contentView.backgroundColor = UIColor.clearColor;
        self.clipsToBounds = YES;
        self.contentView.clipsToBounds = YES;

        _photoClipContainer = [[UIView alloc] init];
        _photoClipContainer.backgroundColor = UIColor.whiteColor;
        _photoClipContainer.clipsToBounds = YES;
        _photoClipContainer.layer.cornerRadius = kHangoRecordPhotoCornerRadius;
        if (@available(iOS 13.0, *)) {
            _photoClipContainer.layer.cornerCurve = kCACornerCurveContinuous;
        }
        [self.contentView addSubview:_photoClipContainer];

        _photoView = [[UIImageView alloc] init];
        _photoView.contentMode = UIViewContentModeScaleAspectFill;
        _photoView.clipsToBounds = YES;
        _photoView.backgroundColor = UIColor.whiteColor;
        if (@available(iOS 13.0, *)) {
            _photoView.layer.cornerCurve = kCACornerCurveContinuous;
        }
        [_photoClipContainer addSubview:_photoView];

        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_moreButton setTitle:@"..." forState:UIControlStateNormal];
        [_moreButton setTitleColor:UIColor.blackColor forState:UIControlStateNormal];
        _moreButton.titleLabel.font = [UIFont boldSystemFontOfSize:22];
        _moreButton.backgroundColor = UIColor.clearColor;
        _moreButton.contentEdgeInsets = UIEdgeInsetsZero;
        [_photoClipContainer addSubview:_moreButton];

        [_photoClipContainer hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.right.bottom.equalTo(self.contentView);
            make.height.equalTo(self.contentView).multipliedBy(kHangoRecordPhotoSideHeightRatio);
        }];
        [_photoView hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.edges.equalTo(_photoClipContainer);
        }];
        [_moreButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.top.equalTo(_photoClipContainer).offset(12);
            make.right.equalTo(_photoClipContainer).offset(-12);
        }];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat radius = kHangoRecordPhotoCornerRadius;
    _photoClipContainer.layer.cornerRadius = radius;
    _photoView.layer.cornerRadius = radius;
    [_photoClipContainer bringSubviewToFront:_moreButton];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    [self applyPhotoFocused:NO animated:NO];
}

- (void)setPhotoFocused:(BOOL)focused animated:(BOOL)animated {
    [self applyPhotoFocused:focused animated:animated];
}

- (void)applyPhotoFocused:(BOOL)focused animated:(BOOL)animated {
    self.photoFocused = focused;
    CGFloat ratio = focused ? kHangoRecordPhotoFocusedHeightRatio : kHangoRecordPhotoSideHeightRatio;
    [_photoClipContainer hgx_remakeConstraints:^(HGXConstraintMaker *make) {
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

@interface HangoRecordDetailViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@end

@implementation HangoRecordDetailViewController {
    UIView *_descWrap;
    UILabel *_descLabel;
    UIView *_emptyStateView;
    UILabel *_hintLabel;
    UIView *_photoRegionView;
    UICollectionView *_photoCarousel;
    NSArray<UIImage *> *_photoImages;
    NSInteger _focusedPhotoIndex;
    NSInteger _photoActionIndex;
    UIButton *_uploadButton;
    UIButton *_dialogueButton;
    HGXConstraint *_photoRegionHeightConstraint;
}

static UIImage *HangoRecordScaledIcon(NSString *name, CGFloat side) {
    UIImage *image = [HangoTheme imageNamed:name];
    if (!image || side <= 0) {
        return image;
    }
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = UIScreen.mainScreen.scale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(side, side) format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        [image drawInRect:CGRectMake(0, 0, side, side)];
    }];
}

- (NSArray<NSString *> *)avatarNamesForParty:(HangoParty *)party {
    HangoDataStore *store = [HangoDataStore shared];
    NSMutableArray<NSString *> *names = [NSMutableArray array];
    if (party.hostAvatarName.length > 0 &&
        ![store isDeniedPersonWithName:party.hostName avatarName:party.hostAvatarName]) {
        [names addObject:party.hostAvatarName];
    }
    for (NSString *name in [store visibleMemberAvatarNamesForParty:party]) {
        if (names.count >= 5) {
            break;
        }
        if (![names containsObject:name]) {
            [names addObject:name];
        }
    }
    return names.copy;
}

- (UIButton *)outlinedCircleButtonWithImageName:(NSString *)imageName iconSize:(CGFloat)iconSize buttonSize:(CGFloat)buttonSize {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = UIColor.whiteColor;
    button.layer.cornerRadius = buttonSize / 2.0;
    button.layer.borderWidth = 1.2;
    button.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
    button.clipsToBounds = YES;
    UIImage *icon = HangoRecordScaledIcon(imageName, iconSize);
    [button setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    CGFloat inset = (buttonSize - iconSize) / 2.0;
    button.contentEdgeInsets = UIEdgeInsetsMake(inset, inset, inset, inset);
    return button;
}

- (UIButton *)outlinedUploadButton {
    UIButton *upload = [UIButton buttonWithType:UIButtonTypeCustom];
    upload.backgroundColor = UIColor.whiteColor;
    upload.layer.cornerRadius = 28;
    upload.layer.borderWidth = 1.2;
    upload.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
    upload.clipsToBounds = YES;

    UIImage *icon = HangoRecordScaledIcon(@"upload_photo_icon", 22);
    [upload setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [upload setTitle:@"Upload party photos" forState:UIControlStateNormal];
    [upload setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    upload.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    upload.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    upload.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 8);
    upload.titleEdgeInsets = UIEdgeInsetsMake(0, 8, 0, -8);
    [upload addTarget:self action:@selector(openDecorate) forControlEvents:UIControlEventTouchUpInside];
    return upload;
}

- (void)setupUI {
    self.showsBackButton = YES;
    if (!self.party) {
        self.party = [HangoDataStore shared].upcomingParties.firstObject;
    }

    UIStackView *avatars = [[UIStackView alloc] init];
    avatars.axis = UILayoutConstraintAxisHorizontal;
    avatars.alignment = UIStackViewAlignmentCenter;
    avatars.spacing = -14;
    for (NSString *name in [self avatarNamesForParty:self.party]) {
        UIImageView *img = [HangoDesignKit avatarWithName:name size:40 bordered:YES];
        [img hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.width.height.hgx_equalTo(40);
        }];
        [avatars addArrangedSubview:img];
    }
    avatars.userInteractionEnabled = NO;
    [self.contentView addSubview:avatars];

    _descWrap = [[UIView alloc] init];
    _descWrap.backgroundColor = [HangoTheme mintBubbleColor];
    _descWrap.layer.cornerRadius = 12;
    _descWrap.layer.borderWidth = 1.0;
    _descWrap.layer.borderColor = [UIColor colorWithWhite:0.82 alpha:1.0].CGColor;
    [self.contentView addSubview:_descWrap];

    _descLabel = [[UILabel alloc] init];
    _descLabel.numberOfLines = 0;
    _descLabel.font = [HangoTheme monoFont];
    _descLabel.textColor = [HangoTheme primaryDarkColor];
    _descLabel.textAlignment = NSTextAlignmentCenter;
    [_descWrap addSubview:_descLabel];

    _emptyStateView = [[UIView alloc] init];
    [self.contentView addSubview:_emptyStateView];

    UIImageView *fireworks = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"placeholder_fireworks"]];
    fireworks.contentMode = UIViewContentModeScaleAspectFit;
    [_emptyStateView addSubview:fireworks];

    UIImageView *wine = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"placeholder_wine"]];
    wine.contentMode = UIViewContentModeScaleAspectFit;
    [_emptyStateView addSubview:wine];

    _hintLabel = [[UILabel alloc] init];
    _hintLabel.text = @"Go upload the pictures you've recorded!";
    _hintLabel.font = [HangoTheme bodyFont];
    _hintLabel.textColor = [HangoTheme accentBlueColor];
    _hintLabel.textAlignment = NSTextAlignmentCenter;
    _hintLabel.numberOfLines = 0;
    [self.contentView addSubview:_hintLabel];

    _photoRegionView = [[UIView alloc] init];
    _photoRegionView.backgroundColor = UIColor.clearColor;
    _photoRegionView.clipsToBounds = YES;
    [self.contentView addSubview:_photoRegionView];

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    layout.minimumLineSpacing = 14;

    _photoCarousel = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _photoCarousel.backgroundColor = UIColor.clearColor;
    _photoCarousel.clipsToBounds = YES;
    _photoCarousel.showsHorizontalScrollIndicator = NO;
    _photoCarousel.decelerationRate = UIScrollViewDecelerationRateFast;
    _photoCarousel.dataSource = self;
    _photoCarousel.delegate = self;
    _photoCarousel.hidden = YES;
    [_photoCarousel registerClass:HangoRecordPhotoCell.class forCellWithReuseIdentifier:kHangoRecordPhotoCellId];
    [_photoRegionView addSubview:_photoCarousel];

    _uploadButton = [self outlinedUploadButton];
    _dialogueButton = [self outlinedCircleButtonWithImageName:@"group_chat_menu_icon" iconSize:30 buttonSize:56];
    [_dialogueButton addTarget:self action:@selector(openGroupDialogue) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_uploadButton];
    [self.contentView addSubview:_dialogueButton];

    [avatars hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(44);
        make.centerX.equalTo(self.contentView);
        make.height.hgx_equalTo(40);
    }];
    [_descWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(avatars.hgx_bottom).offset(16);
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
    }];
    [_descLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(_descWrap).insets(UIEdgeInsetsMake(14, 16, 14, 16));
    }];
    [_emptyStateView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_descWrap.hgx_bottom).offset(28);
        make.left.equalTo(self.contentView).offset(36);
        make.right.equalTo(self.contentView).offset(-36);
        make.bottom.lessThanOrEqualTo(_hintLabel.hgx_top).offset(-20);
    }];
    [fireworks hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.centerX.equalTo(_emptyStateView);
        make.width.lessThanOrEqualTo(_emptyStateView);
        make.height.hgx_equalTo(72);
    }];
    [wine hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(fireworks.hgx_bottom).offset(8);
        make.left.right.bottom.equalTo(_emptyStateView);
        make.height.hgx_lessThanOrEqualTo(220);
    }];
    [_photoRegionView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_descWrap.hgx_bottom).offset(kHangoRecordPhotoCarouselTopInset);
        make.left.right.equalTo(self.contentView);
        self->_photoRegionHeightConstraint = make.height.hgx_equalTo([self recordPhotoRegionHeight]);
    }];
    [_photoCarousel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(_photoRegionView);
    }];
    [_hintLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(28);
        make.right.equalTo(self.contentView).offset(-28);
        make.bottom.equalTo(_uploadButton.hgx_top).offset(-24);
    }];
    [_uploadButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.greaterThanOrEqualTo(_photoRegionView.hgx_bottom).offset(kHangoRecordPhotoRegionBottomGap);
        make.left.equalTo(self.contentView).offset(20);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-20);
        make.height.hgx_equalTo(56);
        make.right.equalTo(_dialogueButton.hgx_left).offset(-12);
    }];
    [_dialogueButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.equalTo(self.contentView).offset(-20);
        make.centerY.equalTo(_uploadButton);
        make.width.height.hgx_equalTo(56);
    }];

    [self refreshContent];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(deniedContactsDidChange) name:HangoDeniedContactsDidChangeNotification object:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)deniedContactsDidChange {
    if (!self.isViewLoaded) {
        return;
    }
    if ([[HangoDataStore shared] isPartyHostDenied:self.party]) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    [self refreshContent];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat height = [self recordPhotoRegionHeight];
    [_photoRegionHeightConstraint setOffset:height];
    [_photoCarousel.collectionViewLayout invalidateLayout];
}

- (CGFloat)recordPhotoRegionHeight {
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    if (viewWidth <= 0) {
        viewWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    }
    return viewWidth * kHangoRecordPhotoWidthRatio * kHangoRecordPhotoAspectRatio;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshContent];
}

- (CGFloat)recordPhotoItemWidthForCarousel:(UICollectionView *)collectionView {
    return CGRectGetWidth(collectionView.bounds) * kHangoRecordPhotoWidthRatio;
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
    [self applyFocusedStateToVisibleCellsAnimated:animated];
}

- (void)applyFocusedStateToVisibleCellsAnimated:(BOOL)animated {
    for (HangoRecordPhotoCell *cell in _photoCarousel.visibleCells) {
        NSIndexPath *indexPath = [_photoCarousel indexPathForCell:cell];
        if (!indexPath) {
            continue;
        }
        BOOL focused = (indexPath.item == _focusedPhotoIndex);
        [cell setPhotoFocused:focused animated:animated];
        cell.moreButton.hidden = !focused;
    }
}

- (HangoContact *)contactForReportingPartyPhoto {
    HangoDataStore *store = [HangoDataStore shared];
    NSString *hostName = self.party.hostName;
    for (HangoContact *contact in [store contactsForParty:self.party]) {
        if ([contact.name isEqualToString:hostName] && ![store isCurrentPersonaContact:contact]) {
            return contact;
        }
    }
    for (HangoContact *contact in [store contactsForParty:self.party]) {
        if (![store isCurrentPersonaContact:contact]) {
            return contact;
        }
    }
    return nil;
}

- (void)refreshContent {
    NSString *invitation = self.party.invitation ?: @"";
    _descLabel.text = [NSString stringWithFormat:@"\"%@\"", invitation];

    _photoImages = [[HangoDataStore shared] partyRecordPhotoImagesForPartyId:self.party.partyId];
    BOOL hasPhotos = _photoImages.count > 0;
    _emptyStateView.hidden = hasPhotos;
    _hintLabel.hidden = hasPhotos;
    _photoCarousel.hidden = !hasPhotos;
    _photoRegionView.hidden = !hasPhotos;

    if (hasPhotos) {
        [_photoCarousel reloadData];
        [_photoCarousel layoutIfNeeded];
        NSInteger lastIndex = _photoImages.count - 1;
        _focusedPhotoIndex = lastIndex;
        if (lastIndex >= 0) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForItem:lastIndex inSection:0];
            [_photoCarousel scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
        }
        [self applyFocusedStateToVisibleCellsAnimated:NO];
    }
}

#pragma mark - UICollectionView

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photoImages.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat width = [self recordPhotoItemWidthForCarousel:collectionView];
    CGFloat height = CGRectGetHeight(collectionView.bounds);
    return CGSizeMake(width, MAX(height, 1));
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout *)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    CGFloat width = CGRectGetWidth(collectionView.bounds);
    CGFloat itemWidth = width * kHangoRecordPhotoWidthRatio;
    CGFloat inset = MAX((width - itemWidth) / 2.0, 0);
    return UIEdgeInsetsMake(0, inset, 0, inset);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                           cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HangoRecordPhotoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kHangoRecordPhotoCellId forIndexPath:indexPath];
    cell.photoView.image = _photoImages[indexPath.item];
    BOOL focused = (indexPath.item == _focusedPhotoIndex);
    cell.moreButton.hidden = !focused;
    cell.moreButton.tag = indexPath.item;
    [cell.moreButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [cell.moreButton addTarget:self action:@selector(photoMoreTapped:) forControlEvents:UIControlEventTouchUpInside];
    [cell setPhotoFocused:(indexPath.item == _focusedPhotoIndex) animated:NO];
    return cell;
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
    [self applyFocusedStateToVisibleCellsAnimated:YES];
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
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)_photoCarousel.collectionViewLayout;
    CGFloat itemWidth = [self recordPhotoItemWidthForCarousel:_photoCarousel];
    CGFloat spacing = layout.minimumLineSpacing;
    if (itemWidth <= 0 || _photoImages.count == 0) {
        return;
    }
    NSInteger index = (NSInteger)lround(targetContentOffset->x / (itemWidth + spacing));
    index = MAX(0, MIN(index, (NSInteger)_photoImages.count - 1));
    targetContentOffset->x = index * (itemWidth + spacing);
    _focusedPhotoIndex = index;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self applyFocusedStateToVisibleCellsAnimated:YES];
    });
}

- (void)photoMoreTapped:(UIButton *)sender {
    if (![self requireLoginForAction]) {
        return;
    }
    NSInteger index = sender.tag;
    if (index < 0 || index >= (NSInteger)_photoImages.count) {
        return;
    }

    BOOL isOwnPhoto = [[HangoDataStore shared] isCurrentUserPartyRecordPhotoAtDisplayIndex:index partyId:self.party.partyId];
    if (isOwnPhoto) {
        [self presentDeletePhotoSheetForIndex:index fromView:sender];
        return;
    }

    __weak typeof(self) weakSelf = self;
    _photoActionIndex = index;
    [HangoDesignKit presentReportBlockActionSheetInView:self.view reportAction:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf openReportForPhotoAtIndex:strongSelf->_photoActionIndex];
    } blockAction:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [strongSelf blockContactForPhotoAtIndex:strongSelf->_photoActionIndex];
    }];
}

- (void)presentDeletePhotoSheetForIndex:(NSInteger)index fromView:(UIView *)sourceView {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self) weakSelf = self;
    [sheet addAction:[UIAlertAction actionWithTitle:@"Delete photo" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [weakSelf confirmDeletePhotoAtDisplayIndex:index];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        sheet.popoverPresentationController.sourceView = sourceView;
        sheet.popoverPresentationController.sourceRect = sourceView.bounds;
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)openReportForPhotoAtIndex:(NSInteger)index {
    HangoReportDetailViewController *vc = [[HangoReportDetailViewController alloc] init];
    vc.contact = [self contactForReportingPartyPhoto];
    if (index >= 0 && index < (NSInteger)_photoImages.count) {
        vc.prefilledPhoto = _photoImages[index];
    }
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)blockContactForPhotoAtIndex:(NSInteger)index {
    (void)index;
    HangoContact *contact = [self contactForReportingPartyPhoto];
    if (!contact || contact.isDenied) {
        return;
    }
    NSString *message = [NSString stringWithFormat:HangoDisplayString(HangoDisplayStringKeyBlockConfirmFormat), contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:HangoDisplayString(HangoDisplayStringKeyBlockQuestion)
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    NSString *contactId = contact.contactId;
    [alert addAction:[UIAlertAction actionWithTitle:HangoDisplayString(HangoDisplayStringKeyBlock) style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [[HangoDataStore shared] blockContactWithId:contactId];
            [MBProgressHUD showSuccessMessage:HangoDisplayString(HangoDisplayStringKeyBlockedSuccessfully)];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmDeletePhotoAtDisplayIndex:(NSInteger)index {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete photo?"
                                                                   message:@"This photo will be removed from the party record."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoDataStore shared] removePartyRecordPhotoAtDisplayIndex:index partyId:weakSelf.party.partyId];
        [weakSelf refreshContent];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openDecorate {
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
        if (!image) {
            return;
        }
        HangoDecoratePhotoViewController *vc = [[HangoDecoratePhotoViewController alloc] init];
        vc.party = self.party;
        vc.selectedImage = image;
        [self.navigationController pushViewController:vc animated:YES];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)openGroupDialogue {
    if (![self requireLoginForAction]) {
        return;
    }
    HangoGroupDialogueViewController *vc = [[HangoGroupDialogueViewController alloc] init];
    vc.party = self.party;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
