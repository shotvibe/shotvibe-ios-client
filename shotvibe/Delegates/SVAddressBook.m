//
//  SVAddressBookWS.m
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "SVAddressBook.h"
#import "SVDefines.h"
#import "AlbumMember.h"


@implementation SVAddressBook


- (id)init {
	self = [super init];
	if (self) {
		//self.alphabet = @[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#"];
		self.filteredKeys = [[NSArray alloc] init];
		self.filteredContacts = [[NSMutableDictionary alloc] init];
		allContacts = [[NSArray alloc] init];
		
		// Get access to the addressbook
		ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
		
		// This is async
		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
			
			if (granted) {
				ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook); // or get the source with ABPersonCopySource(somePersonsABRecordRef);
				CFArrayRef people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering (addressBook, source, ABPersonGetSortOrdering());
				allContacts = [[NSArray alloc] initWithArray:(__bridge NSArray *)(people)];
				
				// For testing purposes
//				allContacts = [allContacts arrayByAddingObjectsFromArray:(__bridge NSArray *)(people)];
//				allContacts = [allContacts arrayByAddingObjectsFromArray:(__bridge NSArray *)(people)];
//				allContacts = [allContacts arrayByAddingObjectsFromArray:(__bridge NSArray *)(people)];
//				allContacts = [allContacts arrayByAddingObjectsFromArray:(__bridge NSArray *)(people)];
//				allContacts = [allContacts arrayByAddingObjectsFromArray:(__bridge NSArray *)(people)];
//				allContacts = [allContacts arrayByAddingObjectsFromArray:(__bridge NSArray *)(people)];
//				allContacts = [allContacts arrayByAddingObjectsFromArray:(__bridge NSArray *)(people)];
//				
				CFRelease(people);
				CFRelease(source);
				NSLog(@"contacts completion");
			}
			else {
				NSLog(@"Unfortunately we need access to the contacts list");
			}
		});
		
		NSLog(@"fin init");
	}
	return self;
}


- (void)filterByKeyword:(NSString*)keyword {
	
	[self.filteredContacts removeAllObjects];
	
	// Iterate over original contacts
	
	for (id evaluatedObject in allContacts) {
		
		NSString *name = (__bridge_transfer NSString*) ABRecordCopyCompositeName((__bridge ABRecordRef)evaluatedObject);
		
		if (keyword == nil || (name != nil && [[name lowercaseString] rangeOfString:keyword].location != NSNotFound))
		{
			NSString *key = [[name substringToIndex:1] uppercaseString];
			if (key == nil || [key isEqualToString:@"_"]) {
				key = @"#";
			}
			NSMutableArray *arr = [self.filteredContacts objectForKey:key];
			if (arr == nil) {
				arr = [[NSMutableArray alloc] init];
			}
			
			ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonPhoneProperty);
			signed long num = ABMultiValueGetCount(phoneNumbers);
			
			if (num == 0) {
				[arr addObject:evaluatedObject];
			}
			else {
				for (CFIndex i = 0; i < num; i++) {
					
					NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
					
					if (phoneNumber != nil && phoneNumber.length > 0) {
						//[aCopyMember setObject:phoneNumber forKey:kMemberPhone];
					}
					[arr addObject:evaluatedObject];
				}
			}
			
			CFRelease(phoneNumbers);
			
			
			[self.filteredContacts setObject:arr forKey:key];
		}
	}
	
	self.filteredKeys = [[self.filteredContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	
	//NSLog(@"self.filteredContacts %@ %@", self.filteredKeys, self.filteredContacts);
}


@end
