#import "HangoHostedPartiesViewController.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

static const CGFloat kHostedPartyCardHeight = 188.0;
static const CGFloat kHostedPartyDeleteButtonWidth = 88.0;
static const CGFloat kHostedPartyDeleteButtonHeight = 40.0;

@implementation HangoHostedPartiesViewController {
    UITableView *_tableView;
    UIView *_emptyView;
    NSArray<HangoParty *> *_parties;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [[UILabel alloc] init];
    title.text = @"The party I hosted";
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
        return [HangoDataStore shared].hostedParties;
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return kHostedPartyCardHeight + 14;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"hostedParty"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"hostedParty"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }

    HangoParty *party = _parties[indexPath.row];
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 18;
    [HangoDesignKit applyCardShadow:card];
    [cell.contentView addSubview:card];

    UILabel *time = [[UILabel alloc] init];
    time.text = [NSString stringWithFormat:@"%@ %@", party.timeText, party.dateText];
    time.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    time.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:time];

    UILabel *invite = [[UILabel alloc] init];
    invite.text = [NSString stringWithFormat:@"  %@  ", party.invitation];
    invite.font = [HangoTheme monoFont];
    invite.textColor = [HangoTheme primaryDarkColor];
    invite.numberOfLines = 2;
    invite.backgroundColor = [HangoTheme mintBubbleColor];
    invite.layer.cornerRadius = 10;
    invite.clipsToBounds = YES;
    [card addSubview:invite];

    UIImageView *pin = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"location_pin_icon"]];
    pin.contentMode = UIViewContentModeScaleAspectFit;
    [card addSubview:pin];

    UILabel *location = [[UILabel alloc] init];
    location.text = party.location;
    location.font = [HangoTheme captionFont];
    location.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:location];

    UIStackView *avatars = [[UIStackView alloc] init];
    avatars.axis = UILayoutConstraintAxisHorizontal;
    avatars.spacing = -10;
    [HangoDesignKit populatePartyMemberAvatarsInStack:avatars party:party size:30];
    [card addSubview:avatars];

    UIView *bottomRow = [[UIView alloc] init];
    [card addSubview:bottomRow];

    UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteButton.accessibilityIdentifier = party.partyId;
    UIImage *deleteIcon = [HangoTheme imageNamed:@"delete_party_button"];
    if (deleteIcon) {
        [deleteButton setImage:[deleteIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    deleteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    deleteButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    deleteButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [deleteButton addTarget:self action:@selector(deletePartyTapped:) forControlEvents:UIControlEventTouchUpInside];
    [bottomRow addSubview:deleteButton];
    [bottomRow addSubview:avatars];

    [card hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(4);
        make.left.equalTo(cell.contentView).offset(16);
        make.right.equalTo(cell.contentView).offset(-16);
        make.bottom.equalTo(cell.contentView).offset(-10);
        make.height.hgx_equalTo(kHostedPartyCardHeight);
    }];
    [time hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.left.equalTo(card).offset(14);
        make.right.equalTo(card).offset(-14);
    }];
    [invite hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(time.hgx_bottom).offset(10);
        make.left.equalTo(card).offset(14);
        make.right.equalTo(card).offset(-14);
        make.height.hgx_greaterThanOrEqualTo(44);
    }];
    [pin hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(invite.hgx_bottom).offset(10);
        make.left.equalTo(invite);
        make.width.height.hgx_equalTo(14);
    }];
    [location hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(pin);
        make.left.equalTo(pin.hgx_right).offset(4);
        make.right.lessThanOrEqualTo(card).offset(-14);
    }];
    [bottomRow hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(card).offset(14);
        make.right.equalTo(card).offset(-14);
        make.bottom.equalTo(card).offset(-14);
        make.height.hgx_equalTo(kHostedPartyDeleteButtonHeight);
    }];
    [avatars hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.centerY.equalTo(bottomRow);
    }];
    [deleteButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.centerY.equalTo(bottomRow);
        make.width.hgx_equalTo(kHostedPartyDeleteButtonWidth);
        make.height.hgx_equalTo(kHostedPartyDeleteButtonHeight);
    }];

    return cell;
}

- (void)deletePartyTapped:(UIButton *)sender {
    if (![self requireLoginForAction]) {
        return;
    }
    NSString *partyId = sender.accessibilityIdentifier;
    if (partyId.length == 0) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Party?"
                                                                   message:@"This cannot be undone."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        [[HangoRequestManager shared] requestWithDelay:0.5 inView:strongSelf.view showsHUD:YES operation:^id {
            return @([[HangoDataStore shared] deleteHostedPartyWithId:partyId]);
        } completion:^(id result, NSError *error) {
            if ([result boolValue]) {
                [MBProgressHUD showSuccessMessage:@"Deleted successfully"];
                [strongSelf loadParties];
            }
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
