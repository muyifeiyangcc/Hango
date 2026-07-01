#import "HangoPermissionManager.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>
#import <CoreLocation/CoreLocation.h>

static CLAuthorizationStatus HangoLocationStatusForManager(CLLocationManager *manager) {
    return manager.authorizationStatus;
}

static BOOL HangoIsLocationStatusAuthorized(CLAuthorizationStatus status) {
    return status == kCLAuthorizationStatusAuthorizedAlways || status == kCLAuthorizationStatusAuthorizedWhenInUse;
}

static CLAuthorizationStatus HangoCurrentLocationStatus(void) {
    return HangoLocationStatusForManager([[CLLocationManager alloc] init]);
}

@interface HangoLocationPermissionRequester : NSObject <CLLocationManagerDelegate>
@property (nonatomic, copy) HangoPermissionHandler completion;
@property (nonatomic, strong) CLLocationManager *manager;
@end

@implementation HangoLocationPermissionRequester                         

- (void)requestWithCompletion:(HangoPermissionHandler)completion {
    self.completion = completion;
    self.manager = [[CLLocationManager alloc] init];
    self.manager.delegate = self;

    CLAuthorizationStatus status = HangoLocationStatusForManager(self.manager);
    if (status == kCLAuthorizationStatusNotDetermined) {
        [self.manager requestWhenInUseAuthorization];
        return;
    }
    [self finishWithGranted:HangoIsLocationStatusAuthorized(status)];
}

- (void)locationManagerDidChangeAuthorization:(CLLocationManager *)manager {
    CLAuthorizationStatus status = HangoLocationStatusForManager(manager);
    if (status != kCLAuthorizationStatusNotDetermined) {
        [self finishWithGranted:HangoIsLocationStatusAuthorized(status)];
    }
}

- (void)finishWithGranted:(BOOL)granted {
    HangoPermissionHandler handler = self.completion;
    self.completion = nil;
    self.manager.delegate = nil;
    self.manager = nil;
    if (handler) {
        handler(granted);
    }
}

@end

@implementation HangoPermissionManager

+ (BOOL)isAuthorizedForPermission:(HangoPermissionType)type {
    switch (type) {
        case HangoPermissionTypeCamera:
            return [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusAuthorized;
        case HangoPermissionTypePhotoLibrary:
            return [self isPhotoLibraryStatusAuthorized:[self photoLibraryStatus]];
        case HangoPermissionTypeMicrophone:
            return AVAudioSession.sharedInstance.recordPermission == AVAudioSessionRecordPermissionGranted;
        case HangoPermissionTypeLocation:
            return HangoIsLocationStatusAuthorized(HangoCurrentLocationStatus());
    }
}

+ (PHAuthorizationStatus)photoLibraryStatus {
    if (@available(iOS 14, *)) {
        return [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    }
    return [PHPhotoLibrary authorizationStatus];
}

+ (BOOL)isPhotoLibraryStatusAuthorized:(PHAuthorizationStatus)status {
    return status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusLimited;
}

+ (void)requestPermission:(HangoPermissionType)type
       fromViewController:(UIViewController *)viewController
               completion:(HangoPermissionHandler)completion {
    if ([self isAuthorizedForPermission:type]) {
        if (completion) {
            completion(YES);
        }
        return;
    }

    UIViewController *presenter = viewController ?: [self topViewController];
    if ([self isDeniedForPermission:type]) {
        [self showDeniedAlertForPermission:type fromViewController:presenter];
        if (completion) {
            completion(NO);
        }
        return;
    }

    switch (type) {
        case HangoPermissionTypeCamera: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!granted) {
                        [self showDeniedAlertForPermission:type fromViewController:presenter];
                    }
                    if (completion) {
                        completion(granted);
                    }
                });
            }];
            break;
        }
        case HangoPermissionTypePhotoLibrary: {
            if (@available(iOS 14, *)) {
                [PHPhotoLibrary requestAuthorizationForAccessLevel:PHAccessLevelReadWrite handler:^(PHAuthorizationStatus status) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        BOOL granted = [self isPhotoLibraryStatusAuthorized:status];
                        if (!granted) {
                            [self showDeniedAlertForPermission:type fromViewController:presenter];
                        }
                        if (completion) {
                            completion(granted);
                        }
                    });
                }];
            } else {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        BOOL granted = status == PHAuthorizationStatusAuthorized;
                        if (!granted) {
                            [self showDeniedAlertForPermission:type fromViewController:presenter];
                        }
                        if (completion) {
                            completion(granted);
                        }
                    });
                }];
            }
            break;
        }
        case HangoPermissionTypeMicrophone: {
            [AVAudioSession.sharedInstance requestRecordPermission:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!granted) {
                        [self showDeniedAlertForPermission:type fromViewController:presenter];
                    }
                    if (completion) {
                        completion(granted);
                    }
                });
            }];
            break;
        }
        case HangoPermissionTypeLocation: {
            static HangoLocationPermissionRequester *requester;
            requester = [[HangoLocationPermissionRequester alloc] init];
            [requester requestWithCompletion:^(BOOL granted) {
                requester = nil;
                if (!granted) {
                    [self showDeniedAlertForPermission:type fromViewController:presenter];
                }
                if (completion) {
                    completion(granted);
                }
            }];
            break;
        }
    }
}

+ (BOOL)isDeniedForPermission:(HangoPermissionType)type {
    switch (type) {
        case HangoPermissionTypeCamera: {
            AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
            return status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted;
        }
        case HangoPermissionTypePhotoLibrary: {
            PHAuthorizationStatus status = [self photoLibraryStatus];
            return status == PHAuthorizationStatusDenied || status == PHAuthorizationStatusRestricted;
        }
        case HangoPermissionTypeMicrophone: {
            AVAudioSessionRecordPermission status = AVAudioSession.sharedInstance.recordPermission;
            return status == AVAudioSessionRecordPermissionDenied;
        }
        case HangoPermissionTypeLocation: {
            CLAuthorizationStatus status = HangoCurrentLocationStatus();
            return status == kCLAuthorizationStatusDenied || status == kCLAuthorizationStatusRestricted;
        }
    }
}

+ (void)showDeniedAlertForPermission:(HangoPermissionType)type fromViewController:(UIViewController *)viewController {
    if (!viewController) {
        return;
    }

    NSString *message = nil;
    switch (type) {
        case HangoPermissionTypeCamera:
            message = @"Please allow camera access in Settings to take photos.";
            break;
        case HangoPermissionTypePhotoLibrary:
            message = @"Please allow photo library access in Settings to choose photos.";
            break;
        case HangoPermissionTypeMicrophone:
            message = @"Please allow microphone access in Settings to record voice notes.";
            break;
        case HangoPermissionTypeLocation:
            message = @"Please allow location access in Settings to use personalized services.";
            break;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Permission Required"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (url) {
            [UIApplication.sharedApplication openURL:url options:@{} completionHandler:nil];
        }
    }]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

+ (void)presentImagePickerWithSourceType:(UIImagePickerControllerSourceType)sourceType
                      fromViewController:(UIViewController *)viewController
                                delegate:(id<UIImagePickerControllerDelegate, UINavigationControllerDelegate>)delegate {
    HangoPermissionType type = sourceType == UIImagePickerControllerSourceTypeCamera
        ? HangoPermissionTypeCamera
        : HangoPermissionTypePhotoLibrary;
    [self requestPermission:type fromViewController:viewController completion:^(BOOL granted) {
        if (!granted) {
            return;
        }
        if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
            return;
        }
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = sourceType;
        picker.delegate = delegate;
        picker.allowsEditing = YES;
        [viewController presentViewController:picker animated:YES completion:nil];
    }];
}

+ (UIViewController *)presentingViewControllerFromView:(UIView *)view {
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class]) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return [self topViewController];
}

+ (UIViewController *)topViewController {
    UIWindow *window = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *candidate in windowScene.windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
        if (window) {
            break;
        }
    }
    window = window ?: UIApplication.sharedApplication.windows.firstObject;
    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    if ([controller isKindOfClass:UINavigationController.class]) {
        return ((UINavigationController *)controller).topViewController ?: controller;
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        return ((UITabBarController *)controller).selectedViewController ?: controller;
    }
    return controller;
}

@end
