#import "HangoWalletViewController.h"
#import "HangoWalletPackage.h"
#import "HangoDataStore.h"
#import "HangoIAPManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoHUD.h"
#import "Masonry.h"
#import <StoreKit/StoreKit.h>

@implementation HangoWalletViewController {
    UILabel *_balanceLabel;
    UITableView *_tableView;
    NSArray<HangoWalletPackage *> *_packages;
}

static const CGFloat kWalletHeaderSparkleWidth = 52.0;
static const CGFloat kWalletHeaderSparkleHeight = 50.0;
static const CGFloat kWalletRowSparkleWidth = 36.0;
static const CGFloat kWalletRowSparkleHeight = 35.0;
static const CGFloat kWalletHeaderHorizontalInset = 20.0;
static const CGFloat kWalletHeaderNavSpacing = 10.0;
static const CGFloat kWalletHeaderListSpacing = 15.0;
static const CGFloat kWalletNavBarHeight = 48.0;
static const CGFloat kWalletHeaderAspectRatio = 363.0 / 1011.0;

- (UIImageView *)sparkleImageView {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"钻石图标"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    [imageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [imageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return imageView;
}

- (void)setupUI {
    self.showsBackButton = YES;
    self.navTitleText = @"Wallt";

    UIImageView *headerBg = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"钱包顶部背景"]];
    headerBg.contentMode = UIViewContentModeScaleAspectFit;
    headerBg.clipsToBounds = YES;
    [self.contentView addSubview:headerBg];

    UILabel *balanceTitle = [[UILabel alloc] init];
    balanceTitle.text = @"Wallt balance";
    balanceTitle.font = [UIFont fontWithName:@"Menlo-Italic" size:15] ?: [UIFont italicSystemFontOfSize:15];
    balanceTitle.textColor = [HangoTheme primaryDarkColor];
    balanceTitle.textAlignment = NSTextAlignmentCenter;
    [headerBg addSubview:balanceTitle];

    UIView *leftRegion = [[UIView alloc] init];
    leftRegion.userInteractionEnabled = NO;
    leftRegion.backgroundColor = UIColor.clearColor;
    [headerBg addSubview:leftRegion];

    UIView *rightRegion = [[UIView alloc] init];
    rightRegion.userInteractionEnabled = NO;
    rightRegion.backgroundColor = UIColor.clearColor;
    [headerBg addSubview:rightRegion];

    UIView *balanceColumn = [[UIView alloc] init];
    [headerBg addSubview:balanceColumn];

    UIImageView *sparkleIcon = [self sparkleImageView];
    [balanceColumn addSubview:sparkleIcon];

    _balanceLabel = [[UILabel alloc] init];
    _balanceLabel.font = [UIFont monospacedSystemFontOfSize:24 weight:UIFontWeightBold];
    _balanceLabel.textColor = [HangoTheme primaryDarkColor];
    _balanceLabel.textAlignment = NSTextAlignmentCenter;
    [balanceColumn addSubview:_balanceLabel];

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.backgroundColor = UIColor.clearColor;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.showsVerticalScrollIndicator = NO;
    _tableView.contentInset = UIEdgeInsetsMake(4, 0, 16, 0);
    _tableView.dataSource = (id<UITableViewDataSource>)self;
    _tableView.delegate = (id<UITableViewDelegate>)self;
    [self.contentView addSubview:_tableView];

    [headerBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(kWalletNavBarHeight + kWalletHeaderNavSpacing);
        make.left.equalTo(self.contentView).offset(kWalletHeaderHorizontalInset);
        make.right.equalTo(self.contentView).offset(-kWalletHeaderHorizontalInset);
        make.height.equalTo(headerBg.mas_width).multipliedBy(kWalletHeaderAspectRatio);
    }];
    [leftRegion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.bottom.equalTo(headerBg);
        make.width.equalTo(headerBg).multipliedBy(0.54);
    }];
    [rightRegion mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.top.bottom.equalTo(headerBg);
        make.width.equalTo(headerBg).multipliedBy(0.42);
    }];
    [balanceTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(leftRegion);
        make.left.greaterThanOrEqualTo(leftRegion).offset(8);
        make.right.lessThanOrEqualTo(leftRegion).offset(-8);
    }];
    [balanceColumn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(rightRegion);
        make.width.mas_equalTo(kWalletHeaderSparkleWidth);
    }];
    [sparkleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(balanceColumn);
        make.width.mas_equalTo(kWalletHeaderSparkleWidth);
        make.height.mas_equalTo(kWalletHeaderSparkleHeight);
    }];
    [_balanceLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sparkleIcon.mas_bottom).offset(2);
        make.centerX.equalTo(balanceColumn);
        make.bottom.equalTo(balanceColumn);
    }];
    [_tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(headerBg.mas_bottom).offset(kWalletHeaderListSpacing);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadWallet];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshBalance];
}

- (void)refreshBalance {
    _balanceLabel.text = @([HangoDataStore shared].currentPersona.sparkleBalance).stringValue;
}

- (void)loadWallet {
    _packages = [HangoDataStore shared].walletPackages;
    [self refreshBalance];
    [_tableView reloadData];

    [[HangoIAPManager shared] requestProductsWithCompletion:^{
        [self->_tableView reloadData];
    }];
}

- (NSString *)displayPriceForPackage:(HangoWalletPackage *)pkg {
    return [[HangoIAPManager shared] localizedPriceForProductId:pkg.productId fallback:pkg.priceText];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _packages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"w"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"w"];
        cell.backgroundColor = UIColor.clearColor;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    for (UIView *v in cell.contentView.subviews) {
        [v removeFromSuperview];
    }

    HangoWalletPackage *pkg = _packages[indexPath.row];

    UIView *card = [[UIView alloc] init];
    card.backgroundColor = UIColor.whiteColor;
    card.layer.cornerRadius = 14;
    [HangoDesignKit applyCardShadow:card];
    [cell.contentView addSubview:card];

    UIImageView *sparkleIcon = [self sparkleImageView];
    [card addSubview:sparkleIcon];

    UILabel *amount = [[UILabel alloc] init];
    amount.text = @(pkg.sparkles).stringValue;
    amount.font = [UIFont monospacedSystemFontOfSize:16 weight:UIFontWeightSemibold];
    amount.textColor = [HangoTheme primaryDarkColor];
    [card addSubview:amount];

    UIButton *price = [UIButton buttonWithType:UIButtonTypeCustom];
    [price setTitle:[self displayPriceForPackage:pkg] forState:UIControlStateNormal];
    [price setTitleColor:[HangoTheme primaryDarkColor] forState:UIControlStateNormal];
    price.titleLabel.font = [HangoTheme monoFont];
    price.layer.cornerRadius = 17;
    price.layer.borderWidth = 1.2;
    price.layer.borderColor = [HangoTheme primaryDarkColor].CGColor;
    price.contentEdgeInsets = UIEdgeInsetsMake(6, 16, 6, 16);
    price.tag = indexPath.row;
    [price addTarget:self action:@selector(buyPackage:) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:price];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(5);
        make.left.equalTo(cell.contentView).offset(20);
        make.right.equalTo(cell.contentView).offset(-20);
        make.bottom.equalTo(cell.contentView).offset(-5);
        make.height.mas_equalTo(56);
    }];
    [sparkleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
        make.width.mas_equalTo(kWalletRowSparkleWidth);
        make.height.mas_equalTo(kWalletRowSparkleHeight);
    }];
    [amount mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sparkleIcon.mas_right).offset(8);
        make.centerY.equalTo(card);
        make.right.lessThanOrEqualTo(price.mas_left).offset(-12);
    }];
    [price mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-14);
        make.centerY.equalTo(card);
        make.height.mas_equalTo(32);
        make.width.mas_greaterThanOrEqualTo(68);
    }];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (void)buyPackage:(UIButton *)sender {
    HangoWalletPackage *pkg = _packages[sender.tag];
    if (pkg.productId.length == 0) {
        return;
    }
    if (![[HangoIAPManager shared] canMakePayments]) {
        [MBProgressHUD showErrorMessage:@"Purchases are disabled on this device."];
        return;
    }

    [MBProgressHUD showActivityMessageInWindow:@"Processing..."];
    __weak typeof(self) weakSelf = self;
    [[HangoIAPManager shared] purchaseProductId:pkg.productId success:^(NSInteger sparkles) {
        [MBProgressHUD hideHUD];
        [[HangoDataStore shared] addSparkles:sparkles];
        [weakSelf refreshBalance];
        [MBProgressHUD showSuccessMessage:@"Purchase successful"];
    } failure:^(NSError *error) {
        [MBProgressHUD hideHUD];
        if (error.code == SKErrorPaymentCancelled) {
            return;
        }
        NSString *message = error.localizedDescription.length > 0 ? error.localizedDescription : @"Purchase failed.";
        [MBProgressHUD showErrorMessage:message];
    }];
}

@end
