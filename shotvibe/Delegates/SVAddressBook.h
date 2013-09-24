//
//  SVAddressBookWS.h
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVAddressBook : NSObject

@property (nonatomic, strong) NSArray *allContacts;
@property (nonatomic, strong) NSMutableDictionary *filteredContacts;// Filtered contacts grouped by alphabet letters
@property (nonatomic, strong) NSArray *filteredKeys;

- (void)filterByKeyword:(NSString*)keyword;
- (NSString*)normalizePhoneNumber:(NSString*)phone;
- (long long)idOfRecord:(ABRecordRef)record;

@end
