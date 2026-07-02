//
//  UIView+HGXAdditions.h
//  HGXAnchor
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "HGXUtilities.h"
#import "HGXConstraintMaker.h"
#import "HGXViewAttribute.h"

/**
 *	Provides constraint maker block
 *  and convience methods for creating HGXViewAttribute which are view + NSLayoutAttribute pairs
 */
@interface HGX_VIEW (HGXAdditions)

/**
 *	following properties return a new HGXViewAttribute with current view and appropriate NSLayoutAttribute
 */
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_left;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_top;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_right;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_bottom;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_leading;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_trailing;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_width;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_height;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_centerX;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_centerY;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_baseline;
@property (nonatomic, strong, readonly) HGXViewAttribute *(^hgx_attribute)(NSLayoutAttribute attr);

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)

@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_firstBaseline;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_lastBaseline;

#endif

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)

@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_leftMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_rightMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_topMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_bottomMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_leadingMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_trailingMargin;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_centerXWithinMargins;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_centerYWithinMargins;

#endif

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 110000) || (__TV_OS_VERSION_MAX_ALLOWED >= 110000)

@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_safeAreaLayoutGuide API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_safeAreaLayoutGuideTop API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_safeAreaLayoutGuideBottom API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_safeAreaLayoutGuideLeft API_AVAILABLE(ios(11.0),tvos(11.0));
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_safeAreaLayoutGuideRight API_AVAILABLE(ios(11.0),tvos(11.0));

#endif

/**
 *	a key to associate with this view
 */
@property (nonatomic, strong) id hgx_key;

/**
 *	Finds the closest common superview between this view and another view
 *
 *	@param	view	other view
 *
 *	@return	returns nil if common superview could not be found
 */
- (instancetype)hgx_closestCommonSuperview:(HGX_VIEW *)view;

/**
 *  Creates a HGXConstraintMaker with the callee view.
 *  Any constraints defined are added to the view or the appropriate superview once the block has finished executing
 *
 *  @param block scope within which you can build up the constraints which you wish to apply to the view.
 *
 *  @return Array of created HGXConstraints
 */
- (NSArray *)hgx_makeConstraints:(void(NS_NOESCAPE ^)(HGXConstraintMaker *make))block;

/**
 *  Creates a HGXConstraintMaker with the callee view.
 *  Any constraints defined are added to the view or the appropriate superview once the block has finished executing.
 *  If an existing constraint exists then it will be updated instead.
 *
 *  @param block scope within which you can build up the constraints which you wish to apply to the view.
 *
 *  @return Array of created/updated HGXConstraints
 */
- (NSArray *)hgx_updateConstraints:(void(NS_NOESCAPE ^)(HGXConstraintMaker *make))block;

/**
 *  Creates a HGXConstraintMaker with the callee view.
 *  Any constraints defined are added to the view or the appropriate superview once the block has finished executing.
 *  All constraints previously installed for the view will be removed.
 *
 *  @param block scope within which you can build up the constraints which you wish to apply to the view.
 *
 *  @return Array of created/updated HGXConstraints
 */
- (NSArray *)hgx_remakeConstraints:(void(NS_NOESCAPE ^)(HGXConstraintMaker *make))block;

@end
