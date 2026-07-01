#import "HangoSessionManager.h"
#import "HangoDataStore.h"

static NSString * const kHangoIsLoggedInKey = @"HangoIsLoggedIn";

@interface HangoSessionManager ()
@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, strong, readwrite) HangoPersona *currentPersona;
@end

@implementation HangoSessionManager

+ (instancetype)shared {
    static HangoSessionManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HangoSessionManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _currentPersona = [HangoDataStore shared].currentPersona;
        _isLoggedIn = [NSUserDefaults.standardUserDefaults boolForKey:kHangoIsLoggedInKey];
    }
    return self;
}

- (void)persistLoginState {
    [NSUserDefaults.standardUserDefaults setBool:self.isLoggedIn forKey:kHangoIsLoggedInKey];
    [NSUserDefaults.standardUserDefaults synchronize];
}

- (void)loginWithEmail:(NSString *)email password:(NSString *)password {
    (void)password;
    HangoPersona *persona = [HangoDataStore shared].currentPersona;
    if (email.length) {
        persona.email = email;
    }
    self.currentPersona = persona;
    self.isLoggedIn = YES;
    [[HangoDataStore shared] persistCurrentPersonaProfile];
    [self persistLoginState];
}

- (void)registerWithEmail:(NSString *)email password:(NSString *)password {
    HangoPersona *persona = [HangoDataStore shared].currentPersona;
    persona.email = email.length ? email : persona.email;
    persona.bio = @"";
    [[HangoDataStore shared] clearSavedPersonaProfile];
    persona.email = email.length ? email : persona.email;
    [[HangoDataStore shared] assignPersonaIdForNewAccount];
    self.currentPersona = persona;
    self.isLoggedIn = YES;
    [[HangoDataStore shared] persistCurrentPersonaProfile];
    [self persistLoginState];
}

- (void)loginWithAppleCredentialIdentifier:(NSString *)personaIdentifier
                               email:(nullable NSString *)email
                         displayName:(nullable NSString *)displayName {
    HangoDataStore *store = [HangoDataStore shared];
    NSString *storedAppleId = [store appleCredentialIdentifier];
    BOOL isDifferentAppleAccount = storedAppleId.length > 0 && ![storedAppleId isEqualToString:personaIdentifier];

    if (![store hasPersistedPersonaProfile]) {
        [store clearSavedPersonaProfile];
        [store assignPersonaIdForNewAccount];
    } else if (isDifferentAppleAccount) {
        [store clearSavedPersonaProfile];
        [store assignPersonaIdForNewAccount];
    }

    [store saveAppleSignInWithCredentialIdentifier:personaIdentifier email:email displayName:displayName];
    self.currentPersona = store.currentPersona;
    self.isLoggedIn = YES;
    [self persistLoginState];
}

- (void)updateProfileWithName:(NSString *)name avatarName:(NSString *)avatarName bio:(NSString *)bio {
    [[HangoDataStore shared] updateCurrentPersonaProfileWithName:name
                                                      avatarName:avatarName
                                                     avatarImage:nil
                                                             bio:bio];
    self.currentPersona = [HangoDataStore shared].currentPersona;
}

- (void)updateProfileWithName:(NSString *)name avatarImage:(UIImage *)avatarImage {
    [[HangoDataStore shared] updateCurrentPersonaProfileWithName:name
                                                      avatarName:nil
                                                     avatarImage:avatarImage
                                                             bio:nil];
    self.currentPersona = [HangoDataStore shared].currentPersona;
}

- (void)logout {
    self.isLoggedIn = NO;
    [self persistLoginState];
}

- (void)deleteAccount {
    [[HangoDataStore shared] clearSavedPersonaProfile];
    [[HangoDataStore shared] clearAppleSignInCredentials];
    self.isLoggedIn = NO;
    self.currentPersona = nil;
    [self persistLoginState];
}

@end
