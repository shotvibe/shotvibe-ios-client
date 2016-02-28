//
//  UILongPressGestureRecognizer+LongPressWithGLFeedTableCell.m
//  shotvibe
//
//  Created by Tsah Kashkash on 11/01/2016.
//  Copyright © 2016 PicsOnAir Ltd. All rights reserved.
//

#import "UILongPressGestureRecognizer+LongPressWithGLFeedTableCell.h"

@implementation UILongPressGestureRecognizer (LongPressWithGLFeedTableCell)

-(GLFeedTableCell*)cell {
    
    return self.cell;

}

- (void)setCell:(GLFeedTableCell *)cell {
    self.cell = cell;
}

@end
