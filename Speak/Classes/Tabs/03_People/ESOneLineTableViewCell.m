//
//  ESOneLineTableViewCell.m
//  app
//
//  Created by Eric Schanet on 24.06.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import "ESOneLineTableViewCell.h"

@implementation ESOneLineTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(20,5,40,40);
    self.textLabel.frame = CGRectMake(70, 15, [UIScreen mainScreen].bounds.size.width - 80, 20);

}
@end
