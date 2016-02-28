//
//  SVInitializationWS.h
//  ShotVibe
//
//  Created by Fredrick Gabelmann on 1/23/13.
//

#import <Foundation/Foundation.h>
#import "SVActivityViewController.h"

@interface SVInitialization : NSObject

#pragma mark - Instance Methods

+ (UIImage *)imageWithColor:(UIColor *)color;

- (void)configureAppearanceProxies;
- (void)initializeLocalSettingsDefaults;

@end
