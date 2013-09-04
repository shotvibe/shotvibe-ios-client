
#import "SVTwitterActivity.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@implementation SVTwitterActivity


- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Twitter", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconTwitter.png"];
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	
}

- (void)performActivity
{
	if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
		
        [mySLComposerSheet setInitialText:self.sharingText];
        [mySLComposerSheet addImage:self.sharingImage];
        [mySLComposerSheet addURL:self.sharingUrl];
        [mySLComposerSheet setCompletionHandler:^(SLComposeViewControllerResult result) {
			
			switch (result) {
				case SLComposeViewControllerResultCancelled:
					NSLog(@"Post Canceled");
					break;
				case SLComposeViewControllerResultDone:
					NSLog(@"Post Sucessful");
					break;
					
				default:
					break;
			}
		}];
		
        [self.controller presentViewController:mySLComposerSheet animated:YES completion:nil];
    }
}


@end
