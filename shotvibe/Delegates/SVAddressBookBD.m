//
//  SVAddressBookBD.m
//  shotvibe
//
//  Created by John Gabelmann on 7/8/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAddressBookBD.h"
#import "SVAddressBookWS.h"

@implementation SVAddressBookBD

+ (void)searchContactsWithString:(NSString *)string WithCompletion:(void (^)(NSArray *albums, NSError *error))block
{
    SVAddressBookWS *workerSession = [[SVAddressBookWS alloc] init];
    
    if (!string) {
        string = @"";
    }
    
    [workerSession searchContactsWithString:string WithCompletion:^(NSArray *albums, NSError *error) {
        block(albums, error);
    }];
}


@end
