//
//  ALAssetsLibrary+helper.m
//  AssetDatabase
//
//  Created by Glenn Wolters on 11/28/11.
//  Copyright (c) 2011 OMGWTFBBQ. All rights reserved.
//

#import "ALAssetsLibrary+helper.h"

@implementation ALAssetsLibrary (helper)

+(ALAssetsLibrary *)sharedLibrary {
	static dispatch_once_t onceToken;
	static ALAssetsLibrary *shared = nil;
	dispatch_once(&onceToken, ^{
		shared = [[ALAssetsLibrary alloc] init];
	});	
	return shared;
}

@end
