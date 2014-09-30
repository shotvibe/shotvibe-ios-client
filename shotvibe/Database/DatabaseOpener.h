//
//  DatabaseOpener.h
//  shotvibe
//
//  Created by raptor on 9/18/14.
//  Copyright (c) 2014 PicsOnAir Ltd. All rights reserved.
//

#import <SL/SQLDatabaseRecipe.h>

#import <Foundation/Foundation.h>

@interface DatabaseOpener : NSObject

+ (id)open:(SLSQLDatabaseRecipe *)recipe;

@end
