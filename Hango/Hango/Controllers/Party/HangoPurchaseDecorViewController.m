#import "HangoPurchaseDecorViewController.h"
#import "HangoDataStore.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "Masonry.h"

static const NSInteger kHangoDecorationPurchaseSparkleCost = 50;

@implementation HangoPurchaseDecorViewController

- (void)setupUI {
    self.view.backgroundColor = UIColor.clearColor;

    UIButton *dimming = [UIButton buttonWithType:UIButtonTypeCustom];
    dimming.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];
    [dimming addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:dimming];

    UIView *sheet = [HangoDesignKit bottomSheetWithTitle:@"Purchase Decorations"];
    sheet.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1 alpha:1];
    [self.view addSubview:sheet];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:self.decorImageName ?: @"artboard_46"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.backgroundColor = UIColor.blackColor;
    icon.layer.cornerRadius = 40;
    icon.clipsToBounds = YES;
    [sheet addSubview:icon];

    UIImageView *sparkleIcon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"钻石图标"]];
    sparkleIcon.contentMode = UIViewContentModeScaleAspectFit;
    [sheet addSubview:sparkleIcon];

    UILabel *cost = [[UILabel alloc] init];
    cost.text = @"× 50";
    cost.font = [HangoTheme headlineFont];
    cost.textColor = [HangoTheme primaryDarkColor];
    [sheet addSubview:cost];

    UIButton *cancel = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleAccent];
    cancel.layer.cornerRadius = 24;
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [sheet addSubview:cancel];

    UIButton *purchase = [HangoDesignKit pillButtonWithTitle:@"Purchase" style:HangoPillButtonStyleDark];
    purchase.layer.cornerRadius = 24;
    [purchase addTarget:self action:@selector(purchaseTapped) forControlEvents:UIControlEventTouchUpInside];
    [sheet addSubview:purchase];

    [dimming mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [sheet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(320);
    }];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sheet).offset(72);
        make.centerX.equalTo(sheet);
        make.width.height.mas_equalTo(80);
    }];
    [sparkleIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(icon.mas_bottom).offset(12);
        make.centerX.equalTo(sheet).offset(-18);
        make.width.height.mas_equalTo(22);
    }];
    [cost mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(sparkleIcon);
        make.left.equalTo(sparkleIcon.mas_right).offset(4);
    }];
    [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sheet).offset(24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.height.mas_equalTo(48);
        make.right.equalTo(sheet.mas_centerX).offset(-8);
    }];
    [purchase mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(sheet).offset(-24);
        make.centerY.height.width.equalTo(cancel);
    }];
}

- (void)cancelTapped {
    if (self.onCancel) {
        self.onCancel();
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)purchaseTapped {
    if ([HangoDataStore shared].currentPersona.sparkleBalance < kHangoDecorationPurchaseSparkleCost) {
        [self openWalletForRecharge];
        return;
    }
    if (self.onPurchase) {
        self.onPurchase();
    }
}

- (void)openWalletForRecharge {
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.onRecharge) {
            weakSelf.onRecharge();
        }
    }];
}

@end
