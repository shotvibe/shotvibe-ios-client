//
//  UILongPressGestureRecognizer+LongPressWithGLFeedTableCell.h
//  shotvibe
//
//  Created by Tsah Kashkash on 11/01/2016.
//  Copyright © 2016 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLFeedTableCell.h"

@interface UILongPressGestureRecognizer (LongPressWithGLFeedTableCell)
@property (nonatomic, retain) GLFeedTableCell * cell;
@end
