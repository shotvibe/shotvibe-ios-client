//
//  SVURLBuilderWS.m
//  shotvibe
//
//  Created by John Gabelmann on 6/27/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVURLBuilderWS.h"
#import "SVDefines.h"

@implementation SVURLBuilderWS

- (NSURL *)photoUrlWithString:(NSString *)aString
{
    NSString *photoURL = nil;
    
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
        if (IS_IPHONE_5) {
            photoURL = [[aString stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone5Extension];
        }
        else
        {
            photoURL = [[aString stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone4Extension];
        }
    }
    else
    {
        photoURL = [[aString stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone3Extension];
    }
    
    return [NSURL URLWithString:photoURL];
}


@end
