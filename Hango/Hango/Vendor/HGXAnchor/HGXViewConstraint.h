//
//  HGXViewConstraint.h
//  HGXAnchor
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "HGXViewAttribute.h"
#import "HGXConstraint.h"
#import "HGXLayoutConstraint.h"
#import "HGXUtilities.h"

/**
 *  A single constraint.
 *  Contains the attributes neccessary for creating a NSLayoutConstraint and adding it to the appropriate view
 */
@interface HGXViewConstraint : HGXConstraint <NSCopying>

/**
 *	First item/view and first attribute of the NSLayoutConstraint
 */
@property (nonatomic, strong, readonly) HGXViewAttribute *firstViewAttribute;

/**
 *	Second item/view and second attribute of the NSLayoutConstraint
 */
@property (nonatomic, strong, readonly) HGXViewAttribute *secondViewAttribute;

/**
 *	initialises the HGXViewConstraint with the first part of the equation
 *
 *	@param	firstViewAttribute	view.hgx_left, view.hgx_width etc.
 *
 *	@return	a new view constraint
 */
- (id)initWithFirstViewAttribute:(HGXViewAttribute *)firstViewAttribute;

/**
 *  Returns all HGXViewConstraints installed with this view as a first item.
 *
 *  @param  view  A view to retrieve constraints for.
 *
 *  @return An array of HGXViewConstraints.
 */
+ (NSArray *)installedConstraintsForView:(HGX_VIEW *)view;

@end
