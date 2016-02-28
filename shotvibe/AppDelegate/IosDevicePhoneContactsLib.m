//
//  IosDevicePhoneContactsLib.m
//  shotvibe
//
//  Created by benny on 1/26/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "SL/ArrayList.h"
#import "SL/PhoneContact.h"

#import "IosDevicePhoneContactsLib.h"

@implementation IosDevicePhoneContactsLib
{
    ABAddressBookRef addressBook_;
    NSMutableArray *listeners_;
}

- (id)init
{
    self = [super init];

    if (self) {
        [self tryCreateAddressBook];
        listeners_ = [[NSMutableArray alloc] init];
    }

    return self;
}


- (void)tryCreateAddressBook
{
    CFErrorRef error;
    addressBook_ = ABAddressBookCreateWithOptions(NULL, &error);
    NSLog(@"%@",error);
    
//    ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
    
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
        ABAddressBookRequestAccessWithCompletion(addressBook_, ^(bool granted, CFErrorRef error) {
            if (granted) {
                // First time access has been granted, add the contact
//                [self _addContactToAddressBook];
                NSLog(@"1");
            } else {
                // User denied access
                // Display an alert telling user the contact could not be added
                NSLog(@"2");
            }
        });
    }
    else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
        // The user has previously given access, add the contact
//        [self _addContactToAddressBook];
        NSLog(@"3");
    }
    else {
        // The user has previously denied access
        // Send an alert telling user to change privacy setting in settings app
        NSLog(@"4");
    }
}


- (SLArrayList *)getDevicePhoneContacts
{
    NSLog(@"getDevicePhoneContacts");

    [[Mixpanel sharedInstance] track:@"zzz getDevicePhoneContacts start"];

    NSUInteger initialCapacity = 2048; // Should be enough for a lot of contacts
    NSMutableArray *results = [[NSMutableArray alloc] initWithCapacity:initialCapacity];

    // We need to create a new ABAddressBook each time to make sure to get the most up-to-date values
    CFErrorRef error;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, &error);

    if (!addressBook) {
        [[Mixpanel sharedInstance] track:@"zzz getDevicePhoneContacts addressBook failed"];
        // Probably a permission error
        return [[SLArrayList alloc] initWithInitialArray:results];
    }

    CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
    CFIndex numPeople = ABAddressBookGetPersonCount(addressBook);

    for (CFIndex i = 0; i < numPeople; ++i) {
        ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);

        NSString *firstName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
        NSString *lastName = (__bridge_transfer NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));

        if (!firstName) {
            firstName = @"";
        }
        if (!lastName) {
            lastName = @"";
        }

        ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);

        for (CFIndex j = 0; j < ABMultiValueGetCount(phoneNumbers); j++) {
            NSString *phoneNumber = (__bridge_transfer NSString *)ABMultiValueCopyValueAtIndex(phoneNumbers, j);
            if (phoneNumber) {
                if ([firstName length] == 0 && [lastName length] == 0) {
                    // For totally nameless contacts, use the phone number as the name
                    lastName = phoneNumber;
                }

                SLPhoneContact *phoneContact = [[SLPhoneContact alloc] initWithNSString:phoneNumber
                                                                           withNSString:lastName
                                                                           withNSString:firstName];
                [results addObject:phoneContact];
            }
        }

        CFRelease(phoneNumbers);
    }

    CFRelease(allPeople);

    CFRelease(addressBook);

    NSLog(@"done getDevicePhoneContacts");

    if ([results count] > 0) {
        [[Mixpanel sharedInstance] track:@"zzz getDevicePhoneContacts contacts returned"
                              properties:@{ @"num_contacts" : [NSString stringWithFormat:@"%d", [results count]] }];
    } else {
        [[Mixpanel sharedInstance] track:@"zzz getDevicePhoneContacts no contacts"];
    }

    return [[SLArrayList alloc] initWithInitialArray:results];
}


static void AddressBookChangeCallback(ABAddressBookRef ntificationaddressbook, CFDictionaryRef info, void *context)
{
    NSLog(@"address book changed");

    IosDevicePhoneContactsLib *lib = (__bridge IosDevicePhoneContactsLib *)(context);

    for (id <SLDevicePhoneContactsLib_DeviceAddressBookListener> listener in lib->listeners_) {
        NSLog(@"firing listener");
        [listener deviceAddressBookChanged];
    }
}


- (void)registerDeviceAddressBookListenerWithSLDevicePhoneContactsLib_DeviceAddressBookListener:(id<SLDevicePhoneContactsLib_DeviceAddressBookListener>)listener
{
    NSAssert(addressBook_, @"addressBook available");

    [listeners_ addObject:listener];

    if (listeners_.count == 1) {
        ABAddressBookRegisterExternalChangeCallback(addressBook_, AddressBookChangeCallback, (__bridge void *)(self));
    }
}


- (void)unregisterDeviceAddressBookListenerWithSLDevicePhoneContactsLib_DeviceAddressBookListener:(id<SLDevicePhoneContactsLib_DeviceAddressBookListener>)listener
{
    [listeners_ removeObject:listener];

    if (listeners_.count == 0) {
        ABAddressBookUnregisterExternalChangeCallback(addressBook_, AddressBookChangeCallback, (__bridge void *)(self));
    }
}


@end
