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
	
    NSString *phoneNr = [[phone componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
	
    // Get only the last 7 digits and store them in phoneId. This unique id is used to mark the contact as a favourite
	NSString *lastDigits = phoneNr.length > 0 ? [phoneNr substringFromIndex:MAX((int)phoneNr.length-7, 0)] : phoneNr;
	
	_phoneId = [lastDigits longLongValue];
	
	if (_phoneId < 1) {
		self.invalid = YES;
	}
}

@end
