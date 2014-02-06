//
//  Util.h
//  shotvibe
//
//  Created by martijn on 13-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Util : NSObject

NSString * showBool(BOOL b);

// For example for showing the result of NSURLConnection requests
NSString * showNSData(NSData *d);

// Return a shortened photoId string, e.g. "d2f4..35f1"
NSString * showShortPhotoId(NSString *idStr);

@end
