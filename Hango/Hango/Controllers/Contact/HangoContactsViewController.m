#import "HangoContactsViewController.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPrivateDialogueViewController.h"
#import "HangoReportViewController.h"
#import "Masonry.h"

@interface HangoContactCell : UITableViewCell
@property (nonatomic, copy) dispatch_block_t onDialogueTapped;
@property (nonatomic, copy) dispatch_block_t onMoreTapped;
- (void)configureWithContact:(HangoContact *)contact;
@end

@implementation HangoContactCell {
    HangoContact *_contact;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onDialogueTapped = nil;
    self.onMoreTapped = nil;
}

- (void)configureWithContact:(HangoContact *)contact {
    _contact = contact;
    for (UIView *v in self.contentView.subviews) {
        [v removeFromSuperview];
    }

    UIView *card = [HangoDesignKit cardView];
    [self.contentView addSubview:card];

    UIImageView *avatar = [HangoDesignKit avatarWithName:contact.avatarName size:48 bordered:NO];
    [card addSubview:avatar];

    UILabel *name = [[UILabel alloc] init];
    name.text = contact.name;
    name.font = [UIFont boldSystemFontOfSize:17];
    name.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:name];

    UILabel *number = [[UILabel alloc] init];
    number.text = contact.number;
    number.font = [HangoTheme captionFont];
    number.textColor = [HangoTheme secondaryTextColor];
    [card addSubview:number];

    UIButton *chatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *chatIcon = [HangoTheme imageNamed:@"contact_chat"];
    if (chatIcon) {
        [chatBtn setImage:[chatIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    }
    chatBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [chatBtn addTarget:self action:@selector(chatTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:chatBtn];

    UIButton *moreBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *moreIcon = [UIImage systemImageNamed:@"ellipsis"];
    if (moreIcon) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:11 weight:UIImageSymbolWeightBold];
        moreIcon = [moreIcon imageByApplyingSymbolConfiguration:config];
        [moreBtn setImage:[moreIcon imageWithTintColor:[HangoTheme primaryDarkColor] renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        [moreBtn setTitle:@"..." forState:UIControlStateNormal];
        [moreBtn setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
        moreBtn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
    }
    moreBtn.userInteractionEnabled = NO;
    [chatBtn addSubview:moreBtn];

    UILongPressGestureRecognizer *morePress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(moreTapped)];
    morePress.minimumPressDuration = 0.45;
    [chatBtn addGestureRecognizer:morePress];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(UIEdgeInsetsMake(5, 16, 5, 16));
        make.height.mas_equalTo(76);
    }];
    [avatar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(12);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(48);
    }];
    [chatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-14);
        make.centerY.equalTo(card);
        make.width.height.mas_equalTo(32);
    }];
    [moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(chatBtn);
        make.width.height.mas_equalTo(20);
    }];
    [name mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(avatar.mas_right).offset(12);
        make.top.equalTo(avatar).offset(4);
        make.right.lessThanOrEqualTo(chatBtn.mas_left).offset(-8);
    }];
    [number mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(name);
        make.top.equalTo(name.mas_bottom).offset(2);
        make.right.lessThanOrEqualTo(chatBtn.mas_left).offset(-8);
    }];
}

- (void)chatTapped {
    if (self.onDialogueTapped) {
        self.onDialogueTapped();
    }
}

- (void)moreTapped:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    if (self.onMoreTapped) {
        self.onMoreTapped();
    }
}

@end

@implementation HangoContactsViewController {
    UITableView *_tableView;
    UIView *_searchWrap;
    UIView *_addOverlay;
    UIView *_addPanel;
    UITextField *_contactIdField;
    NSArray<HangoContact *> *_contacts;
    NSArray<HangoContact *> *_filtered;
}

- (void)viewDidLoad {
    self.tabIndex = HangoTabIndexContacts;
    [super viewDidLoad];
}

- (void)setupUI {
    [super setupUI];

    UILabel *title = [HangoDesignKit titleLabel:@"Contact Person"];
    [self.contentView addSubview:title];

    UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    UIImage *addIcon = [HangoTheme imageNamed:@"add_contact_plus"];
    if (addIcon) {
        [addBtn setImage:[addIcon imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
        addBtn.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    [addBtn addTarget:self action:@selector(addContact) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:addBtn];

    _searchWrap = [HangoDesignKit searchBarWithPlaceholder:@"Search contacts"];
    [self.contentView addSubview:_searchWrap];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [_tableView registerClass:HangoContactCell.class forCellReuseIdentifier:@"cell"];
    [self.contentView addSubview:_tableView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(8);
        make.left.equalTo(self.contentView).offset(20);
    }];
    [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(title);
        make.right.equalTo(self.contentView).offset(-20);
        make.width.height.mas_equalTo(44);
    }];
    [_searchWrap mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(14);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(44);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_searchWrap.mas_bottom).offset(8);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    UITextField *search = [_searchWrap viewWithTag:9001];
    [search addTarget:self action:@selector(searchChanged:) forControlEvents:UIControlEventEditingChanged];
    [self setupAddContactPanel];
    [self loadContacts];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self loadContacts];
}

- (void)setupAddContactPanel {
    _addOverlay = [[UIView alloc] init];
    _addOverlay.hidden = YES;
    _addOverlay.backgroundColor = [UIColor colorWithWhite:0 alpha:0.12];
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissAddContactPanel)];
    [_addOverlay addGestureRecognizer:dismissTap];
    [self.view addSubview:_addOverlay];

    _addPanel = [[UIView alloc] init];
    _addPanel.backgroundColor = UIColor.whiteColor;
    _addPanel.layer.cornerRadius = 20;
    _addPanel.layer.borderWidth = 1.2;
    _addPanel.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
    [_addOverlay addSubview:_addPanel];

    _contactIdField = [[UITextField alloc] init];
    _contactIdField.placeholder = @"Enter your contact's ID";
    _contactIdField.font = [HangoTheme bodyFont];
    _contactIdField.textColor = [HangoTheme primaryDarkColor];
    _contactIdField.keyboardType = UIKeyboardTypeNumberPad;
    _contactIdField.borderStyle = UITextBorderStyleNone;
    [_addPanel addSubview:_contactIdField];

    UIButton *addActionBtn = [HangoDesignKit pillButtonWithTitle:@"Add" style:HangoPillButtonStyleAccent];
    addActionBtn.layer.cornerRadius = 18;
    addActionBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [addActionBtn addTarget:self action:@selector(confirmAddContact) forControlEvents:UIControlEventTouchUpInside];
    [_addPanel addSubview:addActionBtn];

    [_addOverlay mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [_addPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_searchWrap.mas_bottom).offset(10);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(52);
    }];
    [_contactIdField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_addPanel).offset(16);
        make.centerY.equalTo(_addPanel);
        make.right.equalTo(addActionBtn.mas_left).offset(-10);
    }];
    [addActionBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_addPanel).offset(-8);
        make.centerY.equalTo(_addPanel);
        make.width.mas_equalTo(72);
        make.height.mas_equalTo(36);
    }];
}

- (void)loadContacts {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:NO operation:^id {
        return [HangoDataStore shared].contacts;
    } completion:^(id result, NSError *error) {
        self->_contacts = result;
        self->_filtered = result;
        [self->_tableView reloadData];
    }];
}

- (void)searchChanged:(UITextField *)field {
    NSString *text = field.text ?: @"";
    if (text.length == 0) {
        _filtered = _contacts;
    } else {
        NSPredicate *p = [NSPredicate predicateWithFormat:@"name CONTAINS[cd] %@ OR number CONTAINS[cd] %@", text, text];
        _filtered = [_contacts filteredArrayUsingPredicate:p];
    }
    [_tableView reloadData];
}

- (void)addContact {
    _addOverlay.hidden = NO;
    _contactIdField.text = @"";
    [_contactIdField becomeFirstResponder];
}

- (void)dismissAddContactPanel {
    [_contactIdField resignFirstResponder];
    _addOverlay.hidden = YES;
}

- (void)confirmAddContact {
    NSString *contactId = [_contactIdField.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (contactId.length == 0) {
        [self showAlertWithText:@"Please enter your contact's ID."];
        return;
    }

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES operation:^id {
        return @([[HangoDataStore shared] addContactWithNumber:contactId]);
    } completion:^(id result, NSError *error) {
        NSInteger status = [result integerValue];
        if (status == 1) {
            [self dismissAddContactPanel];
            [self loadContacts];
            return;
        }
        if (status == 2) {
            [self showAlertWithText:@"This contact is already in your list."];
            return;
        }
        [self showAlertWithText:@"No member found with this ID."];
    }];
}

- (void)showAlertWithText:(NSString *)text {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)openDialogueWithContact:(HangoContact *)contact {
    HangoPrivateDialogueViewController *vc = [[HangoPrivateDialogueViewController alloc] init];
    vc.contact = contact;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showMoreOptionsForContact:(HangoContact *)contact {
    __weak typeof(self) weakSelf = self;
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        HangoReportViewController *vc = [[HangoReportViewController alloc] init];
        vc.contact = contact;
        [self.navigationController pushViewController:vc animated:YES];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Deny" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [weakSelf confirmBlockContact:contact];
    }]];
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)confirmBlockContact:(HangoContact *)contact {
    if (contact.isDenied) {
        [self showAlertWithText:@"This contact is already in the deny list."];
        return;
    }
    NSString *message = [NSString stringWithFormat:@"Are you sure you want to add %@ to the deny list?", contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add to Deny List?"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoDataStore shared] addContactToDenyList:contact.contactId];
        [weakSelf loadContacts];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _filtered.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    HangoContactCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    HangoContact *contact = _filtered[indexPath.row];
    [cell configureWithContact:contact];
    __weak typeof(self) weakSelf = self;
    cell.onDialogueTapped = ^{
        [weakSelf openDialogueWithContact:contact];
    };
    cell.onMoreTapped = ^{
        [weakSelf showMoreOptionsForContact:contact];
    };
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 86;
}

@end
