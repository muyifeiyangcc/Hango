#import "HangoReportViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoReportDetailViewController.h"
#import "HangoBlacklistViewController.h"
#import <MBProgressHUD+JDragon/MBProgressHUD+JDragon.h>
#import <Masonry/Masonry.h>

@implementation HangoReportViewController

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:@"Report"];
    title.textAlignment = NSTextAlignmentCenter;
    [self.contentView addSubview:title];

    UIStackView *stack = [[UIStackView alloc] init];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 12;
    [self.contentView addSubview:stack];

    for (NSString *reason in [HangoDataStore shared].reportReasons) {
        UIButton *btn = [HangoDesignKit pillButtonWithTitle:reason style:HangoPillButtonStyleLight];
        btn.tag = [[HangoDataStore shared].reportReasons indexOfObject:reason];
        [btn addTarget:self action:@selector(reportReason:) forControlEvents:UIControlEventTouchUpInside];
        [btn mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
        [stack addArrangedSubview:btn];
    }

    UIButton *blacklist = [HangoDesignKit pillButtonWithTitle:@"Add to Blacklist" style:HangoPillButtonStyleOutline];
    [blacklist addTarget:self action:@selector(openBlacklist) forControlEvents:UIControlEventTouchUpInside];
    [blacklist mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
    [stack addArrangedSubview:blacklist];

    [title mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
    }];
    [stack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.centerY.equalTo(self.contentView).offset(20);
    }];
}

- (void)reportReason:(UIButton *)sender {
    NSString *reason = [HangoDataStore shared].reportReasons[sender.tag];
    HangoReportDetailViewController *vc = [[HangoReportDetailViewController alloc] init];
    vc.reason = reason;
    vc.contact = self.contact;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)openBlacklist {
    if (self.contact) {
        [[HangoDataStore shared] toggleBlacklistForContactId:self.contact.contactId];
    }
    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view completion:^{
        [MBProgressHUD showSuccessMessage:@"Added to blacklist"];
        [self.navigationController pushViewController:[[HangoBlacklistViewController alloc] init] animated:YES];
    }];
}

@end
