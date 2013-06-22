//
//  SVDefines.h
//  shotvibe
//
//  Created by Fredrick Gabelmann on 2/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#ifndef shotvibe_SVDefines_h
#define shotvibe_SVDefines_h

#define IS_IOS6_OR_GREATER ([[UIDevice currentDevice].systemVersion floatValue] >= 6.0)
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

#define kApplicationName @"ShotVibe"
#define kApplicationUploadQueueName @"ShotVibeUploadQueue"

#define kPhotoThumbExtension @"_thumb75.jpg"
#define kPhotoIphone3Extension @"_iphone3.jpg"
#define kPhotoIphone4Extension @"_iphone4.jpg"
#define kPhotoIphone5Extension @"_iphone5.jpg"

#define kUserAlbumsLoadedNotification @"SVAlbumsLoaded"
#define kPhotosLoadedNotification @"SVPhotosLoaded"
#define kStartPhotoUpload @"kStartPhotoUpload"
#define kPhotosLoadedForIndexPathNotification @"SVPhotosLoadedForIndexPath"
#define kUploadPhotosToAlbumProgressNotification @"UploadPhotosToAlbumProgressNotification"

#define kSDSyncEngineInitialCompleteKey             @"SyncEngineInitialSyncCompleted"
#define kSDSyncEngineSyncCompletedNotificationName  @"SyncEngineSyncCompleted"
#define kCategoryBadgeUpdatedNotification           @"CategoryBadgeUpdatedNotification"

#endif