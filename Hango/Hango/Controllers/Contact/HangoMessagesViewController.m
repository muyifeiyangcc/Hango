#import "HangoMessagesViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPrivateChatViewController.h"
#import <Masonry/Masonry.h>

@implementation HangoMessagesViewController {
    UITableView *_tableView;
    NSArray<HangoContact *> *_conversations;
}

- (void)viewDidLoad {
    self.tabIndex = HangoTabIndexMessages;
    [super viewDidLoad];
}

- (void)setupUI {
    [super setupUI];

    UILabel *title = [HangoDesignKit titleLabel:@"Messages"];
    [self.contentView addSubview:title];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(12);
        make.left.equalTo(self.contentView).offset(20);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(14);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadMessages];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadMessages];
}

- (void)loadMessages {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [[HangoDataStore shared] activeConversations];
    } completion:^(id result, NSError *error) {
        self->_conversations = result;
        [self->_tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _conversations.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"m"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"m"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    HangoContact *contact = _conversations[indexPath.row];
    UIView *card = [HangoDesignKit cardView];
    [cell.contentView addSubview:card];

    UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:48 bordered:NO];
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = contact.name;
    name.font = [UIFont boldSystemFontOfSize:16];
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UILabel *preview = [[UILabel alloc] init];
    preview.text = @"Is everyone having fun?";
    preview.font = [HangoTheme captionFont];
    preview.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:preview];

    UILabel *time = [[UILabel alloc] init];
    time.text = @"12:30";
    time.font = [HangoTheme captionFont];
    time.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:time];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(4);
        make.left.equalTo(cell.contentView).offset(16);
        make.right.equalTo(cell.contentView).offset(-16);
        make.bottom.equalTo(cell.contentView).offset(-4);
    }];
    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(12);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(48);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.left.equalTo(avatar.mas_right).offset(12);
        make.right.lessThanOrEqualTo(time.mas_left).offset(-8);
    }];
    [preview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(name.mas_bottom).offset(4);
        make.left.equalTo(name);
        make.right.equalTo(card).offset(-16);
    }];
    [time mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(14);
        make.right.equalTo(card).offset(-14);
    }];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HangoPrivateChatViewController *vc = [[HangoPrivateChatViewController alloc] init];
    vc.contact = _conversations[indexPath.row];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
