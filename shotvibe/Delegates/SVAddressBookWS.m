//
//  SVAddressBookWS.m
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "SVAddressBookWS.h"
#import "SVDefines.h"

@interface SVAddressBookWS ()
- (NSArray *)convertContactsToMembers:(NSArray *)contacts;
@end

@implementation SVAddressBookWS



- (void)searchContactsWithString:(NSString *)string WithCompletion:(void (^)(NSArray *, NSError *))block
{
    // First grab all contacts
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
    
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        if (granted) {
            
            // Grab everyone and do an initial sort based on the user's preferences
            CFArrayRef people = ABAddressBookCopyArrayOfAllPeople(addressBook);
            CFMutableArrayRef peopleMutable = CFArrayCreateMutableCopy(kCFAllocatorDefault, CFArrayGetCount(people), people);
            
            CFArraySortValues(peopleMutable, CFRangeMake(0, CFArrayGetCount(peopleMutable)), (CFComparatorFunction)ABPersonComparePeopleByName, (void *)ABPersonGetSortOrdering());
            
            NSArray *allContacts = [[NSArray alloc] initWithArray:(__bridge NSArray *)(peopleMutable)];
            
            CFRelease(peopleMutable);
            CFRelease(people);
            
            if (string.length > 0) {
                // Now build a predicate to filter by phone number or name
                NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
                    ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonPhoneProperty);
                    
                    BOOL result = NO;
                    
                    for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
                        NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                        if ([phoneNumber rangeOfString:string].location != NSNotFound) {
                            result = YES;
                            break;
                        }
                    }
                    
                    if (result == NO) {
                        NSString* firstName = (__bridge_transfer NSString*) ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonFirstNameProperty);
                        if ([[firstName lowercaseString] hasPrefix:[string lowercaseString]]) {
                            result = YES;
                        }
                    }


                    if (result == NO) {
                        NSString* lastName = (__bridge_transfer NSString*) ABRecordCopyValue((__bridge ABRecordRef)evaluatedObject, kABPersonLastNameProperty);
                        if ([[lastName lowercaseString] hasPrefix:[string lowercaseString]]) {
                            result = YES;
                        }
                    }
                    
                    CFRelease(phoneNumbers);
                    
                    return result;
                }];
                
                
                NSArray *filteredContacts = [allContacts filteredArrayUsingPredicate:predicate];
                
                block([self convertContactsToMembers:filteredContacts], nil);
            }
            else
            {
                block([self convertContactsToMembers:allContacts], nil);
            }
            
        }
        else
        {
            block(nil, (__bridge NSError *)(error));
        }
    });
}


#pragma mark - Private Methods

- (NSArray *)convertContactsToMembers:(NSArray *)contacts
{
    NSMutableArray *members = [[NSMutableArray alloc] init];
    
    for (id aPerson in contacts) {
        NSMutableDictionary *aMember = [[NSMutableDictionary alloc] init];
        
        NSString* firstName = (__bridge_transfer NSString*) ABRecordCopyValue((__bridge ABRecordRef)aPerson, kABPersonFirstNameProperty);
        NSString* lastName = (__bridge_transfer NSString*) ABRecordCopyValue((__bridge ABRecordRef)aPerson, kABPersonLastNameProperty);
        
        [aMember setObject:[NSString stringWithFormat:@"%@ %@", firstName, lastName] forKey:kMemberNickname];
        [aMember setObject:[NSString stringWithFormat:@"%@", firstName] forKey:kMemberFirstName];
        [aMember setObject:[NSString stringWithFormat:@"%@", lastName] forKey:kMemberLastName];
        
        ABMultiValueRef phoneNumbers = ABRecordCopyValue((__bridge ABRecordRef)aPerson, kABPersonPhoneProperty);
        for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++) {
            NSString* phoneNumber = (__bridge_transfer NSString*) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
            if (phoneNumber.length > 0) {
                [aMember setObject:phoneNumber forKey:kMemberPhone];
                break;
            }
        }
        
        CFRelease(phoneNumbers);
        
        [members addObject:aMember];
    }
    
    NSSortDescriptor *firstNameDescriptor = [[NSSortDescriptor alloc] initWithKey:kMemberFirstName ascending:YES];
    NSArray  *sortedArray = [members sortedArrayUsingDescriptors:[NSArray arrayWithObject:firstNameDescriptor]];
    
    return sortedArray;
}

@end
