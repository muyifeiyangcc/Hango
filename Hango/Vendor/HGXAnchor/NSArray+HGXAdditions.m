//
//  NSArray+HGXAdditions.m
//  
//
//  Created by Daniel Hammond on 11/26/13.
//
//

#import "NSArray+HGXAdditions.h"
#import "View+HGXAdditions.h"

@implementation NSArray (HGXAdditions)

- (NSArray *)hgx_makeConstraints:(void(^)(HGXConstraintMaker *make))block {
    NSMutableArray *constraints = [NSMutableArray array];
    for (HGX_VIEW *view in self) {
        NSAssert([view isKindOfClass:[HGX_VIEW class]], @"All objects in the array must be views");
        [constraints addObjectsFromArray:[view hgx_makeConstraints:block]];
    }
    return constraints;
}

- (NSArray *)hgx_updateConstraints:(void(^)(HGXConstraintMaker *make))block {
    NSMutableArray *constraints = [NSMutableArray array];
    for (HGX_VIEW *view in self) {
        NSAssert([view isKindOfClass:[HGX_VIEW class]], @"All objects in the array must be views");
        [constraints addObjectsFromArray:[view hgx_updateConstraints:block]];
    }
    return constraints;
}

- (NSArray *)hgx_remakeConstraints:(void(^)(HGXConstraintMaker *make))block {
    NSMutableArray *constraints = [NSMutableArray array];
    for (HGX_VIEW *view in self) {
        NSAssert([view isKindOfClass:[HGX_VIEW class]], @"All objects in the array must be views");
        [constraints addObjectsFromArray:[view hgx_remakeConstraints:block]];
    }
    return constraints;
}

- (void)hgx_distributeViewsAlongAxis:(HGXAxisType)axisType withFixedSpacing:(CGFloat)fixedSpacing leadSpacing:(CGFloat)leadSpacing tailSpacing:(CGFloat)tailSpacing {
    if (self.count < 2) {
        NSAssert(self.count>1,@"views to distribute need to bigger than one");
        return;
    }
    
    HGX_VIEW *tempSuperView = [self hgx_commonSuperviewOfViews];
    if (axisType == HGXAxisTypeHorizontal) {
        HGX_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            HGX_VIEW *v = self[i];
            [v hgx_makeConstraints:^(HGXConstraintMaker *make) {
                if (prev) {
                    make.width.equalTo(prev);
                    make.left.equalTo(prev.hgx_right).offset(fixedSpacing);
                    if (i == self.count - 1) {//last one
                        make.right.equalTo(tempSuperView).offset(-tailSpacing);
                    }
                }
                else {//first one
                    make.left.equalTo(tempSuperView).offset(leadSpacing);
                }
                
            }];
            prev = v;
        }
    }
    else {
        HGX_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            HGX_VIEW *v = self[i];
            [v hgx_makeConstraints:^(HGXConstraintMaker *make) {
                if (prev) {
                    make.height.equalTo(prev);
                    make.top.equalTo(prev.hgx_bottom).offset(fixedSpacing);
                    if (i == self.count - 1) {//last one
                        make.bottom.equalTo(tempSuperView).offset(-tailSpacing);
                    }                    
                }
                else {//first one
                    make.top.equalTo(tempSuperView).offset(leadSpacing);
                }
                
            }];
            prev = v;
        }
    }
}

- (void)hgx_distributeViewsAlongAxis:(HGXAxisType)axisType withFixedItemLength:(CGFloat)fixedItemLength leadSpacing:(CGFloat)leadSpacing tailSpacing:(CGFloat)tailSpacing {
    if (self.count < 2) {
        NSAssert(self.count>1,@"views to distribute need to bigger than one");
        return;
    }
    
    HGX_VIEW *tempSuperView = [self hgx_commonSuperviewOfViews];
    if (axisType == HGXAxisTypeHorizontal) {
        HGX_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            HGX_VIEW *v = self[i];
            [v hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.width.equalTo(@(fixedItemLength));
                if (prev) {
                    if (i == self.count - 1) {//last one
                        make.right.equalTo(tempSuperView).offset(-tailSpacing);
                    }
                    else {
                        CGFloat offset = (1-(i/((CGFloat)self.count-1)))*(fixedItemLength+leadSpacing)-i*tailSpacing/(((CGFloat)self.count-1));
                        make.right.equalTo(tempSuperView).multipliedBy(i/((CGFloat)self.count-1)).with.offset(offset);
                    }
                }
                else {//first one
                    make.left.equalTo(tempSuperView).offset(leadSpacing);
                }
            }];
            prev = v;
        }
    }
    else {
        HGX_VIEW *prev;
        for (int i = 0; i < self.count; i++) {
            HGX_VIEW *v = self[i];
            [v hgx_makeConstraints:^(HGXConstraintMaker *make) {
                make.height.equalTo(@(fixedItemLength));
                if (prev) {
                    if (i == self.count - 1) {//last one
                        make.bottom.equalTo(tempSuperView).offset(-tailSpacing);
                    }
                    else {
                        CGFloat offset = (1-(i/((CGFloat)self.count-1)))*(fixedItemLength+leadSpacing)-i*tailSpacing/(((CGFloat)self.count-1));
                        make.bottom.equalTo(tempSuperView).multipliedBy(i/((CGFloat)self.count-1)).with.offset(offset);
                    }
                }
                else {//first one
                    make.top.equalTo(tempSuperView).offset(leadSpacing);
                }
            }];
            prev = v;
        }
    }
}

- (HGX_VIEW *)hgx_commonSuperviewOfViews
{
    HGX_VIEW *commonSuperview = nil;
    HGX_VIEW *previousView = nil;
    for (id object in self) {
        if ([object isKindOfClass:[HGX_VIEW class]]) {
            HGX_VIEW *view = (HGX_VIEW *)object;
            if (previousView) {
                commonSuperview = [view hgx_closestCommonSuperview:commonSuperview];
            } else {
                commonSuperview = view;
            }
            previousView = view;
        }
    }
    NSAssert(commonSuperview, @"Can't constrain views that do not share a common superview. Make sure that all the views in this array have been added into the same view hierarchy.");
    return commonSuperview;
}

@end
