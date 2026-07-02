#import "HangoSessionManager.h"
#import "HangoDataStore.h"
#import "HangoAccountStore.h"
#import "HangoGuestGuard.h"

static NSString * const kHangoIsLoggedInKey = @"HangoIsLoggedIn";
static NSString * const kHangoIsGuestKey = @"HangoIsGuest";
static NSString * const kHangoSavedPersonaEmailKey = @"HangoSavedPersonaEmail";

@interface HangoSessionManager ()
@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, assign, readwrite) BOOL isGuest;
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
        _isGuest = [NSUserDefaults.standardUserDefaults boolForKey:kHangoIsGuestKey];
        if (_isLoggedIn) {
            _isGuest = NO;
        }
    }
    return self;
}

- (void)persistSessionState {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults setBool:self.isLoggedIn forKey:kHangoIsLoggedInKey];
    [defaults setBool:self.isGuest forKey:kHangoIsGuestKey];
    [defaults synchronize];
}

- (void)clearGuestMode {
    self.isGuest = NO;
}

- (void)enterGuestMode {
    self.isGuest = YES;
    self.isLoggedIn = NO;
    [self persistSessionState];
    [[HangoDataStore shared] unloadDialogueDataForGuestSession];
}

- (void)exitGuestMode {
    [self clearGuestMode];
    [self persistSessionState];
}

+ (BOOL)requireAuthenticationFromViewController:(UIViewController *)viewController {
    (void)viewController;
    return [HangoGuestGuard requireLogin];
}

- (void)persistLoginState {
    [self persistSessionState];
}

- (BOOL)loginWithEmail:(NSString *)email password:(NSString *)password error:(NSError **)error {
    if (![[HangoAccountStore shared] validateLoginWithEmail:email password:password error:error]) {
        return NO;
    }

    NSString *normalizedEmail = [[HangoAccountStore shared] normalizedEmail:email];
    HangoDataStore *store = [HangoDataStore shared];
    NSString *savedEmail = [NSUserDefaults.standardUserDefaults stringForKey:kHangoSavedPersonaEmailKey];
    NSString *normalizedSavedEmail = savedEmail.length > 0 ? [[HangoAccountStore shared] normalizedEmail:savedEmail] : @"";

    if (normalizedSavedEmail.length > 0 && ![normalizedSavedEmail isEqualToString:normalizedEmail]) {
        [store clearSavedPersonaProfile];
    }

    [store loadSavedPersonaProfileIfNeeded];
    store.currentPersona.email = normalizedEmail;
    if ([[HangoAccountStore shared] isSeedTestAccountEmail:normalizedEmail]) {
        [store applySeedProfileForTestAccountWithEmail:normalizedEmail];
    }
    self.currentPersona = store.currentPersona;
    [self clearGuestMode];
    self.isLoggedIn = YES;
    [store persistCurrentPersonaProfile];
    [self persistLoginState];
    [store reloadDialogueDataForCurrentAccount];
    return YES;
}

- (BOOL)registerWithEmail:(NSString *)email password:(NSString *)password error:(NSError **)error {
    if (![[HangoAccountStore shared] registerEmail:email password:password error:error]) {
        return NO;
    }

    NSString *normalizedEmail = [[HangoAccountStore shared] normalizedEmail:email];
    HangoDataStore *store = [HangoDataStore shared];
    [store clearSavedPersonaProfile];
    HangoPersona *persona = store.currentPersona;
    persona.email = normalizedEmail;
    persona.bio = @"";
    [store assignPersonaIdForNewAccount];
    self.currentPersona = persona;
    [self clearGuestMode];
    self.isLoggedIn = YES;
    [store persistCurrentPersonaProfile];
    [self persistLoginState];
    [store reloadDialogueDataForCurrentAccount];
    return YES;
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
    [self clearGuestMode];
    self.isLoggedIn = YES;
    [self persistLoginState];
    [store reloadDialogueDataForCurrentAccount];
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
    [self clearGuestMode];
    self.isLoggedIn = NO;
    [self persistSessionState];
    [[HangoDataStore shared] unloadDialogueDataForGuestSession];
}

- (void)deleteAccount {
    NSString *email = self.currentPersona.email;
    [[HangoAccountStore shared] removeAccountWithEmail:email];
    [[HangoDataStore shared] deletePersistedDialogueDataForCurrentAccount];
    [[HangoDataStore shared] clearSavedPersonaProfile];
    [[HangoDataStore shared] clearAppleSignInCredentials];
    [self clearGuestMode];
    self.isLoggedIn = NO;
    self.currentPersona = nil;
    [self persistSessionState];
    [[HangoDataStore shared] unloadDialogueDataForGuestSession];
}

@end
