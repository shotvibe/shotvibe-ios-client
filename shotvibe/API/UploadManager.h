//
//  UploadManager.h
//  shotvibe
//
//  Created by omer klein on 12/1/15.
//  Copyright © 2015 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SL/MediaUploader.h"

#import <AWSS3/AWSS3.h>

@interface UploadManager : NSObject <SLMediaUploader>

-(id)initWithAWSCredentialsProvider:(id<AWSCredentialsProvider>)awsCredentialsProvider  withUserId:(long long)userId;

-(void)addUploadVideoJob:(NSString *)videoFilePath withAlbumId:(long long)albumId;

@end
