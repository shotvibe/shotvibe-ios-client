//
//  SVOperationQueue.h
//  shotvibe
//
//  Created by Peter Kasson on 6/22/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class SVOperation;

@interface SVOperationQueue : NSManagedObject

@property (nonatomic, retain) NSSet *operations;
@end

@interface SVOperationQueue (CoreDataGeneratedAccessors)

- (void)addOperationsObject:(SVOperation *)value;
- (void)removeOperationsObject:(SVOperation *)value;
- (void)addOperations:(NSSet *)values;
- (void)removeOperations:(NSSet *)values;

@end
