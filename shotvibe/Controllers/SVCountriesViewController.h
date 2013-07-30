//
//  SVCountriesViewController.h
//  shotvibe
//
//  Created by Baluta Cristian on 28/07/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SVCountryViewCell.h"

@class SVCountriesViewController;

@protocol SVCountriesDelegate

- (void)didSelectCountryWithName:(NSString *)name code:(NSString *)code;

@end


@interface SVCountriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {

	NSArray *allCountryNames;
	NSArray *allCountryCodes;
	NSMutableArray *countryNames;
	NSMutableArray *countryCodes;
	NSDictionary *countryNamesByCode;
	NSDictionary *countryCodesByName;
	NSString *countryCode_;
}

@property (nonatomic) id<SVCountriesDelegate> delegate;
@property (nonatomic, retain) NSString *selectedCountryName;
@property (nonatomic, retain) NSString *selectedCountryCode;
@property (nonatomic, retain) IBOutlet UITableView *countriesTable;
@property (nonatomic, strong) IBOutlet UISearchBar *searchbar;

- (void)setWithLocale:(NSLocale *)locale;

@end