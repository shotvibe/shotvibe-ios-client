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
		
		abQueue = dispatch_queue_create("abqueue", DISPATCH_QUEUE_SERIAL);
		dispatch_set_target_queue(abQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
		
		// Get access to the addressbook
		ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
		
		// This is async
		ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
			
			if (granted) {
				ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook); // or get the source with ABPersonCopySource(somePersonsABRecordRef);
				CFArrayRef people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering (addressBook, source, ABPersonGetSortOrdering());
				self.allContacts = [[NSArray alloc] initWithArray:(__bridge NSArray *)(people)];
				RCLog(@"Found %i contacts", self.allContacts.count);
				
				CFRelease(people);
				CFRelease(source);
				
				if (completionBlock)
                    completionBlock(YES,nil);
			}
			else {
				RCLog(@"Unfortunately we need access to the contacts list");
				if (completionBlock)
                    completionBlock(NO,nil);
			}
		});
	}
	return self;
}


- (void)filterByKeyword:(NSString*)keyword completionBlock:(AddressBookSearchCompletionBlock)completionBlock {
	
	dispatch_async(abQueue, ^{
		
		[self.filteredContacts removeAllObjects];
		
		// Iterate over original contacts
		
		for (id evaluatedObject in self.allContacts) {
			
			NSString *name = (__bridge_transfer NSString*) ABRecordCopyCompositeName((__bridge ABRecordRef)evaluatedObject);
			
			if (name == nil) {
				RCLog(@"name is nil. skip this contact");
				continue;
			}
			if (keyword == nil || [[name lowercaseString] rangeOfString:keyword].location != NSNotFound)
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
							NSString* phoneNumericNumber = [phoneNumber stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
							if (phoneNumber != nil && phoneNumber.length > 0 && phoneNumericNumber.length > 0) {
								
								ABRecordRef persona = ABPersonCreate();
								
								CFStringRef firstName = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonFirstNameProperty);
								CFStringRef lastName = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonLastNameProperty);
								ABRecordSetValue (persona, kABPersonFirstNameProperty, firstName, nil);
								ABRecordSetValue (persona, kABPersonLastNameProperty, lastName, nil);
								
								ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
								bool didAddPhone = ABMultiValueAddValueAndLabel(multiPhone, (__bridge CFTypeRef)(phoneNumber), kABPersonPhoneMobileLabel, NULL);
								if (didAddPhone){
									ABRecordSetValue(persona, kABPersonPhoneProperty, multiPhone, nil);
								}
								
								if (ABPersonHasImageData((__bridge ABRecordRef)evaluatedObject)) {
									ABPersonSetImageData(persona, ABPersonCopyImageDataWithFormat((__bridge ABRecordRef)evaluatedObject, kABPersonImageFormatThumbnail), nil);
								}
								
								[arr addObject:(__bridge id)persona];
								
								CFRelease(multiPhone);
								//CFRelease(firstName);
								//CFRelease(lastName);
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
				RCLog(@"%i contacts for key %@", arr.count, key);
			}
		}
		
		self.filteredKeys = [[self.filteredContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			completionBlock();
		});
	});
}

	
	// For testing purposes
	
//	ABRecordRef persona = ABPersonCreate();
//	ABRecordSetValue (persona, kABPersonFirstNameProperty, @"", nil);
//	ABRecordSetValue (persona, kABPersonLastNameProperty, @"", nil);
//	ABMutableMultiValueRef multiPhone = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//	bool didAddPhone = ABMultiValueAddValueAndLabel(multiPhone, @"Google", kABPersonPhoneMobileLabel, NULL);
//	if (didAddPhone){
//		ABRecordSetValue(persona, kABPersonPhoneProperty, multiPhone, nil);
//	}
//	
//	NSMutableArray *arr = [self.filteredContacts objectForKey:@"#"];
//	if (arr == nil) {
//		arr = [[NSMutableArray alloc] init];
//	}
//	[arr addObject:(__bridge id)(persona)];
//	[self.filteredContacts setObject:arr forKey:@"#"];
	
	//CFRelease(multiPhone);
	//CFRelease(persona);
	
	
	
	//RCLog(@"self.filteredContacts %@ %@", self.filteredKeys, self.filteredContacts);


- (int)idOfRecord:(ABRecordRef)record {
	
	ABRecordID id_ = ABRecordGetRecordID(record);
	
	if (id_ == -1) {
		ABMultiValueRef phoneNumbers = ABRecordCopyValue(record, kABPersonPhoneProperty);
		NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
		CFRelease(phoneNumbers);
		phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
		phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"(" withString:@""];
		phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
		phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
		phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
		phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@"*" withString:@""];
		//phoneNumber = [phoneNumber stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
		long long i = [phoneNumber longLongValue];
		return i/64;
	}
	return id_;
}


@end
