#import "HangoRequestManager.h"
#import "HangoAppConfig.h"
#import "HangoAPIURLProtocol.h"
#import "HangoCrypto.h"
#import "HangoHUD.h"

@implementation HangoRequestManager {
    NSURLSession *_session;
    __weak HangoHUD *_activeHUD;
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
        configuration.protocolClasses = @[[HangoAPIURLProtocol class]];
        configuration.timeoutIntervalForRequest = 15;
        _session = [NSURLSession sessionWithConfiguration:configuration];
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
    HangoHUD *hud = [HangoHUD showHUDAddedTo:container animated:YES];
    hud.labelText = @"";
    _activeHUD = hud;
}

- (void)hideHUD {
    [_activeHUD hide:YES];
    _activeHUD = nil;
}

- (void)runLocalOperation:(id (^)(void))operation completion:(HangoRequestCompletion)completion {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        id result = operation ? operation() : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(result, nil);
            }
        });
    });
}

- (void)postJSONToPath:(NSString *)path
            parameters:(NSDictionary *)parameters
            completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion {
    NSURL *baseURL = [NSURL URLWithString:HangoAPIBaseURLString];
    NSURL *url = [NSURL URLWithString:path relativeToURL:baseURL];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    if (parameters) {
        request.HTTPBody = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    }
    [[_session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, error);
                }
            });
            return;
        }
        NSDictionary *json = nil;
        if (data.length > 0) {
            id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            if ([object isKindOfClass:NSDictionary.class]) {
                json = object;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(json, nil);
            }
        });
    }] resume];
}

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(UIView *)view
                showsHUD:(BOOL)showsHUD
               operation:(id (^)(void))operation
              completion:(HangoRequestCompletion)completion {
    if (!showsHUD) {
        [self runLocalOperation:operation completion:completion];
        return;
    }

    NSTimeInterval actualDelay = [self normalizedDelay:delay];
    [self showHUDInView:view];

    NSString *path = [NSString stringWithFormat:@"sync?delay=%.2f", actualDelay];
    [self postJSONToPath:path parameters:@{} completion:^(NSDictionary *response, NSError *error) {
        [self hideHUD];
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        id result = operation ? operation() : nil;
        if (completion) {
            completion(result, nil);
        }
    }];
}

- (void)requestWithDelay:(NSTimeInterval)delay
                  inView:(UIView *)view
                showsHUD:(BOOL)showsHUD
              completion:(dispatch_block_t)completion {
    [self requestWithDelay:delay inView:view showsHUD:showsHUD operation:^id {
        return nil;
    } completion:^(__unused id result, __unused NSError *error) {
        if (completion) {
            completion();
        }
    }];
}

- (void)verifyIAPPurchaseWithProductId:(NSString *)productId
                         transactionId:(NSString *)transactionId
                              sparkles:(NSInteger)sparkles
                             personaId:(NSString *)personaId
                            completion:(void (^)(BOOL, NSError *))completion {
    NSInteger timestamp = (NSInteger)[[NSDate date] timeIntervalSince1970];
    NSString *sign = [HangoCrypto iapSignWithPersonaId:personaId
                                              productId:productId
                                          transactionId:transactionId
                                               sparkles:sparkles
                                              timestamp:timestamp];
    NSDictionary *parameters = @{
        @"personaId": personaId ?: @"",
        @"productId": productId ?: @"",
        @"transactionId": transactionId ?: @"",
        @"sparkles": @(sparkles),
        @"timestamp": @(timestamp),
        @"sign": sign ?: @"",
    };

    NSTimeInterval delay = [self normalizedDelay:0.75];
    NSString *path = [NSString stringWithFormat:@"iap/verify?delay=%.2f", delay];
    [self postJSONToPath:path parameters:parameters completion:^(NSDictionary *responseObject, NSError *error) {
        if (error) {
            if (completion) {
                completion(NO, error);
            }
            return;
        }
        BOOL verified = NO;
        NSNumber *code = responseObject[@"code"];
        verified = code != nil && code.integerValue == 0;
        if (completion) {
            if (verified) {
                completion(YES, nil);
            } else {
                NSError *verifyError = [NSError errorWithDomain:@"HangoIAP"
                                                           code:2
                                                       userInfo:@{NSLocalizedDescriptionKey: @"Receipt verification failed."}];
                completion(NO, verifyError);
            }
        }
    }];
}

@end
