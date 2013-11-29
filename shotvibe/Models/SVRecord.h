//
//  SVRecord.h
//  shotvibe
//
//  Created by Baluta Cristian on 06/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SVRecord : NSObject

@property (nonatomic) int recordId;
@property (nonatomic) int64_t memberId;
@property (nonatomic) int64_t phoneId;// This is the phone number converted to an integer
@property (nonatomic, retain) NSString *fullname;
@property (nonatomic, retain) NSString *surname;
@property (nonatomic, retain) NSString *phone;
@property (nonatomic, retain) NSString *iconDefaultRemotePath;
@property (nonatomic, retain) NSString *iconRemotePath;
@property (nonatomic, retain) NSData *iconLocalData;
@property (nonatomic) BOOL invalid;

@end
