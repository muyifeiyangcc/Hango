#import "HangoInboxViewController.h"
#import "HangoContact.h"
#import "HangoParty.h"
#import "HangoDialogueItem.h"
#import "HangoDialogueThread.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPrivateDialogueViewController.h"
#import "HangoGroupDialogueViewController.h"
#import "Masonry.h"

@implementation HangoInboxViewController {
    UITableView *_tableView;
    UIView *_emptyView;
    NSArray<HangoDialogueThread *> *_threads;
}

- (void)viewDidLoad {
    self.tabIndex = HangoTabIndexInbox;
    [super viewDidLoad];
}

- (void)setupUI {
    [super setupUI];

    UILabel *title = [HangoDesignKit titleLabel:@"Inbox"];
    [self.contentView addSubview:title];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.contentInset = UIEdgeInsetsMake(0, 0, 12, 0);
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.left.equalTo(self.contentView).offset(20);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(16);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    _emptyView = [[UIView alloc] init];
    _emptyView.hidden = YES;
    [self.contentView addSubview:_emptyView];

    UIImageView *emptyImage = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"空数据图"]];
    emptyImage.contentMode = UIViewContentModeScaleAspectFit;
    [_emptyView addSubview:emptyImage];

    UILabel *emptyLabel = [[UILabel alloc] init];
    emptyLabel.text = @"There is no content here.";
    emptyLabel.font = [HangoTheme monoFont];
    emptyLabel.textColor = [HangoTheme primaryDarkColor];
    emptyLabel.textAlignment = NSTextAlignmentCenter;
    emptyLabel.numberOfLines = 0;
    [_emptyView addSubview:emptyLabel];

    [_emptyView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.contentView);
        make.centerX.equalTo(self.contentView);
        make.centerY.equalTo(self.contentView).offset(-70);
    }];
    [emptyImage mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.equalTo(_emptyView);
        make.width.mas_equalTo(220);
        make.height.mas_equalTo(180);
    }];
    [emptyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(emptyImage.mas_bottom).offset(16);
        make.left.right.equalTo(_emptyView).inset(32);
        make.bottom.equalTo(_emptyView);
    }];

    [self loadDialogueItems];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadDialogueItems];
}

- (void)loadDialogueItems {
    _threads = [[HangoDataStore shared] activeDialogueThreads];
    BOOL isEmpty = _threads.count == 0;
    _emptyView.hidden = !isEmpty;
    _tableView.hidden = isEmpty;
    [_tableView reloadData];
}

- (NSString *)titleForThread:(HangoDialogueThread *)thread {
    if (thread.kind == HangoDialogueThreadKindParty) {
        HangoParty *party = thread.party;
        if (party.location.length > 0) {
            return party.location;
        }
        if (party.invitation.length > 0) {
            return party.invitation.length > 36 ? [[party.invitation substringToIndex:36] stringByAppendingString:@"..."] : party.invitation;
        }
        return party.hostName.length > 0 ? [NSString stringWithFormat:@"%@'s Party", party.hostName] : @"Party Dialogue";
    }
    return thread.contact.name ?: @"";
}

- (NSString *)avatarNameForThread:(HangoDialogueThread *)thread {
    if (thread.kind == HangoDialogueThreadKindParty) {
        HangoParty *party = thread.party;
        if (party.hostAvatarName.length > 0) {
            return party.hostAvatarName;
        }
        return party.memberAvatarNames.firstObject ?: @"";
    }
    return thread.contact.avatarName ?: @"";
}

- (HangoDialogueItem *)lastDialogueItemForThread:(HangoDialogueThread *)thread store:(HangoDataStore *)store {
    if (thread.kind == HangoDialogueThreadKindParty) {
        return [store lastDialogueForPartyId:thread.threadId];
    }
    return [store lastDialogueForConversationId:thread.threadId];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _threads.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"m"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"m"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *v in cell.contentView.subviews) [v removeFromSuperview];

    HangoDialogueThread *thread = _threads[indexPath.row];
    HangoDataStore *store = [HangoDataStore shared];
    HangoDialogueItem *lastDialogueItem = [self lastDialogueItemForThread:thread store:store];
    UIView *card = [HangoDesignKit cardView];
    [cell.contentView addSubview:card];

    UIImageView *avatar = [HangoDesignKit avatarWithName:[self avatarNameForThread:thread] size:48 bordered:NO];
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = [self titleForThread:thread];
    name.font = [UIFont boldSystemFontOfSize:16];
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UILabel *badge = nil;
    if (thread.kind == HangoDialogueThreadKindParty) {
        badge = [[UILabel alloc] init];
        badge.text = @"Group";
        badge.font = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        badge.textColor = [HangoTheme primaryDarkColor];
        badge.backgroundColor = [HangoTheme mintBubbleColor];
        badge.textAlignment = NSTextAlignmentCenter;
        badge.layer.cornerRadius = 8;
        badge.clipsToBounds = YES;
        [card addSubview:badge];
    }

    UILabel *preview = [[UILabel alloc] init];
    preview.text = [store previewTextForDialogueItem:lastDialogueItem];
    preview.font = [HangoTheme captionFont];
    preview.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:preview];

    UILabel *time = [[UILabel alloc] init];
    time.text = lastDialogueItem.timeText ?: @"";
    time.font = [HangoTheme captionFont];
    time.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:time];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(5);
        make.left.equalTo(cell.contentView).offset(16);
        make.right.equalTo(cell.contentView).offset(-16);
        make.bottom.equalTo(cell.contentView).offset(-5);
        make.height.mas_greaterThanOrEqualTo(72);
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
    if (badge) {
        [badge mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(name.mas_right).offset(8);
            make.centerY.equalTo(name);
            make.height.mas_equalTo(18);
            make.width.mas_greaterThanOrEqualTo(46);
        }];
    }
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
    return 82;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    HangoDialogueThread *thread = _threads[indexPath.row];
    if (thread.kind == HangoDialogueThreadKindParty) {
        HangoGroupDialogueViewController *vc = [[HangoGroupDialogueViewController alloc] init];
        vc.party = thread.party;
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    HangoPrivateDialogueViewController *vc = [[HangoPrivateDialogueViewController alloc] init];
    vc.contact = thread.contact;
    [self.navigationController pushViewController:vc animated:YES];
}

@end
