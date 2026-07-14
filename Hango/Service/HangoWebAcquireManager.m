#import "HangoWebAcquireManager.h"
#import "HangoRequestManager.h"
#import <StoreKit/StoreKit.h>

typedef void (^HangoWebAcquireCompletion)(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error);

@interface HangoWebAcquireManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, copy, nullable) NSString *pendingBatchNo;
@property (nonatomic, copy, nullable) NSString *pendingTraceCode;
@property (nonatomic, copy, nullable) HangoWebAcquireCompletion pendingCompletion;
@property (nonatomic, strong, nullable) SKProductsRequest *productsRequest;
@property (nonatomic, assign) BOOL observing;
@end

@implementation HangoWebAcquireManager

+ (instancetype)shared {
    static HangoWebAcquireManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HangoWebAcquireManager alloc] init];
    });
    return manager;
}

- (void)acquireBatchNo:(NSString *)batchNo
             traceCode:(NSString *)traceCode
            completion:(void (^)(BOOL, NSDictionary *, NSError *))completion {
    if (batchNo.length == 0) {
        [self finishWithSuccess:NO response:nil error:[self errorWithCode:10 message:@"Invalid batch."] completion:completion];
        return;
    }
    if (![SKPaymentQueue canMakePayments]) {
        [self finishWithSuccess:NO response:nil error:[self errorWithCode:11 message:@"Store access is disabled on this device."] completion:completion];
        return;
    }
    if (self.pendingCompletion) {
        [self finishWithSuccess:NO response:nil error:[self errorWithCode:12 message:@"Another request is in progress."] completion:completion];
        return;
    }

    self.pendingBatchNo = batchNo;
    self.pendingTraceCode = traceCode;
    self.pendingCompletion = completion;

    if (!self.observing) {
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
        self.observing = YES;
    }

    self.productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:batchNo]];
    self.productsRequest.delegate = self;
    [self.productsRequest start];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    SKProduct *product = response.products.firstObject;
    self.productsRequest = nil;
    if (!product) {
        [self settleFailureWithError:[self errorWithCode:13 message:@"Batch not found in App Store."]];
        return;
    }
    SKPayment *payment = [SKPayment paymentWithProduct:product];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    self.productsRequest = nil;
    [self settleFailureWithError:error ?: [self errorWithCode:14 message:@"Unable to load batch."]];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *batchNo = transaction.payment.productIdentifier;
        BOOL isOurs = self.pendingBatchNo.length > 0 && [batchNo isEqualToString:self.pendingBatchNo];
        if (!isOurs) {
            continue;
        }
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self handleCompletedTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                [self settleFailureWithError:transaction.error ?: [self errorWithCode:15 message:@"Request failed."]];
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)handleCompletedTransaction:(SKPaymentTransaction *)transaction {
    NSString *ticket = transaction.transactionIdentifier ?: @"";
    NSString *traceCode = self.pendingTraceCode ?: @"";
    NSString *credential = [self currentStoreCredential];

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    if (credential.length == 0) {
        [self settleFailureWithError:[self errorWithCode:16 message:@"Missing store credential."]];
        return;
    }

    [[HangoRequestManager shared] confirmWebAcquireWithTicket:ticket
                                                   credential:credential
                                                    traceCode:traceCode
                                                   completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            [self settleFailureWithError:error];
            return;
        }
        [self settleSuccessWithResponse:response];
    }];
}

- (NSString *)currentStoreCredential {
    NSURL *receiptURL = [NSBundle mainBundle].appStoreReceiptURL;
    if (!receiptURL) {
        return @"";
    }
    NSData *receiptData = [NSData dataWithContentsOfURL:receiptURL];
    if (receiptData.length == 0) {
        return @"";
    }
    return [receiptData base64EncodedStringWithOptions:0];
}

#pragma mark - Settle helpers

- (void)settleSuccessWithResponse:(NSDictionary *)response {
    HangoWebAcquireCompletion completion = self.pendingCompletion;
    [self clearPending];
    [self finishWithSuccess:YES response:response error:nil completion:completion];
}

- (void)settleFailureWithError:(NSError *)error {
    HangoWebAcquireCompletion completion = self.pendingCompletion;
    [self clearPending];
    [self finishWithSuccess:NO response:nil error:error completion:completion];
}

- (void)clearPending {
    self.pendingBatchNo = nil;
    self.pendingTraceCode = nil;
    self.pendingCompletion = nil;
}

- (void)finishWithSuccess:(BOOL)success
                 response:(NSDictionary *)response
                    error:(NSError *)error
               completion:(HangoWebAcquireCompletion)completion {
    if (!completion) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(success, response, error);
    });
}

- (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    return [NSError errorWithDomain:@"HangoWebAcquire"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"Acquire error."}];
}

@end
