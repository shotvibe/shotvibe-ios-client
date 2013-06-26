//
//  SVOperation.h
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SVUploaderOperationQueue;

@interface SVUploaderOperation : NSManagedObject

@property (nonatomic, retain) NSNumber * albumId;
@property (nonatomic, retain) NSString * photoId;
@property (nonatomic, retain) SVUploaderOperationQueue *queue;
@end