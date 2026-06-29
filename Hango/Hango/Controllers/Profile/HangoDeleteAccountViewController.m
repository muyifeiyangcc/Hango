#import "HangoDeleteAccountViewController.h"
#import "HangoSessionManager.h"
#import "HangoRequestManager.h"
#import "HangoAppRouter.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import <Masonry/Masonry.h>

@implementation HangoDeleteAccountViewController

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];

    UIView *card = [HangoDesignKit bottomSheetWithTitle:@"Delete your account?"];
    card.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1 alpha:1];
    [self.view addSubview:card];

    UILabel *hint = [[UILabel alloc] init];
    hint.text = @"This action cannot be undone.";
    hint.font = [HangoTheme bodyFont];
    hint.textColor = [HangoTheme secondaryTextColor];
    hint.textAlignment = NSTextAlignmentCenter;
    [card addSubview:hint];

    UIButton *cancel = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleAccent];
    cancel.layer.cornerRadius = 24;
    [cancel addTarget:self action:@selector(cancelTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:cancel];

    UIButton *deleteBtn = [HangoDesignKit pillButtonWithTitle:@"Delete" style:HangoPillButtonStyleDark];
    deleteBtn.backgroundColor = UIColor.systemRedColor;
    deleteBtn.layer.cornerRadius = 24;
    [deleteBtn addTarget:self action:@selector(deleteTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:deleteBtn];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(260);
    }];
    [hint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(card).offset(72);
        make.left.right.equalTo(card).insets(UIEdgeInsetsMake(0, 24, 0, 24));
    }];
    [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.height.mas_equalTo(48);
        make.right.equalTo(card.mas_centerX).offset(-8);
    }];
    [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-24);
        make.centerY.height.width.equalTo(cancel);
    }];
}

- (void)cancelTapped {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)deleteTapped {
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [[HangoSessionManager shared] deleteAccount];
        [HangoAppRouter showWelcome];
    }];
}

@end
