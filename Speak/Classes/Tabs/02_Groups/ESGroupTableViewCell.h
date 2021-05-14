//
//  ESGroupTableViewCell.h
//  app
//
//  Created by Eric Schanet on 08.06.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

/**
 *  Interface declaration of the ESGroupTableViewCell, a tableview cell that is used in the groups view to display the different groups
 */
@interface ESGroupTableViewCell : UITableViewCell

/**
 *  Title of the group
 */
@property (strong, nonatomic)  UILabel *celltitle;
/**
 *  Last message sent in the group
 */
@property (strong, nonatomic)  UILabel *subTitle;
/**
 *  Profile picture of the group
 */
@property (strong, nonatomic)  PFImageView *imgView;
/**
 *  Thin separator line between the cells, in the well-known style of iOS
 */
@property (strong, nonatomic)  UIView *thinLine;
/**
 *  With this method we are binding the data of a group to a specific cell
 *
 *  @param group PFObject of the specific group
 */
- (void)setGroup:(PFObject *)group;

@end
