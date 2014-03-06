//
//  Util.h
//  shotvibe
//
//  Created by Oblosys on 13-01-14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


// safe float comparison
#define fequal(a, b) (fabs((a) - (b)) < FLT_EPSILON)

#define square(a) ((a) * (a))

@interface Util : NSObject

+ (float)screenHeight;

+ (float)screenWidth;

NSString * showBool(BOOL b);

NSString * showPoint(CGPoint point);

NSString * showSize(CGSize size);

NSString * showRect(CGRect rect);

// For example for showing the result of NSURLConnection requests
NSString * showNSData(NSData *d);

// Return a shortened photoId string, e.g. "d2f4..35f1"
NSString * showShortPhotoId(NSString *idStr);

@end
