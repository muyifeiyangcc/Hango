#import "HangoDisplayString.h"
#import "HangoIAPManager.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoHUD.h"
#import <StoreKit/StoreKit.h>

typedef void (^HangoBatchAcquireCompletion)(BOOL success, NSDictionary * _Nullable response, NSError * _Nullable error);

static NSDictionary<NSString *, NSNumber *> *HangoIAPSparkleMap(void) {
    static NSDictionary<NSString *, NSNumber *> *map;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        map = @{
            @"kuwifjdkwdvyeuex": @(400),
            @"mekmbbtkjjxsvgyw": @(800),
            @"hnqwpvmxzktrflcd": @(1780),
            @"idaxswttnfhdisim": @(2450),
            @"nwoglcwfvxqnygtk": @(5150),
            @"prprpvxjuvecvsiq": @(10800),
            @"qnrcuelbtiuflyky": @(14900),
            @"gpsgwupyifxtvavf": @(29400),
            @"ymohxnvpkqxutvab": @(34500),
            @"keecuncsynldehal": @(63700),
        };
    });
    return map;
}

static void HangoIAPShowLoading(void) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            HangoIAPShowLoading();
        });
        return;
    }
    [MBProgressHUD showActivityMessageInWindow:@"Processing..."];
}

static void HangoIAPHideLoading(void) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            HangoIAPHideLoading();
        });
        return;
    }
    [MBProgressHUD hideHUD];
}

@interface HangoIAPManager () <SKProductsRequestDelegate, SKPaymentTransactionObserver>
@property (nonatomic, strong) NSMutableDictionary<NSString *, SKProduct *> *productsById;
@property (nonatomic, assign) BOOL didRequestProducts;
@property (nonatomic, copy, nullable) void (^productsCompletion)(void);
@property (nonatomic, copy, nullable) void (^purchaseSuccess)(NSInteger sparkles);
@property (nonatomic, copy, nullable) void (^purchaseFailure)(NSError *error);
@property (nonatomic, copy, nullable) NSString *pendingProductId;
@property (nonatomic, strong, nullable) SKProductsRequest *sparkleProductsRequest;

@property (nonatomic, copy, nullable) NSString *pendingBatchNo;
@property (nonatomic, copy, nullable) NSString *pendingTraceCode;
@property (nonatomic, copy, nullable) HangoBatchAcquireCompletion pendingBatchCompletion;
@property (nonatomic, strong, nullable) SKProductsRequest *batchProductsRequest;
@end

@implementation HangoIAPManager

+ (instancetype)shared {
    static HangoIAPManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HangoIAPManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _productsById = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)start {
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self requestProductsWithCompletion:nil];
}

- (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

- (NSSet<NSString *> *)allProductIdentifiers {
    return [NSSet setWithArray:HangoIAPSparkleMap().allKeys];
}

- (void)requestProductsWithCompletion:(void (^)(void))completion {
    self.productsCompletion = completion;
    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[self allProductIdentifiers]];
    request.delegate = self;
    self.sparkleProductsRequest = request;
    [request start];
}

- (NSString *)localizedPriceForProductId:(NSString *)productId fallback:(NSString *)fallback {
    SKProduct *product = self.productsById[productId];
    if (!product) {
        return fallback ?: @"";
    }
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    formatter.locale = product.priceLocale;
    NSString *price = [formatter stringFromNumber:product.price];
    return price.length > 0 ? price : (fallback ?: @"");
}

- (NSInteger)sparklesForProductId:(NSString *)productId {
    return HangoIAPSparkleMap()[productId].integerValue;
}

- (void)purchaseProductId:(NSString *)productId
                  success:(void (^)(NSInteger))success
                  failure:(void (^)(NSError *))failure {
    if (productId.length == 0) {
        if (failure) {
            failure([NSError errorWithDomain:@"HangoIAP" code:0 userInfo:@{NSLocalizedDescriptionKey: @"Invalid product."}]);
        }
        return;
    }
    if (![self canMakePayments]) {
        if (failure) {
            failure([NSError errorWithDomain:@"HangoIAP" code:1 userInfo:@{NSLocalizedDescriptionKey: HangoDisplayString(HangoDisplayStringKeyPurchasesDisabled)}]);
        }
        return;
    }
    self.pendingProductId = productId;
    self.purchaseSuccess = success;
    self.purchaseFailure = failure;
    HangoIAPShowLoading();
    SKPayment *payment = [SKPayment paymentWithProductIdentifier:productId];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}

#pragma mark - Featured batch acquire

- (void)acquireBatchNo:(NSString *)batchNo
             traceCode:(NSString *)traceCode
            completion:(void (^)(BOOL, NSDictionary *, NSError *))completion {
    if (batchNo.length == 0) {
        [self finishBatchWithSuccess:NO response:nil error:[self batchErrorWithCode:10 message:@"Invalid batch."] completion:completion];
        return;
    }
    if (![SKPaymentQueue canMakePayments]) {
        [self finishBatchWithSuccess:NO response:nil error:[self batchErrorWithCode:11 message:@"Store access is disabled on this device."] completion:completion];
        return;
    }
    if (self.pendingBatchCompletion) {
        [self finishBatchWithSuccess:NO response:nil error:[self batchErrorWithCode:12 message:@"Another request is in progress."] completion:completion];
        return;
    }

    self.pendingBatchNo = batchNo;
    self.pendingTraceCode = traceCode;
    self.pendingBatchCompletion = completion;

    SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:batchNo]];
    request.delegate = self;
    self.batchProductsRequest = request;
    [request start];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    if (request == self.batchProductsRequest) {
        self.batchProductsRequest = nil;
        SKProduct *product = response.products.firstObject;
        if (!product) {
            [self settleBatchFailureWithError:[self batchErrorWithCode:13 message:@"Batch not found in App Store."]];
            return;
        }
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
        return;
    }

    if (request == self.sparkleProductsRequest) {
        self.sparkleProductsRequest = nil;
    }
    for (SKProduct *product in response.products) {
        if (product.productIdentifier.length > 0) {
            self.productsById[product.productIdentifier] = product;
        }
    }
    self.didRequestProducts = YES;
    if (self.productsCompletion) {
        dispatch_async(dispatch_get_main_queue(), self.productsCompletion);
    }
    self.productsCompletion = nil;
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    if (request == self.batchProductsRequest) {
        self.batchProductsRequest = nil;
        [self settleBatchFailureWithError:error ?: [self batchErrorWithCode:14 message:@"Unable to load batch."]];
        return;
    }

    if (request == self.sparkleProductsRequest) {
        self.sparkleProductsRequest = nil;
    }
    (void)error;
    self.didRequestProducts = YES;
    if (self.productsCompletion) {
        dispatch_async(dispatch_get_main_queue(), self.productsCompletion);
    }
    self.productsCompletion = nil;
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (SKPaymentTransaction *transaction in transactions) {
        NSString *productId = transaction.payment.productIdentifier;
        BOOL isSparkle = productId.length > 0 && HangoIAPSparkleMap()[productId] != nil;
        BOOL isBatch = self.pendingBatchNo.length > 0 && [productId isEqualToString:self.pendingBatchNo];

        if (isBatch) {
            [self handleBatchTransaction:transaction];
            continue;
        }
        if (!isSparkle) {
            continue;
        }

        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeSparkleTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedSparkleTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)handleBatchTransaction:(SKPaymentTransaction *)transaction {
    switch (transaction.transactionState) {
        case SKPaymentTransactionStatePurchased:
            [self completeBatchTransaction:transaction];
            break;
        case SKPaymentTransactionStateFailed:
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            [self settleBatchFailureWithError:transaction.error ?: [self batchErrorWithCode:15 message:@"Request failed."]];
            break;
        case SKPaymentTransactionStateRestored:
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
            break;
        default:
            break;
    }
}

- (void)completeSparkleTransaction:(SKPaymentTransaction *)transaction {
    HangoIAPShowLoading();
    NSString *productId = transaction.payment.productIdentifier ?: self.pendingProductId ?: @"";
    NSInteger sparkles = [self sparklesForProductId:productId];
    NSString *personaId = [HangoDataStore shared].currentPersona.personaId ?: @"";
    NSString *transactionId = transaction.transactionIdentifier ?: @"";
    [[HangoRequestManager shared] verifyIAPPurchaseWithProductId:productId
                                                   transactionId:transactionId
                                                        sparkles:sparkles
                                                       personaId:personaId
                                                      completion:^(BOOL verified, NSError *verifyError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            HangoIAPHideLoading();
            if (verified) {
                if (self.purchaseSuccess) {
                    self.purchaseSuccess(sparkles);
                }
            } else if (self.purchaseFailure) {
                self.purchaseFailure(verifyError ?: [NSError errorWithDomain:@"HangoIAP"
                                                                         code:2
                                                                     userInfo:@{NSLocalizedDescriptionKey: @"Receipt verification failed."}]);
            }
            self.purchaseSuccess = nil;
            self.purchaseFailure = nil;
            self.pendingProductId = nil;
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        });
    }];
}

- (void)failedSparkleTransaction:(SKPaymentTransaction *)transaction {
    NSError *error = transaction.error;
    dispatch_async(dispatch_get_main_queue(), ^{
        HangoIAPHideLoading();
        if (self.purchaseFailure && error.code != SKErrorPaymentCancelled) {
            self.purchaseFailure(error);
        }
        self.purchaseSuccess = nil;
        self.purchaseFailure = nil;
        self.pendingProductId = nil;
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    });
}

- (void)completeBatchTransaction:(SKPaymentTransaction *)transaction {
    NSString *ticket = transaction.transactionIdentifier ?: @"";
    NSString *traceCode = self.pendingTraceCode ?: @"";
    NSString *credential = [self currentStoreCredential];

    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];

    if (credential.length == 0) {
        [self settleBatchFailureWithError:[self batchErrorWithCode:16 message:@"Missing store credential."]];
        return;
    }

    [[HangoRequestManager shared] confirmPropsAcquireWithTicket:ticket
                                                   credential:credential
                                                    traceCode:traceCode
                                                   completion:^(NSDictionary *response, NSError *error) {
        if (error) {
            [self settleBatchFailureWithError:error];
            return;
        }
        [self settleBatchSuccessWithResponse:response];
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

#pragma mark - Batch settle helpers

- (void)settleBatchSuccessWithResponse:(NSDictionary *)response {
    HangoBatchAcquireCompletion completion = self.pendingBatchCompletion;
    [self clearPendingBatch];
    [self finishBatchWithSuccess:YES response:response error:nil completion:completion];
}

- (void)settleBatchFailureWithError:(NSError *)error {
    HangoBatchAcquireCompletion completion = self.pendingBatchCompletion;
    [self clearPendingBatch];
    [self finishBatchWithSuccess:NO response:nil error:error completion:completion];
}

- (void)clearPendingBatch {
    self.pendingBatchNo = nil;
    self.pendingTraceCode = nil;
    self.pendingBatchCompletion = nil;
}

- (void)finishBatchWithSuccess:(BOOL)success
                      response:(NSDictionary *)response
                         error:(NSError *)error
                    completion:(HangoBatchAcquireCompletion)completion {
    if (!completion) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(success, response, error);
    });
}

- (NSError *)batchErrorWithCode:(NSInteger)code message:(NSString *)message {
    return [NSError errorWithDomain:@"HangoPropsAcquire"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"Props error."}];
}

@end
