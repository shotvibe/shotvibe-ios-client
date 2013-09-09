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

- (void)didSelectCountryWithName:(NSString *)name regionCode:(NSString *)regionCode;

@end


@interface SVCountriesViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {

	NSArray *allCountryNames;
	NSArray *allCountryCodes;
	NSMutableArray *countryNames;
	NSMutableArray *countryCodes;
	NSDictionary *countryNamesByCode;
	NSDictionary *countryCodesByName;
	
	IBOutlet UITableView *countriesTable;
	IBOutlet UISearchBar *searchbar;
}

@property (nonatomic) id<SVCountriesDelegate> delegate;
@property (nonatomic, retain) NSString *regionCode;

@end