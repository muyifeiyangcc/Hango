//
//  UIView+HGXAdditions.m
//  HGXAnchor
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "View+HGXAdditions.h"
#import <objc/runtime.h>

@implementation HGX_VIEW (HGXAdditions)

- (NSArray *)hgx_makeConstraints:(void(^)(HGXConstraintMaker *))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    HGXConstraintMaker *constraintMaker = [[HGXConstraintMaker alloc] initWithView:self];
    block(constraintMaker);
    return [constraintMaker install];
}

- (NSArray *)hgx_updateConstraints:(void(^)(HGXConstraintMaker *))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    HGXConstraintMaker *constraintMaker = [[HGXConstraintMaker alloc] initWithView:self];
    constraintMaker.updateExisting = YES;
    block(constraintMaker);
    return [constraintMaker install];
}

- (NSArray *)hgx_remakeConstraints:(void(^)(HGXConstraintMaker *make))block {
    self.translatesAutoresizingMaskIntoConstraints = NO;
    HGXConstraintMaker *constraintMaker = [[HGXConstraintMaker alloc] initWithView:self];
    constraintMaker.removeExisting = YES;
    block(constraintMaker);
    return [constraintMaker install];
}

#pragma mark - NSLayoutAttribute properties

- (HGXViewAttribute *)hgx_left {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeft];
}

- (HGXViewAttribute *)hgx_top {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTop];
}

- (HGXViewAttribute *)hgx_right {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeRight];
}

- (HGXViewAttribute *)hgx_bottom {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBottom];
}

- (HGXViewAttribute *)hgx_leading {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeading];
}

- (HGXViewAttribute *)hgx_trailing {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTrailing];
}

- (HGXViewAttribute *)hgx_width {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeWidth];
}

- (HGXViewAttribute *)hgx_height {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeHeight];
}

- (HGXViewAttribute *)hgx_centerX {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterX];
}

- (HGXViewAttribute *)hgx_centerY {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterY];
}

- (HGXViewAttribute *)hgx_baseline {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBaseline];
}

- (HGXViewAttribute *(^)(NSLayoutAttribute))hgx_attribute
{
    return ^(NSLayoutAttribute attr) {
        return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:attr];
    };
}

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)

- (HGXViewAttribute *)hgx_firstBaseline {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeFirstBaseline];
}
- (HGXViewAttribute *)hgx_lastBaseline {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLastBaseline];
}

#endif

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)

- (HGXViewAttribute *)hgx_leftMargin {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeftMargin];
}

- (HGXViewAttribute *)hgx_rightMargin {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeRightMargin];
}

- (HGXViewAttribute *)hgx_topMargin {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTopMargin];
}

- (HGXViewAttribute *)hgx_bottomMargin {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeBottomMargin];
}

- (HGXViewAttribute *)hgx_leadingMargin {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeLeadingMargin];
}

- (HGXViewAttribute *)hgx_trailingMargin {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeTrailingMargin];
}

- (HGXViewAttribute *)hgx_centerXWithinMargins {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterXWithinMargins];
}

- (HGXViewAttribute *)hgx_centerYWithinMargins {
    return [[HGXViewAttribute alloc] initWithView:self layoutAttribute:NSLayoutAttributeCenterYWithinMargins];
}

#endif

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 110000) || (__TV_OS_VERSION_MAX_ALLOWED >= 110000)

- (HGXViewAttribute *)hgx_safeAreaLayoutGuide {
    return [[HGXViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}
- (HGXViewAttribute *)hgx_safeAreaLayoutGuideTop {
    return [[HGXViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeTop];
}
- (HGXViewAttribute *)hgx_safeAreaLayoutGuideBottom {
    return [[HGXViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeBottom];
}
- (HGXViewAttribute *)hgx_safeAreaLayoutGuideLeft {
    return [[HGXViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeLeft];
}
- (HGXViewAttribute *)hgx_safeAreaLayoutGuideRight {
    return [[HGXViewAttribute alloc] initWithView:self item:self.safeAreaLayoutGuide layoutAttribute:NSLayoutAttributeRight];
}

#endif

#pragma mark - associated properties

- (id)hgx_key {
    return objc_getAssociatedObject(self, @selector(hgx_key));
}

- (void)setHgx_key:(id)key {
    objc_setAssociatedObject(self, @selector(hgx_key), key, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - heirachy

- (instancetype)hgx_closestCommonSuperview:(HGX_VIEW *)view {
    HGX_VIEW *closestCommonSuperview = nil;

    HGX_VIEW *secondViewSuperview = view;
    while (!closestCommonSuperview && secondViewSuperview) {
        HGX_VIEW *firstViewSuperview = self;
        while (!closestCommonSuperview && firstViewSuperview) {
            if (secondViewSuperview == firstViewSuperview) {
                closestCommonSuperview = secondViewSuperview;
            }
            firstViewSuperview = firstViewSuperview.superview;
        }
        secondViewSuperview = secondViewSuperview.superview;
    }
    return closestCommonSuperview;
}

@end
