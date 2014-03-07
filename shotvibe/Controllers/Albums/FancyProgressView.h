//
//  FancyProgressView.h
//  shotvibe
//
//  Created by Oblosys on 30-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "Util.h"

@interface FancyProgressView : UIView

@property (nonatomic) float progress; // Between 0.0 and 1.0, values outside are clipped. Setting progress with the property is not animated.

+ (void)disableProgressViewsWithCompletion:(void (^)())completionBlock;

- (void)reset;

- (void)appearWithProgressObject:(id)progressObject;

@end
