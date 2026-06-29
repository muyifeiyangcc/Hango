#import "HangoWalletViewController.h"
#import "HangoWalletPackage.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <MBProgressHUD+JDragon/MBProgressHUD+JDragon.h>
#import <Masonry/Masonry.h>

@implementation HangoWalletViewController {
    UILabel *_balanceLabel;
    UITableView *_tableView;
    NSArray<HangoWalletPackage *> *_packages;
}

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [[UILabel alloc] init];
    title.text = @"Wallt";
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textColor = [HangoTheme primaryDarkColor];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor colorWithRed:0.65 green:0.88 blue:0.98 alpha:0.75];
    card.layer.cornerRadius = 18;
    card.layer.borderWidth = 1;
    card.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.8].CGColor;
    [self.contentView addSubview:card];

    UILabel *balanceTitle = [[UILabel alloc] init];
    balanceTitle.text = @"Wallt balance";
    balanceTitle.font = [UIFont italicSystemFontOfSize:16];
    balanceTitle.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:balanceTitle];

    UIImageView *diamond = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"artboard_48"]];
    diamond.contentMode = UIViewContentModeScaleAspectFit;
    [card addSubview:diamond];

    _balanceLabel = [[UILabel alloc] init];
    _balanceLabel.font = [UIFont boldSystemFontOfSize:34];
    _balanceLabel.textColor = [HangoTheme primaryDarkColor];
    _balanceLabel.textAlignment = NSTextAlignmentRight;
    [card addSubview:_balanceLabel];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
    }];
    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(title.mas_bottom).offset(20);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.mas_equalTo(110);
    }];
    [balanceTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.equalTo(card).offset(18);
    }];
    [diamond mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-24);
        make.centerY.equalTo(card).offset(-8);
        make.width.height.mas_equalTo(56);
    }];
    [_balanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(diamond);
        make.top.equalTo(diamond.mas_bottom).offset(-4);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card.mas_bottom).offset(16);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadWallet];
}

- (void)loadWallet {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view operation:^id {
        return [HangoDataStore shared].walletPackages;
    } completion:^(id result, NSError *error) {
        self->_packages = result;
        self->_balanceLabel.text = @([HangoDataStore shared].currentUser.diamondBalance).stringValue;
        [self->_tableView reloadData];
    }];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _packages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"w"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"w"];
        cell.backgroundColor = UIColor.whiteColor;
        cell.layer.cornerRadius = 14;
        cell.clipsToBounds = YES;
        [HangoDesignKit applyCardShadow:cell];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    HangoWalletPackage *pkg = _packages[indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"  💎 %@", @(pkg.diamonds)];
    cell.textLabel.font = [UIFont boldSystemFontOfSize:17];
    cell.textLabel.textColor = [HangoTheme primaryDarkColor];

    UIButton *price = [UIButton buttonWithType:UIButtonTypeCustom];
    [price setTitle:pkg.priceText forState:UIControlStateNormal];
    [price setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    price.titleLabel.font = [HangoTheme bodyFont];
    price.layer.cornerRadius = 16;
    price.layer.borderWidth = 1.2;
    price.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
    price.tag = indexPath.row;
    [price addTarget:self action:@selector(buyPackage:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = price;
    price.frame = CGRectMake(0, 0, 72, 34);
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60;
}

- (void)buyPackage:(UIButton *)sender {
    HangoWalletPackage *pkg = _packages[sender.tag];
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [[HangoDataStore shared] addDiamonds:pkg.diamonds];
        self->_balanceLabel.text = @([HangoDataStore shared].currentUser.diamondBalance).stringValue;
        [MBProgressHUD showSuccessMessage:@"Purchase successful"];
    }];
}

@end
