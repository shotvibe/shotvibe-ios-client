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
@property (nonatomic, retain) IBOutlet UILabel *locationLabel;

- (void)selectCheckmark:(BOOL)s;
- (void)setDateText:(NSString *)s;

@end

@protocol CameraRollSectionDelegate <NSObject>

- (void)sectionCheckmarkTouched:(CameraRollSection*)section;

@end