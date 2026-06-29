#import "HangoHostedPartiesViewController.h"
#import "HangoParty.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoAllPeopleViewController.h"
#import <Masonry/Masonry.h>

@implementation HangoHostedPartiesViewController {
    UITableView *_tableView;
    NSArray<HangoParty *> *_parties;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"My Parties"];
    [self.contentView addSubview:title];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.left.equalTo(self.contentView).offset(20);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(14);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadParties];
}

- (void)loadParties {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [HangoDataStore shared].hostedParties;
    } completion:^(id result, NSError *error) {
        self->_parties = result;
        [self->_tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _parties.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"p"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"p"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    HangoParty *party = _parties[indexPath.row];
    UIView *card = [HangoDesignKit cardView];
    [cell.contentView addSubview:card];

    UIImageView *cover = [[UIImageView alloc] initWithImage:[HangoTheme avatarImageNamed:party.coverImageName]];
    cover.layer.cornerRadius = 10;
    cover.clipsToBounds = YES;
    cover.contentMode = UIViewContentModeScaleAspectFill;
    [card addSubview:cover];

    UILabel *invite = [[UILabel alloc] init];
    invite.text = party.invitation;
    invite.font = [UIFont boldSystemFontOfSize:15];
    invite.textColor = [HangoTheme primaryDarkColor];
    invite.numberOfLines = 2;
    [card addSubview:invite];

    UILabel *meta = [[UILabel alloc] init];
    meta.text = [NSString stringWithFormat:@"%@ · %@", party.timeText, party.location];
    meta.font = [HangoTheme captionFont];
    meta.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:meta];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(4);
        make.left.equalTo(cell.contentView).offset(16);
        make.right.equalTo(cell.contentView).offset(-16);
        make.bottom.equalTo(cell.contentView).offset(-4);
    }];
    [cover mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(card).insets(UIEdgeInsetsMake(10, 10, 10, 0));
        make.width.mas_equalTo(68);
    }];
    [invite mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.left.equalTo(cover.mas_right).offset(12);
        make.right.equalTo(card).offset(-12);
    }];
    [meta mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(invite.mas_bottom).offset(4);
        make.left.equalTo(invite);
        make.right.equalTo(invite);
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 96;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HangoAllPeopleViewController *vc = [[HangoAllPeopleViewController alloc] init];
    vc.party = _parties[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *cancel = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Cancel" handler:^(__unused UIContextualAction *action, __unused UIView *sourceView, void (^completionHandler)(BOOL)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Cancel Party?" message:@"This cannot be undone." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction *a) { completionHandler(NO); }]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *a) {
            [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
                completionHandler(YES);
            }];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[cancel]];
}

@end
