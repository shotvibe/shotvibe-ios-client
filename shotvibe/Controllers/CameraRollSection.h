//
//  CameraRollSection.h
//  shotvibe
//
//  Created by Baluta Cristian on 21/08/2013.
//  Copyright (c) 2013 PicsOnAir Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CameraRollSection : UICollectionReusableView

@property(nonatomic, retain) id delegate;
@property(nonatomic) int section;
@property(nonatomic, retain) IBOutlet UIButton *selectButton;
@property(nonatomic, retain) IBOutlet UILabel *dateLabel;

@end

@protocol CameraRollSectionDelegate <NSObject>

- (void)sectionCheckmarkTouched:(NSNumber*)section;

@end