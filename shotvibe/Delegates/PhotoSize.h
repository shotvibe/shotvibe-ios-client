//
//  PhotoSize.h
//  shotvibe
//
//  Created by benny on 9/3/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PhotoSize : NSObject

@property (nonatomic, copy, readonly) NSString *extension;
@property (nonatomic, assign, readonly) int width;
@property (nonatomic, assign, readonly) int height;

- (NSString *)getFullExtension;

+ (PhotoSize *)Thumb75;

+ (NSArray *)iteratePhotoSizes:(PhotoSize *)maxSize;

+ (NSArray *)allPhotoSizes;

- (BOOL)isWorseThan:(PhotoSize *)other;

@end
