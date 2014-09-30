//
//  TmpFilePhotoUploadRequest.h
//  shotvibe
//
//  Created by raptor on 9/26/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/PhotoUploadRequest.h"

@interface TmpFilePhotoUploadRequest : NSObject <SLPhotoUploadRequest>

- (id)initWithTmpFile:(NSString *)tmpFile;

@end
