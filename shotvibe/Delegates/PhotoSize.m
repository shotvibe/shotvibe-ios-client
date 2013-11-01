//
//  PhotoSize.m
//  shotvibe
//
//  Created by benny on 9/3/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "PhotoSize.h"

@implementation PhotoSize

- (id) initWithExtension:(NSString *)extension width:(int)width height:(int)height
{
    self = [super init];

    if (self) {
        _extension = extension;
        _width = width;
        _height = height;
    }

    return self;
}

- (NSString *)getFullExtension
{
    return [[@"_" stringByAppendingString:self.extension] stringByAppendingString:@".jpg"];
}

static PhotoSize *Thumb75;

// Array of `PhotoSize` objects
static NSArray *Values;

+ (void)initialize
{
    Thumb75 = [[PhotoSize alloc] initWithExtension:@"thumb75" width:75 height:75];

    /*
     * Ordered from best quality to worst
     */
    Values = [[NSArray alloc] initWithObjects:
              [[PhotoSize alloc] initWithExtension:@"r_wqxga" width:2560 height:1600],
              [[PhotoSize alloc] initWithExtension:@"r_qxga"  width:2048 height:1536],
              [[PhotoSize alloc] initWithExtension:@"r_fhd"   width:1920 height:1080],
              [[PhotoSize alloc] initWithExtension:@"r_wxga"  width:1280 height:800],
              [[PhotoSize alloc] initWithExtension:@"r_xga"   width:1024 height:768],
              [[PhotoSize alloc] initWithExtension:@"r_hd"    width:1280 height:720],
              [[PhotoSize alloc] initWithExtension:@"r_dvgax" width:1136 height:640],
              [[PhotoSize alloc] initWithExtension:@"r_dvga"  width:960  height:640],
              [[PhotoSize alloc] initWithExtension:@"r_qhd"   width:960  height:540],
              [[PhotoSize alloc] initWithExtension:@"r_wvga"  width:800  height:480],
              [[PhotoSize alloc] initWithExtension:@"r_vga"   width:640  height:480],
              [[PhotoSize alloc] initWithExtension:@"r_hvga"  width:480  height:320],
              [[PhotoSize alloc] initWithExtension:@"r_qvga"  width:320  height:240],
              Thumb75
              , nil];
}

+ (PhotoSize *)Thumb75
{
    return Thumb75;
}

+ (NSArray *)iteratePhotoSizes:(PhotoSize *)maxSize
{
    NSRange range;
    range.location = [Values indexOfObjectIdenticalTo:maxSize];
    range.length = Values.count - range.location;

    return [Values subarrayWithRange:range];
}

+ (NSArray *)allPhotoSizes
{
    return Values;
}

- (BOOL)isWorseThan:(PhotoSize *)other
{
    for (PhotoSize *p in [PhotoSize iteratePhotoSizes:self]) {
        if (p == other) {
            return NO;
        }
    }

    return YES;
}

@end
