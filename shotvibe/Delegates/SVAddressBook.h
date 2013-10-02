//
//  SVAddressBookWS.h
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^AddressBookPermissionsBlock)(BOOL granted, NSError *error);


@interface SVAddressBook : NSObject

@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSMutableDictionary *filteredContacts;// Filtered contacts grouped by alphabet letters
@property (nonatomic, strong) NSArray *filteredKeys;

- (id)initWithBlock:(AddressBookPermissionsBlock)completionBlock;
- (void)filterByKeyword:(NSString*)keyword;
- (int)idOfRecord:(ABRecordRef)record;

@end
