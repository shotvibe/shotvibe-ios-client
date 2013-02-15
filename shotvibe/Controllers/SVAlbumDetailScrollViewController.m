//
//  SVAlbumDetailScrollViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 2/14/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAlbumDetailScrollViewController.h"
#import "SVDefines.h"
#import "Photo.h"
#import "Album.h"

@interface SVAlbumDetailScrollViewController ()
- (void)loadImages;
@end

@implementation SVAlbumDetailScrollViewController
{
    Album *selectedAlbum;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    selectedAlbum = self.selectedPhoto.album;
    
    self.photoAlbumView.dataSource = self;
    self.photoScrubberView.dataSource = self;
    [self loadImages];
    [self.photoScrubberView reloadData];
    [self.photoAlbumView reloadData];
    
    [self.photoAlbumView moveToPageAtIndex:[[selectedAlbum.photos allObjects] indexOfObject:self.selectedPhoto] animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark NIPhotoScrubberViewDataSource


- (NSInteger)numberOfPhotosInScrubberView:(NIPhotoScrubberView *)photoScrubberView {
    return [selectedAlbum.photos count];
}


- (UIImage *)photoScrubberView: (NIPhotoScrubberView *)photoScrubberView
              thumbnailAtIndex: (NSInteger)thumbnailIndex {
    NSString* photoIndexKey = [self cacheKeyForPhotoIndex:thumbnailIndex];
    
    UIImage* image = [self.highQualityImageCache objectWithName:photoIndexKey];
    if (nil == image) {
        Photo* photo = [[selectedAlbum.photos allObjects] objectAtIndex:thumbnailIndex];
        
        NSString* thumbnailSource = photo.photoUrl;
        [self requestImageFromSource: thumbnailSource
                           photoSize: NIPhotoScrollViewPhotoSizeOriginal
                          photoIndex: thumbnailIndex];
    }
    
    return image;
}


#pragma mark NIPhotoAlbumScrollViewDataSource


- (NSInteger)numberOfPagesInPagingScrollView:(NIPhotoAlbumScrollView *)photoScrollView {
    return [selectedAlbum.photos count];
}


- (UIImage *)photoAlbumScrollView: (NIPhotoAlbumScrollView *)photoAlbumScrollView
                     photoAtIndex: (NSInteger)photoIndex
                        photoSize: (NIPhotoScrollViewPhotoSize *)photoSize
                        isLoading: (BOOL *)isLoading
          originalPhotoDimensions: (CGSize *)originalPhotoDimensions {
    UIImage* image = nil;
    
    NSString* photoIndexKey = [self cacheKeyForPhotoIndex:photoIndex];
    
    Photo* photo = [[selectedAlbum.photos allObjects] objectAtIndex:photoIndex];
    
    
    image = [self.highQualityImageCache objectWithName:photoIndexKey];
    if (nil != image) {
        *photoSize = NIPhotoScrollViewPhotoSizeOriginal;
        
    } else {
        NSString* source = photo.photoUrl;
        [self requestImageFromSource: source
                           photoSize: NIPhotoScrollViewPhotoSizeOriginal
                          photoIndex: photoIndex];
        
        *isLoading = YES;
    }
    
    return image;
}


- (void)photoAlbumScrollView: (NIPhotoAlbumScrollView *)photoAlbumScrollView
     stopLoadingPhotoAtIndex: (NSInteger)photoIndex {
    // TODO: Figure out how to implement this with AFNetworking.
}


- (id<NIPagingScrollViewPage>)pagingScrollView:(NIPagingScrollView *)pagingScrollView pageViewForIndex:(NSInteger)pageIndex {
    return [self.photoAlbumView pagingScrollView:pagingScrollView pageViewForIndex:pageIndex];
}


#pragma mark - Private Methods

- (void)loadImages {
    for (NSInteger ix = 0; ix < [selectedAlbum.photos count]; ++ix) {
        Photo* photo = [[selectedAlbum.photos allObjects] objectAtIndex:ix];
        
        NSString* photoIndexKey = [self cacheKeyForPhotoIndex:ix];
        
        // Don't load the thumbnail if it's already in memory.
        if (![self.highQualityImageCache containsObjectWithName:photoIndexKey]) {
            NSString* source = photo.photoUrl;
            [self requestImageFromSource: source
                               photoSize: NIPhotoScrollViewPhotoSizeOriginal
                              photoIndex: ix];
        }
    }
}


@end
