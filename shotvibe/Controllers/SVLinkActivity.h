
#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>
#import "SVLinkEvent.h"

@protocol SVLinkActivityDelegate <NSObject>
@optional
- (void)calendarActivityDidFinish:(SVLinkEvent *)event;
- (void)calendarActivityDidFailWithError:(NSError *)error;
- (void)calendarActivityDidFail:(SVLinkEvent *)event withError:(NSError *)error;
@end

@interface SVLinkActivity : UIActivity
@property (assign) id<SVLinkActivityDelegate> delegate;
@end
