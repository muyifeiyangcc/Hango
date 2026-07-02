//
//  UIViewController+HGXAdditions.h
//  HGXAnchor
//
//  Created by Craig Siemens on 2015-06-23.
//
//

#import "HGXUtilities.h"
#import "HGXConstraintMaker.h"
#import "HGXViewAttribute.h"

#ifdef HGX_VIEW_CONTROLLER

@interface HGX_VIEW_CONTROLLER (HGXAdditions)

/**
 *	following properties return a new HGXViewAttribute with appropriate UILayoutGuide and NSLayoutAttribute
 */
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_topLayoutGuide;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_bottomLayoutGuide;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_topLayoutGuideTop;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_topLayoutGuideBottom;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_bottomLayoutGuideTop;
@property (nonatomic, strong, readonly) HGXViewAttribute *hgx_bottomLayoutGuideBottom;


@end

#endif
