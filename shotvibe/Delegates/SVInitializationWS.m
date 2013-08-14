//
//  SVInitializationWS.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import "Album.h"
#import "SVInitializationWS.h"
#import "SVDefines.h"
//#import "SVDownloadSyncEngine.h"
#import "MagicalRecordShorthand.h"
#import "MagicalRecord+Setup.h"

#ifdef CONFIGURATION_Debug
static NSString * const kTestAuthToken = @"Token 8d437481bdf626a9e9cd6fa2236d113eb1c9786d";
#elif CONFIGURATION_Adhoc
static NSString * const kTestAuthToken = @"Token 1d591bfa90ed6aee747a5009ccf6ef27246f6ae6";
#endif

@interface SVInitializationWS ()


@end

@implementation SVInitializationWS

#pragma mark - Instance Methods

- (void)initializeVendorLibraries
{
    
}


- (void)configureAppearanceProxies
{
    // Customize appearance of the navigation bar    
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeFont, nil]];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setTitleVerticalPositionAdjustment:0.0 forBarMetrics:UIBarMetricsLandscapePhone];
    
    {
        UIImage *baseImage = [UIImage imageNamed:@"navBarBg.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UINavigationBar appearance] setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
    }
    
    // Customize back barbuttonitem for nav bar
    /*[[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:3.0 forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsLandscapePhone];*/
    {
        UIImage *baseImage = [UIImage imageNamed:@"navbarBackButton.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 5);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
            
            // Why on earth is the position different depending on version?
        }
        else
        {
            resizableImage = [baseImage stretchableImageWithLeftCapWidth:0 topCapHeight:5];
            
            // iOS5 back buttons are messed up :/
        }
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
		
		[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(-10,0) forBarMetrics:UIBarMetricsDefault];
    }
	
    // Customize regular barbuttonitem for navbar
    [[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],
														  UITextAttributeTextColor,
														  [UIColor clearColor],
														  UITextAttributeTextShadowColor,
														  [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0],
														  UITextAttributeFont, nil]
												forState:UIControlStateNormal];
    //[[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:3.0 forBarMetrics:UIBarMetricsDefault];
    //[[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsLandscapePhone];
    //[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
    //[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(5,0) forBarMetrics:UIBarMetricsLandscapePhone];
    {
        UIImage *baseImage = [UIImage imageNamed:@"butTransparent.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 10, 10);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UIBarButtonItem appearance] setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    }
    
    {
        UIImage *baseImage = [UIImage imageNamed:@"butTransparent.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(15, 10, 15, 10);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UIBarButtonItem appearance] setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    }
    
    
    // Customize UIToolbar
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"pictureDetailToolbarBg.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBackgroundImage:[UIImage imageNamed:@"pictureDetailToolbarBg.png"] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    
    // Customize UISearchBar
    {
        UIImage *baseImage = [UIImage imageNamed:@"searchBarBg.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        
        UIImage *resizableImage = nil;
        if (IS_IOS6_OR_GREATER) {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        else
        {
            resizableImage = [baseImage resizableImageWithCapInsets:insets];
        }
        
        [[UISearchBar appearance] setBackgroundImage:resizableImage];
    }
    
    
    
    //Customize Segment Control
    {
        UIImage *baseImage = [UIImage imageNamed:@"SegmentButtonOutline.png"];
        UIImage *selectedImage = [UIImage imageNamed:@"SegmentButton.png"];
        UIImage *dividerImage = [UIImage imageNamed:@"SegmentSeparator.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 10, 10);
        UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        UIImage *resizableSelectedImage = [selectedImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        
        [[UISegmentedControl appearance] setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UISegmentedControl appearance] setBackgroundImage:resizableSelectedImage forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
        [[UISegmentedControl appearance] setDividerImage:dividerImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
		[[UISegmentedControl appearance] setDividerImage:dividerImage forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
		[[UISegmentedControl appearance] setDividerImage:dividerImage forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
		
		[[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],
															  UITextAttributeTextColor,
															  [UIColor clearColor],
															  UITextAttributeTextShadowColor,
															  [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0],
															  UITextAttributeFont, nil]
													   forState:UIControlStateNormal];
		[[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:0.15 green:0.4 blue:0.6 alpha:1],
																 UITextAttributeTextColor,
																 [UIColor clearColor],
																 UITextAttributeTextShadowColor,
																 [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0],
																 UITextAttributeFont, nil]
													   forState:UIControlStateSelected];
    }
    
    
    
}


- (void)processAnalytics
{
    
}


- (void)initializeLocalSettingsDefaults
{
    // Setup defaults for general notification settings (not for individual albums)
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"HAS_SET_NOTIFICATION_DEFAULTS"]) {
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_NOTIFICATION"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_VIBRATION"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_SOUND"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"GENERAL_PREVIEW_MODE"];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"HAS_SET_NOTIFICATION_DEFAULTS"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (void)initializeManagedObjectModel
{
	NSLog(@"================== initializeManagedObjectModel ===================");
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"ShotVibe.sqlite"];
}


- (void)startSyncing
{
    /*// start bg sync for albums
    [[DownloadSyncEngine sharedEngine] startSync];
    
    // start upload syncing
    [[UploadSyncEngine sharedEngine] startSync];*/
    
    /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [[SVDownloadSyncEngine sharedEngine] startSync];
        
    });*/
}


#pragma mark - Private Methods
@end
