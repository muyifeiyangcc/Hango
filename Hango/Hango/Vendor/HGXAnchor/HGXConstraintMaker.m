//
//  HGXConstraintMaker.m
//  HGXAnchor
//
//  Created by Jonas Budelmann on 20/07/13.
//  Copyright (c) 2013 cloudling. All rights reserved.
//

#import "HGXConstraintMaker.h"
#import "HGXViewConstraint.h"
#import "HGXCompositeConstraint.h"
#import "HGXConstraint+Private.h"
#import "HGXViewAttribute.h"
#import "View+HGXAdditions.h"

@interface HGXConstraintMaker () <HGXConstraintDelegate>

@property (nonatomic, weak) HGX_VIEW *view;
@property (nonatomic, strong) NSMutableArray *constraints;

@end

@implementation HGXConstraintMaker

- (id)initWithView:(HGX_VIEW *)view {
    self = [super init];
    if (!self) return nil;
    
    self.view = view;
    self.constraints = NSMutableArray.new;
    
    return self;
}

- (NSArray *)install {
    if (self.removeExisting) {
        NSArray *installedConstraints = [HGXViewConstraint installedConstraintsForView:self.view];
        for (HGXConstraint *constraint in installedConstraints) {
            [constraint uninstall];
        }
    }
    NSArray *constraints = self.constraints.copy;
    for (HGXConstraint *constraint in constraints) {
        constraint.updateExisting = self.updateExisting;
        [constraint install];
    }
    [self.constraints removeAllObjects];
    return constraints;
}

#pragma mark - HGXConstraintDelegate

- (void)constraint:(HGXConstraint *)constraint shouldBeReplacedWithConstraint:(HGXConstraint *)replacementConstraint {
    NSUInteger index = [self.constraints indexOfObject:constraint];
    NSAssert(index != NSNotFound, @"Could not find constraint %@", constraint);
    [self.constraints replaceObjectAtIndex:index withObject:replacementConstraint];
}

- (HGXConstraint *)constraint:(HGXConstraint *)constraint addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
    HGXViewAttribute *viewAttribute = [[HGXViewAttribute alloc] initWithView:self.view layoutAttribute:layoutAttribute];
    HGXViewConstraint *newConstraint = [[HGXViewConstraint alloc] initWithFirstViewAttribute:viewAttribute];
    if ([constraint isKindOfClass:HGXViewConstraint.class]) {
        //replace with composite constraint
        NSArray *children = @[constraint, newConstraint];
        HGXCompositeConstraint *compositeConstraint = [[HGXCompositeConstraint alloc] initWithChildren:children];
        compositeConstraint.delegate = self;
        [self constraint:constraint shouldBeReplacedWithConstraint:compositeConstraint];
        return compositeConstraint;
    }
    if (!constraint) {
        newConstraint.delegate = self;
        [self.constraints addObject:newConstraint];
    }
    return newConstraint;
}

- (HGXConstraint *)addConstraintWithAttributes:(HGXAttribute)attrs {
    __unused HGXAttribute anyAttribute = (HGXAttributeLeft | HGXAttributeRight | HGXAttributeTop | HGXAttributeBottom | HGXAttributeLeading
                                          | HGXAttributeTrailing | HGXAttributeWidth | HGXAttributeHeight | HGXAttributeCenterX
                                          | HGXAttributeCenterY | HGXAttributeBaseline
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
                                          | HGXAttributeFirstBaseline | HGXAttributeLastBaseline
#endif
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)
                                          | HGXAttributeLeftMargin | HGXAttributeRightMargin | HGXAttributeTopMargin | HGXAttributeBottomMargin
                                          | HGXAttributeLeadingMargin | HGXAttributeTrailingMargin | HGXAttributeCenterXWithinMargins
                                          | HGXAttributeCenterYWithinMargins
#endif
                                          );
    
    NSAssert((attrs & anyAttribute) != 0, @"You didn't pass any attribute to make.attributes(...)");
    
    NSMutableArray *attributes = [NSMutableArray array];
    
    if (attrs & HGXAttributeLeft) [attributes addObject:self.view.hgx_left];
    if (attrs & HGXAttributeRight) [attributes addObject:self.view.hgx_right];
    if (attrs & HGXAttributeTop) [attributes addObject:self.view.hgx_top];
    if (attrs & HGXAttributeBottom) [attributes addObject:self.view.hgx_bottom];
    if (attrs & HGXAttributeLeading) [attributes addObject:self.view.hgx_leading];
    if (attrs & HGXAttributeTrailing) [attributes addObject:self.view.hgx_trailing];
    if (attrs & HGXAttributeWidth) [attributes addObject:self.view.hgx_width];
    if (attrs & HGXAttributeHeight) [attributes addObject:self.view.hgx_height];
    if (attrs & HGXAttributeCenterX) [attributes addObject:self.view.hgx_centerX];
    if (attrs & HGXAttributeCenterY) [attributes addObject:self.view.hgx_centerY];
    if (attrs & HGXAttributeBaseline) [attributes addObject:self.view.hgx_baseline];
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)
    
    if (attrs & HGXAttributeFirstBaseline) [attributes addObject:self.view.hgx_firstBaseline];
    if (attrs & HGXAttributeLastBaseline) [attributes addObject:self.view.hgx_lastBaseline];
    
#endif
    
#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)
    
    if (attrs & HGXAttributeLeftMargin) [attributes addObject:self.view.hgx_leftMargin];
    if (attrs & HGXAttributeRightMargin) [attributes addObject:self.view.hgx_rightMargin];
    if (attrs & HGXAttributeTopMargin) [attributes addObject:self.view.hgx_topMargin];
    if (attrs & HGXAttributeBottomMargin) [attributes addObject:self.view.hgx_bottomMargin];
    if (attrs & HGXAttributeLeadingMargin) [attributes addObject:self.view.hgx_leadingMargin];
    if (attrs & HGXAttributeTrailingMargin) [attributes addObject:self.view.hgx_trailingMargin];
    if (attrs & HGXAttributeCenterXWithinMargins) [attributes addObject:self.view.hgx_centerXWithinMargins];
    if (attrs & HGXAttributeCenterYWithinMargins) [attributes addObject:self.view.hgx_centerYWithinMargins];
    
#endif
    
    NSMutableArray *children = [NSMutableArray arrayWithCapacity:attributes.count];
    
    for (HGXViewAttribute *a in attributes) {
        [children addObject:[[HGXViewConstraint alloc] initWithFirstViewAttribute:a]];
    }
    
    HGXCompositeConstraint *constraint = [[HGXCompositeConstraint alloc] initWithChildren:children];
    constraint.delegate = self;
    [self.constraints addObject:constraint];
    return constraint;
}

#pragma mark - standard Attributes

- (HGXConstraint *)addConstraintWithLayoutAttribute:(NSLayoutAttribute)layoutAttribute {
    return [self constraint:nil addConstraintWithLayoutAttribute:layoutAttribute];
}

- (HGXConstraint *)left {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeft];
}

- (HGXConstraint *)top {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTop];
}

- (HGXConstraint *)right {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeRight];
}

- (HGXConstraint *)bottom {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeBottom];
}

- (HGXConstraint *)leading {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeading];
}

- (HGXConstraint *)trailing {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTrailing];
}

- (HGXConstraint *)width {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeWidth];
}

- (HGXConstraint *)height {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeHeight];
}

- (HGXConstraint *)centerX {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterX];
}

- (HGXConstraint *)centerY {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterY];
}

- (HGXConstraint *)baseline {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeBaseline];
}

- (HGXConstraint *(^)(HGXAttribute))attributes {
    return ^(HGXAttribute attrs){
        return [self addConstraintWithAttributes:attrs];
    };
}

#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000) || (__MAC_OS_X_VERSION_MIN_REQUIRED >= 101100)

- (HGXConstraint *)firstBaseline {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeFirstBaseline];
}

- (HGXConstraint *)lastBaseline {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLastBaseline];
}

#endif


#if (__IPHONE_OS_VERSION_MIN_REQUIRED >= 80000) || (__TV_OS_VERSION_MIN_REQUIRED >= 9000)

- (HGXConstraint *)leftMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeftMargin];
}

- (HGXConstraint *)rightMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeRightMargin];
}

- (HGXConstraint *)topMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTopMargin];
}

- (HGXConstraint *)bottomMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeBottomMargin];
}

- (HGXConstraint *)leadingMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeLeadingMargin];
}

- (HGXConstraint *)trailingMargin {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeTrailingMargin];
}

- (HGXConstraint *)centerXWithinMargins {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterXWithinMargins];
}

- (HGXConstraint *)centerYWithinMargins {
    return [self addConstraintWithLayoutAttribute:NSLayoutAttributeCenterYWithinMargins];
}

#endif


#pragma mark - composite Attributes

- (HGXConstraint *)edges {
    return [self addConstraintWithAttributes:HGXAttributeTop | HGXAttributeLeft | HGXAttributeRight | HGXAttributeBottom];
}

- (HGXConstraint *)size {
    return [self addConstraintWithAttributes:HGXAttributeWidth | HGXAttributeHeight];
}

- (HGXConstraint *)center {
    return [self addConstraintWithAttributes:HGXAttributeCenterX | HGXAttributeCenterY];
}

#pragma mark - grouping

- (HGXConstraint *(^)(dispatch_block_t group))group {
    return ^id(dispatch_block_t group) {
        NSInteger previousCount = self.constraints.count;
        group();

        NSArray *children = [self.constraints subarrayWithRange:NSMakeRange(previousCount, self.constraints.count - previousCount)];
        HGXCompositeConstraint *constraint = [[HGXCompositeConstraint alloc] initWithChildren:children];
        constraint.delegate = self;
        return constraint;
    };
}

@end
