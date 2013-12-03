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
	
	NSString *phoneNr = [phone stringByTrimmingCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
	
	phoneNr = [phone stringByReplacingOccurrencesOfString:@"+" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@"-" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@"(" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@")" withString:@""];
	phoneNr = [phoneNr stringByReplacingOccurrencesOfString:@" " withString:@""];
//	RCLogS(phoneNr);
//	RCLogI(MAX((int)phoneNr.length-7, 0));
	
	NSString *lastDigits = phoneNr.length > 0 ? [phoneNr substringFromIndex:MAX((int)phoneNr.length-7, 0)] : phoneNr;
	
	_phoneId = [lastDigits longLongValue];
	
	if (_phoneId < 1) {
		self.invalid = YES;
	}
}

@end
