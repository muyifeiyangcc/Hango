#import "HangoDisplayString.h"
#import "HangoReportDetailViewController.h"
#import "HangoContact.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPermissionManager.h"
#import "HangoHUD.h"
#import "HGXAnchor.h"

static NSString * const kReportDetailPlaceholder = @"Please describe the issue you are reporting...";
static NSString * const kComplaintDetailPlaceholder = @"Please describe your complaint...";

@interface HangoReportDetailViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation HangoReportDetailViewController {
    UITextView *_detailView;
    UIImageView *_photoView;
    UIImage *_selectedPhoto;
}

- (void)setupUI {
    self.showsBackButton = YES;
    if (self.complaintMode) {
        self.navTitleText = @"Complain";
    }

    NSString *placeholder = self.complaintMode ? kComplaintDetailPlaceholder : kReportDetailPlaceholder;
    _detailView = [[UITextView alloc] init];
    _detailView.backgroundColor = UIColor.whiteColor;
    _detailView.layer.cornerRadius = 18;
    _detailView.font = [HangoTheme bodyFont];
    _detailView.text = placeholder;
    _detailView.textColor = [HangoTheme secondaryTextColor];
    _detailView.textContainerInset = UIEdgeInsetsMake(16, 14, 16, 14);
    _detailView.delegate = self;
    [HangoDesignKit applyCardShadow:_detailView];
    [self.contentView addSubview:_detailView];

    UILabel *photoTitle = [[UILabel alloc] init];
    photoTitle.text = @"Picture (Optional)";
    photoTitle.font = [UIFont boldSystemFontOfSize:16];
    photoTitle.textColor = [HangoTheme primaryDarkColor];
    [self.contentView addSubview:photoTitle];

    UIView *photoBox = [[UIView alloc] init];
    photoBox.backgroundColor = UIColor.whiteColor;
    photoBox.layer.cornerRadius = 18;
    [HangoDesignKit applyCardShadow:photoBox];
    [self.contentView addSubview:photoBox];

    _photoView = [[UIImageView alloc] init];
    _photoView.contentMode = UIViewContentModeScaleAspectFill;
    _photoView.clipsToBounds = YES;
    _photoView.layer.cornerRadius = 18;
    _photoView.hidden = YES;
    [photoBox addSubview:_photoView];

    UIButton *addPhotoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    addPhotoBtn.backgroundColor = [HangoTheme accentBlueColor];
    addPhotoBtn.layer.cornerRadius = 24;
    UIImage *plusIcon = [UIImage systemImageNamed:@"plus"];
    if (plusIcon) {
        UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:20 weight:UIImageSymbolWeightBold];
        plusIcon = [plusIcon imageByApplyingSymbolConfiguration:config];
        [addPhotoBtn setImage:[plusIcon imageWithTintColor:UIColor.whiteColor renderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    } else {
        [addPhotoBtn setTitle:@"+" forState:UIControlStateNormal];
        [addPhotoBtn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        addPhotoBtn.titleLabel.font = [UIFont boldSystemFontOfSize:24];
    }
    [addPhotoBtn addTarget:self action:@selector(pickPhoto) forControlEvents:UIControlEventTouchUpInside];
    [photoBox addSubview:addPhotoBtn];

    UIButton *submit = [HangoDesignKit pillButtonWithTitle:(self.complaintMode ? @"Complain" : HangoDisplayString(HangoDisplayStringKeyReport)) style:HangoPillButtonStyleDark];
    [submit addTarget:self action:@selector(submit) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:submit];

    if (self.prefilledPhoto) {
        _selectedPhoto = self.prefilledPhoto;
        _photoView.image = self.prefilledPhoto;
        _photoView.hidden = NO;
    }

    [_detailView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(self.view.hgx_safeAreaLayoutGuideTop).offset(56);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.hgx_equalTo(200);
    }];
    [photoTitle hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(_detailView.hgx_bottom).offset(20);
        make.left.equalTo(_detailView);
    }];
    [photoBox hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.top.equalTo(photoTitle.hgx_bottom).offset(12);
        make.left.equalTo(_detailView);
        make.width.height.hgx_equalTo(100);
    }];
    [_photoView hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.edges.equalTo(photoBox);
    }];
    [addPhotoBtn hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.center.equalTo(photoBox);
        make.width.height.hgx_equalTo(48);
    }];
    [submit hgx_makeConstraints:^(HGXConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.width.equalTo(self.contentView).multipliedBy(0.58);
        make.bottom.equalTo(self.view.hgx_safeAreaLayoutGuideBottom).offset(-36);
        make.height.hgx_equalTo(56);
    }];
}

- (NSString *)reportDescription {
    NSString *text = [_detailView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *placeholder = self.complaintMode ? kComplaintDetailPlaceholder : kReportDetailPlaceholder;
    if (text.length == 0 || [text isEqualToString:placeholder]) {
        return @"";
    }
    return text;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    NSString *placeholder = self.complaintMode ? kComplaintDetailPlaceholder : kReportDetailPlaceholder;
    if ([textView.text isEqualToString:placeholder]) {
        textView.text = @"";
        textView.textColor = [HangoTheme primaryDarkColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        NSString *placeholder = self.complaintMode ? kComplaintDetailPlaceholder : kReportDetailPlaceholder;
        textView.text = placeholder;
        textView.textColor = [HangoTheme secondaryTextColor];
    }
}

- (void)pickPhoto {
    if (![self requireLoginForAction]) {
        return;
    }
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Take Photo" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [HangoPermissionManager presentImagePickerWithSourceType:UIImagePickerControllerSourceTypeCamera
                                                  fromViewController:self
                                                            delegate:self];
        }]];
    }
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Choose from Library" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
            [HangoPermissionManager presentImagePickerWithSourceType:UIImagePickerControllerSourceTypePhotoLibrary
                                                  fromViewController:self
                                                            delegate:self];
        }]];
    }
    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    if (sheet.popoverPresentationController) {
        sheet.popoverPresentationController.sourceView = self.view;
        sheet.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    }
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    if (image) {
        _selectedPhoto = image;
        _photoView.image = image;
        _photoView.hidden = NO;
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)submit {
    if (![self requireLoginForAction]) {
        return;
    }
    if ([self reportDescription].length == 0) {
        [MBProgressHUD showErrorMessage:@"Please describe the issue."];
        return;
    }

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES completion:^{
        NSString *message = self.complaintMode ? @"Complaint submitted" : HangoDisplayString(HangoDisplayStringKeyReportSuccessful);
        [MBProgressHUD showSuccessMessage:message];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
