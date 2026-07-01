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
#import "HangoPermissionManager.h"
#import "Masonry.h"

static const NSInteger kHangoHomeBooksLabelTag = 58301;

@implementation HangoHomeViewController {
    UIView *_headerBar;
    UILabel *_recentTitleLabel;
    UIScrollView *_scrollView;
    UIView *_scrollContent;
    UIStackView *_partyStack;
    UIStackView *_albumStack;
    UIButton *_hostedPartiesButton;
    NSArray<HangoAlbumItem *> *_albumItems;
    BOOL _didRequestLocationPermission;
}

- (void)viewDidLoad {
    self.tabIndex = HangoTabIndexHome;
    [super viewDidLoad];
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

    _albumStack = [[UIStackView alloc] init];
    _albumStack.axis = UILayoutConstraintAxisHorizontal;
    _albumStack.distribution = UIStackViewDistributionFillEqually;
    _albumStack.alignment = UIStackViewAlignmentFill;
    _albumStack.spacing = 12;
    [_scrollContent addSubview:_albumStack];

    UILabel *upcomingTitle = [[UILabel alloc] init];
    upcomingTitle.text = @"Upcoming Parties";
    upcomingTitle.font = [UIFont boldSystemFontOfSize:20];
    upcomingTitle.textColor = [HangoTheme primaryDarkColor];
    [_scrollContent addSubview:upcomingTitle];

    UIImageView *partyIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"artboard_55"]];
    partyIcon.contentMode = UIViewContentModeScaleAspectFit;
    [_scrollContent addSubview:partyIcon];

    UILabel *allLabel = [HangoDesignKit linkLabel:@"<All>"];
    allLabel.userInteractionEnabled = YES;
    [allLabel addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openHosted)]];
    [_scrollContent addSubview:allLabel];

    _partyStack = [[UIStackView alloc] init];
    _partyStack.axis = UILayoutConstraintAxisVertical;
    _partyStack.spacing = 14;
    [_scrollContent addSubview:_partyStack];

    [_headerBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.mas_equalTo(52);
    }];
    [_recentTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_headerBar).offset(20);
        make.centerY.equalTo(_headerBar);
        make.right.lessThanOrEqualTo(_hostedPartiesButton.mas_left).offset(-8);
    }];
    [_hostedPartiesButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_headerBar);
        make.right.equalTo(_headerBar).offset(-20);
        make.width.height.mas_equalTo(44);
    }];
    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_headerBar.mas_bottom);
        make.left.right.bottom.equalTo(self.contentView);
    }];
    [_scrollContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];
    [albumTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_scrollContent).offset(8);
        make.left.equalTo(_scrollContent).offset(20);
    }];
    [booksLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(albumTitle);
        make.right.equalTo(_scrollContent).offset(-20);
    }];
    [_albumStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(albumTitle.mas_bottom).offset(12);
        make.left.equalTo(_scrollContent).offset(20);
        make.right.equalTo(_scrollContent).offset(-20);
        make.height.mas_equalTo(140);
    }];
    [upcomingTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_albumStack.mas_bottom).offset(22);
        make.left.equalTo(partyIcon.mas_right).offset(6);
    }];
    [partyIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(upcomingTitle);
        make.left.equalTo(_scrollContent).offset(20);
        make.width.height.mas_equalTo(22);
    }];
    [allLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(upcomingTitle);
        make.right.equalTo(_scrollContent).offset(-20);
    }];
    [_partyStack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(upcomingTitle.mas_bottom).offset(12);
        make.left.equalTo(_scrollContent).offset(16);
        make.right.equalTo(_scrollContent).offset(-16);
        make.bottom.equalTo(_scrollContent).offset(-12);
    }];

    [self loadData];
}

- (NSString *)homeBooksLabelText {
    NSArray<HangoParty *> *parties = [HangoDataStore shared].attendedParties;
    NSInteger attendedCount = parties.count;
    return [NSString stringWithFormat:@"<%ld books>", (long)attendedCount];
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_didRequestLocationPermission) {
        _didRequestLocationPermission = YES;
        [HangoPermissionManager requestPermission:HangoPermissionTypeLocation fromViewController:self completion:nil];
    }
}

- (void)loadData {
    __weak typeof(self) weakSelf = self;
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:NO operation:^id {
        return [HangoDataStore shared].upcomingParties;
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

    _albumItems = [HangoDataStore shared].albumItems;
    for (NSInteger i = 0; i < (NSInteger)_albumItems.count; i++) {
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
    for (UIView *v in _partyStack.arrangedSubviews) {
        [_partyStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }
    for (HangoParty *party in parties) {
        HangoPartyCardView *card = [[HangoPartyCardView alloc] init];
        [card configureWithParty:party];
        [_partyStack addArrangedSubview:card];
    }
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
    HangoHostedPartiesViewController *vc = [[HangoHostedPartiesViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openAttended {
    HangoAttendedPartiesViewController *vc = [[HangoAttendedPartiesViewController alloc] init];
    vc.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
