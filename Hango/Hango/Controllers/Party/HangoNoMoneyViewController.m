#import "HangoNoMoneyViewController.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoWalletViewController.h"
#import <Masonry/Masonry.h>

@implementation HangoNoMoneyViewController

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];

    UIView *sheet = [HangoDesignKit bottomSheetWithTitle:@"Insufficient Balance"];
    sheet.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1 alpha:1];
    [self.view addSubview:sheet];

    UIImageView *icon = [[UIImageView alloc] initWithImage:[HangoTheme imageNamed:@"artboard_55"]];
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.layer.cornerRadius = 40;
    icon.clipsToBounds = YES;
    [sheet addSubview:icon];

    UILabel *cost = [[UILabel alloc] init];
    cost.text = @"× 50";
    cost.font = [HangoTheme headlineFont];
    cost.textColor = [HangoTheme primaryDarkColor];
    cost.textAlignment = NSTextAlignmentCenter;
    [sheet addSubview:cost];

    UIButton *cancel = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleAccent];
    cancel.layer.cornerRadius = 24;
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [sheet addSubview:cancel];

    UIButton *recharge = [HangoDesignKit pillButtonWithTitle:@"Recharge" style:HangoPillButtonStyleDark];
    recharge.layer.cornerRadius = 24;
    [recharge addTarget:self action:@selector(rechargeTapped) forControlEvents:UIControlEventTouchUpInside];
    [sheet addSubview:recharge];

    [sheet mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(320);
    }];
    [icon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(sheet).offset(72);
        make.centerX.equalTo(sheet);
        make.width.height.mas_equalTo(80);
    }];
    [cost mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(icon.mas_bottom).offset(12);
        make.centerX.equalTo(sheet);
    }];
    [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(sheet).offset(24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.height.mas_equalTo(48);
        make.right.equalTo(sheet.mas_centerX).offset(-8);
    }];
    [recharge mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(sheet).offset(-24);
        make.centerY.height.width.equalTo(cancel);
    }];
}

- (void)cancelTapped {
    if (self.onCancel) self.onCancel();
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)rechargeTapped {
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.onRecharge) {
            weakSelf.onRecharge();
        } else if (weakSelf.navigationController) {
            [weakSelf.navigationController pushViewController:[[HangoWalletViewController alloc] init] animated:YES];
        }
    }];
}

@end
