#import "HangoInvitePartyContactsViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HGXAnchor.h"

@interface HangoInvitePartyContactsViewController () <UITableViewDataSource, UITableViewDelegate>
@end

@implementation HangoInvitePartyContactsViewController {
    UITableView *_tableView;
    UIView *_emptyView;
    UIButton *_doneButton;
    NSArray<HangoContact *> *_contacts;
    NSMutableSet<NSString *> *_selectedIds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _selectedIds = [NSMutableSet setWithArray:self.selectedContactIds ?: @[]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadContacts];
}

- (void)setupUI {
    self.showsBackButton = YES;
    self.navTitleText = @"Invite Contacts";

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    [_tableView registerClass:UITableViewCell.class forCellReuseIdentifier:@"cell"];
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

    _doneButton = [HangoDesignKit pillButtonWithTitle:@"Done" style:HangoPillButtonStyleDark];
    _doneButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    [_doneButton addTarget:self action:@selector(doneTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:_doneButton];

    [_tableView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.right.equalTo(self.contentView);
    }];
    [_emptyView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_tableView);
        make.left.right.equalTo(self.contentView);
        make.bottom.equalTo(_doneButton.hgx_top).offset(-12);
    }];
    [emptyImage hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(_emptyView);
        make.centerY.equalTo(_emptyView).offset(-24);
        make.width.hgx_equalTo(220);
        make.height.hgx_equalTo(180);
    }];
    [emptyLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(emptyImage.hgx_bottom).offset(16);
        make.left.right.equalTo(_emptyView).inset(32);
    }];
    [_doneButton hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_tableView.hgx_bottom).offset(12);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.bottom.equalTo(self.contentView).offset(-24);
        make.height.hgx_equalTo(56);
    }];

    [self reloadContacts];
}

- (void)reloadContacts {
    _contacts = [HangoDataStore shared].visibleContacts;
    [self updateContentState];
    [_tableView reloadData];
}

- (void)updateContentState {
    BOOL isEmpty = _contacts.count == 0;
    _emptyView.hidden = !isEmpty;
    _tableView.hidden = isEmpty;
    _doneButton.enabled = !isEmpty;
    if (isEmpty) {
        _doneButton.backgroundColor = [[HangoTheme primaryDarkColor] colorWithAlphaComponent:0.45];
        [_doneButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.65] forState:UIControlStateNormal];
    } else {
        _doneButton.backgroundColor = [HangoTheme primaryDarkColor];
        [_doneButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    }
}

- (void)doneTapped {
    if (_contacts.count == 0) {
        return;
    }

    NSMutableArray<HangoContact *> *selected = [NSMutableArray array];
    for (HangoContact *contact in _contacts) {
        if ([_selectedIds containsObject:contact.contactId]) {
            [selected addObject:contact];
        }
    }
    if (self.onComplete) {
        self.onComplete(selected.copy);
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _contacts.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }
    cell.backgroundColor = UIColor.clearColor;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    HangoContact *contact = _contacts[indexPath.row];
    BOOL selected = [_selectedIds containsObject:contact.contactId];

    UIView *card = [HangoDesignKit cardView];
    [cell.contentView addSubview:card];

    UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:44 bordered:NO];
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = contact.name;
    name.font = [UIFont boldSystemFontOfSize:16];
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UIImageView *check = [[UIImageView alloc] init];
    check.contentMode = UIViewContentModeScaleAspectFit;
    if (selected) {
        UIImage *checkIcon = [UIImage systemImageNamed:@"checkmark.circle.fill"];
        if (checkIcon) {
            checkIcon = [checkIcon imageWithTintColor:[HangoTheme accentBlueColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        check.image = checkIcon;
    } else {
        UIImage *circle = [UIImage systemImageNamed:@"circle"];
        if (circle) {
            circle = [circle imageWithTintColor:[HangoTheme secondaryTextColor] renderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        check.image = circle;
    }
    [card addSubview:check];

    [card hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(cell.contentView).insets(UIEdgeInsetsMake(4, 16, 4, 16));
    }];
    [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(card).offset(12);
        make.centerY.equalTo(card);
        make.width.height.hgx_equalTo(44);
    }];
    [name hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(avatar.hgx_right).offset(12);
        make.centerY.equalTo(card);
        make.right.lessThanOrEqualTo(check.hgx_left).offset(-8);
    }];
    [check hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.equalTo(card).offset(-14);
        make.centerY.equalTo(card);
        make.width.height.hgx_equalTo(24);
    }];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HangoContact *contact = _contacts[indexPath.row];
    if ([_selectedIds containsObject:contact.contactId]) {
        [_selectedIds removeObject:contact.contactId];
    } else {
        [_selectedIds addObject:contact.contactId];
    }
    [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}

@end
