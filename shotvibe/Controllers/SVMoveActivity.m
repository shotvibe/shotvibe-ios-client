//
//  SVMoveActivity.m
//  shotvibe
//
//  Created by Baluta Cristian on 04/09/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVMoveActivity.h"

@implementation SVMoveActivity

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Move", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconMove"];
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	
}

- (void)performActivity
{
	
}

@end
