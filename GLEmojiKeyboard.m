//
//  GLEmojiKeyboard.m
//  shotvibe
//
//  Created by Tsah Kashkash on 06/01/2016.
//  Copyright © 2016 PicsOnAir Ltd. All rights reserved.
//

#import "GLEmojiKeyboard.h"
#import "ShotVibeAppDelegate.h"

@implementation GLEmojiKeyboard

- (instancetype)initWithView:(UIView*)view frame:(CGRect)withRect {
    self = [super init];
    if (self) {
        
        self.numberOfClicks = 0;
        self.allEmojisLabelsArray = [[NSMutableArray alloc] init];
        self.allEmojisArray = [[ShotVibeAppDelegate sharedDelegate] allEmojisArray];
        //        self.allEmojisArray = [[NSMutableArray alloc] initWithObjects:@"😄", @"😃", @"😀", @"😊", @"☺️", @"😉", @"😍", @"😘", @"😚", @"😗", @"😙", @"😜", @"😝", @"😛", @"😳", @"😁", @"😔", @"😌", @"😒", @"😞", @"😣", @"😢", @"😂", @"😭", @"😪", @"😥", @"😰", @"😅", @"😓", @"😩", @"😫", @"😨", @"😱", @"😠", @"😡", @"😤", @"😖", @"😆", @"😋", @"😷", @"😎", @"😴", @"😵", @"😲", @"😟", @"😦", @"😧", @"😈", @"👿", @"😮", @"😬", @"😐", @"😕", @"😯", @"😶", @"😇", @"😏", @"😑", @"👲", @"👳", @"👮", @"👷", @"💂", @"👶", @"👦", @"👧", @"👨", @"👩", @"👴", @"👵", @"👱", @"👼", @"👸", @"😺", @"😸", @"😻", @"😽", @"😼", @"🙀", @"😿", @"😹", @"😾", @"👹", @"👺", @"🙈", @"🙉", @"🙊", @"💀", @"👽", @"💩", @"🔥", @"✨", @"🌟", @"💫", @"💥", @"💢", @"💦", @"💧", @"💤", @"💨", @"👂", @"👀", @"👃", @"👅", @"👄", @"👍", @"👎", @"👌", @"👊", @"✊", @"✌️", @"👋", @"✋", @"👐", @"👆", @"👇", @"👉", @"👈", @"🙌", @"🙏", @"☝️", @"👏", @"💪", @"🚶", @"🏃", @"💃", @"👫", @"👪", @"👬", @"👭", @"💏", @"💑", @"👯", @"🙆", @"🙅", @"💁", @"🙋", @"💆", @"💇", @"💅", @"👰", @"🙎", @"🙍", @"🙇", @"🎩", @"👑", @"👒", @"👟", @"👞", @"👡", @"👠", @"👢", @"👕", @"👔", @"👚", @"👗", @"🎽", @"👖", @"👘", @"👙", @"💼", @"👜", @"👝", @"👛", @"👓", @"🎀", @"🌂", @"💄", @"💛", @"💙", @"💜", @"💚", @"❤️", @"💔", @"💗", @"💓", @"💕", @"💖", @"💞", @"💘", @"💌", @"💋", @"💍", @"💎", @"👤", @"👥", @"💬", @"👣", @"💭", @"🐶", @"🐺", @"🐱", @"🐭", @"🐹", @"🐰", @"🐸", @"🐯", @"🐨", @"🐻", @"🐷", @"🐽", @"🐮", @"🐗", @"🐵", @"🐒", @"🐴", @"🐑", @"🐘", @"🐼", @"🐧", @"🐦", @"🐤", @"🐥", @"🐣", @"🐔", @"🐍", @"🐢", @"🐛", @"🐝", @"🐜", @"🐞", @"🐌", @"🐙", @"🐚", @"🐠", @"🐟", @"🐬", @"🐳", @"🐋", @"🐄", @"🐏", @"🐀", @"🐃", @"🐅", @"🐇", @"🐉", @"🐎", @"🐐", @"🐓", @"🐕", @"🐖", @"🐁", @"🐂", @"🐲", @"🐡", @"🐊", @"🐫", @"🐪", @"🐆", @"🐈", @"🐩", @"🐾", @"💐", @"🌸", @"🌷", @"🍀", @"🌹", @"🌻", @"🌺", @"🍁", @"🍃", @"🍂", @"🌿", @"🌾", @"🍄", @"🌵", @"🌴", @"🌲", @"🌳", @"🌰", @"🌱", @"🌼", @"🌐", @"🌞", @"🌝", @"🌚", @"🌑", @"🌒", @"🌓", @"🌔", @"🌕", @"🌖", @"🌗", @"🌘", @"🌜", @"🌛", @"🌙", @"🌍", @"🌎", @"🌏", @"🌋", @"🌌", @"🌠", @"⭐️", @"☀️", @"⛅️", @"☁️", @"⚡️", @"☔️", @"❄️", @"⛄️", @"🌀", @"🌁", @"🌈", @"🌊", @"🎍", @"💝", @"🎎", @"🎒", @"🎓", @"🎏", @"🎆", @"🎇", @"🎐", @"🎑", @"🎃", @"👻", @"🎅", @"🎄", @"🎁", @"🎋", @"🎉", @"🎊", @"🎈", @"🎌", @"🔮", @"🎥", @"📷", @"📹", @"📼", @"💿", @"💽", @"💾", @"💻", @"📱", @"☎️", @"📞", @"📟", @"📠", @"📡", @"📺", @"📻", @"🔊", @"🔉", @"🔈", @"🔇", @"🔔", @"🔕", @"📢", @"📣", @"⏳", @"⌛️", @"⏰", @"⌚️", @"🔓", @"🔒", @"🔏", @"🔐", @"🔑", @"🔎", @"💡", @"🔦", @"🔆", @"🔅", @"🔌", @"🔋", @"🔍", @"🛁", @"🚿", @"🚽", @"🔧", @"🔩", @"🔨", @"🚪", @"🚬", @"💣", @"🔫", @"🔪", @"💊", @"💉", @"💰", @"💴", @"💵", @"💳", @"💸", @"📲", @"📧", @"📥", @"📤", @"✉️", @"📩", @"📨", @"📯", @"📬", @"📭", @"📮", @"📦", @"📝", @"📄", @"📃", @"📑", @"📊", @"📈", @"📉", @"📜", @"📋", @"📅", @"📆", @"📇", @"📁", @"📂", @"✂️", @"📌", @"📎", @"✒️", @"✏️", @"📏", @"📐", @"📕", @"📗", @"📘", @"📙", @"📓", @"📔", @"📒", @"📚", @"📖", @"🔖", @"📛", @"🔬", @"🔭", @"📰", @"🎨", @"🎬", @"🎤", @"🎧", @"🎼", @"🎵", @"🎶", @"🎹", @"🎻", @"🎺", @"🎷", @"🎸", @"👾", @"🎮", @"🃏", @"🎴", @"🀄️", @"🎲", @"🎯", @"🏈", @"🏀", @"⚽️", @"⚾️", @"🎾", @"🎱", @"🏉", @"🎳", @"⛳️", @"🚵", @"🚴", @"🏁", @"🏇", @"🏆", @"🎿", @"🏂", @"🏊", @"🏄", @"🎣", @"☕️", @"🍵", @"🍶", @"🍼", @"🍺", @"🍸", @"🍹", @"🍷", @"🍴", @"🍕", @"🍔", @"🍟", @"🍗", @"🍖", @"🍝", @"🍛", @"🍤", @"🍱", @"🍣", @"🍥", @"🍙", @"🍘", @"🍚", @"🍜", @"🍲", @"🍢", @"🍡", @"🍳", @"🍞", @"🍩", @"🍮", @"🍦", @"🍨", @"🍧", @"🎂", @"🍰", @"🍪", @"🍫", @"🍬", @"🍭", @"🍯", @"🍎", @"🍏", @"🍊", @"🍋", @"🍒", @"🍇", @"🍉", @"🍓", @"🍑", @"🍈", @"🍌", @"🍐", @"🍍", @"🍠", @"🍆", @"🍅", @"🌽", nil];
        
        
        self.view = [[UIView alloc] initWithFrame:CGRectMake(0, -withRect.size.height*0.7, [[UIScreen mainScreen] bounds].size.width, withRect.size.height*0.7)];
        self.view.clipsToBounds = YES;
        self.view.backgroundColor = [UIColor clearColor];
        self.view.userInteractionEnabled = YES;
        
        
        
        
        UIVisualEffect *blurEffect;
        blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        
        UIVisualEffectView *visualEffectView;
        visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        
        visualEffectView.frame = CGRectMake(0, 0, self.view.frame.size.width, [[UIScreen mainScreen] bounds].size.height);
        [self.view addSubview:visualEffectView];
        
        
        //        self.view.cli
        [view addSubview:self.view];
        
        
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        self.scrollView.userInteractionEnabled = YES;
        //        self.scrollView.contentSize = CGSizeMake(<#CGFloat width#>, <#CGFloat height#>);
        
        
        [view setUserInteractionEnabled:YES];
        [self.view setUserInteractionEnabled:YES];
        
        
        int emojiesPerRow = 8;
        int numberOfRows = 6;
        float hieghtForRow = self.view.frame.size.height/numberOfRows;
        float widthForRow = self.view.frame.size.width/emojiesPerRow;
        int count = 0;
        
        self.scrollView.contentSize  = CGSizeMake(self.view.frame.size.width*11, withRect.size.height*0.7);
        self.scrollView.pagingEnabled = YES;
        
        
        UITapGestureRecognizer * keyboardTapped = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(keyboardDidTapped:)];
        [self.scrollView addGestureRecognizer:keyboardTapped];
        
        for(NSString * emoji in self.allEmojisArray){
            
            
            int column = count % 8;
            int page = count / 48;
            int row = count / 8 - (page*6);
            
            
            
            NSLog(@"current kb page is : %d",page);
            
            
            float x = (page * self.view.frame.size.width)+column * self.view.frame.size.width/8;
            float y = (row * self.view.frame.size.height/6);
            
            
            UILabel * l = [[UILabel alloc] initWithFrame:CGRectMake(x, y, widthForRow, hieghtForRow)];
            l.numberOfLines = 0;
            l.font = [UIFont systemFontOfSize:34];
            l.userInteractionEnabled = YES;
            l.backgroundColor = [UIColor clearColor];
            l.textAlignment = NSTextAlignmentCenter;
            l.text = [self.allEmojisArray objectAtIndex:count];
            [self.scrollView addSubview:l];
            [self.allEmojisLabelsArray addObject:l];
            
            
            count++;
        }
        
        [self.view addSubview:self.scrollView];
        [self slideKeyBoardIn];
        
    }
    return self;
}

- (BOOL) enableInputClicksWhenVisible {
    return YES;
}

- (void) keyboardDidTapped: (UITapGestureRecognizer *)recognizer
{
    
    //    [[UIDevice currentDevice] playInputClick];
    AudioServicesPlaySystemSound(1104);
    //Code to handle the gesture
    CGPoint location = [recognizer locationInView:self.scrollView];
    
    
    int page = location.x / self.view.frame.size.width;
    int col = (location.x - (page * self.view.frame.size.width)) / (self.view.frame.size.width/8);
    int row = location.y / (self.view.frame.size.height/6);
    
    
    int count = (page * 48) + (row*8) + col;
    
    
    NSLog(@"%@",[self.allEmojisArray objectAtIndex:count]);
    UILabel * tappedLabel = [self.allEmojisLabelsArray objectAtIndex:count];
    
    [self.scrollView bringSubviewToFront:tappedLabel];
    
    
    
    
    
    [UIView animateWithDuration:0.05 animations:^{
        
        tappedLabel.transform = CGAffineTransformScale(tappedLabel.transform, 2, 2);
        
    } completion:^(BOOL success){
        [UIView animateWithDuration:0.1 animations:^{
            tappedLabel.transform = CGAffineTransformIdentity;
        }];
        if(self.numberOfClicks < 10){
            self.textField.text = [self.textField.text stringByAppendingString:tappedLabel.text];
            self.numberOfClicks++;
        }
    }];
}

-(void)backSpacePressed {
    
    if(self.numberOfClicks > 0){
        AudioServicesPlaySystemSound(1104);
        self.textField.text = [self.textField.text substringToIndex:[self.textField.text length] - 2];
        self.numberOfClicks--;
    }
    
}

-(void)slideKeyBoardOut {
    
    
    [UIView animateWithDuration:0.750 delay:0
         usingSpringWithDamping:0.35f initialSpringVelocity:5.0f
                        options:0 animations:^{
                            
                            self.view.frame = CGRectMake(0, -self.view.frame.size.height, [[UIScreen mainScreen] bounds].size.width, self.view.frame.size.height);
                            
                        } completion:^(BOOL finished) {
                            [self.view removeFromSuperview];
                        }];
    
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"kKeyBoardWillHide" object:nil];
    //    [UIView animateWithDuration:0.3 animations:^{
    //        self.view.frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height*0.60, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height*0.40);
    //    } completion:^(BOOL finished) {
    //        [[NSNotificationCenter defaultCenter] postNotificationName:@"kKeyBoardDidHide" object:nil];
    //    }];
}

-(void)slideKeyBoardIn {
    
    
    [UIView animateWithDuration:0.750 delay:0
         usingSpringWithDamping:0.35f initialSpringVelocity:5.0f
                        options:0 animations:^{
                            
                            self.view.frame = CGRectMake(0, self.view.frame.size.height*0.255, [[UIScreen mainScreen] bounds].size.width, self.view.frame.size.height);
                            
                        } completion:nil];
    
}

@end
