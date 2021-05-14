//
//  ItemViewController.h
//  app
//
//  Created by Eric Schanet on 24.06.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ESConstants.h"
#import <Parse/Parse.h>
@class ItemViewController;
@protocol ItemViewDelegate <NSObject>
-(void)sendingViewController:(ItemViewController *) controller sentItem:(PFUser *) retItem;
@end
@interface ItemViewController : UITableViewController <UITextFieldDelegate>
@property (assign, nonatomic) id <ItemViewDelegate> delegate;
@end