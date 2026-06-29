#import "HangoHomeViewController.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPartyCardView.h"
#import "HangoRecordDetailViewController.h"
#import "HangoHostedPartiesViewController.h"
#import <Masonry/Masonry.h>

@implementation HangoHomeViewController {
    UIScrollView *_scrollView;
    UIView *_scrollContent;
    UIStackView *_partyStack;
    UIStackView *_albumStack;
}

- (void)viewDidLoad {
    self.tabIndex = HangoTabIndexHome;
    [super viewDidLoad];
}

- (void)setupUI {
    [super setupUI];

    _scrollView = [[UIScrollView alloc] init];
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.contentView addSubview:_scrollView];

    _scrollContent = [[UIView alloc] init];
    [_scrollView addSubview:_scrollContent];

    UILabel *recentTitle = [HangoDesignKit titleLabel:@"Recent Parties Attended"];
    [_scrollContent addSubview:recentTitle];

    UIButton *gridBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [gridBtn setImage:[[HangoTheme imageNamed:@"home_grid_top_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [gridBtn addTarget:self action:@selector(openHosted) forControlEvents:UIControlEventTouchUpInside];
    [_scrollContent addSubview:gridBtn];

    UILabel *albumTitle = [HangoDesignKit subtitleLabel:@"Party Photo Album"];
    [_scrollContent addSubview:albumTitle];

    UILabel *books = [HangoDesignKit linkLabel:@"<16 books>"];
    [_scrollContent addSubview:books];

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

    [_scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    [_scrollContent mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_scrollView);
        make.width.equalTo(_scrollView);
    }];
    [recentTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_scrollContent).offset(8);
        make.left.equalTo(_scrollContent).offset(20);
        make.right.lessThanOrEqualTo(gridBtn.mas_left).offset(-8);
    }];
    [gridBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(recentTitle);
        make.right.equalTo(_scrollContent).offset(-20);
        make.width.height.mas_equalTo(28);
    }];
    [albumTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(recentTitle.mas_bottom).offset(18);
        make.left.equalTo(recentTitle);
    }];
    [books mas_makeConstraints:^(MASConstraintMaker *make) {
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
        make.left.equalTo(recentTitle);
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadData];
}

- (void)loadData {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [HangoDataStore shared].upcomingParties;
    } completion:^(id result, NSError *error) {
        [self reloadAlbums];
        [self reloadParties:result];
    }];
}

- (void)reloadAlbums {
    for (UIView *v in _albumStack.arrangedSubviews) {
        [_albumStack removeArrangedSubview:v];
        [v removeFromSuperview];
    }

    NSArray<HangoAlbumItem *> *items = [HangoDataStore shared].albumItems;
    NSInteger count = MIN(items.count, 3);
    for (NSInteger i = 0; i < count; i++) {
        HangoAlbumItem *item = items[i];
        UIView *card = [HangoDesignKit albumCardWithImageName:item.imageName dateText:item.dateText];
        card.userInteractionEnabled = YES;
        [card addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(openRecord)]];
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
        __weak typeof(self) weakSelf = self;
        card.onReceive = ^{
            [weakSelf openRecordForParty:party];
        };
        [card mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(188); }];
        [_partyStack addArrangedSubview:card];
    }
}

- (void)openRecord {
    [self openRecordForParty:[HangoDataStore shared].upcomingParties.firstObject];
}

- (void)openRecordForParty:(HangoParty *)party {
    HangoRecordDetailViewController *vc = [[HangoRecordDetailViewController alloc] init];
    vc.party = party;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openHosted {
    [self.navigationController pushViewController:[[HangoHostedPartiesViewController alloc] init] animated:YES];
}

@end
