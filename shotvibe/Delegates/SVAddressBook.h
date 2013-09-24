//
//  SVAddressBookWS.h
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVAddressBook : NSObject {
	
	NSArray *allContacts;
}

@property (nonatomic, strong) NSMutableDictionary *filteredContacts;// Filtered contacts grouped by alphabet letters
@property (nonatomic, strong) NSArray *filteredKeys;

- (void)filterByKeyword:(NSString*)keyword;

@end
