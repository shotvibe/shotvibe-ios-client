//
//  NetworkLogViewController.m
//  shotvibe
//
//  Created by raptor on 3/1/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import "ShotVibeAppDelegate.h"
#import "SL/NetworkStatusManager.h"
#import "SL/ArrayList.h"
#import "SL/APIException.h"
#import "java/lang/Integer.h"

#import "NetworkLogViewController.h"

@interface NetworkErrorDialogDelegate : NSObject <UIAlertViewDelegate>

- (id)initWithParentViewController:(UIViewController *)parentViewController;
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

@end

@implementation NetworkErrorDialogDelegate
{
    UIViewController *parentViewController_;

    // A hack to prevent ARC from releasing the delegate
    id selfLoop_;
}

- (id)initWithParentViewController:(UIViewController *)parentViewController
{
    self = [super init];

    if (self) {
        parentViewController_ = parentViewController;
        selfLoop_ = self;
    }

    return self;
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSInteger cancelButton = 0;

    if (buttonIndex != cancelButton) {
        NSLog(@"FOOOO");
        NetworkLogViewController *networkLogViewController = [[NetworkLogViewController alloc] initWithStyle:UITableViewStylePlain];

        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:networkLogViewController];
        [parentViewController_ presentViewController:navigationController animated:YES completion:NULL];
    }

    // Break the cycle so that ARC will release the delegate
    selfLoop_ = nil;
}


@end

@interface NetworkLogViewController ()
{
    NSArray *log_;
}

@end

@implementation NetworkLogViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}


+ (void)showNetworkErrorDialog:(UIViewController *)parentViewController
{
    ShotVibeAppDelegate *app = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];

    SLArrayList *log = [app.networkStatusManager getNetworkRequestsLog];
    SLNetworkStatusManager_LogEntry *entry = [[log array] lastObject];

    NSString *message = @"";
    if (![entry isSuccessfulRequest]) {
        message = [[entry getError] getUserFriendlyMessage];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Internet Connection Error"
                                                    message:message
                                                   delegate:[[NetworkErrorDialogDelegate alloc] initWithParentViewController:parentViewController]
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:@"Technical Info", nil];
    [alert show];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Network Log";

    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneButtonTapped:)];

    self.navigationItem.leftBarButtonItem = doneButton;

    ShotVibeAppDelegate *app = (ShotVibeAppDelegate *)[[UIApplication sharedApplication] delegate];

    log_ = [[app.networkStatusManager getNetworkRequestsLog] array];

    // TODO Somehow scroll to the bottom
}


- (void)doneButtonTapped:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // No grouping, only a single section
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Each log entry is a row
    return log_.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];

    // Configure the cell...
    SLNetworkStatusManager_LogEntry *entry = [log_ objectAtIndex:indexPath.row];
    if ([entry isSuccessfulRequest]) {
        cell.textLabel.text = [NSString stringWithFormat:@"%d %@ %@",
                               [entry getStatusCode],
                               [entry getHttpMethod],
                               [entry getUrl]];
    } else {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ %@ %@",
                               [[entry getError] getHttpStatusCode].description,
                               [[entry getError] getHttpMethod],
                               [[entry getError] getUrl]];
        cell.textLabel.textColor = [UIColor redColor];
    }

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SLNetworkStatusManager_LogEntry *entry = [log_ objectAtIndex:indexPath.row];

    NSString *message;
    if ([entry isSuccessfulRequest]) {
        message = [NSString stringWithFormat:@"%d %@ %@",
                   [entry getStatusCode],
                   [entry getHttpMethod],
                   [entry getUrl]];
    } else {
        message = [[entry getError] getTechnicalMessage];
    }
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Network Log"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}


@end
