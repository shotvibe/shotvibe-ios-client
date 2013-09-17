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
#import "SVCameraPickerDelegate.h"
#import "SVSelectionGridCell.h"
#import "CameraRollSection.h"
#import "SVImageCropViewController.h"
#import "AlbumManager.h"
#import "AlbumSummary.h"

@interface SVImagePickerSelector : UIViewController <CameraRollSectionDelegate, SVImageCropDelegate> {
	
	NSMutableArray *sectionsKeys;
	NSMutableDictionary *sections;
	NSMutableArray *selectedPhotos;
	CLGeocoder *geocoder;
}

@property (nonatomic, assign) int64_t albumId;
@property (nonatomic, strong) AlbumManager *albumManager;
@property (nonatomic) id <SVCameraPickerDelegate> delegate;
@property (nonatomic) id cropDelegate;
@property (nonatomic) BOOL oneImagePicker;

@property (nonatomic, strong) NSArray *takenPhotos;// Set only one of this options
@property (nonatomic, strong) NSArray *libraryPhotos;
@property (nonatomic, strong) AlbumSummary *selectedAlbum;
@property (nonatomic, strong) ALAssetsGroup *selectedGroup;

@property (nonatomic, strong) IBOutlet UIView *gridviewContainer;
@property (nonatomic, strong) IBOutlet UICollectionView *gridView;

- (void)doneButtonPressed;

@end
