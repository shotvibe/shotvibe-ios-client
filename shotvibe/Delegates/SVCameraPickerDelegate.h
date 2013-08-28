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

@class Album;
@protocol SVCameraPickerDelegate <NSObject>

@required
- (void)cameraExit;
- (void)cameraWasDismissedWithAlbum:(Album*)album;
@optional
- (void)didSelectPhoto:(UIImage *)thePhoto;
//- (void)imagesCaptured:(NSArray*)capturedImages forAlbum:(Album*)selectedAlbum;

@end
