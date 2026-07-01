#import "HangoReportViewController.h"
#import "HangoContact.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoReportDetailViewController.h"
#import "HangoDenyListViewController.h"
#import "HangoHUD.h"
#import "Masonry.h"

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

    UIButton *denyButton = [HangoDesignKit pillButtonWithTitle:@"Add to Deny List" style:HangoPillButtonStyleOutline];
    [denyButton addTarget:self action:@selector(openDenyList) forControlEvents:UIControlEventTouchUpInside];
    [denyButton mas_makeConstraints:^(MASConstraintMaker *make) { make.height.mas_equalTo(48); }];
    [stack addArrangedSubview:denyButton];

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

- (void)openDenyList {
    if (!self.contact) {
        return;
    }
    if (self.contact.isDenied) {
        [self.navigationController pushViewController:[[HangoDenyListViewController alloc] init] animated:YES];
        return;
    }

    NSString *message = [NSString stringWithFormat:@"Are you sure you want to add %@ to the deny list?", self.contact.name];
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add to Deny List?"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    __weak typeof(self) weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[HangoDataStore shared] addContactToDenyList:weakSelf.contact.contactId];
        [[HangoRequestManager shared] requestWithDelay:0.75 inView:weakSelf.view showsHUD:YES completion:^{
            [MBProgressHUD showSuccessMessage:@"Added to deny list"];
            [weakSelf.navigationController pushViewController:[[HangoDenyListViewController alloc] init] animated:YES];
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
