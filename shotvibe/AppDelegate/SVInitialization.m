//
//  SVInitializationWS.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import "SL/AlbumSummary.h"
#import "SVInitialization.h"
#import "SVDefines.h"


@implementation SVInitialization


- (void)configureAppearanceProxies {
	
    if (IS_IOS7) {
		
		//[[UINavigationBar appearance] setBarTintColor:BLUE];
		//[[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, nil]];
	}
	else {
        UIImage *baseImage = [UIImage imageNamed:@"navBarBg.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 0, 20);
        UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
        
        [[UINavigationBar appearance] setBackgroundImage:resizableImage forBarMetrics:UIBarMetricsDefault];
		[[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor], UITextAttributeTextColor, [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], UITextAttributeFont, nil]];
	}
    
    // Customize back barbuttonitem for nav bar
    /*[[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:3.0 forBarMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsLandscapePhone];*/
    if (IS_IOS7) {
		
		//[[UIBarButtonItem appearance] setTintColor:[UIColor whiteColor]];
	}
	else {
        UIImage *baseImage = [UIImage imageNamed:@"navbarBackButton.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(5, 20, 5, 5);
        UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets resizingMode:UIImageResizingModeStretch];
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
		
		[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(-10,0) forBarMetrics:UIBarMetricsDefault];
		
		// Customize regular barbuttonitem for navbar
		[[UIBarButtonItem appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],
															  UITextAttributeTextColor,
															  [UIColor clearColor],
															  UITextAttributeTextShadowColor,
															  [UIFont fontWithName:@"HelveticaNeue-Light" size:15.0],
															  UITextAttributeFont, nil]
													forState:UIControlStateNormal];
    }
	
    //[[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:3.0 forBarMetrics:UIBarMetricsDefault];
    //[[UIBarButtonItem appearance] setBackgroundVerticalPositionAdjustment:1.0 forBarMetrics:UIBarMetricsLandscapePhone];
    //[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(15,0) forBarMetrics:UIBarMetricsDefault];
    //[[UIBarButtonItem appearance] setTitlePositionAdjustment:UIOffsetMake(5,0) forBarMetrics:UIBarMetricsLandscapePhone];
    if (!IS_IOS7) {
        UIImage *baseImage = [UIImage imageNamed:@"butTransparent.png"];
        UIEdgeInsets insets = UIEdgeInsetsMake(10, 10, 10, 10);
        UIImage *resizableImage = [baseImage resizableImageWithCapInsets:insets];
        
        [[UIBarButtonItem appearance] setBackgroundImage:resizableImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
		
		
        UIEdgeInsets insetsL = UIEdgeInsetsMake(15, 10, 15, 10);
        UIImage *resizableImageL = [baseImage resizableImageWithCapInsets:insetsL resizingMode:UIImageResizingModeStretch];
        
        [[UIBarButtonItem appearance] setBackgroundImage:resizableImageL forState:UIControlStateNormal barMetrics:UIBarMetricsLandscapePhone];
    }
    
    
    // Customize UIToolbar
	{
		[[UIToolbar appearance] setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.7]];
		[[UIToolbar appearance] setBackgroundImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
		//[[UIToolbar appearance] setBackgroundImage:resizableImage forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
	}
    
	
    // Customize UISearchBar
    if (!IS_IOS7) {
		UIImage *search_bg = [UIImage imageNamed:@"searchFieldBg.png"];
		UIImage *resizable_bg = [search_bg resizableImageWithCapInsets:UIEdgeInsetsMake(5, 20, 5, 20) resizingMode:UIImageResizingModeStretch];
		
		[[UISearchBar appearance] setBackgroundImage:[UIImage imageNamed:@"SearchBg.png"]];
		[[UISearchBar appearance] setSearchFieldBackgroundImage:resizable_bg forState:UIControlStateNormal];
		[[UISearchBar appearance] setImage:[UIImage imageNamed:@"searchFieldIcon.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
    }
    
    
    
    //Customize Segment Control
    if (IS_IOS7) {
		
		[[UISegmentedControl appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName:BLUE} forState:UIControlStateSelected];
		[[UISegmentedControl appearance] setTintColor:[UIColor whiteColor]];
	}
	else {
		
		//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
		//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateSelected rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
		//	[self.segmentControl setDividerImage:[UIImage imageNamed:@"SegmentSeparator.png"] forLeftSegmentState:UIControlStateNormal rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
		
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
		
		[[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor grayColor],
															  UITextAttributeTextColor,
															  [UIColor clearColor],
															  UITextAttributeTextShadowColor,
															  [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0],
															  UITextAttributeFont, nil]
													   forState:UIControlStateNormal];
		
		[[UISegmentedControl appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:BLUE,
																 UITextAttributeTextColor,
																 [UIColor clearColor],
																 UITextAttributeTextShadowColor,
																 [UIFont fontWithName:@"HelveticaNeue-Light" size:12.0],
																 UITextAttributeFont, nil]
													   forState:UIControlStateSelected];
    }
    
    
	// UISlider
	
	UIImage *minImage = [[UIImage imageNamed:@"slider-track-fill.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6) resizingMode:UIImageResizingModeStretch];
    UIImage *maxImage = [[UIImage imageNamed:@"slider-track.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 6, 0, 6) resizingMode:UIImageResizingModeStretch];
    UIImage *thumbImage = [UIImage imageNamed:@"slider-cap.png"];
	
    [[UISlider appearance] setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateHighlighted];
    
	// Placeholder text color
	//[[UILabel appearanceWhenContainedIn:[UISearchBar class], nil] setTextColor:[UIColor darkGrayColor]];
	
    
}


- (void)initializeLocalSettingsDefaults {
	
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


@end
