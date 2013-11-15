//
//  SVRecord.m
//  shotvibe
//
//  Created by Baluta Cristian on 06/11/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVRecord.h"

@implementation SVRecord

- (void)setPhone:(NSString *)phone {
	
	_phone = phone;
	
	NSString *phoneNr = [phone stringByReplacingOccurrencesOfString:@"+" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@"-" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@"(" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@")" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	_phoneId = [phoneNr longLongValue];
}

@end
