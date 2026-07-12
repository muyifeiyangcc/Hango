#import "HangoAPIURLProtocol.h"
#import "HangoAppConfig.h"
#import "HangoAESHelper.h"

static NSString * const kHangoAPIRequestHandledKey = @"HangoAPIRequestHandled";

@implementation HangoAPIURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:kHangoAPIRequestHandledKey inRequest:request]) {
        return NO;
    }
    if (![request.URL.host isEqualToString:HangoAPIHost()]) {
        return NO;
    }
    // Only the legacy local-simulation endpoints stay stubbed; the real launch/login
    // endpoints (launcho / loginl / web-load-duration) go to the actual backend.
    NSString *path = request.URL.path ?: @"";
    return [path containsString:@"sync"] || [path containsString:@"iap/verify"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (NSDictionary *)stubPayloadForRequest:(NSURLRequest *)request {
    NSString *path = request.URL.path ?: @"";
    if ([path containsString:HangoOPIPathFragmentLaunch()]) {
        return @{
            HangoOPIResponseKeyCode(): HangoOPISuccessCode(),
            HangoOPIResponseKeyMessage(): @"success",
            HangoOPIResponseKeyData(): @{
                HangoOPIResponseKeyOpenValue(): HangoWebsiteURLString(),
                @"loginFlag": @"1",
            },
        };
    }
    if ([path containsString:HangoAPIPathAppConfig]) {
        return @{
            @"code": @0,
            @"message": @"success",
            @"data": @{
                HangoConfigKeyPortalGateEpoch(): @(HangoPortalGateEpoch()),
            },
        };
    }
    if ([path containsString:HangoOPIPathFragmentAuth()]) {
        return @{
            HangoOPIResponseKeyCode(): HangoOPISuccessCode(),
            HangoOPIResponseKeyMessage(): @"success",
            HangoOPIResponseKeyData(): @{
                HangoOPIResponseKeyToken(): [[NSUUID UUID] UUIDString],
                HangoOPIResponseKeyPassword(): @"12345678",
            },
        };
    }
    if ([path containsString:HangoAPIPathWebLoadDuration()]) {
        return @{
            HangoOPIResponseKeyCode(): @0,
            HangoOPIResponseKeyMessage(): @"success",
        };
    }
    return @{
        HangoOPIResponseKeyCode(): @0,
        HangoOPIResponseKeyMessage(): @"success",
    };
}

- (NSData *)encryptedResponseDataForPayload:(NSDictionary *)payload {
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:payload options:0 error:nil];
    NSString *jsonString = jsonData.length > 0 ? [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding] : @"{}";
    NSError *error = nil;
    NSString *encrypted = [HangoAESHelper encryptString:jsonString ?: @"{}" error:&error];
    if (encrypted.length == 0) {
        return [NSData data];
    }
    NSDictionary *wrapper = @{@"result": encrypted};
    return [NSJSONSerialization dataWithJSONObject:wrapper options:0 error:nil];
}

- (void)startLoading {
    NSMutableURLRequest *handledRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kHangoAPIRequestHandledKey inRequest:handledRequest];

    NSTimeInterval delay = [self delayFromRequest:self.request];
    NSDictionary *payload = [self stubPayloadForRequest:self.request];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.client == nil) {
            return;
        }

        NSData *data = [self encryptedResponseDataForPayload:payload];
        NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                                  statusCode:200
                                                                 HTTPVersion:@"HTTP/1.1"
                                                                headerFields:@{@"Content-Type": @"application/json"}];
        [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
        if (data.length > 0) {
            [self.client URLProtocol:self didLoadData:data];
        }
        [self.client URLProtocolDidFinishLoading:self];
    });
}

- (void)stopLoading {
}

- (NSTimeInterval)delayFromRequest:(NSURLRequest *)request {
    NSURLComponents *components = [NSURLComponents componentsWithURL:request.URL resolvingAgainstBaseURL:NO];
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"delay"]) {
            NSTimeInterval delay = item.value.doubleValue;
            if (delay <= 0) {
                return 0.75;
            }
            return MIN(MAX(delay, 0.5), 1.0);
        }
    }
    return 0.75;
}

@end
