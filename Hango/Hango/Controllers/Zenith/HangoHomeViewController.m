#import "HangoHomeViewController.h"
#import "HangoAlbumItem.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPartyCardView.h"
#import "HangoRecordDetailViewController.h"
#import "HangoHostedPartiesViewController.h"
#import "HangoAttendedPartiesViewController.h"
#import "HangoUpcomingPartiesViewController.h"
#import "HGXAnchor.h"

static const NSInteger kHangoHomeBooksLabelTag = 58301;
static const NSInteger kHangoHomeAlbumDisplayCount = 3;
static const CGFloat kHangoHomeAlbumSectionHeight = 140.0;
static const CGFloat kHangoHomeAlbumHorizontalInset = 40.0;
static const CGFloat kHangoHomeAlbumMaskHorizontalInset = 20.0;
static const CGFloat kHangoHomeAlbumMaskHeight = 62.0;
static const CGFloat kHangoHomeAlbumMaskBottomOverflow = 8.0;
static const CGFloat kHangoHomePartySectionCornerRadius = 30.0;
static const CGFloat kHangoHomePartySectionVerticalInset = 27.0;
static const CGFloat kHangoHomePartySectionHorizontalInset = 20.0;

@implementation HangoHomeViewController {
    UIView *_headerBar;
    UILabel *_recentTitleLabel;
    UIScrollView *_scrollView;
    UIView *_scrollContent;
    UIView *_partySectionContainer;
    UIStackView *_partyStack;
    UIStackView *_albumStack;
    UIView *_albumSection;
    UIView *_albumMaskOverlay;
    UIButton *_hostedPartiesButton;
    NSArray<HangoAlbumItem *> *_albumItems;
    NSArray<HangoParty *> *_upcomingParties;
}

- (void)viewDidLoad {
    self.tabIndex = HangoTabIndexHome;
    [super viewDidLoad];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(deniedContactsDidChange) name:HangoDeniedContactsDidChangeNotification object:nil];
}

- (void)dealloc {
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)deniedContactsDidChange {
    if (!self.isViewLoaded) {
        return;
    }
    [self updateBooksLabel];
    [self loadData];
}

- (void)setupUI {
    [super setupUI];

    _headerBar = [[UIView alloc] init];
    _headerBar.backgroundColor = UIColor.clearColor;
    [self.contentView addSubview:_headerBar];

    _recentTitleLabel = [HangoDesignKit titleLabel:@"Recent Parties Attended"];
    [_headerBar addSubview:_recentTitleLabel];

    _hostedPartiesButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_hostedPartiesButton setImage:[[HangoTheme imageNamed:@"home_grid_top_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    _hostedPartiesButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_hostedPartiesButton addTarget:self action:@selector(openHosted) forControlEvents:UIControlEventTouchUpInside];
    [_headerBar addSubview:_hostedPartiesButton];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.contentView addSubview:_scrollView];

    _scrollContent = [[UIView alloc] init];
    [_scrollView addSubview:_scrollContent];

    UILabel *albumTitle = [HangoDesignKit subtitleLabel:@"Party Photo Album"];
    [_scrollContent addSubview:albumTitle];

    UILabel *booksLabel = [HangoDesignKit linkLabel:[self homeBooksLabelText]];
    booksLabel.tag = kHangoHomeBooksLabelTag;
    booksLabel.userInteractionEnabled = YES;
    [booksLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openAttended)]];
    [_scrollContent addSubview:booksLabel];

    _albumSection = [[UIView alloc] init];
    [_scrollContent addSubview:_albumSection];

    _albumStack = [[UIStackView alloc] init];
    _albumStack.axis = UILayoutConstraintAxisHorizontal;
    _albumStack.distribution = UIStackViewDistributionFillEqually;
    _albumStack.alignment = UIStackViewAlignmentFill;
    _albumStack.spacing = 12;
    [_albumSection addSubview:_albumStack];

    _albumMaskOverlay = [HangoDesignKit homeAlbumMaskOverlayView];
    [_scrollContent addSubview:_albumMaskOverlay];

    UILabel *upcomingTitle = [[UILabel alloc] init];
    upcomingTitle.text = @"Upcoming Parties";
    upcomingTitle.font = [UIFont boldSystemFontOfSize:20];
    upcomingTitle.textColor = [HangoTheme primaryDarkColor];
    [_scrollContent addSubview:upcomingTitle];

    UIImageView *partyIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"upcoming_parties_icon"]];
    partyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_scrollContent addSubview:partyIcon];

    UILabel *allLabel = [HangoDesignKit linkLabel:@"<All>"];
    allLabel.userInteractionEnabled = YES;
    [allLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openUpcomingAll)]];
    [_scrollContent addSubview:allLabel];

    _partySectionContainer = [[UIView alloc] init];
    _partySectionContainer.backgroundColor = [UIColor colorWithRed:242.0 / 255.0 green:249.0 / 255.0 blue:255.0 / 255.0 alpha:1.0];
    _partySectionContainer.layer.cornerRadius = kHangoHomePartySectionCornerRadius;
    _partySectionContainer.clipsToBounds = YES;
    [_scrollContent addSubview:_partySectionContainer];

    _partyStack = [[UIStackView alloc] init];
    _partyStack.axis = UILayoutConstraintAxisVertical;
    _partyStack.spacing = 12;
    [_partySectionContainer addSubview:_partyStack];

    [_headerBar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.hgx_equalTo(52);
    }];
    [_recentTitleLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_headerBar).offset(20);
        make.centerY.equalTo(_headerBar);
        make.right.lessThanOrEqualTo(_hostedPartiesButton.hgx_left).offset(-8);
    }];
    [_hostedPartiesButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(_headerBar);
        make.right.equalTo(_headerBar).offset(-20);
        make.width.height.hgx_equalTo(44);
    }];
    [_scrollView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_headerBar.hgx_bottom);
        make.left.right.bottom.equalTo(self.contentView);
    }];
    [_scrollContent hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];
    [albumTitle hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_scrollContent).offset(8);
        make.left.equalTo(_scrollContent).offset(20);
    }];
    [booksLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(albumTitle);
        make.right.equalTo(_scrollContent).offset(-20);
    }];
    [_albumSection hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(albumTitle.hgx_bottom).offset(12);
        make.left.equalTo(_scrollContent).offset(kHangoHomeAlbumHorizontalInset);
        make.right.equalTo(_scrollContent).offset(-kHangoHomeAlbumHorizontalInset);
        make.height.hgx_equalTo(kHangoHomeAlbumSectionHeight);
    }];
    [_albumStack hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(_albumSection);
    }];
    [_albumMaskOverlay hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(_scrollContent).offset(kHangoHomeAlbumMaskHorizontalInset);
        make.right.equalTo(_scrollContent).offset(-kHangoHomeAlbumMaskHorizontalInset);
        make.height.hgx_equalTo(kHangoHomeAlbumMaskHeight);
        make.bottom.equalTo(_albumSection.hgx_bottom).offset(kHangoHomeAlbumMaskBottomOverflow);
    }];
    [upcomingTitle hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_albumSection.hgx_bottom).offset(22);
        make.left.equalTo(partyIcon.hgx_right).offset(6);
    }];
    [partyIcon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(upcomingTitle);
        make.left.equalTo(_scrollContent).offset(20);
        make.width.height.hgx_equalTo(22);
    }];
    [allLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(upcomingTitle);
        make.right.equalTo(_scrollContent).offset(-20);
    }];
    [_partySectionContainer hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(upcomingTitle.hgx_bottom).offset(12);
        make.left.right.equalTo(_scrollContent);
        make.bottom.equalTo(_scrollContent).offset(-12);
    }];
    [_partyStack hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_partySectionContainer).offset(kHangoHomePartySectionVerticalInset);
        make.left.equalTo(_partySectionContainer).offset(kHangoHomePartySectionHorizontalInset);
        make.right.equalTo(_partySectionContainer).offset(-kHangoHomePartySectionHorizontalInset);
        make.bottom.equalTo(_partySectionContainer).offset(-kHangoHomePartySectionVerticalInset);
    }];

    [self loadData];
}

- (NSString *)homeBooksLabelText {
    NSArray<HangoParty *> *parties = [HangoDataStore shared].visibleAttendedParties;
    NSInteger attendedCount = parties.count;
    return [NSString stringWithFormat:@"<%ldbooks>", (long)attendedCount];
}

- (void)updateBooksLabel {
    if (!_scrollContent) {
        return;
    }
    UIView *booksView = [_scrollContent viewWithTag:kHangoHomeBooksLabelTag];
    if (![booksView isKindOfClass:[UILabel class]]) {
        return;
    }
    ((UILabel *)booksView).text = [self homeBooksLabelText];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBooksLabel];
    [self loadData];
}

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:NO operation:^id {
        return [HangoDataStore shared].visibleUpcomingParties;
    } completion:^(id result, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.isViewLoaded) {
            return;
        }
        [strongSelf reloadAlbums];
        [strongSelf reloadParties:result];
    }];
}

- (void)reloadAlbums {
    for (UIView *v in _albumStack.arrangedSubviews) {
        [_albumStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    _albumItems = [HangoDataStore shared].visibleAlbumItems;
    NSInteger displayCount = MIN((NSInteger)_albumItems.count, kHangoHomeAlbumDisplayCount);
    for (NSInteger i = 0; i < displayCount; i++) {
        HangoAlbumItem *item = _albumItems[i];
        UIImage *coverImage = nil;
        if (item.partyId.length > 0) {
            coverImage = [[HangoDataStore shared] latestPartyRecordPhotoImageForPartyId:item.partyId];
        }
        UIView *card = [HangoDesignKit albumCardWithImage:coverImage fallbackImageName:item.imageName dateText:item.dateText];
        card.userInteractionEnabled = YES;
        card.tag = i;
        [card addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openRecordFromAlbum:)]];
        [_albumStack addArrangedSubview:card];
    }
}

- (void)reloadParties:(NSArray<HangoParty *> *)parties {
    _upcomingParties = parties;
    for (UIView *v in _partyStack.arrangedSubviews) {
        [_partyStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    for (NSInteger i = 0; i < (NSInteger)parties.count; i++) {
        HangoParty *party = parties[i];
        HangoPartyCardView *card = [[HangoPartyCardView alloc] init];
        [card configureWithParty:party];
        card.userInteractionEnabled = YES;
        card.tag = i;
        [card addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(partyCardTapped:)]];
        [_partyStack addArrangedSubview:card];
    }
}

- (void)partyCardTapped:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    if (index < 0 || index >= (NSInteger)_upcomingParties.count) {
        return;
    }
    [self openRecordForParty:_upcomingParties[index]];
}

- (void)openRecordFromAlbum:(UITapGestureRecognizer *)gesture {
    NSInteger index = gesture.view.tag;
    HangoParty *party = nil;
    if (index >= 0 && index < _albumItems.count) {
        NSString *partyId = _albumItems[index].partyId;
        if (partyId.length > 0) {
            party = [[HangoDataStore shared] partyWithId:partyId];
        }
    }
    if (!party) {
        party = [HangoDataStore shared].upcomingParties.firstObject;
    }
    [self openRecordForParty:party];
}

- (void)openRecordForParty:(HangoParty *)party {
    HangoRecordDetailViewController *vc = [[HangoRecordDetailViewController alloc] init];
    vc.party = party;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openHosted {
    if (![self requireLoginForAction]) {
        return;
    }
    HangoHostedPartiesViewController *vc = [[HangoHostedPartiesViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openUpcomingAll {
    HangoUpcomingPartiesViewController *vc = [[HangoUpcomingPartiesViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openAttended {
    if (![self requireLoginForAction]) {
        return;
    }
    HangoAttendedPartiesViewController *vc = [[HangoAttendedPartiesViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
