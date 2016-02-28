//
//  YALSunyRefreshControl.h
//  YALSunyPullToRefresh
//
//  Created by Konstantin Safronov on 12/24/14.
//  Copyright (c) 2014 Konstantin Safronov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YALSunnyRefreshControl : UIView

+ (YALSunnyRefreshControl*)attachToScrollView:(UIScrollView *)scrollView
                                      target:(id)target
                               refreshAction:(SEL)refreshAction;

- (void)startRefreshing;

- (void)endRefreshing;

@end
// Copyright belongs to original author
// http://code4app.net (en) http://code4app.com (cn)
// From the most professional code share website: Code4App.net