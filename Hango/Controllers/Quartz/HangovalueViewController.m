#import "HangoDisplayString.h"
#import "HangovalueViewController.h"
#import "HangovaluePackage.h"
#import "HangoDataStore.h"
#import "HangoIAPManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"
#import <StoreKit/StoreKit.h>

@implementation HangovalueViewController {
    UILabel *_balanceLabel;
    UITableView *_tableView;
    NSArray<HangovaluePackage *> *_packages;
}

static const CGFloat kvalueHeaderSparkleWidth = 52.0;
static const CGFloat kvalueHeaderSparkleHeight = 50.0;
static const CGFloat kvalueRowSparkleWidth = 36.0;
static const CGFloat kvalueRowSparkleHeight = 35.0;
static const CGFloat kvalueHeaderHorizontalInset = 20.0;
static const CGFloat kvalueHeaderNavSpacing = 10.0;
static const CGFloat kvalueHeaderListSpacing = 15.0;
static const CGFloat kvalueNavBarHeight = 48.0;
static const CGFloat kvalueHeaderAspectRatio = 363.0 / 1011.0;

- (UIImageView *)sparkleImageView {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"sparkle_icon"]];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.clipsToBounds = YES;
    [imageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [imageView setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];
    return imageView;
}

- (void)setupUI {
    self.showsBackButton = YES;
    self.navTitleText = HangoDisplayString(HangoDisplayStringKeyValue);

    UIImageView *headerBg = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"top_bg"]];
    headerBg.contentMode = UIViewContentModeScaleAspectFit;
    headerBg.clipsToBounds = YES;
    [self.contentView addSubview:headerBg];

    UILabel *balanceTitle = [[UILabel alloc] init];
    balanceTitle.text = HangoDisplayString(HangoDisplayStringKeyValueBalance);
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

    [headerBg hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(kvalueNavBarHeight + kvalueHeaderNavSpacing);
        make.left.equalTo(self.contentView).offset(kvalueHeaderHorizontalInset);
        make.right.equalTo(self.contentView).offset(-kvalueHeaderHorizontalInset);
        make.height.equalTo(headerBg.hgx_width).multipliedBy(kvalueHeaderAspectRatio);
    }];
    [leftRegion hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.top.bottom.equalTo(headerBg);
        make.width.equalTo(headerBg).multipliedBy(0.54);
    }];
    [rightRegion hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.top.bottom.equalTo(headerBg);
        make.width.equalTo(headerBg).multipliedBy(0.42);
    }];
    [balanceTitle hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(leftRegion);
        make.left.greaterThanOrEqualTo(leftRegion).offset(8);
        make.right.lessThanOrEqualTo(leftRegion).offset(-8);
    }];
    [balanceColumn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(rightRegion);
        make.width.hgx_equalTo(kvalueHeaderSparkleWidth);
    }];
    [sparkleIcon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.left.right.equalTo(balanceColumn);
        make.width.hgx_equalTo(kvalueHeaderSparkleWidth);
        make.height.hgx_equalTo(kvalueHeaderSparkleHeight);
    }];
    [_balanceLabel hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(sparkleIcon.hgx_bottom).offset(2);
        make.centerX.equalTo(balanceColumn);
        make.bottom.equalTo(balanceColumn);
    }];
    [_tableView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(headerBg.hgx_bottom).offset(kvalueHeaderListSpacing);
        make.left.right.bottom.equalTo(self.contentView);
    }];

    [self loadvalue];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshBalance];
}

- (void)refreshBalance {
    _balanceLabel.text = @([HangoDataStore shared].currentPersona.sparkleBalance).stringValue;
}

- (void)loadvalue {
    _packages = [HangoDataStore shared].valuePackages;
    [self refreshBalance];
    [_tableView reloadData];

    [[HangoIAPManager shared] requestProductsWithCompletion:^{
        [self->_tableView reloadData];
    }];
}

- (NSString *)displayPriceForPackage:(HangovaluePackage *)pkg {
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

    HangovaluePackage *pkg = _packages[indexPath.row];

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

    [card hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(cell.contentView).offset(5);
        make.left.equalTo(cell.contentView).offset(20);
        make.right.equalTo(cell.contentView).offset(-20);
        make.bottom.equalTo(cell.contentView).offset(-5);
        make.height.hgx_equalTo(56);
    }];
    [sparkleIcon hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(card).offset(16);
        make.centerY.equalTo(card);
        make.width.hgx_equalTo(kvalueRowSparkleWidth);
        make.height.hgx_equalTo(kvalueRowSparkleHeight);
    }];
    [amount hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(sparkleIcon.hgx_right).offset(8);
        make.centerY.equalTo(card);
        make.right.lessThanOrEqualTo(price.hgx_left).offset(-12);
    }];
    [price hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.right.equalTo(card).offset(-14);
        make.centerY.equalTo(card);
        make.height.hgx_equalTo(32);
        make.width.hgx_greaterThanOrEqualTo(68);
    }];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 66;
}

- (void)buyPackage:(UIButton *)sender {
    if (![self requireLoginForAction]) {
        return;
    }
    HangovaluePackage *pkg = _packages[sender.tag];
    if (pkg.productId.length == 0) {
        return;
    }
    if (![[HangoIAPManager shared] canMakePayments]) {
        [MBProgressHUD showErrorMessage:HangoDisplayString(HangoDisplayStringKeyPurchasesDisabled)];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [[HangoIAPManager shared] purchaseProductId:pkg.productId success:^(NSInteger sparkles) {
        [[HangoDataStore shared] addSparkles:sparkles];
        [weakSelf refreshBalance];
        [MBProgressHUD showSuccessMessage:HangoDisplayString(HangoDisplayStringKeyPurchaseSuccessful)];
    } failure:^(NSError *error) {
        if (error.code == SKErrorPaymentCancelled) {
            return;
        }
        NSString *message = error.localizedDescription.length > 0 ? error.localizedDescription : HangoDisplayString(HangoDisplayStringKeyPurchaseFailed);
        [MBProgressHUD showErrorMessage:message];
    }];
}

@end
