//
//  ESPageViewController.h
//  app
//
//  Created by Eric Schanet on 30.05.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

/**
 *  Interface declaration of the page view controller, the controller that is displayed in the welcome view and holds a short insight of the app's features
 */
@interface ESPageViewController : UIViewController
/**
 *  Index of the displayed page
 */
@property NSUInteger pageIndex;
/**
 *  Name of the displayed png file
 */
@property NSString *imgFile;
/**
 *  Title label displayed near the images
 */
@property (strong, nonatomic) IBOutlet UILabel *lblScreenLabel;
/**
 *  Subtitle lable displayed near the images
 */
@property (strong, nonatomic) IBOutlet UILabel *lblScreenSubLabel;
/**
 *  Some text for the title
 */
@property NSString *txtTitle;
/**
 *  Some text for the subtitle
 */
@property NSString *subTxtTitle;
/**
 *  Actual image shown in the respective controller
 */
@property (strong, nonatomic) IBOutlet UIImageView *ivScreenImage;
@end
