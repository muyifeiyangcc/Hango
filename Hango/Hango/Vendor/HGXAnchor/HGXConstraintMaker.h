//
//  HGXConstraintMaker.h
//  HGXAnchor
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "HGXConstraint.h"
#import "HGXUtilities.h"

typedef NS_OPTIONS(NSInteger, HGXAttribute) {
    HGXAttributeLeft = 1 << NSLayoutAttributeLeft,
    HGXAttributeRight = 1 << NSLayoutAttributeRight,
    HGXAttributeTop = 1 << NSLayoutAttributeTop,
    HGXAttributeBottom = 1 << NSLayoutAttributeBottom,
    HGXAttributeLeading = 1 << NSLayoutAttributeLeading,
    HGXAttributeTrailing = 1 << NSLayoutAttributeTrailing,
    HGXAttributeWidth = 1 << NSLayoutAttributeWidth,
    HGXAttributeHeight = 1 << NSLayoutAttributeHeight,
    HGXAttributeCenterX = 1 << NSLayoutAttributeCenterX,
    HGXAttributeCenterY = 1 << NSLayoutAttributeCenterY,
    HGXAttributeBaseline = 1 << NSLayoutAttributeBaseline,
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    
    HGXAttributeFirstBaseline = 1 << NSLayoutAttributeFirstBaseline,
    HGXAttributeLastBaseline = 1 << NSLayoutAttributeLastBaseline,
    
#endif
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)
    
    HGXAttributeLeftMargin = 1 << NSLayoutAttributeLeftMargin,
    HGXAttributeRightMargin = 1 << NSLayoutAttributeRightMargin,
    HGXAttributeTopMargin = 1 << NSLayoutAttributeTopMargin,
    HGXAttributeBottomMargin = 1 << NSLayoutAttributeBottomMargin,
    HGXAttributeLeadingMargin = 1 << NSLayoutAttributeLeadingMargin,
    HGXAttributeTrailingMargin = 1 << NSLayoutAttributeTrailingMargin,
    HGXAttributeCenterXWithinMargins = 1 << NSLayoutAttributeCenterXWithinMargins,
    HGXAttributeCenterYWithinMargins = 1 << NSLayoutAttributeCenterYWithinMargins,

#endif
    
};

/**
 *  Provides factory methods for creating HGXConstraints.
 *  Constraints are collected until they are ready to be installed
 *
 */
@interface HGXConstraintMaker : NSObject

/**
 *	The following properties return a new HGXViewConstraint
 *  with the first item set to the makers associated view and the appropriate HGXViewAttribute
 */
@property (nonatomic, strong, readonly) HGXConstraint *left;
@property (nonatomic, strong, readonly) HGXConstraint *top;
@property (nonatomic, strong, readonly) HGXConstraint *right;
@property (nonatomic, strong, readonly) HGXConstraint *bottom;
@property (nonatomic, strong, readonly) HGXConstraint *leading;
@property (nonatomic, strong, readonly) HGXConstraint *trailing;
@property (nonatomic, strong, readonly) HGXConstraint *width;
@property (nonatomic, strong, readonly) HGXConstraint *height;
@property (nonatomic, strong, readonly) HGXConstraint *centerX;
@property (nonatomic, strong, readonly) HGXConstraint *centerY;
@property (nonatomic, strong, readonly) HGXConstraint *baseline;

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)

@property (nonatomic, strong, readonly) HGXConstraint *firstBaseline;
@property (nonatomic, strong, readonly) HGXConstraint *lastBaseline;

#endif

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)

@property (nonatomic, strong, readonly) HGXConstraint *leftMargin;
@property (nonatomic, strong, readonly) HGXConstraint *rightMargin;
@property (nonatomic, strong, readonly) HGXConstraint *topMargin;
@property (nonatomic, strong, readonly) HGXConstraint *bottomMargin;
@property (nonatomic, strong, readonly) HGXConstraint *leadingMargin;
@property (nonatomic, strong, readonly) HGXConstraint *trailingMargin;
@property (nonatomic, strong, readonly) HGXConstraint *centerXWithinMargins;
@property (nonatomic, strong, readonly) HGXConstraint *centerYWithinMargins;

#endif

/**
 *  Returns a block which creates a new HGXCompositeConstraint with the first item set
 *  to the makers associated view and children corresponding to the set bits in the
 *  HGXAttribute parameter. Combine multiple attributes via binary-or.
 */
@property (nonatomic, strong, readonly) HGXConstraint *(^attributes)(HGXAttribute attrs);

/**
 *	Creates a HGXCompositeConstraint with type HGXCompositeConstraintTypeEdges
 *  which generates the appropriate HGXViewConstraint children (top, left, bottom, right)
 *  with the first item set to the makers associated view
 */
@property (nonatomic, strong, readonly) HGXConstraint *edges;

/**
 *	Creates a HGXCompositeConstraint with type HGXCompositeConstraintTypeSize
 *  which generates the appropriate HGXViewConstraint children (width, height)
 *  with the first item set to the makers associated view
 */
@property (nonatomic, strong, readonly) HGXConstraint *size;

/**
 *	Creates a HGXCompositeConstraint with type HGXCompositeConstraintTypeCenter
 *  which generates the appropriate HGXViewConstraint children (centerX, centerY)
 *  with the first item set to the makers associated view
 */
@property (nonatomic, strong, readonly) HGXConstraint *center;

/**
 *  Whether or not to check for an existing constraint instead of adding constraint
 */
@property (nonatomic, assign) BOOL updateExisting;

/**
 *  Whether or not to remove existing constraints prior to installing
 */
@property (nonatomic, assign) BOOL removeExisting;

/**
 *	initialises the maker with a default view
 *
 *	@param	view	any HGXConstraint are created with this view as the first item
 *
 *	@return	a new HGXConstraintMaker
 */
- (id)initWithView:(HGX_VIEW *)view;

/**
 *	Calls install method on any HGXConstraints which have been created by this maker
 *
 *	@return	an array of all the installed HGXConstraints
 */
- (NSArray *)install;

- (HGXConstraint * (^)(dispatch_block_t))group;

@end
