#import "HangoReportDetailViewController.h"
#import "HangoContact.h"
#import "HangoRequestManager.h"
#import "HangoDesignKit.h"
#import "HangoTheme.h"
#import "HangoPermissionManager.h"
#import "HangoHUD.h"
#import "Masonry.h"

static NSString * const kReportDetailPlaceholder = @"Please describe the issue you are reporting...";

@interface HangoReportDetailViewController () <UITextViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@end

@implementation HangoReportDetailViewController {
    UITextView *_detailView;
    UIImageView *_photoView;
    UIImage *_selectedPhoto;
}

- (void)setupUI {
    self.showsBackButton = YES;

    _detailView = [[UITextView alloc] init];
    _detailView.backgroundColor = UIColor.whiteColor;
    _detailView.layer.cornerRadius = 18;
    _detailView.font = [HangoTheme bodyFont];
    _detailView.text = kReportDetailPlaceholder;
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

    UIButton *submit = [HangoDesignKit pillButtonWithTitle:@"Report" style:HangoPillButtonStyleDark];
    [submit addTarget:self action:@selector(submit) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:submit];

    [_detailView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop).offset(56);
        make.left.equalTo(self.contentView).offset(20);
        make.right.equalTo(self.contentView).offset(-20);
        make.height.mas_equalTo(200);
    }];
    [photoTitle mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(_detailView.mas_bottom).offset(20);
        make.left.equalTo(_detailView);
    }];
    [photoBox mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(photoTitle.mas_bottom).offset(12);
        make.left.equalTo(_detailView);
        make.width.height.mas_equalTo(100);
    }];
    [_photoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(photoBox);
    }];
    [addPhotoBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(photoBox);
        make.width.height.mas_equalTo(48);
    }];
    [submit mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.contentView);
        make.width.equalTo(self.contentView).multipliedBy(0.58);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom).offset(-36);
        make.height.mas_equalTo(56);
    }];
}

- (NSString *)reportDescription {
    NSString *text = [_detailView.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0 || [text isEqualToString:kReportDetailPlaceholder]) {
        return @"";
    }
    return text;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:kReportDetailPlaceholder]) {
        textView.text = @"";
        textView.textColor = [HangoTheme primaryDarkColor];
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (textView.text.length == 0) {
        textView.text = kReportDetailPlaceholder;
        textView.textColor = [HangoTheme secondaryTextColor];
    }
}

- (void)pickPhoto {
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
    if ([self reportDescription].length == 0) {
        [MBProgressHUD showErrorMessage:@"Please describe the issue."];
        return;
    }

    [[HangoRequestManager shared] requestWithDelay:0.75 inView:self.view showsHUD:YES completion:^{
        [MBProgressHUD showSuccessMessage:@"Report successful"];
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
