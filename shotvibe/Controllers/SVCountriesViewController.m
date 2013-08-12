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
    allCountryNames = [names sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	countryNames = [[NSMutableArray alloc] initWithArray:allCountryNames];
    
	countryCodes = [NSMutableArray arrayWithCapacity:[names count]];
    for (NSString *name in countryNames)
    {
        [countryCodes addObject:[countryCodesByName objectForKey:name]];
    }
	allCountryCodes = [[NSArray alloc] initWithArray:countryCodes];
	
	countryCode_ = [[NSUserDefaults standardUserDefaults] stringForKey:kUserCountryCode];
	if (countryCode_ == nil)
		countryCode_ = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
	
	// Configure views
	
	self.searchbar.backgroundImage = [UIImage imageNamed:@"searchFieldBg.png"];
	[self.searchbar setSearchFieldBackgroundImage:[UIImage imageNamed:@"butTransparent.png"] forState:UIControlStateNormal];
	[self.searchbar setImage:[UIImage imageNamed:@"searchFieldIcon.png"] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
	
}

- (void)viewDidAppear:(BOOL)animated{
	
	for (int i=0; i<countryCodes.count; i++) {
		if ([[countryCodes objectAtIndex:i] isEqualToString:countryCode_]) {
			[self.countriesTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:NO];
			break;
		}
	}
}


- (NSString*) selectedCountryCode {
	return countryCode_;
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
	countryCode_ = [countryCodes objectAtIndex:indexPath.row];
	[[tableView cellForRowAtIndexPath:indexPath] setSelected:NO];
	
	[self.delegate didSelectCountryWithName:[countryNames objectAtIndex:indexPath.row] code:[countryCode_ copy]];
	
	[self.navigationController popViewControllerAnimated:YES];
}





#pragma mark - UISearchbarDelegate Methods

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
	[self filterCountriesBy:searchBar.text];
	self.countriesTable.frame = CGRectMake(0, 44, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height-216-45-44-20);
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self filterCountriesBy:searchBar.text];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self filterCountriesBy:searchBar.text];
    [searchBar resignFirstResponder];
	self.countriesTable.frame = CGRectMake(0, 44, self.view.frame.size.width, [UIScreen mainScreen].bounds.size.height-45-44-20);
}

- (void) filterCountriesBy:(NSString*)term {
	
	if (term == nil || [term isEqualToString:@""]) {
		
		countryNames = [NSMutableArray arrayWithArray:allCountryNames];
		countryCodes = [NSMutableArray arrayWithArray:allCountryCodes];
	}
	else {
		
		countryNames = [NSMutableArray array];
		countryCodes = [NSMutableArray array];
		
		for (int i = 0; i<allCountryNames.count; i++) {
			
			if ([[[allCountryNames objectAtIndex:i] lowercaseString] rangeOfString:[term lowercaseString]].location != NSNotFound) {
				
				[countryNames addObject:[allCountryNames objectAtIndex:i]];
				[countryCodes addObject:[allCountryCodes objectAtIndex:i]];
			}
		}
	}
	
	[self.countriesTable reloadData];
}




@end
