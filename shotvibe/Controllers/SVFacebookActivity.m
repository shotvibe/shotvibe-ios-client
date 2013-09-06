
#import "SVFacebookActivity.h"
#import <Social/Social.h>
#import <Accounts/Accounts.h>

@implementation SVFacebookActivity

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Facebook", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconFacebook.png"];
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
	SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
	
	[mySLComposerSheet setInitialText:self.sharingText];
	[mySLComposerSheet addURL:self.sharingUrl];
	[mySLComposerSheet addImage:self.sharingImage];
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

@end
