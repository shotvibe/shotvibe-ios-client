
#import "SVMailActivity.h"
#import "SVDefines.h"

@implementation SVMailActivity {
	MFMailComposeViewController *mailComposeViewController;
}

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Mail", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconMail.png"];
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
	return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
	
}

- (void)performActivity {
	
	if ([MFMailComposeViewController canSendMail]) {
		mailComposeViewController = [[MFMailComposeViewController alloc] init];
		mailComposeViewController.mailComposeDelegate = self;
		[mailComposeViewController setMessageBody:[NSString stringWithFormat:@"%@ %@", self.sharingText, self.sharingUrl.absoluteString] isHTML:YES];
		[mailComposeViewController addAttachmentData:UIImageJPEGRepresentation(self.sharingImage, 0.75f) mimeType:@"image/jpeg" fileName:@"photo.jpg"];
		[mailComposeViewController setSubject:@"Shotvibe"];
		
		if (IS_IOS7) {
			[mailComposeViewController.navigationBar setTintColor:[UIColor blackColor]];
		}
		
		[self.controller presentViewController:mailComposeViewController animated:YES completion:nil];
	}
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	
	[mailComposeViewController dismissViewControllerAnimated:YES completion:^{
		
	}];
}

@end
