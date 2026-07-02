#import "HangoUpcomingPartiesViewController.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPartyCardView.h"
#import "HangoRecordDetailViewController.h"
#import "HGXAnchor.h"

static const CGFloat kUpcomingPartyCardEstimatedHeight = 202.0;

@implementation HangoUpcomingPartiesViewController {
    UITableView *_tableView;
    UIView *_emptyView;
    NSArray<HangoParty *> *_parties;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [[UILabel alloc] init];
    title.text = @"Upcoming Parties";
    UIFontDescriptor *descriptor = [[UIFont boldSystemFontOfSize:22].fontDescriptor
        fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    title.font = [UIFont fontWithDescriptor:descriptor size:22];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [HangoTheme primaryDarkColor];
    [self.contentView addSubview:title];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = kUpcomingPartyCardEstimatedHeight;
    [self.contentView addSubview:_tableView];

    _emptyView = [[UIView alloc] init];
    _emptyView.hidden = YES;
    [self.contentView addSubview:_emptyView];

    UIImageView *emptyImage = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"empty_state_illustration"]];
    emptyImage.contentMode = UIViewContentModeScaleAspectFit;
    [_emptyView addSubview:emptyImage];

    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"There is no content here.";
    emptyLabel.font = [HangoTheme monoFont];
    emptyLabel.textColor = [HangoTheme primaryDarkColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.numberOfLines = 0;
    [_emptyView addSubview:emptyLabel];

    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.centerX.equalTo(self.contentView);
        make.left.greaterThanOrEqualTo(self.contentView).offset(56);
        make.right.lessThanOrEqualTo(self.contentView).offset(-20);
    }];
    [_tableView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(title.hgx_bottom).offset(16);
        make.left.right.bottom.equalTo(self.contentView);
    }];
    [_emptyView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.right.equalTo(self.contentView);
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView).offset(-70);
    }];
    [emptyImage hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.centerX.equalTo(_emptyView);
        make.width.hgx_equalTo(220);
        make.height.hgx_equalTo(180);
    }];
    [emptyLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(emptyImage.hgx_bottom).offset(16);
        make.left.right.equalTo(_emptyView).inset(32);
        make.bottom.equalTo(_emptyView);
    }];

    [self loadParties];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadParties];
}

- (void)loadParties {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:NO operation:^id {
        return [HangoDataStore shared].visibleUpcomingParties;
    } completion:^(id result, NSError *error) {
        self->_parties = result;
        BOOL isEmpty = self->_parties.count == 0;
        self->_emptyView.hidden = !isEmpty;
        self->_tableView.hidden = isEmpty;
        [self->_tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _parties.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"upcomingParty"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"upcomingParty"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }

    HangoParty *party = _parties[indexPath.row];
    HangoPartyCardView *card = [[HangoPartyCardView alloc] init];
    [card configureWithParty:party];
    [cell.contentView addSubview:card];
    [card hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(4);
        make.left.equalTo(cell.contentView).offset(16);
        make.right.equalTo(cell.contentView).offset(-16);
        make.bottom.equalTo(cell.contentView).offset(-10);
    }];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HangoRecordDetailViewController *vc = [[HangoRecordDetailViewController alloc] init];
    vc.party = _parties[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
