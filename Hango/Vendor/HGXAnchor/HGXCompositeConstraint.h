//
//  HGXCompositeConstraint.h
//  HGXAnchor
//
//  Created by Jonas Budelmann on 21/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "HGXConstraint.h"
#import "HGXUtilities.h"

/**
 *	A group of HGXConstraint objects
 */
@interface HGXCompositeConstraint : HGXConstraint

/**
 *	Creates a composite with a predefined array of children
 *
 *	@param	children	child HGXConstraints
 *
 *	@return	a composite constraint
 */
- (id)initWithChildren:(NSArray *)children;

@end
