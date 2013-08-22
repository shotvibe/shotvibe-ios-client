//
//  CaptureSelectImagesViewController.h
//  shotvibe
//
//  Created by John Gabelmann on 5/1/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "ALAssetsLibrary+helper.h"
#import "CaptureViewfinderController.h"
#import "SVSelectionGridCell.h"
#import "CameraRollSection.h"
#import "SVBusinessDelegate.h"

@class Album;

@interface CaptureSelectImagesViewController : UIViewController <CameraRollSectionDelegate> {
	
	NSMutableArray *sectionsKeys;
	NSMutableDictionary *sections;
	NSMutableArray *selectedPhotos;
	CLGeocoder *geocoder;
}

@property (nonatomic, strong) NSArray *takenPhotos;// Set only one of this options
@property (nonatomic, strong) NSArray *libraryPhotos;
@property (nonatomic, strong) Album *selectedAlbum;
@property (nonatomic, strong) ALAssetsGroup *selectedGroup;

@property (nonatomic) id <CaptureViewfinderDelegate> delegate;

@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;

- (void)doneButtonPressed;

@end
