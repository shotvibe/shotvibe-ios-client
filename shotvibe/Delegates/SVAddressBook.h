//
//  SVAddressBookWS.h
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AddressBookPermissionsBlock)(BOOL granted, NSError *error);
typedef void(^AddressBookSearchCompletionBlock)();


@interface SVAddressBook : NSObject {
	
	dispatch_queue_t abQueue;
}

@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSMutableDictionary *filteredContacts;// Filtered contacts grouped by alphabet letters
@property (nonatomic, strong) NSArray *filteredKeys;

- (id)initWithBlock:(AddressBookPermissionsBlock)completionBlock;
- (void)filterByKeyword:(NSString*)keyword completionBlock:(AddressBookSearchCompletionBlock)completionBlock;
- (int)idOfRecord:(ABRecordRef)record;
- (ABRecordRef)recordOfRecordId:(ABRecordID)recordId;

@end
