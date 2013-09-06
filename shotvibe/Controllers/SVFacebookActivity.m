
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
	//if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
	SLComposeViewController *mySLComposerSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
	
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
    //}
}
/*
- (id)init
{
    self = [super initWithTitle:NSLocalizedStringFromTable(@"activity.Facebook.title", @"REActivityViewController", @"Facebook")
                          image:[UIImage imageNamed:@"REActivityViewController.bundle/Icon_Facebook"]
                    actionBlock:nil];
    if (!self)
        return nil;
    
    __typeof(&*self) __weak weakSelf = self;
    self.actionBlock = ^(REActivity *activity, REActivityViewController *activityViewController) {
        UIViewController *presenter = activityViewController.presentingController;
        NSDictionary *userInfo = weakSelf.userInfo ? weakSelf.userInfo : activityViewController.userInfo;
        [activityViewController dismissViewControllerAnimated:YES completion:^{
            [weakSelf shareFromViewController:presenter
                                     text:[userInfo objectForKey:@"text"]
                                      url:[userInfo objectForKey:@"url"]
                                    image:[userInfo objectForKey:@"image"]];
        }];
    };
    
    return self;
}

- (void)shareFromViewController:(UIViewController *)viewController text:(NSString *)text url:(NSURL *)url image:(UIImage *)image
{
    DEFacebookComposeViewController *facebookViewComposer = [[DEFacebookComposeViewController alloc] init];
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
        viewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    else
        [UIApplication sharedApplication].delegate.window.rootViewController.modalPresentationStyle = UIModalPresentationCurrentContext;
    
    if (text)
        [facebookViewComposer setInitialText:text];
    if (url)
        [facebookViewComposer addURL:url];
    if (image)
        [facebookViewComposer addImage:image];
    [viewController presentViewController:facebookViewComposer animated:YES completion:nil];
}*/

@end
