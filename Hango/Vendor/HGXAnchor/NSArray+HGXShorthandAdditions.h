//
//  NSArray+HGXShorthandAdditions.h
//  HGXAnchor
//
//  Created by Jonas Budelmann on 22/07/13.
//  Copyright (c) 2013 Jonas Budelmann. All rights reserved.
//

#import "NSArray+HGXAdditions.h"

#ifdef HGX_SHORTHAND

/**
 *	Shorthand array additions without the 'hgx_' prefixes,
 *  only enabled if HGX_SHORTHAND is defined
 */
@interface NSArray (HGXShorthandAdditions)

- (NSArray *)makeConstraints:(void(^)(HGXConstraintMaker *make))block;
- (NSArray *)updateConstraints:(void(^)(HGXConstraintMaker *make))block;
- (NSArray *)remakeConstraints:(void(^)(HGXConstraintMaker *make))block;

@end

@implementation NSArray (HGXShorthandAdditions)

- (NSArray *)makeConstraints:(void(^)(HGXConstraintMaker *))block {
    return [self hgx_makeConstraints:block];
}

- (NSArray *)updateConstraints:(void(^)(HGXConstraintMaker *))block {
    return [self hgx_updateConstraints:block];
}

- (NSArray *)remakeConstraints:(void(^)(HGXConstraintMaker *))block {
    return [self hgx_remakeConstraints:block];
}

@end

#endif
