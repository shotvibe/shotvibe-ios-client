
#import "SVLinkActivity.h"

@interface SVLinkActivity ()
@property (strong) NSMutableArray *events;
@end

@implementation SVLinkActivity

-(id)init
{
    self = [super init];
    
    if (self) {
        self.events = [NSMutableArray array];
    }
    
    return self;
}

- (NSString *)activityType {
    return NSStringFromClass([self class]);
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Get link", @"");
}

- (UIImage *)activityImage {
    return [UIImage imageNamed:@"IconLink.png"];
}

-(BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
    EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
    
    /*
     * "Save to Calendar" will only be displayed if the authorization status is
     * either not determined or authorized. There's no reason to display it otherwise.
     */
    for (id item in activityItems) {
        if ([item isKindOfClass:[SVLinkEvent class]] &&
            (status == EKAuthorizationStatusNotDetermined || status == EKAuthorizationStatusAuthorized)) {
            return YES;
        }
    }
    
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
    for (id item in activityItems)
        if ([item isKindOfClass:[SVLinkEvent class]])
            [self.events addObject:item];
}

- (void)performActivity
{
    EKEventStore *ekEventStore = [[EKEventStore alloc] init];
    
    [ekEventStore requestAccessToEntityType:EKEntityTypeEvent
                                 completion:^(BOOL granted, NSError *kError)
    {
        if (granted) {
            for (SVLinkEvent *event in self.events) {
                EKEvent *ekEvent = [EKEvent eventWithEventStore:ekEventStore];
                ekEvent.URL = event.URL;
                
                NSError *error = nil;
                [ekEventStore saveEvent:ekEvent
                                   span:EKSpanThisEvent
                                  error:&error];
                
                if (error == nil) {
                    if ([self.delegate respondsToSelector:@selector(calendarActivityDidFinish:)])
                        [self.delegate calendarActivityDidFinish:event];
                } else {
                    if ([self.delegate respondsToSelector:@selector(calendarActivityDidFail:withError:)])
                        [self.delegate calendarActivityDidFail:event withError:error];
                }
            }
        }
		else {
            if ([self.delegate respondsToSelector:@selector(calendarActivityDidFailWithError:)])
                [self.delegate calendarActivityDidFailWithError:kError];
        }
    }];
    
    [self activityDidFinish:YES];
}

@end
