//
//  SVSidebarAlbumSection.m
//  shotvibe
//
//  Created by Baluta Cristian on 06/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVSidebarAlbumSection.h"

@implementation SVSidebarAlbumSection

- (instancetype)init {
	
	self = [super init];
	if (self) {
		_rows = [[NSMutableArray alloc] init];
	}
	return self;
}


- (NSUInteger)countOfRowHeights {
	return [self.rows count];
}

- (id)objectInRowHeightsAtIndex:(NSUInteger)idx {
	return self.rows[idx];
}

- (void)insertObject:(id)anObject inRowHeightsAtIndex:(NSUInteger)idx {
	[self.rows insertObject:anObject atIndex:idx];
}

- (void)insertRowHeights:(NSArray *)rowHeightArray atIndexes:(NSIndexSet *)indexes {
	[self.rows insertObjects:rowHeightArray atIndexes:indexes];
}

- (void)removeObjectFromRowHeightsAtIndex:(NSUInteger)idx {
	[self.rows removeObjectAtIndex:idx];
}

- (void)removeRowHeightsAtIndexes:(NSIndexSet *)indexes {
	[self.rows removeObjectsAtIndexes:indexes];
}

- (void)replaceObjectInRowHeightsAtIndex:(NSUInteger)idx withObject:(id)anObject {
	self.rows[idx] = anObject;
}

- (void)replaceRowHeightsAtIndexes:(NSIndexSet *)indexes withRowHeights:(NSArray *)rowHeightArray {
	[self.rows replaceObjectsAtIndexes:indexes withObjects:rowHeightArray];
}


@end
