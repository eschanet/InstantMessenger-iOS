//
//  ESTableViewCell.m
//  app
//
//  Created by Eric Schanet on 23.06.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import "ESTableViewCell.h"

@implementation ESTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(15,5,40,40);
    self.textLabel.frame = CGRectMake(70, 8, [UIScreen mainScreen].bounds.size.width - 80, 20);
    self.detailTextLabel.frame = CGRectMake(70, 25, [UIScreen mainScreen].bounds.size.width - 80, 20);
    self.separatorInset = UIEdgeInsetsMake(0, 70, 0, 0);
}
@end
