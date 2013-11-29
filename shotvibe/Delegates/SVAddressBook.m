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
#import "AlbumUser.h"


@implementation SVAddressBook

+ (instancetype)sharedBook {
    static SVAddressBook *_sharedBook = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _sharedBook = [[self alloc] init];
    });
    
    return _sharedBook;
}

- (void)requestAccessWithCompletion:(AddressBookPermissionsBlock)completionBlock {
	
	//self.alphabet = @[@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z",@"#"];
	self.filteredKeys = [[NSArray alloc] init];
	self.filteredContacts = [[NSMutableDictionary alloc] init];
	self.allContacts = [[NSArray alloc] init];
	_granted = NO;
	
	abQueue = dispatch_queue_create("abqueue", DISPATCH_QUEUE_SERIAL);
	dispatch_set_target_queue(abQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
	
	// Get access to the addressbook
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
	
	// This is async
	ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
		
		_granted = granted;
		
		if (granted) {
			//CFArrayRef sources = ABAddressBookCopyArrayOfAllSources(addressBook);
			//ABRecordRef source = ABAddressBookCopyDefaultSource(addressBook); // or get the source with ABPersonCopySource(somePersonsABRecordRef);
			//CFArrayRef people = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering (addressBook, sources, ABPersonGetSortOrdering());
			//CFRelease(source);
			
			CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
			NSArray *contacts = [[NSArray alloc] initWithArray:(__bridge NSArray *)(people)];
			CFRelease(people);
			
			// Create SVRecord objects
			__block NSMutableArray *svRecords = [NSMutableArray array];
			
			dispatch_async(abQueue, ^{
				
				// Iterate over original contacts
				
				for (id evaluatedObject in contacts) {
					
					//NSString *fullname = (__bridge_transfer NSString*) ABRecordCopyCompositeName((__bridge ABRecordRef)(evaluatedObject));
					//NSString *surname = (__bridge_transfer NSString*) ABRecordCopyValue(<#ABRecordRef record#>, ABProperty)((__bridge ABRecordRef)(evaluatedObject));
					NSString *firstName = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)(evaluatedObject), kABPersonFirstNameProperty);
					NSString *lastName = (__bridge NSString *)ABRecordCopyValue((__bridge ABRecordRef)(evaluatedObject), kABPersonLastNameProperty);
					NSString *surname = @"";
					
					if (!lastName) {
						lastName = @"";
						surname = firstName;
					}
					if (!firstName) {
						firstName = @"";
						surname = firstName;
					}
					NSString *fullname = [NSString stringWithFormat:@"%@ %@", lastName, firstName];
					
					ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonPhoneProperty);
					signed long num = ABMultiValueGetCount(phoneNumbers);
					
					if (num == 0) {
						// Record with no phone number
						SVRecord *record = [[SVRecord alloc] init];
						record.recordId = svRecords.count;
						record.fullname = fullname;
						record.surname = surname;
						record.phone = @" ";
						record.invalid = YES;
						
						int i = record.recordId;
						if (i>78) i = 1 + i%78;
						record.iconDefaultRemotePath = [NSString stringWithFormat:@"https://shotvibe-avatars-01.s3.amazonaws.com/default-avatar-00%@%i.jpg", i<10?@"0":@"", i];
						
						[svRecords addObject:record];
					}
					else {
						for (CFIndex i = 0; i < num; i++) {
							
							NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
							
							SVRecord *record = [[SVRecord alloc] init];
							record.recordId = svRecords.count;
							record.fullname = fullname;
							record.surname = surname;
							record.phone = phoneNumber.length > 0 ? phoneNumber : @" ";
							record.invalid = phoneNumber.length <= 1;
							//RCLog(@"%i %@ %@ -> %@", record.recordId, record.name, record.phone, phoneNumericNumber);
							
							if (ABPersonHasImageData((__bridge ABRecordRef)evaluatedObject)) {
								record.iconLocalData = (__bridge NSData *)(ABPersonCopyImageDataWithFormat((__bridge ABRecordRef)evaluatedObject, kABPersonImageFormatThumbnail));
							}
							
							int i = record.recordId;
							if (i>78) i = 1 + i%78;
							record.iconDefaultRemotePath = [NSString stringWithFormat:@"https://shotvibe-avatars-01.s3.amazonaws.com/default-avatar-00%@%i.jpg", i<10?@"0":@"", i];
							
							[svRecords addObject:record];
						}
					}
										
					if (phoneNumbers != nil) CFRelease(phoneNumbers);
				}
				
				self.allContacts = svRecords;
				
				dispatch_async(dispatch_get_main_queue(), ^{
					
					[self filterByKeyword:nil membersOnly:NO completionBlock:^{
						
						if (completionBlock)
							completionBlock(YES,nil);
					}];
				});
			});
		}
		else {
			if (completionBlock)
				completionBlock(NO,nil);
		}
	});
}

- (void)filterByKeyword:(NSString*)keyword membersOnly:(BOOL)membersOnly completionBlock:(AddressBookSearchCompletionBlock)completionBlock {
	
	dispatch_async(abQueue, ^{
		
		[self.filteredContacts removeAllObjects];
		
		// Iterate over original contacts
		
		for (SVRecord *record in self.allContacts) {
			
			if (keyword == nil || [[record.fullname lowercaseString] rangeOfString:keyword].location != NSNotFound) {
				
				// Check if this contacts is a shotvibe member
				if (record.memberId == 0 && membersOnly) {
					continue;
				}
				
				NSString *key = [[record.fullname substringToIndex:1] uppercaseString];
				if (key == nil || [key isEqualToString:@"_"]) {
					key = @"#";
				}
				NSMutableArray *arr = [self.filteredContacts objectForKey:key];
				if (arr == nil) {
					arr = [[NSMutableArray alloc] init];
				}
				[arr addObject:record];
				
				[self.filteredContacts setObject:arr forKey:key];
			}
		}
		
		self.filteredKeys = [[self.filteredContacts allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			completionBlock();
		});
	});
}

- (SVRecord*)recordOfPhoneId:(int64_t)phoneId {
	
	for (SVRecord *record in self.allContacts) {
		if (record.phoneId == phoneId) {
			return record;
		}
	}
	
	return nil;
}

@end
