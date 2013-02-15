//
//  SVInitializationWS.h
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import <Foundation/Foundation.h>

@interface SVInitializationWS : NSObject

#pragma mark - Instance Methods

- (void)initializeVendorLibraries;
- (void)configureAppearanceProxies;
- (void)processAnalytics;
- (void)initializeLocalSettingsDefaults;
- (void)initializeManagedObjectModel;
@end
