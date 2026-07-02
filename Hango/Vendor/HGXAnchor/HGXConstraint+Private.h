//
//  HGXConstraint+Private.h
//  HGXAnchor
//
//  Created by Nick Tymchenko on 29/04/14.
//  Copyright (c) 2014 cloudling. All rights reserved.
//

#import "HGXConstraint.h"

@protocol HGXConstraintDelegate;


@interface HGXConstraint ()

/**
 *  Whether or not to check for an existing constraint instead of adding constraint
 */
@property (nonatomic, assign) BOOL updateExisting;

/**
 *	Usually HGXConstraintMaker but could be a parent HGXConstraint
 */
@property (nonatomic, weak) id<HGXConstraintDelegate> delegate;

/**
 *  Based on a provided value type, is equal to calling:
 *  NSNumber - setOffset:
 *  NSValue with CGPoint - setPointOffset:
 *  NSValue with CGSize - setSizeOffset:
 *  NSValue with HGXEdgeInsets - setInsets:
 */
- (void)setLayoutConstantWithValue:(NSValue *)value;

@end


@interface HGXConstraint (Abstract)

/**
 *	Sets the constraint relation to given NSLayoutRelation
 *  returns a block which accepts one of the following:
 *    HGXViewAttribute, UIView, NSValue, NSArray
 *  see readme for more details.
 */
- (HGXConstraint * (^)(id, NSLayoutRelation))equalToWithRelation;

/**
 *	Override to set a custom chaining behaviour
 */
- (HGXConstraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute;

@end


@protocol HGXConstraintDelegate <NSObject>

/**
 *	Notifies the delegate when the constraint needs to be replaced with another constraint. For example
 *  A HGXViewConstraint may turn into a HGXCompositeConstraint when an array is passed to one of the equality blocks
 */
- (void)constraint:(HGXConstraint *)constraint shouldBeReplacedWithConstraint:(HGXConstraint *)replacementConstraint;

- (HGXConstraint *)constraint:(HGXConstraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute;

@end
