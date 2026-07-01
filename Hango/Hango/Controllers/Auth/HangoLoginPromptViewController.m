#import "HangoLoginPromptViewController.h"
#import "HangoAppRouter.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "Masonry.h"

@implementation HangoLoginPromptViewController

- (void)setupUI {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.45];

    UIView *card = [HangoDesignKit bottomSheetWithTitle:@"Login Required"];
    card.backgroundColor = [UIColor colorWithRed:0.88 green:0.96 blue:1 alpha:1];
    [self.view addSubview:card];

    UIButton *cancel = [HangoDesignKit pillButtonWithTitle:@"Cancel" style:HangoPillButtonStyleAccent];
    cancel.layer.cornerRadius = 24;
    [cancel addTarget:self action:@selector(dismissSelf) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:cancel];

    UIButton *login = [HangoDesignKit pillButtonWithTitle:@"Login" style:HangoPillButtonStyleDark];
    login.layer.cornerRadius = 24;
    [login addTarget:self action:@selector(loginTapped) forControlEvents:UIControlEventTouchUpInside];
    [card addSubview:login];

    [card mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.view);
        make.height.mas_equalTo(220);
    }];
    [cancel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(card).offset(24);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-20);
        make.height.mas_equalTo(48);
        make.right.equalTo(card.mas_centerX).offset(-8);
    }];
    [login mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(card).offset(-24);
        make.centerY.height.width.equalTo(cancel);
    }];
}

- (void)dismissSelf {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginTapped {
    [self dismissViewControllerAnimated:YES completion:^{
        [HangoAppRouter showWelcome];
    }];
}

@end
