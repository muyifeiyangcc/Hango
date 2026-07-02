//
//  UIView+HGXShorthandAdditions.h
//  HGXAnchor
//
//  Created by Jonas Budelmann on 22/07/13.
//  Copyright (c) 2013 Jonas Budelmann. All rights reserved.
//

#import "View+HGXAdditions.h"

#ifdef HGX_SHORTHAND

/**
 *	Shorthand view additions without the 'hgx_' prefixes,
 *  only enabled if HGX_SHORTHAND is defined
 */
@interface HGX_VIEW (HGXShorthandAdditions)

@property (nonatomic, strong, readonly) HGXViewAttribute *left;
@property (nonatomic, strong, readonly) HGXViewAttribute *top;
@property (nonatomic, strong, readonly) HGXViewAttribute *right;
@property (nonatomic, strong, readonly) HGXViewAttribute *bottom;
@property (nonatomic, strong, readonly) HGXViewAttribute *leading;
@property (nonatomic, strong, readonly) HGXViewAttribute *trailing;
@property (nonatomic, strong, readonly) HGXViewAttribute *width;
@property (nonatomic, strong, readonly) HGXViewAttribute *height;
@property (nonatomic, strong, readonly) HGXViewAttribute *centerX;
@property (nonatomic, strong, readonly) HGXViewAttribute *centerY;
@property (nonatomic, strong, readonly) HGXViewAttribute *baseline;
@property (nonatomic, strong, readonly) HGXViewAttribute *(^attribute)(NSLayoutAttribute attr);

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)

@property (nonatomic, strong, readonly) HGXViewAttribute *firstBaseline;
@property (nonatomic, strong, readonly) HGXViewAttribute *lastBaseline;

#endif

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)

@property (nonatomic, strong, readonly) HGXViewAttribute *leftMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *rightMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *topMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *bottomMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *leadingMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *trailingMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *centerXWithinMargins;
@property (nonatomic, strong, readonly) HGXViewAttribute *centerYWithinMargins;

#endif

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 110000) || (__TV_OS_VERSION_MAX_ALLOWED >= 110000)

@property (nonatomic, strong, readonly) HGXViewAttribute *safeAreaLayoutGuideTop API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, strong, readonly) HGXViewAttribute *safeAreaLayoutGuideBottom API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, strong, readonly) HGXViewAttribute *safeAreaLayoutGuideLeft API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, strong, readonly) HGXViewAttribute *safeAreaLayoutGuideRight API_AVAILABLE(ios(11.0),tvos(11.0));

#endif

- (NSArray *)makeConstraints:(void(^)(HGXConstraintMaker *make))block;
- (NSArray *)updateConstraints:(void(^)(HGXConstraintMaker *make))block;
- (NSArray *)remakeConstraints:(void(^)(HGXConstraintMaker *make))block;

@end

#define HGX_ATTR_FORWARD(attr)  \
- (HGXViewAttribute *)attr {    \
    return [self hgx_##attr];   \
}

@implementation HGX_VIEW (HGXShorthandAdditions)

HGX_ATTR_FORWARD(top);
HGX_ATTR_FORWARD(left);
HGX_ATTR_FORWARD(bottom);
HGX_ATTR_FORWARD(right);
HGX_ATTR_FORWARD(leading);
HGX_ATTR_FORWARD(trailing);
HGX_ATTR_FORWARD(width);
HGX_ATTR_FORWARD(height);
HGX_ATTR_FORWARD(centerX);
HGX_ATTR_FORWARD(centerY);
HGX_ATTR_FORWARD(baseline);

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)

HGX_ATTR_FORWARD(firstBaseline);
HGX_ATTR_FORWARD(lastBaseline);

#endif

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)

HGX_ATTR_FORWARD(leftMargin);
HGX_ATTR_FORWARD(rightMargin);
HGX_ATTR_FORWARD(topMargin);
HGX_ATTR_FORWARD(bottomMargin);
HGX_ATTR_FORWARD(leadingMargin);
HGX_ATTR_FORWARD(trailingMargin);
HGX_ATTR_FORWARD(centerXWithinMargins);
HGX_ATTR_FORWARD(centerYWithinMargins);

#endif

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 110000) || (__TV_OS_VERSION_MAX_ALLOWED >= 110000)

HGX_ATTR_FORWARD(safeAreaLayoutGuideTop);
HGX_ATTR_FORWARD(safeAreaLayoutGuideBottom);
HGX_ATTR_FORWARD(safeAreaLayoutGuideLeft);
HGX_ATTR_FORWARD(safeAreaLayoutGuideRight);

#endif

- (HGXViewAttribute *(^)(NSLayoutAttribute))attribute {
    return [self hgx_attribute];
}

- (NSArray *)makeConstraints:(void(NS_NOESCAPE ^)(HGXConstraintMaker *))block {
    return [self hgx_makeConstraints:block];
}

- (NSArray *)updateConstraints:(void(NS_NOESCAPE ^)(HGXConstraintMaker *))block {
    return [self hgx_updateConstraints:block];
}

- (NSArray *)remakeConstraints:(void(NS_NOESCAPE ^)(HGXConstraintMaker *))block {
    return [self hgx_remakeConstraints:block];
}

@end

#endif
