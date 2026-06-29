#import "HangoRequestManager.h"
#import "HangoMockURLProtocol.h"
#import <AFNetworking/AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>

static NSString * const kHangoMockBaseURLString = @"https://mock.hango.app/v1/";

@implementation HangoRequestManager {
    AFHTTPSessionManager *_sessionManager;
    __weak MBProgressHUD *_activeHUD;
}

+ (instancetype)shared {
    static HangoRequestManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HangoRequestManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        configuration.protocolClasses = @[[HangoMockURLProtocol class]];

        NSURL *baseURL = [NSURL URLWithString:kHangoMockBaseURLString];
        _sessionManager = [[AFHTTPSessionManager alloc] initWithBaseURL:baseURL sessionConfiguration:configuration];
        _sessionManager.requestSerializer = [AFJSONRequestSerializer serializer];
        _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
        _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/plain", nil];
        _sessionManager.requestSerializer.timeoutInterval = 15;
    }
    return self;
}

- (NSTimeInterval)normalizedDelay:(NSTimeInterval)delay {
    if (delay <= 0) {
        return 0.75;
    }
    return MIN(MAX(delay, 0.5), 1.0);
}

- (UIView *)hudContainerForView:(UIView *)view {
    if (view) {
        return view;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
        if (windowScene.windows.firstObject) {
            return windowScene.windows.firstObject;
        }
    }
    return nil;
}

- (void)showHUDInView:(UIView *)view {
    [self hideHUD];
    UIView *container = [self hudContainerForView:view];
    if (!container) {
        return;
    }
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:container animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.labelText = @"";
    _activeHUD = hud;
}

- (void)hideHUD {
    [_activeHUD hide:YES];
    _activeHUD = nil;
}

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(UIView *)view
               operation:(id (^)(void))operation
              completion:(HangoRequestCompletion)completion {
    NSTimeInterval actualDelay = [self normalizedDelay:delay];
    [self showHUDInView:view];

    NSString *path = [NSString stringWithFormat:@"simulate?delay=%.2f", actualDelay];
    [_sessionManager POST:path
               parameters:@{}
                  headers:nil
                 progress:nil
                  success:^(__unused NSURLSessionDataTask *task, __unused id responseObject) {
        [self hideHUD];
        id result = operation ? operation() : nil;
        if (completion) {
            completion(result, nil);
        }
    } failure:^(__unused NSURLSessionDataTask *task, NSError *error) {
        [self hideHUD];
        if (completion) {
            completion(nil, error);
        }
    }];
}

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(UIView *)view
              completion:(dispatch_block_t)completion {
    [self requestWithDelay:delay inView:view operation:^id {
        return nil;
    } completion:^(__unused id result, __unused NSError *error) {
        if (completion) {
            completion();
        }
    }];
}

@end
