#import "HangoAccountStore.h"

NSErrorDomain const HangoAccountErrorDomain = @"HangoAccountErrorDomain";

static NSString * const kHangoRegisteredAccountsKey = @"HangoRegisteredAccounts_v1";
static NSString * const kHangoSeedEmail = @"hango123@gmail.com";
static NSString * const kHangoSeedPassword = @"123456";

@implementation HangoAccountStore

+ (instancetype)shared {
    static HangoAccountStore *store;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        store = [[HangoAccountStore alloc] init];
    });
    return store;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self ensureSeedAccounts];
    }
    return self;
}

- (NSString *)normalizedEmail:(NSString *)email {
    return [[email stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] lowercaseString];
}

- (NSMutableDictionary<NSString *, NSString *> *)mutableAccounts {
    NSDictionary *stored = [NSUserDefaults.standardUserDefaults dictionaryForKey:kHangoRegisteredAccountsKey];
    return stored ? [stored mutableCopy] : [NSMutableDictionary dictionary];
}

- (void)saveAccounts:(NSDictionary<NSString *, NSString *> *)accounts {
    [NSUserDefaults.standardUserDefaults setObject:accounts forKey:kHangoRegisteredAccountsKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)ensureSeedAccounts {
    NSMutableDictionary<NSString *, NSString *> *accounts = [self mutableAccounts];
    NSString *seedEmail = [self normalizedEmail:kHangoSeedEmail];
    if (accounts[seedEmail].length == 0) {
        accounts[seedEmail] = kHangoSeedPassword;
        [self saveAccounts:accounts];
    }
}

- (NSError *)errorWithCode:(HangoAccountErrorCode)code message:(NSString *)message {
    return [NSError errorWithDomain:HangoAccountErrorDomain
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message}];
}

- (BOOL)validateEmailFormat:(NSString *)email error:(NSError **)error {
    NSString *normalized = [self normalizedEmail:email];
    if (normalized.length == 0 || [normalized rangeOfString:@"@"].location == NSNotFound) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodeInvalidEmail
                                 message:@"Please enter a valid email address."];
        }
        return NO;
    }
    return YES;
}

- (BOOL)isRegisteredEmail:(NSString *)email {
    NSString *normalized = [self normalizedEmail:email];
    if (normalized.length == 0) {
        return NO;
    }
    return [self mutableAccounts][normalized].length > 0;
}

- (BOOL)isSeedTestAccountEmail:(NSString *)email {
    return [[self normalizedEmail:email] isEqualToString:[self normalizedEmail:kHangoSeedEmail]];
}

- (BOOL)registerEmail:(NSString *)email password:(NSString *)password error:(NSError **)error {
    if (![self validateEmailFormat:email error:error]) {
        return NO;
    }
    if (password.length == 0) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodePasswordRequired
                                 message:@"Please enter a password."];
        }
        return NO;
    }

    NSString *normalized = [self normalizedEmail:email];
    NSMutableDictionary<NSString *, NSString *> *accounts = [self mutableAccounts];
    if (accounts[normalized].length > 0) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodeAlreadyRegistered
                                 message:@"This email is already registered."];
        }
        return NO;
    }

    accounts[normalized] = password;
    [self saveAccounts:accounts];
    return YES;
}

- (BOOL)validateLoginWithEmail:(NSString *)email password:(NSString *)password error:(NSError **)error {
    if (![self validateEmailFormat:email error:error]) {
        return NO;
    }
    if (password.length == 0) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodePasswordRequired
                                 message:@"Please enter your password."];
        }
        return NO;
    }

    NSString *normalized = [self normalizedEmail:email];
    NSString *storedPassword = [self mutableAccounts][normalized];
    if (storedPassword.length == 0) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodeNotRegistered
                                 message:@"No account found for this email. Please sign up first."];
        }
        return NO;
    }
    if (![storedPassword isEqualToString:password]) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodeIncorrectPassword
                                 message:@"Incorrect password."];
        }
        return NO;
    }
    return YES;
}

- (BOOL)updatePasswordForEmail:(NSString *)email password:(NSString *)password error:(NSError **)error {
    if (![self validateEmailFormat:email error:error]) {
        return NO;
    }
    if (password.length == 0) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodePasswordRequired
                                 message:@"Please enter a password."];
        }
        return NO;
    }

    NSString *normalized = [self normalizedEmail:email];
    NSMutableDictionary<NSString *, NSString *> *accounts = [self mutableAccounts];
    if (accounts[normalized].length == 0) {
        if (error) {
            *error = [self errorWithCode:HangoAccountErrorCodeNotRegistered
                                 message:@"No account found for this email. Please sign up first."];
        }
        return NO;
    }

    accounts[normalized] = password;
    [self saveAccounts:accounts];
    return YES;
}

- (void)removeAccountWithEmail:(NSString *)email {
    NSString *normalized = [self normalizedEmail:email];
    if (normalized.length == 0) {
        return;
    }
    NSMutableDictionary<NSString *, NSString *> *accounts = [self mutableAccounts];
    if (!accounts[normalized]) {
        return;
    }
    [accounts removeObjectForKey:normalized];
    [self saveAccounts:accounts];
}

@end
