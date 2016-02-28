//
//  MediaHelper.h
//  shotvibe
//
//  Created by benny on 11/19/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SaveImageCompletion)(NSError *error);

@interface MediaHelper : NSObject

+ (void)saveImageToAlbum:(UIImage *)image toAlbum:(NSString *)albumName withCompletionBlock:(SaveImageCompletion)completionBlock;

@end
