#import "HangoDisplayString.h"
#import "HangoReportViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoReportDetailViewController.h"
#import "HangoDenyListViewController.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

@implementation HangoReportViewController

- (void)setupUI {
    self.showsBackButton = YES;

    UILabel *title = [HangoDesignKit titleLabel:HangoDisplayString(HangoDisplayStringKeyReport)];
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
        [btn hgx_makeConstraints:^(HGXConstraintMaker *make) { make.height.hgx_equalTo(48); }];
        [stack addArrangedSubview:btn];
    }

    UIButton *blockButton = [HangoDesignKit pillButtonWithTitle:HangoDisplayString(HangoDisplayStringKeyBlock) style:HangoPillButtonStyleOutline];
    [blockButton addTarget:self action:@selector(blockContact) forControlEvents:UIControlEventTouchUpInside];
    [blockButton hgx_makeConstraints:^(HGXConstraintMaker *make) { make.height.hgx_equalTo(48); }];
    [stack addArrangedSubview:blockButton];

    [title hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.contentView).offset(52);
        make.centerX.equalTo(self.contentView);
    }];
    [stack hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.left.equalTo(self.contentView).offset(24);
        make.right.equalTo(self.contentView).offset(-24);
        make.centerY.equalTo(self.contentView).offset(20);
    }];
}

- (void)reportReason:(UIButton *)sender {
    if (![self requireLoginForAction]) {
        return;
    }
    NSString *reason = [HangoDataStore shared].reportReasons[sender.tag];
    HangoReportDetailViewController *vc = [[HangoReportDetailViewController alloc] init];
    vc.reason = reason;
    vc.contact = self.contact;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)blockContact {
    if (![self requireLoginForAction]) {
        return;
    }
    if (!self.contact) {
        return;
    }
    if (self.contact.isDenied) {
        [self.navigationController pushViewController:[[HangoDenyListViewController alloc] init] animated:YES];
        return;
    }

    NSString *message = [NSString stringWithFormat:HangoDisplayString(HangoDisplayStringKeyBlockConfirmFormat), self.contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:HangoDisplayString(HangoDisplayStringKeyBlockQuestion)
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:HangoDisplayString(HangoDisplayStringKeyBlock) style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoDataStore shared] addContactToDenyList:weakSelf.contact.contactId];
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [MBProgressHUD showSuccessMessage:HangoDisplayString(HangoDisplayStringKeyBlockedSuccessfully)];
            [weakSelf.navigationController pushViewController:[[HangoDenyListViewController alloc] init] animated:YES];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
