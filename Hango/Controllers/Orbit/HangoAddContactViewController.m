#import "HangoAddContactViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPrivateDialogueViewController.h"
#import "HGXAnchor.h"

@implementation HangoAddContactViewController {
    UIView *_searchWrap;
    UITableView *_tableView;
    NSArray<HangoContact *> *_suggestions;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Add Contact"];
    [self.contentView addSubview:title];

    _searchWrap = [HangoDesignKit searchBarWithPlaceholder:@"Search by number"];
    [self.contentView addSubview:_searchWrap];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.equalTo(self.contentView).offset(20);
    }];
    [_searchWrap hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(title.hgx_bottom).offset(14);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.hgx_equalTo(44);
    }];
    [_tableView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_searchWrap.hgx_bottom).offset(12);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:NO operation:^id {
        return [HangoDataStore shared].visibleContacts;
    } completion:^(id result, NSError *error) {
        self->_suggestions = result;
        [self->_tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _suggestions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"c"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"c"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    HangoContact *contact = _suggestions[indexPath.row];
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

    UIImageView *arrow = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"artboard_52"]];
    arrow.contentMode = UIViewContentModeScaleAspectFit;
    [card addSubview:arrow];

    [card hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(4);
        make.left.equalTo(cell.contentView).offset(16);
        make.right.equalTo(cell.contentView).offset(-16);
        make.bottom.equalTo(cell.contentView).offset(-4);
    }];
    [avatar hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(card).offset(12);
        make.centerY.equalTo(card);
        make.width.height.hgx_equalTo(44);
    }];
    [name hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(card).offset(12);
        make.left.equalTo(avatar.hgx_right).offset(12);
    }];
    [number hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(name.hgx_bottom).offset(2);
        make.left.equalTo(name);
    }];
    [arrow hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerY.equalTo(card);
        make.right.equalTo(card).offset(-14);
        make.width.height.hgx_equalTo(20);
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 72;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self requireLoginForAction]) {
        return;
    }
    HangoContact *contact = _suggestions[indexPath.row];
    HangoPrivateDialogueViewController *vc = [[HangoPrivateDialogueViewController alloc] init];
    vc.contact = contact;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
