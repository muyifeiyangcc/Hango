#import "HangoLaunchPermissionManager.h"
#import "HangoAppConfig.h"
#import <CoreTelephony/CTCellularData.h>

@implementation HangoLaunchPermissionManager

+ (CTCellularData *)sharedCellularData {
    static CTCellularData *cellularData;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cellularData = [[CTCellularData alloc] init];
    });
    return cellularData;
}

+ (void)ensureNetworkAccessFromViewController:(UIViewController *)viewController
                                   completion:(HangoNetworkAccessHandler)completion {
    // Touch CTCellularData first so restriction callbacks are armed.
    (void)[self sharedCellularData];

    // Outbound traffic is required to surface the system wireless-data permission sheet.
    [self probeAPIHostWithCompletion:^(BOOL reachedHost, NSHTTPURLResponse *httpResponse, NSError *error) {
        CTCellularDataRestrictedState state = [self sharedCellularData].restrictedState;
        BOOL permissionDenied = (state == kCTCellularDataRestricted) || [self isNetworkPermissionDeniedError:error];
        BOOL permissionAllowed = (state == kCTCellularDataNotRestricted);
        BOOL hasUsableResponse = (httpResponse != nil) || reachedHost;

        if (permissionDenied) {
            // After an explicit deny, guide user to Settings. While the system sheet is up
            // (unknown + DataNotAllowed), don't cover it with another alert.
            if (state == kCTCellularDataRestricted) {
                [self presentNetworkPermissionHintFrom:viewController];
            }
            if (completion) {
                completion(NO);
            }
            return;
        }

        if (permissionAllowed || hasUsableResponse) {
            if (completion) {
                completion(YES);
            }
            return;
        }

        // Unknown restriction + no usable response: do not proceed.
        [self presentNetworkPermissionHintFrom:viewController];
        if (completion) {
            completion(NO);
        }
    }];
}

+ (void)probeAPIHostWithCompletion:(void (^)(BOOL reachedHost, NSHTTPURLResponse * _Nullable httpResponse, NSError * _Nullable error))completion {
    // Before featured window: probe the public site only — do not touch OPI/auth hosts.
    NSString *base = userLogingTime() ? HangoAPIURLString() : HangoOfficialSiteURLString();
    NSString *urlString = [NSString stringWithFormat:@"%@/", base];
    NSURL *url = [NSURL URLWithString:urlString];
    if (!url) {
        if (completion) {
            completion(NO, nil, [NSError errorWithDomain:@"HangoNetwork" code:-1 userInfo:nil]);
        }
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    request.timeoutInterval = 8.0;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.waitsForConnectivity = NO;
    configuration.timeoutIntervalForRequest = 8.0;
    configuration.timeoutIntervalForResource = 8.0;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        (void)data;
        NSHTTPURLResponse *http = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse *)response : nil;
        BOOL reached = (http != nil);
        dispatch_async(dispatch_get_main_queue(), ^{
            [session finishTasksAndInvalidate];
            if (completion) {
                completion(reached, http, error);
            }
        });
    }] resume];
}

+ (BOOL)isNetworkPermissionDeniedError:(NSError *)error {
    if (!error) {
        return NO;
    }
    for (NSError *node = error; node != nil; node = node.userInfo[NSUnderlyingErrorKey]) {
        if ([node.domain isEqualToString:NSURLErrorDomain] && node.code == NSURLErrorDataNotAllowed) {
            return YES;
        }
        id pathReport = node.userInfo[@"_NSURLErrorNWPathKey"];
        if ([pathReport isKindOfClass:NSString.class] &&
            [pathReport rangeOfString:@"Denied" options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

+ (BOOL)isConnectivityBlockedError:(NSError *)error {
    if (!error) {
        return NO;
    }
    if ([self isNetworkPermissionDeniedError:error]) {
        return YES;
    }
    if (![error.domain isEqualToString:NSURLErrorDomain]) {
        return NO;
    }
    switch (error.code) {
        case NSURLErrorNotConnectedToInternet:
        case NSURLErrorInternationalRoamingOff:
        case NSURLErrorCallIsActive:
        case NSURLErrorDataNotAllowed:
            return YES;
        default:
            return NO;
    }
}

+ (void)presentNetworkPermissionHintFrom:(UIViewController *)viewController {
    if (!viewController || viewController.presentedViewController) {
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:@"Network access is required. Please allow WLAN & Cellular Data for Hango, then try again."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
        if (settingsURL) {
            [[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
        }
    }]];
    [viewController presentViewController:alert animated:YES completion:nil];
}

@end
