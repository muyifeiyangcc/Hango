#import "HangoDisplayString.h"
#import "HangoAllPeopleViewController.h"
#import "HangoParty.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPrivateDialogueViewController.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

@interface HangoAllPeopleViewController () <UICollectionViewDelegateFlowLayout>
@end

@implementation HangoAllPeopleViewController {
    UICollectionView *_collectionView;
    NSArray<HangoContact *> *_people;
}

static const CGFloat kAllPeopleHorizontalInset = 16.0;
static const CGFloat kAllPeopleColumnSpacing = 12.0;
static const CGFloat kAllPeopleRowSpacing = 14.0;
static const CGFloat kAllPeopleCardHeight = 214.0;
static const CGFloat kAllPeopleActionButtonHeight = 36.0;

- (UIButton *)actionButtonWithTitle:(NSString *)title style:(HangoPillButtonStyle)style {
    UIButton *button = [HangoDesignKit pillButtonWithTitle:title style:style];
    button.layer.cornerRadius = kAllPeopleActionButtonHeight / 2.0;
    button.titleLabel.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightSemibold];
    if (style == HangoPillButtonStyleAccent) {
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
    return button;
}

- (void)setupUI {
    self.showsBackButton = YES;
    self.navTitleText = @"All personnel";

    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.minimumInteritemSpacing = kAllPeopleColumnSpacing;
    layout.minimumLineSpacing = kAllPeopleRowSpacing;
    layout.sectionInset = UIEdgeInsetsMake(8, kAllPeopleHorizontalInset, 16, kAllPeopleHorizontalInset);

    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    _collectionView.backgroundColor = UIColor.clearColor;
    _collectionView.dataSource = (id<UICollectionViewDataSource>)self;
    _collectionView.delegate = (id<UICollectionViewDelegateFlowLayout>)self;
    [_collectionView registerClass:UICollectionViewCell.class forCellWithReuseIdentifier:@"cell"];
    [self.contentView addSubview:_collectionView];

    [_collectionView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(deniedContactsDidChange) name:HangoDeniedContactsDidChangeNotification object:nil];
    [self loadPeople];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)deniedContactsDidChange {
    if (!self.isViewLoaded) {
        return;
    }
    [self loadPeople];
}

- (void)loadPeople {
    if (self.party) {
        _people = [[HangoDataStore shared] contactsForParty:self.party];
    } else {
        _people = [HangoDataStore shared].visibleContacts;
    }
    [_collectionView reloadData];
}

- (CGFloat)cardWidthForCollectionView:(UICollectionView *)collectionView {
    CGFloat totalWidth = CGRectGetWidth(collectionView.bounds);
    if (totalWidth <= 0) {
        totalWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    }
    return floor((totalWidth - kAllPeopleHorizontalInset * 2 - kAllPeopleColumnSpacing) / 2.0);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _people.count;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                    layout:(UICollectionViewLayout *)collectionViewLayout
    sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake([self cardWidthForCollectionView:collectionView], kAllPeopleCardHeight);
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 18;
    [HangoDesignKit applyCardShadow:card];
    [cell.contentView addSubview:card];

    HangoContact *contact = _people[indexPath.item];
    HangoDataStore *store = [HangoDataStore shared];
    BOOL tracked = [store isContactInList:contact];
    BOOL isSelf = [store isCurrentPersonaContact:contact];
    if (!isSelf && self.party.isHosted &&
        [self.party.hostName isEqualToString:store.currentPersona.name] &&
        [contact.name isEqualToString:self.party.hostName]) {
        isSelf = YES;
    }

    UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:56 bordered:NO];
    avatar.userInteractionEnabled = NO;
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = contact.name;
    name.font = [HangoTheme monoFont];
    name.textAlignment = NSTextAlignmentCenter;
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UIButton *trackButton = nil;
    UIButton *dialogueButton = nil;
    if (!isSelf) {
        NSString *trackTitle = tracked ? HangoDisplayString(HangoDisplayStringKeyUnfollow) : HangoDisplayString(HangoDisplayStringKeyFollow);
        trackButton = [self actionButtonWithTitle:trackTitle style:HangoPillButtonStyleAccent];
        trackButton.tag = indexPath.item;
        [trackButton addTarget:self action:@selector(trackTapped:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:trackButton];

        dialogueButton = [self actionButtonWithTitle:HangoDisplayString(HangoDisplayStringKeyMessage) style:HangoPillButtonStyleDark];
        dialogueButton.tag = indexPath.item;
        [dialogueButton addTarget:self action:@selector(openDialogueTapped:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:dialogueButton];
    }

    [card hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(cell.contentView);
    }];
    [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.centerX.equalTo(card);
        make.width.height.hgx_equalTo(56);
    }];
    [name hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(avatar.hgx_bottom).offset(8);
        make.left.right.equalTo(card).inset(10);
        if (!isSelf) {
            make.bottom.lessThanOrEqualTo(card).offset(-14);
        } else {
            make.bottom.equalTo(card).offset(-14);
        }
    }];
    if (dialogueButton) {
        [dialogueButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.equalTo(card).offset(12);
            make.right.equalTo(card).offset(-12);
            make.bottom.equalTo(card).offset(-14);
            make.height.hgx_equalTo(kAllPeopleActionButtonHeight);
        }];
    }
    if (trackButton) {
        [trackButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
            make.left.right.height.equalTo(dialogueButton);
            make.bottom.equalTo(dialogueButton.hgx_top).offset(-8);
            make.top.greaterThanOrEqualTo(name.hgx_bottom).offset(12);
        }];
    }
    return cell;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPeople];
}

- (void)trackTapped:(UIButton *)sender {
    if (![self requireLoginForAction]) {
        return;
    }
    if (sender.tag < 0 || sender.tag >= (NSInteger)_people.count) {
        return;
    }

    HangoContact *contact = _people[sender.tag];
    BOOL tracked = [[HangoDataStore shared] isContactInList:contact];
    sender.enabled = NO;

    [MBProgressHUD showActivityMessageInWindow:@""];
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUD];
        sender.enabled = YES;

        HangoDataStore *store = [HangoDataStore shared];
        BOOL success = tracked ? [store untrackContact:contact] : [store trackContact:contact];
        if (!success) {
            return;
        }

        [MBProgressHUD showSuccessMessage:tracked ? HangoDisplayString(HangoDisplayStringKeyUnfollowedSuccessfully) : HangoDisplayString(HangoDisplayStringKeyFollowedSuccessfully)];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
        [strongSelf->_collectionView reloadItemsAtIndexPaths:@[indexPath]];
    });
}

- (void)openDialogueTapped:(UIButton *)sender {
    if (![self requireLoginForAction]) {
        return;
    }
    if (sender.tag < 0 || sender.tag >= (NSInteger)_people.count) {
        return;
    }
    HangoContact *contact = _people[sender.tag];
    HangoPrivateDialogueViewController *vc = [[HangoPrivateDialogueViewController alloc] init];
    vc.contact = contact;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
