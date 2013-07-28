//
//  SVCountriesViewController.m
//  shotvibe
//
//  Created by Baluta Cristian on 28/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVCountriesViewController.h"
#import "NBPhoneNumberUtil.h"


@implementation SVCountriesViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
	
	NSString *path = [[NSBundle mainBundle] pathForResource:@"Countries" ofType:@"plist"];
    countryNamesByCode = [[NSDictionary alloc] initWithContentsOfFile:path];
    
    NSMutableDictionary *codesByName = [NSMutableDictionary dictionary];
    for (NSString *code in [countryNamesByCode allKeys])
    {
        [codesByName setObject:code forKey:[countryNamesByCode objectForKey:code]];
    }
    countryCodesByName = [codesByName copy];
    
    NSArray *names = [countryNamesByCode allValues];
    countryNames = [names sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    NSMutableArray *codes = [NSMutableArray arrayWithCapacity:[names count]];
    for (NSString *name in countryNames)
    {
        [codes addObject:[countryCodesByName objectForKey:name]];
    }
    countryCodes = [codes copy];
	
	countryCode_ = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
}
- (void)viewDidAppear:(BOOL)animated{
	
	for (int i=0; i<countryCodes.count; i++) {
		if ([[countryCodes objectAtIndex:i] isEqualToString:countryCode_]) {
			[self.countriesTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
			break;
		}
	}
}


- (void)setWithLocale:(NSLocale *)locale
{
    self.selectedCountryCode = [locale objectForKey:NSLocaleCountryCode];
}





#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [countryNames count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SVCountryViewCell *cell = (SVCountryViewCell*)[tableView dequeueReusableCellWithIdentifier:@"SVCountryViewCell"];
    
	NSInteger countryCode = [[NBPhoneNumberUtil sharedInstance] getCountryCodeForRegion:[countryCodes objectAtIndex:indexPath.row]];
	
    cell.title.text = [countryNames objectAtIndex:indexPath.row];
    cell.code.text = [NSString stringWithFormat:@"+%i", countryCode];
	cell.countryImage.image = [UIImage imageNamed:[countryCodes objectAtIndex:indexPath.row]];
	
	if ([countryCode_ isEqualToString:[countryCodes objectAtIndex:indexPath.row]]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    
    return cell;
}


//- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
//{
//    return alphabet;
//}


//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
//{
//	NSArray *arr = [self.records objectForKey:[alphabet objectAtIndex:section]];
//	
//    if ([arr count] > 0) {
//        return [alphabet objectAtIndex:section];
//    }
//	
//    return nil;
//}


#pragma mark - TableviewDelegate Methods


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
	NSLog(@"1 %@", self.delegate);
	[self.delegate didSelectCountryWithName:[countryNames objectAtIndex:indexPath.row] code:[countryCodes objectAtIndex:indexPath.row]];
	NSLog(@"1");
	[self dismissViewControllerAnimated:YES completion:nil];
	NSLog(@"1");
}




@end
