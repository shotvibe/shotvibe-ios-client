//
//  RCImageView.h
//  IMAGIN
//
//  Created by Baluta Cristian on 4/7/10.
//  Copyright 2010 ralcr. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CFNetwork/CFNetwork.h>


@interface RCImageView : UIImageView {
	id delegate;
	int i;
	NSString *referer;
	NSURLConnection *connection;
	NSMutableData *imageData; // Received data in steps
	
	long long totalBytesExpected;
	long long totalBytesLoaded;
}

@property(nonatomic, copy) NSString *referer;
@property(nonatomic, retain) NSMutableData *imageData;
@property(nonatomic) int i;
@property(nonatomic) BOOL autosize;

- (id)initWithFrame:(CGRect)frame delegate:(id)d;
- (void)loadNetworkImage:(NSString *)path;
- (void)cancel;

@end


@protocol RCImageViewDelegate <NSObject>
@optional
- (void)onPhotoProgress:(NSNumber*)percent nr:(NSNumber*)index;
- (void)onPhotoComplete:(NSNumber*)index;
- (void)onPhotoError:(NSNumber*)index;

@end