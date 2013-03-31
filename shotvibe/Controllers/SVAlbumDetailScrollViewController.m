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
#import "UINavigationController+MFSideMenu.h"
#import "MFSideMenu.h"

@interface SVAlbumDetailScrollViewController ()
- (void)loadImages;
- (void)deleteButtonPressed;
- (void)exportButtonPressed;
- (void)toggleMenu;
@end

@implementation SVAlbumDetailScrollViewController
{
    Album *selectedAlbum;
}

#pragma mark - Actions

- (void)deleteButtonPressed
{
    // Do stuff
}


- (void)exportButtonPressed
{
    // Do other stuff
}


- (void)toggleMenu
{
    [self.navigationController.sideMenu toggleRightSideMenu];
}


#pragma mark - Initializers

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    // Setup menu button
    UIBarButtonItem *menuButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"userIcon.png"] style:UIBarButtonItemStyleBordered target:self action:@selector(toggleMenu)];
    self.navigationItem.rightBarButtonItem = menuButton;
    
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


- (void)updateToolbarItems {
    UIBarItem* flexibleSpace =
    [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace
                                                  target: nil
                                                  action: nil];
    
    if (nil == self.nextButton) {
        UIImage* nextIcon = [UIImage imageNamed:@"exportIcon.png"];
        
        // We weren't able to find the next or previous icons in your application's resources.
        // Ensure that you've dragged the NimbusPhotos.bundle from src/photos/resources into your
        // application with the "Create Folder References" option selected. You can verify that
        // you've done this correctly by expanding the NimbusPhotos.bundle file in your project
        // and verifying that the 'gfx' directory is blue. Also verify that the bundle is being
        // copied in the Copy Bundle Resources phase.
        NIDASSERT(nil != nextIcon);
        
        self.nextButton = [[UIBarButtonItem alloc] initWithImage: nextIcon
                                                       style: UIBarButtonItemStylePlain
                                                      target: self
                                                      action: @selector(exportButtonPressed)];
        
    }
    
    if (nil == self.previousButton) {
        UIImage* previousIcon = [UIImage imageNamed:@"trashIcon.png"];
        
        // We weren't able to find the next or previous icons in your application's resources.
        // Ensure that you've dragged the NimbusPhotos.bundle from src/photos/resources into your
        // application with the "Create Folder References" option selected. You can verify that
        // you've done this correctly by expanding the NimbusPhotos.bundle file in your project
        // and verifying that the 'gfx' directory is blue. Also verify that the bundle is being
        // copied in the Copy Bundle Resources phase.
        NIDASSERT(nil != previousIcon);
        
        self.previousButton = [[UIBarButtonItem alloc] initWithImage: previousIcon
                                                           style: UIBarButtonItemStylePlain
                                                          target: self
                                                          action: @selector(deleteButtonPressed)];
    }
    
    self.toolbar.items = [NSArray arrayWithObjects:self.previousButton, flexibleSpace, self.nextButton, nil];
    
}


@end
