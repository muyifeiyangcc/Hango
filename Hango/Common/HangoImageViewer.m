#import "HangoImageViewer.h"

@interface HangoImageViewerController : UIViewController <UIScrollViewDelegate>
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, weak, nullable) UIView *sourceView;
@end

@implementation HangoImageViewerController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.blackColor;

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.delegate = self;
    scrollView.minimumZoomScale = 1.0;
    scrollView.maximumZoomScale = 3.0;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scrollView];

    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.image];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.frame = scrollView.bounds;
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    imageView.userInteractionEnabled = YES;
    [scrollView addSubview:imageView];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissViewer)];
    [self.view addGestureRecognizer:tap];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return scrollView.subviews.firstObject;
}

- (void)dismissViewer {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

@implementation HangoImageViewer

+ (void)showImage:(UIImage *)image fromSourceView:(UIView *)sourceView {
    if (!image) {
        return;
    }
    UIWindow *window = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        window = windowScene.windows.firstObject;
        if (window) {
            break;
        }
    }
    UIViewController *presenter = window.rootViewController;
    while (presenter.presentedViewController) {
        presenter = presenter.presentedViewController;
    }
    if (!presenter) {
        return;
    }
    HangoImageViewerController *viewer = [[HangoImageViewerController alloc] init];
    viewer.image = image;
    viewer.sourceView = sourceView;
    viewer.modalPresentationStyle = UIModalPresentationFullScreen;
    viewer.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [presenter presentViewController:viewer animated:YES completion:nil];
}

@end
