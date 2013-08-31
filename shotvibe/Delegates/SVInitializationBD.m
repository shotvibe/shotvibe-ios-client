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
    
    [worker configureAppearanceProxies];
    [worker initializeLocalSettingsDefaults];
}
@end
