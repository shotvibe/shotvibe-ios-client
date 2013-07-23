//
//  SVAddressBookBD.h
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVAddressBookBD : NSObject

// Passing nil or @"" as the string parameter will return all address book contacts ordered according to user preferences. This returns an array of dictionaries containing the potential members' names and phone number
+ (void)searchContactsWithString:(NSString *)string WithCompletion:(void (^)(NSArray *albums, NSError *error))block;


@end
