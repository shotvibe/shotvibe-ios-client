//
//  SVSyncEngine.h
//  shotvibe
//
//  Created by Baluta Cristian on 10/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SVDownloadManager.h"
#import "SVUploadManager.h"

@interface SVSyncEngine : NSObject

- (void) start;
- (void) stop;

@end
