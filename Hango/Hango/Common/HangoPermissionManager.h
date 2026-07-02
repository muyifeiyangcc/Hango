#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HangoPermissionType) {
    HangoPermissionTypeCamera,
    HangoPermissionTypePhotoLibrary,
    HangoPermissionTypeMicrophone,
};

typedef void (^HangoPermissionHandler)(BOOL granted);

@interface HangoPermissionManager : NSObject

+ (BOOL)isAuthorizedForPermission:(HangoPermissionType)type;
+ (void)requestPermission:(HangoPermissionType)type
       fromViewController:(nullable UIViewController *)viewController
               completion:(nullable HangoPermissionHandler)completion;

+ (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                      fromViewController:(UIViewController *)viewController
                                delegate:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate;

+ (nullable UIViewController *)presentingViewControllerFromView:(UIView *)view;

@end

NS_ASSUME_NONNULL_END
