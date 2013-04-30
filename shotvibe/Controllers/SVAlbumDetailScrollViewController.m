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
#import "Member.h"
#import "SVBusinessDelegate.h"

@interface SVAlbumDetailScrollViewController ()

@property (nonatomic, strong) UILabel *detailLabel;

- (void)loadImages;
- (void)deleteButtonPressed;
- (void)exportButtonPressed;
- (void)toggleMenu;
- (void)configureDetailText;
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
    
    UIActionSheet *exportOptions = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", @"") destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Move Picture", @""), NSLocalizedString(@"Share to Facebook", @""), NSLocalizedString(@"Share to Instagram", @""), NSLocalizedString(@"Set as Profile Picture", @""), NSLocalizedString(@"Email photo", @""), NSLocalizedString(@"Get Link", @""), nil];
    
    [exportOptions showFromToolbar:self.toolbar];
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
    
    
    // Setup detail label
    self.detailLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, -57, self.view.frame.size.width, 57)];
    self.detailLabel.backgroundColor = [UIColor clearColor];
    self.detailLabel.textColor = [UIColor colorWithRed:0.92 green:0.92 blue:0.92 alpha:1.0];
    self.detailLabel.numberOfLines = 2;
    if (IS_IOS6_OR_GREATER) {
        self.detailLabel.textAlignment = NSTextAlignmentCenter;
    }
    else
    {
        self.detailLabel.textAlignment = UITextAlignmentCenter;
    }
    self.detailLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:16];
    self.detailLabel.shadowColor = [UIColor blackColor];
    self.detailLabel.shadowOffset = CGSizeMake(0, 1);
    self.detailLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    [self.toolbar addSubview:self.detailLabel];
    
    selectedAlbum = self.selectedPhoto.album;
    
    self.photoAlbumView.dataSource = self;
    self.photoScrubberView.dataSource = self;
    [self loadImages];
    [self.photoScrubberView reloadData];
    [self.photoAlbumView reloadData];
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    [self.photoAlbumView moveToPageAtIndex:[[[selectedAlbum.photos allObjects] sortedArrayUsingDescriptors:@[descriptor]] indexOfObject:self.selectedPhoto] animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
    // Kill any drag processes here and now
    [self.navigationController.sideMenu setMenuState:MFSideMenuStateClosed];
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
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
        Photo* photo = [[[selectedAlbum.photos allObjects] sortedArrayUsingDescriptors:@[descriptor]] objectAtIndex:thumbnailIndex];
        
        NSString* thumbnailSource = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoThumbExtension];
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
    
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    Photo* photo = [[[selectedAlbum.photos allObjects] sortedArrayUsingDescriptors:@[descriptor]] objectAtIndex:photoIndex];
    
    
    image = [self.highQualityImageCache objectWithName:photoIndexKey];
    
    if (!image) {
        image = [SVBusinessDelegate loadImageFromAlbum:selectedAlbum withPath:photo.photoId];
    }
    if (nil != image) {
        *photoSize = NIPhotoScrollViewPhotoSizeOriginal;
        
    } else {
        
        NSString *photoURL = nil;
        
        if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)] && [[UIScreen mainScreen] scale] == 2){
            if (IS_IPHONE_5) {
                photoURL = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone5Extension];
            }
            else
            {
                photoURL = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone4Extension];
            }
        }
        else
        {
            photoURL = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoIphone3Extension];
        }
        
        [self requestImageFromSource: photoURL
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


#pragma mark - UIActionSheet Delegate Methods

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    // TODO: Handle what selection the user made
}


#pragma mark - Private Methods

- (void)loadImages {
    for (NSInteger ix = 0; ix < [selectedAlbum.photos count]; ++ix) {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
        Photo* photo = [[[selectedAlbum.photos allObjects] sortedArrayUsingDescriptors:@[descriptor]] objectAtIndex:ix];
        
        NSString* photoIndexKey = [self cacheKeyForPhotoIndex:ix];
        
        // Don't load the thumbnail if it's already in memory.
        if (![self.highQualityImageCache containsObjectWithName:photoIndexKey]) {
            NSString* source = [[photo.photoUrl stringByDeletingPathExtension] stringByAppendingString:kPhotoThumbExtension];
            [self requestImageFromSource: source
                               photoSize: NIPhotoScrollViewPhotoSizeThumbnail
                              photoIndex: ix];
        }
    }
}


- (void)configureDetailText
{
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"dateCreated" ascending:NO];
    Photo *photo = [[[selectedAlbum.photos allObjects] sortedArrayUsingDescriptors:@[descriptor]] objectAtIndex:self.photoAlbumView.centerPageIndex];
    
    NSString *updatedBy = NSLocalizedString(@"Updated by ", @"");
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"MM.dd, HH:mm\"";
    
    self.detailLabel.text = [NSString stringWithFormat:@"%@%@\n%@", updatedBy, photo.author.nickname, [NSDateFormatter localizedStringFromDate:photo.dateCreated dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]];
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

- (void)refreshChromeState {
    
    [self setChromeTitle];
    [self configureDetailText];
}


- (void)setChromeTitle {
    /*self.title = [NSString stringWithFormat:@"%d of %d",
                  (self.photoAlbumView.centerPageIndex + 1),
                  self.photoAlbumView.numberOfPages];*/
    
    self.title = selectedAlbum.name;
}


@end
