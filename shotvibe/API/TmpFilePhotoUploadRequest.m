//
//  TmpFilePhotoUploadRequest.m
//  shotvibe
//
//  Created by raptor on 9/26/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "TmpFilePhotoUploadRequest.h"

@implementation TmpFilePhotoUploadRequest
{
    NSString *tmpFile_;
}


- (id)initWithTmpFile:(NSString *)tmpFile
{
    self = [super init];
    if (self) {
        tmpFile_ = tmpFile;
    }
    return self;
}


- (void)saveToFileWithNSString:(NSString *)fileName
{
    NSError *error;
    if (![[NSFileManager defaultManager] moveItemAtPath:tmpFile_
                                                 toPath:fileName
                                                  error:&error]) {
        NSLog(@"Error Moving file: %@", error.description);
        @throw [[NSException alloc] initWithName:@"Error Moving File"
                                          reason:[NSString stringWithFormat:@"Error Moving %@ to %@, error: %@", tmpFile_, fileName, error.description]
                                        userInfo:nil];
    }
}


@end
