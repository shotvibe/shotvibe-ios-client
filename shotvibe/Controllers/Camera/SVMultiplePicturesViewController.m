//
//  SVMultiplePicturesViewController.m
//  shotvibe
//
//  Created by Salvatore Balzano on 27/01/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "SVMultiplePicturesViewController.h"
#import "SVAlbumCell.h"
#import "SL/AlbumSummary.h"
#import "SL/AlbumPhoto.h"
#import "SL/AlbumServerPhoto.h"
#import "SL/ArrayList.h"
#import "SL/DateTime.h"
#import "SL/APIException.h"
#import "SVDefines.h"
#import "SVAlbumGridViewController.h"
#import "MBProgressHUD.h"
#import "NSDate+Formatting.h"
#import "PhotoUploadRequest.h"

@interface SVMultiplePicturesViewController ()

@property (nonatomic) int64_t albumId;

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) IBOutlet UIView *createNewAlbumTitleView;
@property (nonatomic, strong) IBOutlet UITextField *albumField;
@property (nonatomic) BOOL shouldNotPostNotificationWhenClose;

- (IBAction)newAlbumClosed:(id)sender;
- (IBAction)newAlbumDone:(id)sender;

@end

@implementation SVMultiplePicturesViewController

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

    // Setup titleview
//    UIImageView *titleView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo.png"]];
//    UIView *titleContainer = [[UIView alloc] initWithFrame:titleView.frame];
//    [titleContainer addSubview:titleView];
//    titleContainer.backgroundColor = [UIColor clearColor];
//    titleView.frame = CGRectMake(0, -1, titleView.frame.size.width, titleView.frame.size.height);
//    self.navigationItem.titleView = titleContainer;
    self.title = @"Select an album";
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self hideDropDown:NO];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.albums count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier = (indexPath.row == 0) ? @"SVAlbumListTopCell" : @"SVAlbumListCell";
    SVAlbumListViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.delegate = self;
    cell.parentTableView = self.tableView;
    cell.scrollView.scrollEnabled = NO;

    if (indexPath.row == 0) {
        [cell.networkImageView setImage:[UIImage imageNamed:@"NewAlbum"]];
        cell.title.text = @"Create New Album";
        cell.title.font = [UIFont fontWithName:cell.title.font.fontName size:17];
        cell.title.textColor = [UIColor colorWithWhite:132.0 / 255 alpha:1];
        cell.title.frame = CGRectMake(cell.title.frame.origin.x, 0, cell.title.frame.size.width, cell.contentView.bounds.size.height - 4);
    } else {
        SLAlbumSummary *album = self.albums[indexPath.row - 1];

        if ([album getNumNewPhotos] > 0) {
            [cell.numberNotViewedIndicator setTitle:[album getNumNewPhotos] > 99 ? @"99+":[NSString stringWithFormat:@"%lld", [album getNumNewPhotos]] forState:UIControlStateNormal];
            cell.numberNotViewedIndicator.hidden = NO;
        } else {
            cell.numberNotViewedIndicator.hidden = YES;
        }

        long long seconds = [[album getDateUpdated] getTimeStamp] / 1000000LL;
        NSDate *dateUpdated = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
        NSString *distanceOfTimeInWords = [dateUpdated distanceOfTimeInWords];

        cell.tag = indexPath.row;
        cell.title.text = [album getName];
        cell.author.text = @"";
        cell.timestamp.hidden = YES;

        [cell.networkImageView setImage:nil];
        // TODO: latestPhotos might be nil if we insert an AlbumContents instead AlbumSummary
        if ([album getLatestPhotos].array.count > 0) {
            SLAlbumPhoto *latestPhoto = [[album getLatestPhotos].array objectAtIndex:0];
            if ([latestPhoto getServerPhoto]) {
                cell.author.text = [NSString stringWithFormat:@"Last added by %@", [[[latestPhoto getServerPhoto] getAuthor] getMemberNickname]];

                [cell.networkImageView setPhoto:[[latestPhoto getServerPhoto] getId] photoUrl:[[latestPhoto getServerPhoto] getUrl] photoSize:[PhotoSize Thumb75] manager:self.albumManager.photoFilesManager];
                [cell.timestamp setTitle:distanceOfTimeInWords forState:UIControlStateNormal];
                cell.timestamp.hidden = NO;
            }
        } else {
            [cell.networkImageView setImage:[UIImage imageNamed:@"placeholderImage"]];
            cell.author.text = [NSString stringWithFormat:@"Empty album"];
        }
    }
    return cell;
}


- (void)selectCell:(UITableViewCell *)cell
{
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self tableView:self.tableView didSelectRowAtIndexPath:indexPath];
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        [self showDropDown];
    } else {
        SLAlbumSummary *album = self.albums[indexPath.row - 1];
        self.albumId = [album getId];

        NSString *s = [NSString stringWithFormat:@"Are you sure you want to upload the photos to %@?", [album getName]];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:s delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"") otherButtonTitles:NSLocalizedString(@"Yes", @""), nil];
        [alert show];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    if (!self.shouldNotPostNotificationWhenClose) {
        //http://stackoverflow.com/questions/1214965/setting-action-for-back-button-in-navigation-controller
        if (([self.navigationController.viewControllers indexOfObject:self] == NSNotFound) || ([self.navigationController.viewControllers count] == 0)) {
            // back button was pressed.  We know this is true because self is no longer in the navigation stack.
            [[self.navigationController.viewControllers lastObject] view].hidden = YES;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"kSVPickAlbumCancel" object:nil];
        }
    }
    [super viewWillDisappear:animated];
}


- (void)uploadPhotos
{
    self.shouldNotPostNotificationWhenClose = YES;
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    if (controllers.count == 2) {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
        SVAlbumGridViewController *controller = (SVAlbumGridViewController *)[mainStoryboard instantiateViewControllerWithIdentifier:@"SVAlbumGridViewController"];
        controller.albumManager = self.albumManager;
        controller.albumId = self.albumId;
        controller.scrollToTop = YES;
        [controllers replaceObjectAtIndex:1 withObject:controller];
        [self.navigationController setViewControllers:controllers];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }

    RCLog(@"====================== 1. Upload selected photos to albumId %lli", self.albumId);

    // Upload the taken photos
    NSMutableArray *photoUploadRequests = [[NSMutableArray alloc] init];
    for (NSString *selectedPhotoPath in self.images) {
        PhotoUploadRequest *photoUploadRequest = [[PhotoUploadRequest alloc] initWithPath:selectedPhotoPath];
        [photoUploadRequests addObject:photoUploadRequest];
    }
    [self.albumManager.photoUploadManager uploadPhotos:self.albumId photoUploadRequests:photoUploadRequests];

    NSDictionary *userInfo = @{
        @"albumId" : [NSNumber numberWithLongLong:self.albumId]
    };
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATIONCENTER_ALBUM_CHANGED object:nil userInfo:userInfo];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [self uploadPhotos];
    }
}


- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    // TODO: Deselect item
}


- (IBAction)newAlbumClosed:(id)sender
{
    [self hideDropDown:YES];
}


- (IBAction)newAlbumDone:(id)sender
{
    NSString *name = self.albumField.text.length == 0 ? self.albumField.placeholder : self.albumField.text;
    [self createNewAlbumWithTitle:name];
}


- (void)createNewAlbumWithTitle:(NSString *)title
{
    RCLog(@"createNewAlbumWithTitle %@", title);
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];

    // Write the album to server
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        SLAlbumContents *albumContents = nil;
        SLAPIException *apiException = nil;
        @try {
            albumContents = [[self.albumManager getShotVibeAPI] createNewBlankAlbum:title];
        } @catch (SLAPIException *exception) {
            apiException = exception;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            if (apiException) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Creating Album"
                                                                message:apiException.description
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
            } else {
                self.albumId = [albumContents getId];
                [self.albumManager refreshAlbumList];

                [self.albumManager addAlbumListListener:self];
            }
        }


                       );
    }


                   );
}


- (void)onAlbumListBeginRefresh
{
}


- (void)onAlbumListRefreshComplete:(NSArray *)albums
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    [self hideDropDown:NO];
    [self uploadPhotos];

    [self.albumManager removeAlbumListListener:self];
}


- (void)onAlbumListRefreshError:(SLAPIException *)exception
{
    [MBProgressHUD hideHUDForView:self.view animated:YES];

    [self hideDropDown:NO];
    [self.albumManager removeAlbumListListener:self];
}


#pragma mark drop down stuffs

- (void)showDropDown
{
    NSString *currentDateString = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                                 dateStyle:NSDateFormatterLongStyle
                                                                 timeStyle:NSDateFormatterNoStyle];
    self.albumField.text = @"";
    self.albumField.placeholder = currentDateString;

    self.tableView.userInteractionEnabled = NO;

    CGRect frame = self.createNewAlbumTitleView.frame;
    frame.origin.y = self.tableView.frame.origin.y - frame.size.height;
    self.createNewAlbumTitleView.frame = frame;
    self.createNewAlbumTitleView.hidden = NO;

    [UIView animateWithDuration:0.3 animations:^{
        CGRect frame = self.createNewAlbumTitleView.frame;
        if (IS_IOS7) {
            frame.origin.y = self.tableView.frame.origin.y + self.navigationController.navigationBar.bounds.size.height;
        } else {
            frame.origin.y = self.tableView.frame.origin.y;
        }
        self.createNewAlbumTitleView.frame = frame;
    }


                     completion:^(BOOL finished) {
        [self.albumField becomeFirstResponder];
    }


    ];
}


- (void)hideDropDown:(BOOL)animated
{
    [self.albumField resignFirstResponder];

    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            CGRect frame = self.createNewAlbumTitleView.frame;
            frame.origin.y = self.tableView.frame.origin.y - frame.size.height;
            self.createNewAlbumTitleView.frame = frame;
        }


                         completion:^(BOOL finished) {
            self.tableView.userInteractionEnabled = YES;
        }


        ];
    } else {
        CGRect frame = self.createNewAlbumTitleView.frame;
        frame.origin.y = self.tableView.frame.origin.y - frame.size.height;
        self.createNewAlbumTitleView.frame = frame;
        self.tableView.userInteractionEnabled = YES;
    }
}


#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.albumField) {
        [self newAlbumDone:nil];
    }
    return YES;
}


@end
