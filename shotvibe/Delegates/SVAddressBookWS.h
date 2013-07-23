//
//  SVAddressBookWS.h
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVAddressBookWS : NSObject

- (void)searchContactsWithString:(NSString *)string WithCompletion:(void (^)(NSArray *albums, NSError *error))block;

@end
