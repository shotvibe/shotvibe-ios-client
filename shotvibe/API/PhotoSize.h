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

+ (PhotoSize *)FeedSize;

+ (NSArray *)iteratePhotoSizes:(PhotoSize *)maxSize;

+ (NSArray *)allPhotoSizes;

- (id) initWithExtension:(NSString *)extension width:(int)width height:(int)height;

- (BOOL)isWorseThan:(PhotoSize *)other;

@end
