#import "HangoBlacklistViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <MBProgressHUD+JDragon/MBProgressHUD+JDragon.h>
#import <Masonry/Masonry.h>

@implementation HangoBlacklistViewController {
    UITableView *_tableView;
    NSArray<HangoContact *> *_blacklisted;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Blacklist"];
    [self.contentView addSubview:title];

    _tableView = [[UITableView alloc] init];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    [self.contentView addSubview:_tableView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.equalTo(self.contentView).offset(20);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(14);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadBlacklist];
}

- (void)loadBlacklist {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"isBlacklisted == YES"];
        return [[HangoDataStore shared].contacts filteredArrayUsingPredicate:p];
    } completion:^(id result, NSError *error) {
        self->_blacklisted = result;
        [self->_tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX(_blacklisted.count, 1);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"b"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"b"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    if (_blacklisted.count == 0) {
        UIView *card = [HangoDesignKit cardView];
        [cell.contentView addSubview:card];
        UILabel *empty = [[UILabel alloc] init];
        empty.text = @"No blocked users";
        empty.font = [HangoTheme bodyFont];
        empty.textColor = [HangoTheme secondaryTextColor];
        empty.textAlignment = NSTextAlignmentCenter;
        [card addSubview:empty];
        [card mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(cell.contentView).insets(UIEdgeInsetsMake(4, 16, 4, 16));
            make.height.mas_equalTo(64);
        }];
        [empty mas_makeConstraints:^(MASConstraintMaker *make) { make.center.equalTo(card); }];
        return cell;
    }

    HangoContact *contact = _blacklisted[indexPath.row];
    UIView *card = [HangoDesignKit cardView];
    [cell.contentView addSubview:card];

    UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:44 bordered:NO];
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = contact.name;
    name.font = [UIFont boldSystemFontOfSize:16];
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UILabel *number = [[UILabel alloc] init];
    number.text = contact.number;
    number.font = [HangoTheme captionFont];
    number.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:number];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(4);
        make.left.equalTo(cell.contentView).offset(16);
        make.right.equalTo(cell.contentView).offset(-16);
        make.bottom.equalTo(cell.contentView).offset(-4);
    }];
    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(12);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(44);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(12);
        make.left.equalTo(avatar.mas_right).offset(12);
    }];
    [number mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(name.mas_bottom).offset(2);
        make.left.equalTo(name);
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return _blacklisted.count > 0;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *remove = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Remove" handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        HangoContact *contact = self->_blacklisted[indexPath.row];
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
            [[HangoDataStore shared] toggleBlacklistForContactId:contact.contactId];
            [MBProgressHUD showSuccessMessage:@"Removed"];
            [self loadBlacklist];
            completionHandler(YES);
        }];
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

@end
