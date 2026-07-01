#import "HangoAPIURLProtocol.h"
#import "HangoAppConfig.h"

static NSString * const kHangoAPIRequestHandledKey = @"HangoAPIRequestHandled";

@implementation HangoAPIURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if ([NSURLProtocol propertyForKey:kHangoAPIRequestHandledKey inRequest:request]) {
        return NO;
    }
    return [request.URL.host isEqualToString:HangoWebsiteHost];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

+ (BOOL)requestIsCacheEquivalent:(NSURLRequest *)a toRequest:(NSURLRequest *)b {
    return [super requestIsCacheEquivalent:a toRequest:b];
}

- (void)startLoading {
    NSMutableURLRequest *handledRequest = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:kHangoAPIRequestHandledKey inRequest:handledRequest];

    NSTimeInterval delay = [self delayFromRequest:self.request];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.client == nil) {
            return;
        }

        NSData *data = [NSJSONSerialization dataWithJSONObject:@{
            @"code": @0,
            @"message": @"success"
        } options:0 error:nil];
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
