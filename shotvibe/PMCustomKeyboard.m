//
//  PMCustomKeyboard.m
//  PunjabiKeyboard
//
//  Created by Kulpreet Chilana on 7/31/12.
//  Copyright (c) 2012 Kulpreet Chilana. All rights reserved.
//

#import "PMCustomKeyboard.h"

#define kFont [UIFont fontWithName:@"GothamRounded-Book" size:18]
#define kAltLabel @"😀"
#define kReturnLabel @"✔️"
#define kSpaceLabel @"______"
#define kChar @[ @"😄", @"😃", @"😀", @"😊", @"☺️", @"😉", @"😍", @"😘", @"😚", @"😗", @"😙", @"😜", @"😝", @"😛", @"😳", @"😁", @"😔", @"😌", @"😒", @"😞", @"😣", @"😢", @"😂", @"😭", @"😪", @"😥", @"😰", @"😅", @"😓", @"😩"]
//#define kChar_shift @[ @"1", @"2", @"3", @"4", @"5", @"6", @"ਙ", @"ਘ", @"ਧ", @"ਝ", @"ਢ", @"ਓ", @"ਏ", @"ਅ", @"ਇ", @"ਉ", @"ਫ", @"ੜ", @"ਖ", @"ਥ", @"ਛ", @"ਠ", @"◌ੰ", @"◌ੱ", @"ਣ", @"ਫ਼", @"ਜ਼", @"ਲ਼", @"ਸ਼", @"ਞ" ]
//#define kChar_alt @[ @"੧", @"੨", @"੩", @"੪", @"੫", @"੬", @"੭", @"੮", @"੯", @"੦", @"ੴ", @"-", @"/", @":", @";", @"(", @")", @"$", @"₹", @"&", @"@", @"\"", @"ਖ਼", @"ਗ਼", @"।", @"॥", @".", @",", @"?", @"!" ]

#define kEmoji_one @[ @"😄", @"😃", @"😀", @"😊", @"☺️", @"😉", @"😍", @"😘", @"😚", @"😗", @"😙", @"😜", @"😝", @"😛", @"😳", @"😁", @"😔", @"😌", @"😒", @"😞", @"😣", @"😢", @"😂", @"😭", @"😪", @"😥", @"😰", @"😅", @"😓", @"😩"]
#define kEmoji_two @[ @"😫", @"😨", @"😱", @"😠", @"😡", @"😤", @"😖", @"😆", @"😋", @"😷", @"😎", @"😴", @"😵", @"😲", @"😟", @"😦", @"😧", @"😈", @"👿", @"😮", @"😬", @"😐", @"😕", @"😯", @"😶", @"😇", @"😏", @"😑", @"👲", @"👳" ]
#define kEmoji_three @[ @"👮", @"👷", @"💂", @"👶", @"👦", @"👧", @"👨", @"👩", @"👴", @"👵", @"👱", @"👼", @"👸", @"😺", @"😸", @"😻", @"😽", @"😼", @"🙀", @"😿", @"😹", @"😾", @"👹", @"👺", @"🙈", @"🙉", @"🙊", @"💀", @"👽", @"💩"]
#define kEmoji_four @[ @"🔥", @"✨", @"🌟", @"💫", @"💥", @"💢", @"💦", @"💧", @"💤", @"💨", @"👂", @"👀", @"👃", @"👅", @"👄", @"👍", @"👎", @"👌", @"👊", @"✊", @"✌️", @"👋", @"✋", @"👐", @"👆", @"👇", @"👉", @"👈", @"🙌", @"🙏" ]
#define kEmoji_five @[ @"☝️", @"👏", @"💪", @"🚶", @"🏃", @"💃", @"👫", @"👪", @"👬", @"👭", @"💏", @"💑", @"👯", @"🙆", @"🙅", @"💁", @"🙋", @"💆", @"💇", @"💅", @"👰", @"🙎", @"🙍", @"🙇", @"🎩", @"👑", @"👒", @"👟", @"👞", @"👡" ]
#define kEmoji_six @[ @"👠", @"👢", @"👕", @"👔", @"👚", @"👗", @"🎽", @"👖", @"👘", @"👙", @"💼", @"👜", @"👝", @"👛", @"👓", @"🎀", @"🌂", @"💄", @"💛", @"💙", @"💜", @"💚", @"❤️", @"💔", @"💗", @"💓", @"💕", @"💖", @"💞", @"💘" ]
#define kEmoji_seven @[ @"💌", @"💋", @"💍", @"💎", @"👤", @"👥", @"💬", @"👣", @"💭", @"🐶", @"🐺", @"🐱", @"🐭", @"🐹", @"🐰", @"🐸", @"🐯", @"🐨", @"🐻", @"🐷", @"🐽", @"🐮", @"🐗", @"🐵", @"🐒", @"🐴", @"🐑", @"🐘", @"🐼", @"🐧" ]
#define kEmoji_eight @[ @"🐦", @"🐤", @"🐥", @"🐣", @"🐔", @"🐍", @"🐢", @"🐛", @"🐝", @"🐜", @"🐞", @"🐌", @"🐙", @"🐚", @"🐠", @"🐟", @"🐬", @"🐳", @"🐋", @"🐄", @"🐏", @"🐀", @"🐃", @"🐅", @"🐇", @"🐉", @"🐎", @"🐐", @"🐓", @"🐕" ]
#define kEmoji_nine @[ @"🐖", @"🐁", @"🐂", @"🐲", @"🐡", @"🐊", @"🐫", @"🐪", @"🐆", @"🐈", @"🐩", @"🐾", @"💐", @"🌸", @"🌷", @"🍀", @"🌹", @"🌻", @"🌺", @"🍁", @"🍃", @"🍂", @"🌿", @"🌾", @"🍄", @"🌵", @"🌴", @"🌲", @"🌳", @"🌰" ]
#define kEmoji_ten @[ @"🌱", @"🌼", @"🌐", @"🌞", @"🌝", @"🌚", @"🌑", @"🌒", @"🌓", @"🌔", @"🌕", @"🌖", @"🌗", @"🌘", @"🌜", @"🌛", @"🌙", @"🌍", @"🌎", @"🌏", @"🌋", @"🌌", @"🌠", @"⭐️", @"☀️", @"⛅️", @"☁️", @"⚡️", @"☔️", @"❄️" ]
#define kEmoji_eleven @[ @"⛄️", @"🌀", @"🌁", @"🌈", @"🌊", @"🎍", @"💝", @"🎎", @"🎒", @"🎓", @"🎏", @"🎆", @"🎇", @"🎐", @"🎑", @"🎃", @"👻", @"🎅", @"🎄", @"🎁", @"🎋", @"🎉", @"🎊", @"🎈", @"🎌", @"🔮", @"🎥", @"📷", @"📹", @"📼" ]
#define kEmoji_twelve @[ @"💿", @"📀", @"💽", @"💾", @"💻", @"📱", @"☎️", @"📞", @"📟", @"📠", @"📡", @"📺", @"📻", @"🔊", @"🔉", @"🔈", @"🔇", @"🔔", @"🔕", @"📢", @"📣", @"⏳", @"⌛️", @"⏰", @"⌚️", @"🔓", @"🔒", @"🔏", @"🔐", @"🔑" ]
#define kEmoji_thirtheen @[ @"🔎", @"💡", @"🔦", @"🔆", @"🔅", @"🔌", @"🔋", @"🔍", @"🛁", @"🛀", @"🚿", @"🚽", @"🔧", @"🔩", @"🔨", @"🚪", @"🚬", @"💣", @"🔫", @"🔪", @"💊", @"💉", @"💰", @"💴", @"💵", @"💷", @"💶", @"💳", @"💸", @"📲" ]
#define kEmoji_fourteen @[ @"📧", @"📥", @"📤", @"✉️", @"📩", @"📨", @"📯", @"📫", @"📪", @"📬", @"📭", @"📮", @"📦", @"📝", @"📄", @"📃", @"📑", @"📊", @"📈", @"📉", @"📜", @"📋", @"📅", @"📆", @"📇", @"📁", @"📂", @"✂️", @"📌", @"📎" ]
#define kEmoji_fivetheen @[ @"✒️", @"✏️", @"📏", @"📐", @"📕", @"📗", @"📘", @"📙", @"📓", @"📔", @"📒", @"📚", @"📖", @"🔖", @"📛", @"🔬", @"🔭", @"📰", @"🎨", @"🎬", @"🎤", @"🎧", @"🎼", @"🎵", @"🎶", @"🎹", @"🎻", @"🎺", @"🎷", @"🎸" ]
#define kEmoji_sixteen @[ @"👾", @"🎮", @"🃏", @"🎴", @"🀄️", @"🎲", @"🎯", @"🏈", @"🏀", @"⚽️", @"⚾️", @"🎾", @"🎱", @"🏉", @"🎳", @"⛳️", @"🚵", @"🚴", @"🏁", @"🏇", @"🏆", @"🎿", @"🏂", @"🏊", @"🏄", @"🎣", @"☕️", @"🍵", @"🍶", @"🍼" ]
#define kEmoji_seventeen @[ @"🍺", @"🍻", @"🍸", @"🍹", @"🍷", @"🍴", @"🍕", @"🍔", @"🍟", @"🍗", @"🍖", @"🍝", @"🍛", @"🍤", @"🍱", @"🍣", @"🍥", @"🍙", @"🍘", @"🍚", @"🍜", @"🍲", @"🍢", @"🍡", @"🍳", @"🍞", @"🍩", @"🍮", @"🍦", @"🍨" ]
#define kEmoji_eightteen @[ @"🍧", @"🎂", @"🍰", @"🍪", @"🍫", @"🍬", @"🍭", @"🍯", @"🍎", @"🍏", @"🍊", @"🍋", @"🍒", @"🍇", @"🍉", @"🍓", @"🍑", @"🍈", @"🍌", @"🍐", @"🍍", @"🍠", @"🍆", @"🍅", @"🌽", @"🍍", @"🍠", @"🍆", @"🍅", @"🌽" ]



enum {
    PKNumberPadViewImageLeft = 0,
    PKNumberPadViewImageInner,
    PKNumberPadViewImageRight,
    PKNumberPadViewImageMax
};

@interface PMCustomKeyboard ()

@property (nonatomic, assign, getter=isShifted) BOOL shifted;
@property (nonatomic, retain) NSArray * pallets;
@property (nonatomic) int currentPallete;
@property (nonatomic) int charchtersCounter;
@property (nonatomic, retain) NSArray * recentsEmoji;

@end

@implementation PMCustomKeyboard
@synthesize textView = _textView;

- (id)init {
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	CGRect frame;
    
    self.charchtersCounter = 0;
    
//    self.recentsEmoji = [[NSMutableArray alloc] init];
//    self.recentsEmoji = @[ @"😄", @"😃", @"😀", @"😊", @"☺️", @"😉", @"😍", @"😘", @"😚", @"😗", @"😙", @"😜", @"😝", @"😛", @"😳", @"😁", @"😔", @"😌", @"😒", @"😞", @"😣", @"😢", @"😂", @"😭", @"😪", @"😥", @"😰", @"😅", @"😓", @"😩"];
    
    
    
    
//    for(NSString * emoji in recentsEmojisDict){
//    
//        self.recentsEmoji addObject:<#(nonnull id)#>
//        
//    }
    
    
    
    
	if(UIDeviceOrientationIsLandscape(orientation))
        frame = CGRectMake(0, 0, 480, 162);
    else
        frame = CGRectMake(0, 0, 320, 216);
	
	self = [super initWithFrame:frame];
	
	if (self) {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"PMCustomKeyboard" owner:self options:nil];
		[[nib objectAtIndex:0] setFrame:frame];
        self = [nib objectAtIndex:0];
    }
	
    self.shifted = YES;
    [self.altButton setTitle:kAltLabel forState:UIControlStateNormal];
    
//    [self.altButton setTitle:@"0" forState:UIControlStateNormal];
	
	[self.returnButton setTitle:kReturnLabel forState:UIControlStateNormal];
	self.returnButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    [self loadRecentsFromNsDefaults];
	
	[self loadCharactersWithArray:self.recentsEmoji];
    
    [self.spaceButton setBackgroundImage:[PMCustomKeyboard imageFromColor:[UIColor colorWithWhite:0.4 alpha:0.5]]
                                forState:UIControlStateHighlighted];
    self.spaceButton.layer.cornerRadius = 7.0;
    self.spaceButton.layer.masksToBounds = YES;
    self.spaceButton.layer.borderWidth = 0;
    [self.spaceButton setTitle:kSpaceLabel forState:UIControlStateNormal];
	
    
    // Keyboard Customization for iOS 7
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        [self.keyboardBackground setImage:[UIImage imageNamed:@"iOS7_Keyboard"]];
        self.spaceButton.layer.cornerRadius = 4.0;
        [self.spaceButton.titleLabel setFont:kFont];
        [self.spaceButton.titleLabel setShadowOffset:CGSizeMake(0, 0)];
        [self.returnButton.titleLabel setFont:kFont];
        [self.altButton.titleLabel setFont:kFont];
        [self.altButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.altButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [self.shiftButton setShowsTouchWhenHighlighted:NO];
        [self.deleteButton setImage:[UIImage imageNamed:@"delete_iOS7"] forState:UIControlStateHighlighted];
        [self.spaceButton setBackgroundImage:[PMCustomKeyboard imageFromColor:[UIColor colorWithRed:0.725 green:0.741 blue:0.757 alpha:1.000]] forState:UIControlStateHighlighted];
        self.returnButton.layer.cornerRadius = 4.0;
        self.returnButton.layer.masksToBounds = YES;
        self.returnButton.layer.borderWidth = 0;
        [self.returnButton setBackgroundImage:[PMCustomKeyboard imageFromColor:[UIColor whiteColor]] forState:UIControlStateHighlighted];
        //[self.returnButton setEnabled:NO];
        //[self.returnButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [self.returnButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.returnButton setTitleColor:[UIColor blackColor] forState:UIControlStateHighlighted];
        [self.spaceButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        
    }
    
    
    
    self.pallets = [[NSArray alloc] initWithObjects:kEmoji_one,kEmoji_two,kEmoji_three,kEmoji_four,kEmoji_five,kEmoji_six,kEmoji_seven,kEmoji_eight,kEmoji_nine,kEmoji_ten,kEmoji_eleven,kEmoji_twelve,kEmoji_thirtheen,kEmoji_fourteen,kEmoji_fivetheen,kEmoji_sixteen,kEmoji_seventeen,kEmoji_eightteen, nil];
    self.currentPallete = 0;
    
	return self;
}

-(void)loadRecentsFromNsDefaults {

    
    NSMutableDictionary * recentsEmojisDict = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"RecentsEmojies"]];
    if([recentsEmojisDict count] > 0){
        self.recentsEmoji = @[ @"😄", @"😃", @"😀", @"😊", @"☺️", @"😉", @"😍", @"😘", @"😚", @"😗", @"😙", @"😜", @"😝", @"😛", @"😳", @"😁", @"😔", @"😌", @"😒", @"😞", @"😣", @"😢", @"😂", @"😭", @"😪", @"😥", @"😰", @"😅", @"😓", @"😩"];
    } else {
        self.recentsEmoji = [[[recentsEmojisDict keysSortedByValueUsingComparator: ^(id obj1, id obj2) {
            
            if ([obj1 integerValue] > [obj2 integerValue]) {
                
                return (NSComparisonResult)NSOrderedDescending;
            }
            if ([obj1 integerValue] < [obj2 integerValue]) {
                
                return (NSComparisonResult)NSOrderedAscending;
            }
            
            return (NSComparisonResult)NSOrderedSame;
        }] reverseObjectEnumerator] allObjects];
    }
    
    
    NSLog(@"");
    
    
    
}

-(void)setTextView:(id<UITextInput>)textView {
	if ([textView isKindOfClass:[UITextView class]]) {
        [(UITextView *)textView setInputView:self];
        /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkShouldEnableReturnButton:)
                                                     name:UITextViewTextDidChangeNotification
                                                   object:textView];*/
    }
    else if ([textView isKindOfClass:[UITextField class]]) {
        [(UITextField *)textView setInputView:self];
        /*[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(checkShouldEnableReturnButton:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:textView];*/
    }
    
    _textView = textView;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    if (action == @selector(paste:))
        return NO;
    return [super canPerformAction:action withSender:sender];
}

-(void)checkShouldEnableReturnButton:(NSNotification *)notification {
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        if ([self.textView isKindOfClass:[UITextView class]]) {
            UITextView *textView = (UITextView *)self.textView;
            if (textView.text.length > 0) {
                [self.returnButton setEnabled:YES];
                [self.returnButton setBackgroundImage:[PMCustomKeyboard imageFromColor:[UIColor colorWithRed:0.082 green:0.478 blue:0.984 alpha:1.000]] forState:UIControlStateNormal];
                [self.returnButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            }
            else {
                [self.returnButton setEnabled:NO];
                [self.returnButton setBackgroundImage:nil forState:UIControlStateNormal];
                [self.returnButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            }
        }
        else if ([self.textView isKindOfClass:[UITextField class]]) {
            UITextField *textField = (UITextField *)self.textView;
            if (textField.text.length > 0) {
                [self.returnButton setEnabled:YES];
                [self.returnButton setBackgroundImage:[PMCustomKeyboard imageFromColor:[UIColor colorWithRed:0.082 green:0.478 blue:0.984 alpha:1.000]] forState:UIControlStateNormal];
                [self.returnButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            }
            else {
                [self.returnButton setEnabled:NO];
                [self.returnButton setBackgroundImage:nil forState:UIControlStateNormal];
                [self.returnButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
            }
        }
    }
}

-(id<UITextInput>)textView {
	return _textView;
}

-(void)loadCharactersWithArray:(NSArray *)a {
	int i = 0;
    
    [self loadRecentsFromNsDefaults];
    
	for (UIButton *b in self.characterKeys) {
        
        CATransition *transitionAnimation = [CATransition animation];
        [transitionAnimation setType:kCATransitionFade];
        [transitionAnimation setDuration:0.15f];
        [transitionAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
        [transitionAnimation setFillMode:kCAFillModeBoth];
        [b.layer addAnimation:transitionAnimation forKey:@"fadeAnimation"];
        
        if(i < [a count]){
            [b setTitle:[a objectAtIndex:i] forState:UIControlStateNormal];
            if ([b.titleLabel.text characterAtIndex:0] < 128 && ![[b.titleLabel.text substringToIndex:1] isEqualToString:@"◌"])
                [b.titleLabel setFont:[UIFont systemFontOfSize:22]];
            else
                [b.titleLabel setFont:kFont];
        } else {
            [b setTitle:@"" forState:UIControlStateNormal];
        }
		
		i++;
	}
}

- (BOOL) enableInputClicksWhenVisible {
    return YES;
}

/* IBActions for Keyboard Buttons */

- (IBAction)returnPressed:(id)sender
{
    [[UIDevice currentDevice] playInputClick];

	if ([self.textView isKindOfClass:[UITextView class]])
    {
        [self.textView insertText:@"\n"];
		[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
    }
	else if ([self.textView isKindOfClass:[UITextField class]])
    {
        if ([[(UITextField *)self.textView delegate] respondsToSelector:@selector(textFieldShouldReturn:)])
        {
            [[(UITextField *)self.textView delegate] textFieldShouldReturn:(UITextField *)self.textView];
        }
    }
}

- (IBAction)shiftPressed:(id)sender {
	[[UIDevice currentDevice] playInputClick];
//	if (!self.isShifted) {
		[self.shiftButton setBackgroundImage:[UIImage imageNamed:@"glow.png"] forState:UIControlStateNormal];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
            [self.shiftButton setBackgroundImage:[UIImage imageNamed:@"shift.png"] forState:UIControlStateNormal];
        }
		[self loadCharactersWithArray:self.recentsEmoji];
        [self.altButton setTitle:kAltLabel forState:UIControlStateNormal];
//    } else {
    
//    }
}

- (IBAction)unShift {
	if (self.isShifted) {
		[self.shiftButton setBackgroundImage:nil forState:UIControlStateNormal];
		[self loadCharactersWithArray:kChar];
	}
	if (!self.isShifted)
		self.shifted = YES;
	else
		self.shifted = NO;
}

- (IBAction)spacePressed:(id)sender {
    [[UIDevice currentDevice] playInputClick];
    
	[self.textView insertText:@" "];
    
	if (self.isShifted)
//		[self unShift];
	
        if ([self.textView isKindOfClass:[UITextView class]]){
            
            [[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
            
        } else if ([self.textView isKindOfClass:[UITextField class]]){
            [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textView];
        }
}

- (IBAction)altPressed:(id)sender {
    [[UIDevice currentDevice] playInputClick];
    
    
    if(self.isShifted){
    
        [self.shiftButton setBackgroundImage:nil forState:UIControlStateNormal];
        self.shifted = NO;
        [self loadCharactersWithArray:[self.pallets objectAtIndex:self.currentPallete]];
        [self.altButton setTitle:[NSString stringWithFormat:@"%d",self.currentPallete] forState:UIControlStateNormal];
        
        
    } else {
        
        
        
        UIButton *button = (UIButton *)sender;
        
        //	if ([button.titleLabel.text isEqualToString:kAltLabel]) {
        
        if(self.currentPallete == self.pallets.count-2){
            self.currentPallete = 0;
            
            [self loadCharactersWithArray:[self.pallets objectAtIndex:0]];
            [self.altButton setTitle:[NSString stringWithFormat:@"%d",0] forState:UIControlStateNormal];
            //        self.currentPallete++;
            
            //    } else if (self.currentPallete){
            
        } else {
            
            [self loadCharactersWithArray:[self.pallets objectAtIndex:self.currentPallete+1]];
            [self.altButton setTitle:[NSString stringWithFormat:@"%d",self.currentPallete+1] forState:UIControlStateNormal];
            self.currentPallete++;
            
            //    NSLog(<#NSString * _Nonnull format, ...#>)
        }
        
        
    }
    
    
	

    
    
//        [self.altButton setTitle:[kChar objectAtIndex:18] forState:UIControlStateNormal];
//	}
//	else {
//		[self loadCharactersWithArray:kChar];
//        [self.altButton setTitle:kAltLabel forState:UIControlStateNormal];
//	}
}

- (IBAction)deletePressed:(id)sender {
    [[UIDevice currentDevice] playInputClick];
    self.charchtersCounter--;
	[self.textView deleteBackward];
	[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification
														object:self.textView];
	if ([self.textView isKindOfClass:[UITextView class]])
		[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
	else if ([self.textView isKindOfClass:[UITextField class]])
		[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textView];
}

- (void)updateRecentsWithCharchter:(NSString*)charchter {

    NSMutableDictionary * recentsEmojisDict = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"RecentsEmojies"]];

    
    //recents contain the charchter
    if([recentsEmojisDict objectForKey:charchter]){
        NSLog(@"found the emoji");
        
        NSNumber * currentCount = [recentsEmojisDict objectForKey:charchter];
        
        [recentsEmojisDict setObject:[NSNumber numberWithInt:[currentCount intValue]+1] forKey:charchter];
        [[NSUserDefaults standardUserDefaults] setObject:recentsEmojisDict forKey:@"RecentsEmojies"];
        [[NSUserDefaults standardUserDefaults] synchronize];
//        raise charchters value by one
        
        
    //recents dose not contain charchter
    } else {
        NSLog(@"couldnt found the emoji");
        [recentsEmojisDict setObject:[NSNumber numberWithInt:1] forKey:charchter];
        [[NSUserDefaults standardUserDefaults] setObject:recentsEmojisDict forKey:@"RecentsEmojies"];
        [[NSUserDefaults standardUserDefaults] synchronize];
//        add the charchter with pressed 1 as value and emoji as key
        
    }
//    [self loadRecentsFromNsDefaults];
    

}

- (IBAction)characterPressed:(id)sender {
	UIButton *button = (UIButton *)sender;
	NSString *character = [NSString stringWithString:button.titleLabel.text];
    
    if(![character isEqualToString:@""] && self.charchtersCounter <= 9){
        
    self.charchtersCounter++;
    
    [self updateRecentsWithCharchter:character];
    [self loadRecentsFromNsDefaults];
//    [self loadCharactersWithArray:self.recentsEmoji];
	
	
	[self.textView insertText:character];

	
	if ([self.textView isKindOfClass:[UITextView class]])
		[[NSNotificationCenter defaultCenter] postNotificationName:UITextViewTextDidChangeNotification object:self.textView];
	else if ([self.textView isKindOfClass:[UITextField class]])
		[[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidChangeNotification object:self.textView];
    }
}

- (void)addPopupToButton:(UIButton *)b {
    UIImageView *keyPop = nil;
    UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 52, 60)];
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7.0) {
        if (b == [self.characterKeys objectAtIndex:0] || b == [self.characterKeys objectAtIndex:11]) {
            keyPop = [[UIImageView alloc] initWithImage:[self createiOS7KeytopImageWithKind:PKNumberPadViewImageRight]];
            keyPop.frame = CGRectMake(-16, -71, keyPop.frame.size.width, keyPop.frame.size.height);
        }
        else if (b == [self.characterKeys objectAtIndex:10] || b == [self.characterKeys objectAtIndex:21]) {
            keyPop = [[UIImageView alloc] initWithImage:[self createiOS7KeytopImageWithKind:PKNumberPadViewImageLeft]];
            keyPop.frame = CGRectMake(-38, -71, keyPop.frame.size.width, keyPop.frame.size.height);
        }
        else {
            keyPop = [[UIImageView alloc] initWithImage:[self createiOS7KeytopImageWithKind:PKNumberPadViewImageInner]];
            keyPop.frame = CGRectMake(-27, -71, keyPop.frame.size.width, keyPop.frame.size.height);
        }
        
    }
    else {
        if (b == [self.characterKeys objectAtIndex:0] || b == [self.characterKeys objectAtIndex:11]) {
            keyPop = [[UIImageView alloc] initWithImage:[self createKeytopImageWithKind:PKNumberPadViewImageRight]];
            keyPop.frame = CGRectMake(-16, -71, keyPop.frame.size.width, keyPop.frame.size.height);
        }
        else if (b == [self.characterKeys objectAtIndex:10] || b == [self.characterKeys objectAtIndex:21]) {
            keyPop = [[UIImageView alloc] initWithImage:[self createKeytopImageWithKind:PKNumberPadViewImageLeft]];
            keyPop.frame = CGRectMake(-38, -71, keyPop.frame.size.width, keyPop.frame.size.height);
        }
        else {
            keyPop = [[UIImageView alloc] initWithImage:[self createKeytopImageWithKind:PKNumberPadViewImageInner]];
            keyPop.frame = CGRectMake(-27, -71, keyPop.frame.size.width, keyPop.frame.size.height);
        }
        
    }
    
    if ([b.titleLabel.text characterAtIndex:0] < 128 && ![[b.titleLabel.text substringToIndex:1] isEqualToString:@"◌"])
        [text setFont:[UIFont systemFontOfSize:40]];
    else
        [text setFont:[UIFont fontWithName:kFont.fontName size:40]];
    
    [text setTextAlignment:NSTextAlignmentCenter];
    [text setBackgroundColor:[UIColor clearColor]];
    [text setAdjustsFontSizeToFitWidth:YES];
    [text setText:b.titleLabel.text];
    
    keyPop.layer.shadowColor = [UIColor colorWithWhite:0.1 alpha:1.0].CGColor;
    keyPop.layer.shadowOffset = CGSizeMake(0, 2.0);
    keyPop.layer.shadowOpacity = 0.30;
    keyPop.layer.shadowRadius = 3.0;
    keyPop.clipsToBounds = NO;
    
    [keyPop addSubview:text];
    [b addSubview:keyPop];
}

- (void)touchesBegan: (NSSet *)touches withEvent: (UIEvent *)event {
    CGPoint location = [[touches anyObject] locationInView:self];
    
    for (UIButton *b in self.characterKeys) {
        if ([b subviews].count > 1) {
            [[[b subviews] objectAtIndex:1] removeFromSuperview];
        }
        if(CGRectContainsPoint(b.frame, location))
        {
            [self addPopupToButton:b];
            [[UIDevice currentDevice] playInputClick];
        }
    }
}

-(void)touchesMoved: (NSSet *)touches withEvent: (UIEvent *)event {
    CGPoint location = [[touches anyObject] locationInView:self];
    
    for (UIButton *b in self.characterKeys) {
        if ([b subviews].count > 1) {
            [[[b subviews] objectAtIndex:1] removeFromSuperview];
        }
        if(CGRectContainsPoint(b.frame, location))
        {
            [self addPopupToButton:b];
        }
    }
}


-(void) touchesEnded: (NSSet *)touches withEvent: (UIEvent *)event{
    CGPoint location = [[touches anyObject] locationInView:self];
    
    for (UIButton *b in self.characterKeys) {
        if ([b subviews].count > 1) {
            [[[b subviews] objectAtIndex:1] removeFromSuperview];
        }
        if(CGRectContainsPoint(b.frame, location))
        {
            [self characterPressed:b];
        }
    }
}

/* UI Utilities */

+ (UIImage *) imageFromColor:(UIColor *)color {
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

#define _UPPER_WIDTH   (52.0 * [[UIScreen mainScreen] scale])
#define _LOWER_WIDTH   (32.0 * [[UIScreen mainScreen] scale])

#define _PAN_UPPER_RADIUS  (7.0 * [[UIScreen mainScreen] scale])
#define _PAN_LOWER_RADIUS  (7.0 * [[UIScreen mainScreen] scale])

#define _PAN_UPPDER_WIDTH   (_UPPER_WIDTH-_PAN_UPPER_RADIUS*2)
#define _PAN_UPPER_HEIGHT    (61.0 * [[UIScreen mainScreen] scale])

#define _PAN_LOWER_WIDTH     (_LOWER_WIDTH-_PAN_LOWER_RADIUS*2)
#define _PAN_LOWER_HEIGHT    (30.0 * [[UIScreen mainScreen] scale])

#define _PAN_UL_WIDTH        ((_UPPER_WIDTH-_LOWER_WIDTH)/2)

#define _PAN_MIDDLE_HEIGHT    (11.0 * [[UIScreen mainScreen] scale])

#define _PAN_CURVE_SIZE      (7.0 * [[UIScreen mainScreen] scale])

#define _PADDING_X     (15 * [[UIScreen mainScreen] scale])
#define _PADDING_Y     (10 * [[UIScreen mainScreen] scale])
#define _WIDTH   (_UPPER_WIDTH + _PADDING_X*2)
#define _HEIGHT   (_PAN_UPPER_HEIGHT + _PAN_MIDDLE_HEIGHT + _PAN_LOWER_HEIGHT + _PADDING_Y*2)


#define _OFFSET_X    -25 * [[UIScreen mainScreen] scale])
#define _OFFSET_Y    59 * [[UIScreen mainScreen] scale])


- (UIImage *)createKeytopImageWithKind:(int)kind
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPoint p = CGPointMake(_PADDING_X, _PADDING_Y);
    CGPoint p1 = CGPointZero;
    CGPoint p2 = CGPointZero;
    
    p.x += _PAN_UPPER_RADIUS;
    CGPathMoveToPoint(path, NULL, p.x, p.y);
    
    p.x += _PAN_UPPDER_WIDTH;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.y += _PAN_UPPER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 _PAN_UPPER_RADIUS,
                 3.0*M_PI/2.0,
                 4.0*M_PI/2.0,
                 false);
    
    p.x += _PAN_UPPER_RADIUS;
    p.y += _PAN_UPPER_HEIGHT - _PAN_UPPER_RADIUS - _PAN_CURVE_SIZE;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p1 = CGPointMake(p.x, p.y + _PAN_CURVE_SIZE);
    switch (kind) {
        case PKNumberPadViewImageLeft:
            p.x -= _PAN_UL_WIDTH*2;
            break;
            
        case PKNumberPadViewImageInner:
            p.x -= _PAN_UL_WIDTH;
            break;
            
        case PKNumberPadViewImageRight:
            break;
    }
    
    p.y += _PAN_MIDDLE_HEIGHT + _PAN_CURVE_SIZE*2;
    p2 = CGPointMake(p.x, p.y - _PAN_CURVE_SIZE);
    CGPathAddCurveToPoint(path, NULL,
                          p1.x, p1.y,
                          p2.x, p2.y,
                          p.x, p.y);
    
    p.y += _PAN_LOWER_HEIGHT - _PAN_CURVE_SIZE - _PAN_LOWER_RADIUS;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.x -= _PAN_LOWER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 _PAN_LOWER_RADIUS,
                 4.0*M_PI/2.0,
                 1.0*M_PI/2.0,
                 false);
    
    p.x -= _PAN_LOWER_WIDTH;
    p.y += _PAN_LOWER_RADIUS;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.y -= _PAN_LOWER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 _PAN_LOWER_RADIUS,
                 1.0*M_PI/2.0,
                 2.0*M_PI/2.0,
                 false);
    
    p.x -= _PAN_LOWER_RADIUS;
    p.y -= _PAN_LOWER_HEIGHT - _PAN_LOWER_RADIUS - _PAN_CURVE_SIZE;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p1 = CGPointMake(p.x, p.y - _PAN_CURVE_SIZE);
    
    switch (kind) {
        case PKNumberPadViewImageLeft:
            break;
            
        case PKNumberPadViewImageInner:
            p.x -= _PAN_UL_WIDTH;
            break;
            
        case PKNumberPadViewImageRight:
            p.x -= _PAN_UL_WIDTH*2;
            break;
    }
    
    p.y -= _PAN_MIDDLE_HEIGHT + _PAN_CURVE_SIZE*2;
    p2 = CGPointMake(p.x, p.y + _PAN_CURVE_SIZE);
    CGPathAddCurveToPoint(path, NULL,
                          p1.x, p1.y,
                          p2.x, p2.y,
                          p.x, p.y);
    
    p.y -= _PAN_UPPER_HEIGHT - _PAN_UPPER_RADIUS - _PAN_CURVE_SIZE;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.x += _PAN_UPPER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 _PAN_UPPER_RADIUS,
                 2.0*M_PI/2.0,
                 3.0*M_PI/2.0,
                 false);
    //----
    CGContextRef context;
    UIGraphicsBeginImageContext(CGSizeMake(_WIDTH,
                                           _HEIGHT));
    context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, _HEIGHT);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    //----
    
    // draw gradient
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
    CGFloat components[] = {
        0.95f, 1.0f,
        0.85f, 1.0f,
        0.675f, 1.0f,
        0.8f, 1.0f};
    
    
    size_t count = sizeof(components)/ (sizeof(CGFloat)* 2);
    
    CGRect frame = CGPathGetBoundingBox(path);
    CGPoint startPoint = frame.origin;
    CGPoint endPoint = frame.origin;
    endPoint.y = frame.origin.y + frame.size.height;
    
    CGGradientRef gradientRef =
    CGGradientCreateWithColorComponents(colorSpaceRef, components, NULL, count);
    
    CGContextDrawLinearGradient(context,
                                gradientRef,
                                startPoint,
                                endPoint,
                                kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradientRef);
    CGColorSpaceRelease(colorSpaceRef);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    UIImage * image = [UIImage imageWithCGImage:imageRef scale:[[UIScreen mainScreen] scale] orientation:UIImageOrientationDown];
    CGImageRelease(imageRef);
    
    UIGraphicsEndImageContext();
    
    CFRelease(path);
    
    return image;
}

#define __UPPER_WIDTH   (52.0 * [[UIScreen mainScreen] scale])
#define __LOWER_WIDTH   (24.0 * [[UIScreen mainScreen] scale])

#define __PAN_UPPER_RADIUS  (10.0 * [[UIScreen mainScreen] scale])
#define __PAN_LOWER_RADIUS  (5.0 * [[UIScreen mainScreen] scale])

#define __PAN_UPPDER_WIDTH   (__UPPER_WIDTH-__PAN_UPPER_RADIUS*2)
#define __PAN_UPPER_HEIGHT    (52.0 * [[UIScreen mainScreen] scale])

#define __PAN_LOWER_WIDTH     (__LOWER_WIDTH-__PAN_LOWER_RADIUS*2)
#define __PAN_LOWER_HEIGHT    (47.0 * [[UIScreen mainScreen] scale])

#define __PAN_UL_WIDTH        ((__UPPER_WIDTH-__LOWER_WIDTH)/2)

#define __PAN_MIDDLE_HEIGHT    (2.0 * [[UIScreen mainScreen] scale])

#define __PAN_CURVE_SIZE      (10.0 * [[UIScreen mainScreen] scale])

#define __PADDING_X     (15 * [[UIScreen mainScreen] scale])
#define __PADDING_Y     (10 * [[UIScreen mainScreen] scale])
#define __WIDTH   (__UPPER_WIDTH + __PADDING_X*2)
#define __HEIGHT   (__PAN_UPPER_HEIGHT + __PAN_MIDDLE_HEIGHT + __PAN_LOWER_HEIGHT + __PADDING_Y*2)


#define __OFFSET_X    -25 * [[UIScreen mainScreen] scale])
#define __OFFSET_Y    59 * [[UIScreen mainScreen] scale])


- (UIImage *)createiOS7KeytopImageWithKind:(int)kind
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPoint p = CGPointMake(__PADDING_X, __PADDING_Y);
    CGPoint p1 = CGPointZero;
    CGPoint p2 = CGPointZero;
    
    p.x += __PAN_UPPER_RADIUS;
    CGPathMoveToPoint(path, NULL, p.x, p.y);
    
    p.x += __PAN_UPPDER_WIDTH;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.y += __PAN_UPPER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 __PAN_UPPER_RADIUS,
                 3.0*M_PI/2.0,
                 4.0*M_PI/2.0,
                 false);
    
    p.x += __PAN_UPPER_RADIUS;
    p.y += __PAN_UPPER_HEIGHT - __PAN_UPPER_RADIUS - __PAN_CURVE_SIZE;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p1 = CGPointMake(p.x, p.y + __PAN_CURVE_SIZE);
    switch (kind) {
        case PKNumberPadViewImageLeft:
            p.x -= __PAN_UL_WIDTH*2;
            break;
            
        case PKNumberPadViewImageInner:
            p.x -= __PAN_UL_WIDTH;
            break;
            
        case PKNumberPadViewImageRight:
            break;
    }
    
    p.y += __PAN_MIDDLE_HEIGHT + __PAN_CURVE_SIZE*2;
    p2 = CGPointMake(p.x, p.y - __PAN_CURVE_SIZE);
    CGPathAddCurveToPoint(path, NULL,
                          p1.x, p1.y,
                          p2.x, p2.y,
                          p.x, p.y);
    
    p.y += __PAN_LOWER_HEIGHT - __PAN_CURVE_SIZE - __PAN_LOWER_RADIUS;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.x -= __PAN_LOWER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 __PAN_LOWER_RADIUS,
                 4.0*M_PI/2.0,
                 1.0*M_PI/2.0,
                 false);
    
    p.x -= __PAN_LOWER_WIDTH;
    p.y += __PAN_LOWER_RADIUS;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.y -= __PAN_LOWER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 __PAN_LOWER_RADIUS,
                 1.0*M_PI/2.0,
                 2.0*M_PI/2.0,
                 false);
    
    p.x -= __PAN_LOWER_RADIUS;
    p.y -= __PAN_LOWER_HEIGHT - __PAN_LOWER_RADIUS - __PAN_CURVE_SIZE;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p1 = CGPointMake(p.x, p.y - __PAN_CURVE_SIZE);
    
    switch (kind) {
        case PKNumberPadViewImageLeft:
            break;
            
        case PKNumberPadViewImageInner:
            p.x -= __PAN_UL_WIDTH;
            break;
            
        case PKNumberPadViewImageRight:
            p.x -= __PAN_UL_WIDTH*2;
            break;
    }
    
    p.y -= __PAN_MIDDLE_HEIGHT + __PAN_CURVE_SIZE*2;
    p2 = CGPointMake(p.x, p.y + __PAN_CURVE_SIZE);
    CGPathAddCurveToPoint(path, NULL,
                          p1.x, p1.y,
                          p2.x, p2.y,
                          p.x, p.y);
    
    p.y -= __PAN_UPPER_HEIGHT - __PAN_UPPER_RADIUS - __PAN_CURVE_SIZE;
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    
    p.x += __PAN_UPPER_RADIUS;
    CGPathAddArc(path, NULL,
                 p.x, p.y,
                 __PAN_UPPER_RADIUS,
                 2.0*M_PI/2.0,
                 3.0*M_PI/2.0,
                 false);
    //----
    CGContextRef context;
    UIGraphicsBeginImageContext(CGSizeMake(__WIDTH,
                                           __HEIGHT));
    context = UIGraphicsGetCurrentContext();
    
    switch (kind) {
        case PKNumberPadViewImageLeft:
            CGContextTranslateCTM(context, 6.0, __HEIGHT);
            break;
            
        case PKNumberPadViewImageInner:
            CGContextTranslateCTM(context, 0.0, __HEIGHT);
            break;
            
        case PKNumberPadViewImageRight:
            CGContextTranslateCTM(context, -6.0, __HEIGHT);
            break;
    }
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextAddPath(context, path);
    CGContextClip(context);
    
    //----
    
    CGRect frame = CGPathGetBoundingBox(path);
    CGContextSetFillColorWithColor(context, [[UIColor colorWithRed:0.973 green:0.976 blue:0.976 alpha:1.000] CGColor]);
    CGContextFillRect(context, frame);
    
    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    
    UIImage * image = [UIImage imageWithCGImage:imageRef scale:[[UIScreen mainScreen] scale] orientation:UIImageOrientationDown];
    CGImageRelease(imageRef);
    
    UIGraphicsEndImageContext();
    
    
    CFRelease(path);
    
    return image;
}


@end

