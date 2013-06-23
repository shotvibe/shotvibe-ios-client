//
//  SVInitializationBD.m
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import "SVInitializationBD.h"
#import "SVInitializationWS.h"

@implementation SVInitializationBD

#pragma mark - Class Methods

+ (void)initialize
{
    SVInitializationWS *worker = [[SVInitializationWS alloc] init];
    
    [worker initializeVendorLibraries];
    [worker configureAppearanceProxies];
    [worker processAnalytics];
    [worker initializeLocalSettingsDefaults];
    [worker initializeManagedObjectModel];
    [worker startSyncing];
}
@end
