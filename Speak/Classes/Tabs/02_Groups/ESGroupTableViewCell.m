//
//  ESGroupTableViewCell.m
//  app
//
//  Created by Eric Schanet on 08.06.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import "ESGroupTableViewCell.h"

@implementation ESGroupTableViewCell

@synthesize imgView,celltitle,subTitle,thinLine;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        imgView = [[PFImageView alloc]initWithFrame:CGRectMake(10, 10, 50, 50)];
        celltitle = [[UILabel alloc]initWithFrame:CGRectMake(80, 14, [UIScreen mainScreen].bounds.size.width - 70, 20)];
        subTitle = [[UILabel alloc]initWithFrame:CGRectMake(80, 33, [UIScreen mainScreen].bounds.size.width - 70, 20)];
        thinLine = [[UIView alloc]init];
        [self.contentView addSubview:imgView];
        [self.contentView addSubview:celltitle];
        [self.contentView addSubview:subTitle];
        [self.contentView addSubview:thinLine];

    }
    
    return self;
}
- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (void)layoutSubviews {
    [super layoutSubviews];

    imgView.frame = CGRectMake(10, 10, 50, 50);
    celltitle.frame = CGRectMake(70, 12, [UIScreen mainScreen].bounds.size.width - 70, 30);
    subTitle.frame = CGRectMake(70, 30, [UIScreen mainScreen].bounds.size.width - 70, 30);
    imgView.layer.cornerRadius = 25;
    imgView.layer.masksToBounds = YES;

    celltitle.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
    
    subTitle.textColor = [UIColor lightGrayColor];
    subTitle.font = [UIFont fontWithName:@"HelveticaNeue" size:13];
    
}
- (void)setGroup:(PFObject *)group {
    if (![group objectForKey:kESUserPicture]) {
        [imgView setImage:[UIImage imageNamed:@"group_placeholder"]];
    }
    else {
        [imgView setFile:[group objectForKey:kESUserPicture]];
        [imgView loadInBackground];
        
    }
    celltitle.text = group[kESGroupName];
    
    subTitle.text = [NSString stringWithFormat:@"%d members", (int) [group[kESGroupMembers] count]];

    thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    thinLine.frame = CGRectMake(20, 69.5, [UIScreen mainScreen].bounds.size.width, 0.5);

}
@end
