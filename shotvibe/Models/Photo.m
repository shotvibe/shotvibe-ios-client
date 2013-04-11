//
//  Photo.m
//  shotvibe
//
//  Created by John Gabelmann on 4/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "Photo.h"
#import "Album.h"
#import "Member.h"


@implementation Photo

@dynamic albumId;
@dynamic dateCreated;
@dynamic photoId;
@dynamic photoUrl;
@dynamic hasViewed;
@dynamic album;
@dynamic author;


- (void)prepareForDeletion
{
    [super prepareForDeletion];
    
    /*if ([self.hasViewed boolValue]) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *documentsDirectoryPath = [documentsDirectory stringByAppendingPathComponent:self.album.name];
        
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.jpg", documentsDirectoryPath, self.photoId];
        
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:filePath])
        {
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
        }
    }*/
    
}

@end
