//
//  LDCollectionViewCell.h
//  LivelyDemo
//
//  Created by Patrick Nollet on 07/03/2014.
//
//

#import <UIKit/UIKit.h>
#import "AlbumPhoto.h"

@interface LDCollectionViewCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *cellImage;
@property (retain, nonatomic) IBOutlet UILabel * textLabel;
@property (nonatomic, retain) SLAlbumPhoto * cellSlPhoto;
@property (nonatomic, retain) UIImageView * videoBadge;
@end
