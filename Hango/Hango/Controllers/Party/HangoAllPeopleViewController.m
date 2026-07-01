#import "HangoAllPeopleViewController.h"
#import "HangoParty.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPrivateDialogueViewController.h"
#import "HangoHUD.h"
#import "Masonry.h"

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

    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadPeople];
}

- (void)loadPeople {
    if (self.party) {
        _people = [[HangoDataStore shared] contactsForParty:self.party];
    } else {
        _people = [HangoDataStore shared].contacts;
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
    BOOL tracked = [[HangoDataStore shared] isContactInList:contact];
    BOOL isSelf = [[HangoDataStore shared] isCurrentPersonaContact:contact];

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
    if (!isSelf) {
        NSString *trackTitle = tracked ? @"Untrack" : @"Track";
        trackButton = [self actionButtonWithTitle:trackTitle style:HangoPillButtonStyleAccent];
        trackButton.tag = indexPath.item;
        [trackButton addTarget:self action:@selector(trackTapped:) forControlEvents:UIControlEventTouchUpInside];
        [card addSubview:trackButton];
    }

    UIButton *dialogueButton = [self actionButtonWithTitle:@"Dialogue" style:HangoPillButtonStyleDark];
    dialogueButton.tag = indexPath.item;
    [dialogueButton addTarget:self action:@selector(openDialogueTapped:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:dialogueButton];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cell.contentView);
    }];
    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.centerX.equalTo(card);
        make.width.height.mas_equalTo(56);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(avatar.mas_bottom).offset(8);
        make.left.right.equalTo(card).inset(10);
    }];
    [dialogueButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(12);
        make.right.equalTo(card).offset(-12);
        make.bottom.equalTo(card).offset(-14);
        make.height.mas_equalTo(kAllPeopleActionButtonHeight);
    }];
    if (trackButton) {
        [trackButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.height.equalTo(dialogueButton);
            make.bottom.equalTo(dialogueButton.mas_top).offset(-8);
        }];
    } else {
        [dialogueButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.greaterThanOrEqualTo(name.mas_bottom).offset(12);
        }];
    }
    return cell;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadPeople];
}

- (void)trackTapped:(UIButton *)sender {
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

        [MBProgressHUD showSuccessMessage:tracked ? @"Untracked successfully" : @"Tracked successfully"];
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
        [strongSelf->_collectionView reloadItemsAtIndexPaths:@[indexPath]];
    });
}

- (void)openDialogueTapped:(UIButton *)sender {
    if (sender.tag < 0 || sender.tag >= (NSInteger)_people.count) {
        return;
    }
    HangoContact *contact = _people[sender.tag];
    HangoPrivateDialogueViewController *vc = [[HangoPrivateDialogueViewController alloc] init];
    vc.contact = contact;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
