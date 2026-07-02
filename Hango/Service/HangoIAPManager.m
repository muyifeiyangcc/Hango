#import "HangoDisplayString.h"
#import "HangoIAPManager.h"
#import "HangoDataStore.h"
#import "HangoRequestManager.h"
#import "HangoHUD.h"
#import <StoreKit/StoreKit.h>

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

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
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
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
                break;
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
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

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
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

@end
