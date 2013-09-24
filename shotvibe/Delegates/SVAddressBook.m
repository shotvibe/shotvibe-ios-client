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


- (id)initWithBlock:(AddressBookPermissionsBlock)completionBlock {
	self = [super init];
	if (self) {
		//self.alphabet = @[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#"];
		self.filteredKeys = [[NSArray alloc] init];
		self.filteredContacts = [[NSMutableDictionary alloc] init];
		self.allContacts = [[NSArray alloc] init];
		
		// Get access to the addressbook
		ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
		
		// This is async
		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
			
			if (granted) {
				ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook); // or get the source with ABPersonCopySource(somePersonsABRecordRef);
				CFArrayRef people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering (addressBook, source, ABPersonGetSortOrdering());
				self.allContacts = [[NSArray alloc] initWithArray:(__bridge NSArray *)(people)];
				
				CFRelease(people);
				CFRelease(source);
				
				if (completionBlock)
                    completionBlock(YES,nil);
			}
			else {
				NSLog(@"Unfortunately we need access to the contacts list");
				if (completionBlock)
                    completionBlock(NO,nil);
			}
		});
	}
	return self;
}


- (void)filterByKeyword:(NSString*)keyword {
	
	[self.filteredContacts removeAllObjects];
	
	// Iterate over original contacts
	
	for (id evaluatedObject in self.allContacts) {
		
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
					
					if (i > 0) {
						// Create a separate contact with the alternative phone numbers of a contact
						NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
						if (phoneNumber != nil && phoneNumber.length > 0) {
							
							ABRecordRef persona = ABPersonCreate();
							
							CFStringRef firstName = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonFirstNameProperty);
							CFStringRef lastName = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonLastNameProperty);
							ABRecordSetValue (persona, kABPersonFirstNameProperty, firstName, nil);
							ABRecordSetValue (persona, kABPersonLastNameProperty, lastName, nil);
							//CFRelease(firstName);
							//CFRelease(lastName);
							
							ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
							bool didAddPhone = ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(phoneNumber), kABPersonPhoneMobileLabel, NULL);
							if (didAddPhone){
								ABRecordSetValue(persona, kABPersonPhoneProperty, multiPhone, nil);
							}
							CFRelease(multiPhone);
							
							if (ABPersonHasImageData((__bridge ABRecordRef)evaluatedObject)) {
								ABPersonSetImageData(persona, ABPersonCopyImageDataWithFormat((__bridge ABRecordRef)evaluatedObject, kABPersonImageFormatThumbnail), nil);
							}
							
							[arr addObject:(__bridge id)(persona)];
							
							CFRelease(persona);
						}
					}
					else {
						[arr addObject:evaluatedObject];
					}
				}
			}
			
			CFRelease(phoneNumbers);
			
			
			[self.filteredContacts setObject:arr forKey:key];
		}
	}
	
	self.filteredKeys = [[self.filteredContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
	
	//NSLog(@"self.filteredContacts %@ %@", self.filteredKeys, self.filteredContacts);
}

- (long long)idOfRecord:(ABRecordRef)record {
	
	ABRecordID id_ = ABRecordGetRecordID(record);
	
	if (id_ == -1) {
		ABMultiValueRef phoneNumbers = ABRecordCopyValue(record, kABPersonPhoneProperty);
		NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
		CFRelease(phoneNumbers);
		phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
		phoneNumber = [phoneNumber stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
		return [phoneNumber longLongValue];
	}
	return id_;
}


@end
