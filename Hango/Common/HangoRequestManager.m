#import "HangoRequestManager.h"
#import "HangoBridgeString.h"
#import "HangoAppConfig.h"
#import "HangoAPIURLProtocol.h"
#import "HangoCrypto.h"
#import "HangoHUD.h"
#import "HangoDeviceHelper.h"
#import "HangoAPITokenStore.h"
#import "HangoParcel.h"
#import "HangoClientProfileAssembler.h"
#import <netdb.h>
#import <arpa/inet.h>

@implementation HangoRequestManager {
    NSURLSession *_session;
    NSURLSession *_launchSession;
    NSURLSessionDataTask *_launchDataTask;
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
        [self rebuildNetworkSession];
        [self rebuildLaunchNetworkSession];
    }
    return self;
}

- (void)rebuildNetworkSession {
    if (_session) {
        [_session invalidateAndCancel];
    }
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.protocolClasses = @[[HangoAPIURLProtocol class]];
    configuration.timeoutIntervalForRequest = 15;
    _session = [NSURLSession sessionWithConfiguration:configuration];
}

- (void)rebuildLaunchNetworkSession {
    [_launchDataTask cancel];
    _launchDataTask = nil;
    if (_launchSession) {
        [_launchSession invalidateAndCancel];
    }
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.protocolClasses = @[[HangoAPIURLProtocol class]];
    configuration.timeoutIntervalForRequest = 10;
    configuration.timeoutIntervalForResource = 15;
    configuration.waitsForConnectivity = NO;
    _launchSession = [NSURLSession sessionWithConfiguration:configuration];
}

- (void)resetNetworkSessionForLaunchRetry {
    NSLog(@"[HangoAPI] resetting launch URL session");
    [self rebuildLaunchNetworkSession];
}

- (void)cancelLaunchRequest {
    [_launchDataTask cancel];
    _launchDataTask = nil;
}

- (void)preflightDNSForAPIHostWithCompletion:(void (^)(BOOL resolved))completion {
    NSString *host = [NSURL URLWithString:HangoAPIURLString()].host;
    if (host.length == 0) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        const char *hostCString = host.UTF8String;
        struct addrinfo hints;
        memset(&hints, 0, sizeof(hints));
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_family = AF_UNSPEC;
        struct addrinfo *result = NULL;
        int status = getaddrinfo(hostCString, "443", &hints, &result);
        if (result) {
            freeaddrinfo(result);
        }
        BOOL resolved = status == 0;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"[HangoAPI] DNS preflight %@ resolved=%@", host, resolved ? @"YES" : @"NO");
            if (completion) {
                completion(resolved);
            }
        });
    });
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

- (void)applyCommonHeadersToRequest:(NSMutableURLRequest *)request {
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[HangoDeviceHelper appVersion] forHTTPHeaderField:HangoOPIKeyAppVersion()];
    [request setValue:[HangoDeviceHelper deviceNo] forHTTPHeaderField:HangoOPILoginKeyDeviceNo()];
    [request setValue:[HangoAPITokenStore pushToken] forHTTPHeaderField:HangoOPIHeaderPushToken()];
    [request setValue:[HangoAPITokenStore sessionToken] forHTTPHeaderField:HangoOPIHeaderLoginToken()];
    [request setValue:HangoAppId forHTTPHeaderField:HangoOPIKeyAppId()];
}

- (NSString *)jsonStringFromParameters:(NSDictionary *)parameters {
    NSDictionary *payload = parameters ?: @{};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    if (jsonData.length == 0) {
        return @"{}";
    }
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] ?: @"{}";
}

- (NSDictionary *)dictionaryFromResponseData:(NSData *)data error:(NSError **)error {
    if (data.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:@"HangoAPI"
                                         code:-1
                                     userInfo:@{NSLocalizedDescriptionKey: @"Empty response."}];
        }
        return nil;
    }

    id outerObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    if ([outerObject isKindOfClass:NSDictionary.class]) {
        NSDictionary *outer = (NSDictionary *)outerObject;
        NSString *foldedResult = [outer[HangoOPIResponseKeyResult()] isKindOfClass:NSString.class] ? outer[HangoOPIResponseKeyResult()] : nil;
        if (foldedResult.length > 0) {
            NSString *opened = [HangoParcel openBlob:foldedResult];
            NSData *openedData = [opened dataUsingEncoding:NSUTF8StringEncoding];
            id innerObject = openedData.length > 0 ? [NSJSONSerialization JSONObjectWithData:openedData options:0 error:nil] : nil;
            if ([innerObject isKindOfClass:NSDictionary.class]) {
                // Preserve the outer envelope's code/message so callers can still
                // decide success by code (the opened inner payload omits them).
                NSMutableDictionary *merged = [innerObject mutableCopy];
                if (outer[HangoOPIResponseKeyCode()] != nil) {
                    merged[HangoOPIResponseKeyCode()] = outer[HangoOPIResponseKeyCode()];
                }
                if (outer[HangoOPIResponseKeyMessage()] != nil) {
                    merged[HangoOPIResponseKeyMessage()] = outer[HangoOPIResponseKeyMessage()];
                }
                return merged;
            }
        }
        return outer;
    }

    NSString *bodyString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (bodyString.length > 0) {
        NSString *opened = [HangoParcel openBlob:bodyString];
        NSData *openedData = [opened dataUsingEncoding:NSUTF8StringEncoding];
        id innerObject = openedData.length > 0 ? [NSJSONSerialization JSONObjectWithData:openedData options:0 error:nil] : nil;
        if ([innerObject isKindOfClass:NSDictionary.class]) {
            return innerObject;
        }
    }

    if (error) {
        *error = [NSError errorWithDomain:@"HangoAPI"
                                     code:-2
                                 userInfo:@{NSLocalizedDescriptionKey: @"Unable to parse response."}];
    }
    return nil;
}

- (void)postJSONToPath:(NSString *)path
            parameters:(NSDictionary *)parameters
            completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion {
    NSString *urlString = [path hasPrefix:@"/"]
        ? [HangoAPIURLString() stringByAppendingString:path]
        : nil;
    NSURL *url = urlString.length > 0
        ? [NSURL URLWithString:urlString]
        : [NSURL URLWithString:path relativeToURL:[NSURL URLWithString:[HangoAPIURLString() stringByAppendingString:@"/v1/"]]];
    [self postParcelJSONToURL:url parameters:parameters completion:completion];
}

- (void)postParcelJSONToURL:(NSURL *)url
                 parameters:(NSDictionary *)parameters
                    session:(NSURLSession *)session
         trackTaskAsLaunch:(BOOL)trackTaskAsLaunch
                 completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion {
    if (!url) {
        if (completion) {
            completion(nil, [NSError errorWithDomain:@"HangoAPI"
                                                 code:-4
                                             userInfo:@{NSLocalizedDescriptionKey: @"Invalid request URL."}]);
        }
        return;
    }

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    [self applyCommonHeadersToRequest:request];

    NSString *jsonString = [self jsonStringFromParameters:parameters];
    NSError *foldError = nil;
    NSString *foldedBody = [HangoParcel foldText:jsonString error:&foldError];
    if (foldedBody.length == 0) {
        if (completion) {
            completion(nil, foldError ?: [NSError errorWithDomain:@"HangoAPI"
                                                             code:-3
                                                         userInfo:@{NSLocalizedDescriptionKey: @"Request fold failed."}]);
        }
        return;
    }
    request.HTTPBody = [foldedBody dataUsingEncoding:NSUTF8StringEncoding];

    NSURLSession *activeSession = session ?: _session;
    NSURLSessionDataTask *task = [activeSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (trackTaskAsLaunch) {
            self->_launchDataTask = nil;
        }
        NSInteger statusCode = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *)response).statusCode : -1;
        NSString *rawBody = data.length > 0 ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
        NSLog(@"[HangoAPI] POST %@ status=%ld error=%@ rawBody=%@", url.absoluteString, (long)statusCode, error, rawBody);
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(nil, error);
                }
            });
            return;
        }
        NSError *parseError = nil;
        NSDictionary *json = [self dictionaryFromResponseData:data error:&parseError];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(json, json ? nil : parseError);
            }
        });
    }];
    if (trackTaskAsLaunch) {
        _launchDataTask = task;
    }
    [task resume];
}

- (void)postParcelJSONToURL:(NSURL *)url
                 parameters:(NSDictionary *)parameters
                 completion:(void (^)(NSDictionary * _Nullable response, NSError * _Nullable error))completion {
    [self postParcelJSONToURL:url parameters:parameters session:_session trackTaskAsLaunch:NO completion:completion];
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

    // Before featured window: keep native HUD delays local — no OPI sync traffic.
    if (!userLogingTime()) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(actualDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hideHUD];
            id result = operation ? operation() : nil;
            if (completion) {
                completion(result, nil);
            }
        });
        return;
    }

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

- (NSDictionary *)dataDictionaryFromResponse:(NSDictionary *)response {
    if (![response isKindOfClass:NSDictionary.class]) {
        return nil;
    }
    NSDictionary *data = response[HangoOPIResponseKeyData()];
    if ([data isKindOfClass:NSDictionary.class]) {
        return data;
    }
    return response;
}

- (NSError *)apiErrorFromResponse:(NSDictionary *)response fallback:(NSString *)fallback {
    NSString *detail = [response[HangoOPIResponseKeyMessage()] isKindOfClass:NSString.class] ? response[HangoOPIResponseKeyMessage()] : fallback;
    return [NSError errorWithDomain:@"HangoAPI"
                               code:([response[HangoOPIResponseKeyCode()] respondsToSelector:@selector(integerValue)] ? [response[HangoOPIResponseKeyCode()] integerValue] : -1)
                           userInfo:@{NSLocalizedDescriptionKey: detail ?: @"Request failed."}];
}

- (void)fetchAppConfigWithCompletion:(HangoAPIResponseHandler)completion {
    [self postJSONToPath:HangoAPIPathAppConfig parameters:@{} completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        NSDictionary *data = [self dataDictionaryFromResponse:response];
        if (completion) {
            completion(data ?: @{}, nil);
        }
    }];
}

- (void)fetchFeaturedContentConfigWithCompletion:(HangoAPIResponseHandler)completion {
    NSDictionary *payload = [HangoClientProfileAssembler appConfigRequestBody];
    NSString *urlString = [HangoAPIURLString() stringByAppendingString:HangoAPIPathAppLaunch()];
    NSURL *url = [NSURL URLWithString:urlString];
    [self postParcelJSONToURL:url
                   parameters:payload
                      session:_launchSession
           trackTaskAsLaunch:YES
                   completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        if (![response isKindOfClass:NSDictionary.class] || response.count == 0) {
            if (completion) {
                completion(nil, [NSError errorWithDomain:@"HangoAPI"
                                                   code:-5
                                               userInfo:@{NSLocalizedDescriptionKey: @"Empty launch response."}]);
            }
            return;
        }
        if (completion) {
            completion(response, nil);
        }
    }];
}

- (void)submitAuthWithParameters:(NSDictionary *)parameters
                          inView:(UIView *)view
                        showsHUD:(BOOL)showsHUD
                      completion:(HangoAPIResponseHandler)completion {
    if (showsHUD) {
        [self showHUDInView:view];
    }

    [self postJSONToPath:HangoAPIPathAuthEntry() parameters:parameters completion:^(NSDictionary *response, NSError *error) {
        if (showsHUD) {
            [self hideHUD];
        }
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        NSString *code = [response[HangoOPIResponseKeyCode()] isKindOfClass:NSString.class]
            ? response[HangoOPIResponseKeyCode()]
            : ([response[HangoOPIResponseKeyCode()] respondsToSelector:@selector(stringValue)] ? [response[HangoOPIResponseKeyCode()] stringValue] : nil);
        if (![code isEqualToString:HangoOPISuccessCode()]) {
            if (completion) {
                completion(nil, [self apiErrorFromResponse:response fallback:@"Entry failed."]);
            }
            return;
        }
        if (completion) {
            completion(response, nil);
        }
    }];
}

- (void)reportOpenTimetMs:(NSTimeInterval)durationMs completion:(HangoAPIResponseHandler)completion {
    // Doc 3.2.4: opiBody `timeo` = elapsed load time in milliseconds (String).
    NSString *openTime = [@((NSInteger)round(durationMs)) stringValue];
    NSDictionary *parameters = @{
        HangoOPIKeyOpenTime(): openTime,
    };
    [self postJSONToPath:HangoAPIPathOpenTimet() parameters:parameters completion:^(NSDictionary *response, NSError *error) {
        if (completion) {
            completion(response, error);
        }
    }];
}

- (void)confirmPropsAcquireWithTicket:(NSString *)ticket
                          credential:(NSString *)credential
                           traceCode:(NSString *)traceCode
                          completion:(HangoAPIResponseHandler)completion {
    NSData *callbackData = [NSJSONSerialization dataWithJSONObject:@{ HangoBridgeTraceKey(): traceCode ?: @"" }
                                                          options:0
                                                            error:nil];
    NSString *callbackJSON = callbackData.length > 0
        ? [[NSString alloc] initWithData:callbackData encoding:NSUTF8StringEncoding]
        : @"{}";
    NSDictionary *parameters = @{
        HangoOPIPayKeyPurchaseId(): ticket ?: @"",
        HangoOPIPayKeyReceipt(): credential ?: @"",
        HangoOPIPayKeyCallback(): callbackJSON ?: @"{}",
    };
    [self postJSONToPath:HangoAPIPathIOSPayVerify() parameters:parameters completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            if (completion) {
                completion(nil, error);
            }
            return;
        }
        NSString *code = [response[HangoOPIResponseKeyCode()] isKindOfClass:NSString.class]
            ? response[HangoOPIResponseKeyCode()]
            : ([response[HangoOPIResponseKeyCode()] respondsToSelector:@selector(stringValue)] ? [response[HangoOPIResponseKeyCode()] stringValue] : nil);
        if (![code isEqualToString:HangoOPISuccessCode()]) {
            if (completion) {
                completion(nil, [self apiErrorFromResponse:response fallback:@"Confirmation failed."]);
            }
            return;
        }
        if (completion) {
            completion(response, nil);
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
