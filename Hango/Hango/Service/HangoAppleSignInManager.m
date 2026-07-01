#import "HangoAppleSignInManager.h"
#import "HangoDataStore.h"
#import "HangoSessionManager.h"
#import "HangoTheme.h"
#import <AuthenticationServices/AuthenticationServices.h>

@interface HangoAppleSignInManager () <ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding>
@property (nonatomic, weak) UIViewController *presentingViewController;
@property (nonatomic, copy) HangoAppleSignInCompletion completion;
@end

@implementation HangoAppleSignInManager

+ (instancetype)shared {
    static HangoAppleSignInManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[HangoAppleSignInManager alloc] init];
    });
    return manager;
}

- (void)signInFromViewController:(UIViewController *)viewController
                      completion:(HangoAppleSignInCompletion)completion {
    self.presentingViewController = viewController;
    self.completion = completion;

    ASAuthorizationAppleIDProvider *provider = [[ASAuthorizationAppleIDProvider alloc] init];
    ASAuthorizationAppleIDRequest *request = [provider createRequest];
    request.requestedScopes = @[ASAuthorizationScopeFullName, ASAuthorizationScopeEmail];

    ASAuthorizationController *controller = [[ASAuthorizationController alloc] initWithAuthorizationRequests:@[request]];
    controller.delegate = self;
    controller.presentationContextProvider = self;
    [controller performRequests];
}

#pragma mark - ASAuthorizationControllerDelegate

- (void)authorizationController:(ASAuthorizationController *)controller
   didCompleteWithAuthorization:(ASAuthorization *)authorization {
    if (![authorization.credential isKindOfClass:ASAuthorizationAppleIDCredential.class]) {
        [self finishWithSuccess:NO error:[self errorWithCode:-1 message:@"Unsupported Apple sign-in credential."]];
        return;
    }

    ASAuthorizationAppleIDCredential *credential = (ASAuthorizationAppleIDCredential *)authorization.credential;
    NSString *personaIdentifier = credential.user;
    if (personaIdentifier.length == 0) {
        [self finishWithSuccess:NO error:[self errorWithCode:-2 message:@"Apple sign-in did not return a credential identifier."]];
        return;
    }

    NSString *email = credential.email;
    NSString *displayName = [self displayNameFromCredential:credential];

    [[HangoSessionManager shared] loginWithAppleCredentialIdentifier:personaIdentifier
                                                         email:email
                                                   displayName:displayName];
    [self finishWithSuccess:YES error:nil];
}

- (void)authorizationController:(ASAuthorizationController *)controller didCompleteWithError:(NSError *)error {
    [self finishWithSuccess:NO error:error];
}

#pragma mark - ASAuthorizationControllerPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForAuthorizationController:(ASAuthorizationController *)controller {
    UIWindow *window = self.presentingViewController.view.window;
    if (window) {
        return window;
    }
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *candidate in windowScene.windows) {
            if (candidate.isKeyWindow) {
                return candidate;
            }
        }
    }
    return UIApplication.sharedApplication.windows.firstObject;
}

#pragma mark - Helpers

- (NSString *)displayNameFromCredential:(ASAuthorizationAppleIDCredential *)credential {
    NSString *displayName = [self displayNameFromPersonName:credential.fullName];
    if (displayName.length > 0) {
        return displayName;
    }
    return [[HangoDataStore shared] appleCachedDisplayNameForCredentialIdentifier:credential.user];
}

- (nullable NSString *)displayNameFromPersonName:(NSPersonNameComponents *)nameComponents {
    if (!nameComponents) {
        return nil;
    }

    NSString *formatted = [NSPersonNameComponentsFormatter localizedStringFromPersonNameComponents:nameComponents
                                                                                            style:NSPersonNameComponentsFormatterStyleDefault
                                                                                          options:0];
    NSString *trimmed = [formatted stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length > 0) {
        return trimmed;
    }

    NSMutableArray<NSString *> *parts = [NSMutableArray array];
    if (nameComponents.givenName.length > 0) {
        [parts addObject:nameComponents.givenName];
    }
    if (nameComponents.familyName.length > 0) {
        [parts addObject:nameComponents.familyName];
    }
    trimmed = [[parts componentsJoinedByString:@" "] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return trimmed.length > 0 ? trimmed : nil;
}

- (NSError *)errorWithCode:(NSInteger)code message:(NSString *)message {
    return [NSError errorWithDomain:@"HangoAppleSignIn"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: message ?: @"Apple sign-in failed."}];
}

- (void)finishWithSuccess:(BOOL)success error:(NSError *)error {
    HangoAppleSignInCompletion completion = self.completion;
    self.completion = nil;
    self.presentingViewController = nil;
    if (completion) {
        completion(success, error);
    }
}

+ (NSString *)initialsFromDisplayName:(NSString *)displayName {
    NSString *trimmed = [displayName stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (trimmed.length == 0) {
        return @"";
    }

    NSArray<NSString *> *parts = [trimmed componentsSeparatedByCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSMutableString *initials = [NSMutableString string];
    for (NSString *part in parts) {
        NSString *word = [part stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
        if (word.length == 0) {
            continue;
        }
        [initials appendString:[[word substringToIndex:1] uppercaseString]];
        if (initials.length >= 2) {
            break;
        }
    }
    return initials.copy;
}

+ (UIImage *)avatarImageForDisplayName:(NSString *)displayName {
    NSString *initials = [self initialsFromDisplayName:displayName];
    if (initials.length == 0) {
        return nil;
    }

    CGFloat size = 240.0;
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.opaque = YES;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(size, size) format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
        [[HangoTheme primaryDarkColor] setFill];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(0, 0, size, size)] fill];

        NSDictionary *attributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:96 weight:UIFontWeightSemibold],
            NSForegroundColorAttributeName: UIColor.whiteColor
        };
        CGSize textSize = [initials sizeWithAttributes:attributes];
        CGRect textRect = CGRectMake((size - textSize.width) / 2.0,
                                     (size - textSize.height) / 2.0 - 4.0,
                                     textSize.width,
                                     textSize.height);
        [initials drawInRect:textRect withAttributes:attributes];
    }];
}

@end
