//
//  SVCameraPickerDelegate.h
//  shotvibe
//
//  Created by Baluta Cristian on 23/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVCameraPickerDelegate : NSObject

@end

@class SLAlbumSummary;
@protocol SVCameraPickerDelegate <NSObject>

@required
- (void)cameraExit;
- (void)cameraWasDismissedWithAlbum:(SLAlbumSummary *)album;
@optional
- (void)didSelectPhoto:(UIImage *)thePhoto;
//- (void)imagesCaptured:(NSArray*)capturedImages forAlbum:(Album*)selectedAlbum;

@end
