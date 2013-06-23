//
//  SVOperationQueue.h
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SVUploaderOperation;

@interface SVUploaderOperationQueue : NSManagedObject

@property (nonatomic, retain) NSSet *operations;
@end

@interface SVUploaderOperationQueue (CoreDataGeneratedAccessors)

- (void)addOperationsObject:(SVUploaderOperation *)value;
- (void)removeOperationsObject:(SVUploaderOperation *)value;
- (void)addOperations:(NSSet *)values;
- (void)removeOperations:(NSSet *)values;

@end
