//
//  HGXConstraint.h
//  HGXAnchor
//
//  Created by Jonas Budelmann on 22/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "HGXUtilities.h"

/**
 *	Enables Constraints to be created with chainable syntax
 *  Constraint can represent single NSLayoutConstraint (HGXViewConstraint) 
 *  or a group of NSLayoutConstraints (MASComposisteConstraint)
 */
@interface HGXConstraint : NSObject

// Chaining Support

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeBottom, NSLayoutAttributeRight
 */
- (HGXConstraint * (^)(HGXEdgeInsets insets))insets;

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeBottom, NSLayoutAttributeRight
 */
- (HGXConstraint * (^)(CGFloat inset))inset;

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeWidth, NSLayoutAttributeHeight
 */
- (HGXConstraint * (^)(CGSize offset))sizeOffset;

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeCenterX, NSLayoutAttributeCenterY
 */
- (HGXConstraint * (^)(CGPoint offset))centerOffset;

/**
 *	Modifies the NSLayoutConstraint constant
 */
- (HGXConstraint * (^)(CGFloat offset))offset;

/**
 *  Modifies the NSLayoutConstraint constant based on a value type
 */
- (HGXConstraint * (^)(NSValue *value))valueOffset;

/**
 *	Sets the NSLayoutConstraint multiplier property
 */
- (HGXConstraint * (^)(CGFloat multiplier))multipliedBy;

/**
 *	Sets the NSLayoutConstraint multiplier to 1.0/dividedBy
 */
- (HGXConstraint * (^)(CGFloat divider))dividedBy;

/**
 *	Sets the NSLayoutConstraint priority to a float or HGXLayoutPriority
 */
- (HGXConstraint * (^)(HGXLayoutPriority priority))priority;

/**
 *	Sets the NSLayoutConstraint priority to HGXLayoutPriorityLow
 */
- (HGXConstraint * (^)(void))priorityLow;

/**
 *	Sets the NSLayoutConstraint priority to HGXLayoutPriorityMedium
 */
- (HGXConstraint * (^)(void))priorityMedium;

/**
 *	Sets the NSLayoutConstraint priority to HGXLayoutPriorityHigh
 */
- (HGXConstraint * (^)(void))priorityHigh;

/**
 *	Sets the constraint relation to NSLayoutRelationEqual
 *  returns a block which accepts one of the following:
 *    HGXViewAttribute, UIView, NSValue, NSArray
 *  see readme for more details.
 */
- (HGXConstraint * (^)(id attr))equalTo;

/**
 *	Sets the constraint relation to NSLayoutRelationGreaterThanOrEqual
 *  returns a block which accepts one of the following:
 *    HGXViewAttribute, UIView, NSValue, NSArray
 *  see readme for more details.
 */
- (HGXConstraint * (^)(id attr))greaterThanOrEqualTo;

/**
 *	Sets the constraint relation to NSLayoutRelationLessThanOrEqual
 *  returns a block which accepts one of the following:
 *    HGXViewAttribute, UIView, NSValue, NSArray
 *  see readme for more details.
 */
- (HGXConstraint * (^)(id attr))lessThanOrEqualTo;

/**
 *	Optional semantic property which has no effect but improves the readability of constraint
 */
- (HGXConstraint *)with;

/**
 *	Optional semantic property which has no effect but improves the readability of constraint
 */
- (HGXConstraint *)and;

/**
 *	Creates a new HGXCompositeConstraint with the called attribute and reciever
 */
- (HGXConstraint *)left;
- (HGXConstraint *)top;
- (HGXConstraint *)right;
- (HGXConstraint *)bottom;
- (HGXConstraint *)leading;
- (HGXConstraint *)trailing;
- (HGXConstraint *)width;
- (HGXConstraint *)height;
- (HGXConstraint *)centerX;
- (HGXConstraint *)centerY;
- (HGXConstraint *)baseline;

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)

- (HGXConstraint *)firstBaseline;
- (HGXConstraint *)lastBaseline;

#endif

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)

- (HGXConstraint *)leftMargin;
- (HGXConstraint *)rightMargin;
- (HGXConstraint *)topMargin;
- (HGXConstraint *)bottomMargin;
- (HGXConstraint *)leadingMargin;
- (HGXConstraint *)trailingMargin;
- (HGXConstraint *)centerXWithinMargins;
- (HGXConstraint *)centerYWithinMargins;

#endif


/**
 *	Sets the constraint debug name
 */
- (HGXConstraint * (^)(id key))key;

// NSLayoutConstraint constant Setters
// for use outside of hgx_updateConstraints/hgx_makeConstraints blocks

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeBottom, NSLayoutAttributeRight
 */
- (void)setInsets:(HGXEdgeInsets)insets;

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeTop, NSLayoutAttributeLeft, NSLayoutAttributeBottom, NSLayoutAttributeRight
 */
- (void)setInset:(CGFloat)inset;

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeWidth, NSLayoutAttributeHeight
 */
- (void)setSizeOffset:(CGSize)sizeOffset;

/**
 *	Modifies the NSLayoutConstraint constant,
 *  only affects HGXConstraints in which the first item's NSLayoutAttribute is one of the following
 *  NSLayoutAttributeCenterX, NSLayoutAttributeCenterY
 */
- (void)setCenterOffset:(CGPoint)centerOffset;

/**
 *	Modifies the NSLayoutConstraint constant
 */
- (void)setOffset:(CGFloat)offset;


// NSLayoutConstraint Installation support

#if TARGET_OS_MAC && !(TARGET_OS_IPHONE || TARGET_OS_TV)
/**
 *  Whether or not to go through the animator proxy when modifying the constraint
 */
@property (nonatomic, copy, readonly) HGXConstraint *animator;
#endif

/**
 *  Activates an NSLayoutConstraint if it's supported by an OS. 
 *  Invokes install otherwise.
 */
- (void)activate;

/**
 *  Deactivates previously installed/activated NSLayoutConstraint.
 */
- (void)deactivate;

/**
 *	Creates a NSLayoutConstraint and adds it to the appropriate view.
 */
- (void)install;

/**
 *	Removes previously installed NSLayoutConstraint
 */
- (void)uninstall;

@end


/**
 *  Convenience auto-boxing macros for HGXConstraint methods.
 *
 *  Defining HGX_SHORTHAND_GLOBALS will turn on auto-boxing for default syntax.
 *  A potential drawback of this is that the unprefixed macros will appear in global scope.
 */
#define hgx_equalTo(...)                 equalTo(HGXBoxValue((__VA_ARGS__)))
#define hgx_greaterThanOrEqualTo(...)    greaterThanOrEqualTo(HGXBoxValue((__VA_ARGS__)))
#define hgx_lessThanOrEqualTo(...)       lessThanOrEqualTo(HGXBoxValue((__VA_ARGS__)))

#define hgx_offset(...)                  valueOffset(HGXBoxValue((__VA_ARGS__)))


#ifdef HGX_SHORTHAND_GLOBALS

#define equalTo(...)                     hgx_equalTo(__VA_ARGS__)
#define greaterThanOrEqualTo(...)        hgx_greaterThanOrEqualTo(__VA_ARGS__)
#define lessThanOrEqualTo(...)           hgx_lessThanOrEqualTo(__VA_ARGS__)

#define offset(...)                      hgx_offset(__VA_ARGS__)

#endif


@interface HGXConstraint (AutoboxingSupport)

/**
 *  Aliases to corresponding relation methods (for shorthand macros)
 *  Also needed to aid autocompletion
 */
- (HGXConstraint * (^)(id attr))hgx_equalTo;
- (HGXConstraint * (^)(id attr))hgx_greaterThanOrEqualTo;
- (HGXConstraint * (^)(id attr))hgx_lessThanOrEqualTo;

/**
 *  A dummy method to aid autocompletion
 */
- (HGXConstraint * (^)(id offset))hgx_offset;

@end
