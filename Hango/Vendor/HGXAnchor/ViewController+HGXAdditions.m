//
//  UIViewController+HGXAdditions.m
//  HGXAnchor
//
//  Created by Craig Siemens on 2015-06-23.
//
//

#import "ViewController+HGXAdditions.h"

#ifdef HGX_VIEW_CONTROLLER

@implementation HGX_VIEW_CONTROLLER (HGXAdditions)

- (HGXViewAttribute *)hgx_topLayoutGuide {
    return [[HGXViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}
- (HGXViewAttribute *)hgx_topLayoutGuideTop {
    return [[HGXViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (HGXViewAttribute *)hgx_topLayoutGuideBottom {
    return [[HGXViewAttribute alloc] initWithView:self.view item:self.topLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}

- (HGXViewAttribute *)hgx_bottomLayoutGuide {
    return [[HGXViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (HGXViewAttribute *)hgx_bottomLayoutGuideTop {
    return [[HGXViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (HGXViewAttribute *)hgx_bottomLayoutGuideBottom {
    return [[HGXViewAttribute alloc] initWithView:self.view item:self.bottomLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}



@end

#endif
