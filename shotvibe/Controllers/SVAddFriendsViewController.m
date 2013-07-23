//
//  SVAddFriendsViewController.m
//  shotvibe
//
//  Created by John Gabelmann on 4/12/13.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import "SVAddFriendsViewController.h"
#import "SVAddressBookBD.h"
#import "SVDefines.h"


@interface SVAddFriendsViewController ()<UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIScrollView *addedContactsScrollView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (nonatomic, strong) NSArray *records;
@property (nonatomic, strong) NSMutableArray *contactsToAdd;

- (IBAction)cancelPressed:(id)sender;
- (NSArray *)filterNonAlphabetContacts:(NSArray *)contacts;

@end

@implementation SVAddFriendsViewController
{
    NSArray *alphabet;
}

#pragma mark - Actions

- (IBAction)donePressed:(id)sender {
    // add members to album
    //TODO if already shotvibe member just add to album else sent notification to user to join?
    NSLog(@"contacts to add >> %@", self.contactsToAdd);
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)cancelPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        //show shotvibe
        [self loadShotVibeContacts];
    }else{
        //show phone contacts
        [self loadAddressbookContacts];
    }
}


#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    CGRect segmentFrame = self.segmentControl.frame;
    segmentFrame.origin.y -= 1.5;
    self.segmentControl.frame = segmentFrame;
    
    self.contactsToAdd = [[NSMutableArray alloc] init];
    self.records = nil;
    
    alphabet = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O", @"P", @"Q", @"R", @"S", @"T", @"U", @"V", @"W", @"X", @"Y", @"Z", @"#"];
    
    [self loadShotVibeContacts];
}


#pragma mark -
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return alphabet.count;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == alphabet.count - 1) {
        return [[self filterNonAlphabetContacts:self.records] count];
    }
    
    return [[self.records filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", kMemberFirstName, [alphabet objectAtIndex:section]]] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    return alphabet;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
 
    if ([[self filterNonAlphabetContacts:self.records] count] > 0 && section == alphabet.count - 1) {
        return [alphabet objectAtIndex:section];
    }
    
    if ([[self.records filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", kMemberFirstName, [alphabet objectAtIndex:section]]] count] > 0) {
        return [alphabet objectAtIndex:section];
    }
    
    return nil;
}


#pragma mark - TableviewDelegate Methods


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.searchBar resignFirstResponder];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *tappedCell = [tableView cellForRowAtIndexPath:indexPath];
    if ([tappedCell.imageView isEqual:[UIImage imageNamed:@"contactCellCheckmark_active"]]) {
        return;
    }
    if (![self.contactsToAdd containsObject:[self.records objectAtIndex:indexPath.row]]) {
        [tappedCell.imageView setImage:[UIImage imageNamed:@"contactCellCheckmark_active"]];
        //add tapped contact to contact holder
        [self.contactsToAdd addObject:[self.records objectAtIndex:indexPath.row]];
        
        [self updateToField];
    }
}


#pragma mark -
#pragma mark Search

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [SVAddressBookBD searchContactsWithString:searchText WithCompletion:^(NSArray *albums, NSError *error) {
        self.records = albums;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}


#pragma mark - Private Methods

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSArray *filteredRecords = nil;
    
    if (indexPath.section == alphabet.count - 1) {
        filteredRecords = [self filterNonAlphabetContacts:self.records];
    }
    else
    {
        filteredRecords = [self.records filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"%K BEGINSWITH[cd] %@", kMemberFirstName, [alphabet objectAtIndex:indexPath.section]]];
    }
    
    cell.textLabel.text = [[filteredRecords objectAtIndex:indexPath.row] objectForKey:kMemberNickname];
    cell.detailTextLabel.text = [[filteredRecords objectAtIndex:indexPath.row] objectForKey:kMemberPhone];
    
    if ([self.contactsToAdd containsObject:[self.records objectAtIndex:indexPath.row]]) {
        cell.imageView.image = [UIImage imageNamed:@"contactCellCheckmark_active"];
    }else{
        cell.imageView.image = [UIImage imageNamed:@"contactCellCheckmark_inactive"];
    }
    
}


-(void)updateToField
{
    //remove any current buttons
    for (UIView *v in self.addedContactsScrollView.subviews) {
        if (![v isKindOfClass:[UIImageView class]]) {
            [v removeFromSuperview];
        }
    }
    
    int x = 5;
    //create a new dynamic button
    for ( int j = 0; j<[self.contactsToAdd count]; j++)
    {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        
        NSDictionary *contactDic = [self.contactsToAdd objectAtIndex:j];
        [button setTitle:[contactDic objectForKey:kMemberFirstName] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
        [button setTag:j];
        [button sizeToFit];
        
        [button setBackgroundImage:[[UIImage imageNamed:@"contactsStreachableButton_normal"] stretchableImageWithLeftCapWidth:45.0 topCapHeight:0.0] forState:UIControlStateNormal];

        [button setBackgroundImage:[[UIImage imageNamed:@"contactsStreachableButton_down"] stretchableImageWithLeftCapWidth:45.0 topCapHeight:0.0] forState:UIControlStateHighlighted];
        
        [button addTarget:self action:@selector(removeContactFromList:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.addedContactsScrollView addSubview:button];
        
        CGRect frame = CGRectMake(x, 10, button.frame.size.width, 30);
        button.frame = frame;
        
        x = x + button.frame.size.width + 5;
        
        [self.addedContactsScrollView setContentSize:(CGSizeMake(x, self.addedContactsScrollView.frame.size.height))];
    }
}

-(void)removeContactFromList:(UIButton *)sender
{
    [self.contactsToAdd removeObjectAtIndex:sender.tag];
    
    [self updateToField];
    
    [self.tableView reloadData];
}


-(void)loadShotVibeContacts
{
    self.records = nil;
    [self.tableView reloadData];
}

-(void)loadAddressbookContacts
{
    [SVAddressBookBD searchContactsWithString:nil WithCompletion:^(NSArray *albums, NSError *error) {
        self.records = albums;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    }];
}


- (NSArray *)filterNonAlphabetContacts:(NSArray *)contacts
{
    return [contacts filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSDictionary * evaluatedObject, NSDictionary *bindings) {
        
        BOOL result = YES;
        NSString * firstName = [evaluatedObject objectForKey:kMemberFirstName];
        
        for (NSString *letter in alphabet) {
            
            if ([letter isEqualToString:@"#"]) {
                break;
            }
            else if ([[firstName lowercaseString] hasPrefix:[letter lowercaseString]]) {
                result = NO;
            }
        }
        
        return result;
    }]];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
