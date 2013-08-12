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

static NSString * const kAPIBaseURLString = @"https://api.shotvibe.com/";

#define kApplicationName @"ShotVibe"
#define kApplicationUploadQueueName @"ShotVibeUploadQueue"

#define kApplicationUserId @"userId"
#define kApplicationUserAuthToken @"userAuthToken"

#define kPhotoThumbExtension @"_thumb75.jpg"
#define kPhotoIphone3Extension @"_iphone3.jpg"
#define kPhotoIphone4Extension @"_iphone4.jpg"
#define kPhotoIphone5Extension @"_iphone5.jpg"

#define kUserAlbumsLastRequestedDate @"SVAlbumsLastRequestedDate"
#define kUserAlbumsLoadedNotification @"SVAlbumsLoaded"
#define kPhotosLoadedNotification @"SVPhotosLoaded"
#define kStartPhotoUpload @"kStartPhotoUpload"
#define kPhotosLoadedForIndexPathNotification @"SVPhotosLoadedForIndexPath"
#define kUploadPhotosToAlbumProgressNotification @"UploadPhotosToAlbumProgressNotification"

#define kSVSyncEngineDownloadCompletedNotification	@"SyncEngineDownloadCompletedNotification"
#define kSVSyncEngineDownloadIndividualCompletedNotification      @"SyncEngineDownloadIndividualCompletedNotification"
#define kSVSyncEngineAlbumProcessedNotification   @"kSVSyncEngineAlbumProcessedNotification"

#define kMemberNickname     @"nickname"
#define kMemberPhone        @"phone"
#define kMemberFirstName    @"firstName"
#define kMemberLastName     @"lastname"

#define kUserCountryCode	@"country_code"

typedef enum {
    SVObjectSyncCompleted = 0,
    SVObjectSyncDownloadNeeded,
    SVObjectSyncUploadNeeded,
    SVObjectSyncUploadProgress,
    SVObjectSyncUploadComplete,
    SVObjectSyncDeleteNeeded,
} SVObjectSyncStatus;


#endif
