//
// Copyright (c) 2015 Eric Schanet
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ESProfileView.h"
#import "NavigationController.h"
#import "JTSImageViewController.h"
#import "JTSImageInfo.h"
#import "ESUtility.h"

@interface ESProfileView()
{
    /**
     *  String of the user's Id
     */
	NSString *userId;
    /**
     *  The actual PFUser
     */
	PFUser *user;
}
/**
 *  This is the header of the profile page, containing all the labels and pictures
 */
@property (strong, nonatomic) IBOutlet UIView *viewHeader;
/**
 *  ImageView of the user's profile picture
 */
@property (strong, nonatomic) IBOutlet PFImageView *imageUser;
/**
 *  Label of the user's name
 */
@property (strong, nonatomic) IBOutlet UILabel *labelName;
/**
 *  Label of the user's bio
 */
@property (strong, nonatomic) IBOutlet UILabel *bioView;
/**
 *  Blurred profile picture, used as a header picture
 */
@property (strong, nonatomic) UIImageView *blurredBackground;
/**
 *  A report cell, used to report the user in case he has infringed the terms
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellReport;
/**
 *  A block cell, used to block the user
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellBlock;
/**
 *  Intercepting touches on the profile picture of the user
 */
@property (strong, nonatomic) UIButton *profileImageButton;

@end

@implementation ESProfileView

@synthesize viewHeader, imageUser, labelName, bioView;
@synthesize cellReport, cellBlock, profileImageButton, blurredBackground;

- (id)initWith:(NSString *)userId_ andUser:(PFUser *)user_
{
	self = [super init];
	userId = userId_;
    user = user_;
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"PROFILE";
	self.tableView.tableHeaderView = viewHeader;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"More_Options_64"] style:UIBarButtonItemStyleDone target:self action:@selector(showBlockFunctionality)];
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
    imageUser.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 35, 15, 70, 70);
    labelName.frame = CGRectMake(5, 95, [UIScreen mainScreen].bounds.size.width - 10, 30);
    viewHeader.frame = CGRectMake(viewHeader.frame.origin.x, viewHeader.frame.origin.y, [UIScreen mainScreen].bounds.size.width, 140);
    bioView.alpha = 0;
    
    labelName.text = user[kESUserFullname];
    [imageUser setFile:user[kESUserBigPicture]];
				[imageUser loadInBackground];


    profileImageButton = [[UIButton alloc] initWithFrame:imageUser.frame];
    [profileImageButton addTarget:self action:@selector(didTapAvatar) forControlEvents:UIControlEventTouchDown];
    [viewHeader addSubview:profileImageButton];
    
    blurredBackground = [[UIImageView alloc]initWithImage:imageUser.image];
    blurredBackground.frame = viewHeader.frame;
    blurredBackground.contentMode = UIViewContentModeScaleToFill;
    [viewHeader insertSubview:blurredBackground atIndex:0];
    
    // create effect
    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    
    // add effect to an effect view
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
    effectView.frame = blurredBackground.frame;
    
    // add the effect view to the image view
    [blurredBackground addSubview:effectView];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}
- (void)viewWillAppear:(BOOL)animated {
}

#pragma mark - Backend actions

- (void)loadUser
{
	PFQuery *query = [PFQuery queryWithClassName:kESUserClassName];
	[query whereKey:kESUserObjectID equalTo:userId];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
	{
		if (error == nil)
		{
			user = [objects firstObject];
			if (user != nil)
			{
				[imageUser setFile:user[kESUserPicture]];
				[imageUser loadInBackground];
				
				labelName.text = user[kESUserFullname];
                
                NSString *string = [user objectForKey:@"UserInfo"];
                if (string) {
                    bioView.text = string;
                    CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width - 80,FLT_MAX);
                    NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
                    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;

                    CGSize expectedLabelSize = [string boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:16], NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
                    
                    bioView.frame = CGRectMake(40, labelName.frame.origin.y + labelName.frame.size.height + 10, [UIScreen mainScreen].bounds.size.width - 80, expectedLabelSize.height);
                     viewHeader.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, labelName.frame.origin.y + labelName.frame.size.height + expectedLabelSize.height + 20);
                    
                    [UIView beginAnimations:nil context:nil];
                    [UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
                    [UIView setAnimationDelegate:self];
                    [UIView setAnimationDuration:0.2];
                    bioView.alpha = 1;
                    self.tableView.tableHeaderView = viewHeader;
                    [UIView commitAnimations];
                    
                }
			}
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - User actions
- (void)didTapAvatar {
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
#if TRY_AN_ANIMATED_GIF == 1
    imageInfo.imageURL = [NSURL URLWithString:@"http://media.giphy.com/media/O3QpFiN97YjJu/giphy.gif"];
#else
    imageInfo.image = imageUser.image;
#endif
    imageInfo.referenceRect = imageUser.frame;
    imageInfo.referenceView = imageUser.superview;
    imageInfo.referenceContentMode = imageUser.contentMode;
    imageInfo.referenceCornerRadius = imageUser.layer.cornerRadius;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
    
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}
- (void)actionReport
{
	UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
										  destructiveButtonTitle:nil otherButtonTitles:@"Report user", nil];
	action.tag = 1;
	[action showInView:self.view];
}

- (void)actionBlock
{
	UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
										  destructiveButtonTitle:@"Block user" otherButtonTitles:nil];
	action.tag = 2;
	[action showInView:self.view];
}
- (void) showBlockFunctionality {
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:@"Block user" otherButtonTitles:@"Report user", nil];
    action.tag = 3;
    [action showInView:self.view];
}
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == 1) [self actionSheet:actionSheet clickedButtonAtIndex1:buttonIndex];
	if (actionSheet.tag == 2) [self actionSheet:actionSheet clickedButtonAtIndex2:buttonIndex];
    if (actionSheet.tag == 3) {
        if (buttonIndex == 1) {
            if (user != nil)
            {
                [ESUtility reportUser:user];
            }
        }
        else if (buttonIndex == actionSheet.destructiveButtonIndex) {
            [ESUtility blockUser:user];
            [ProgressHUD show:nil Interaction:NO];
            [self performSelector:@selector(delayedPopToRootViewController) withObject:nil afterDelay:1.0];

        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex1:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		if (user != nil)
		{
            [ESUtility reportUser:user];
		}
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex2:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		if (user != nil)
		{
            [ESUtility blockUser:user];
			[ProgressHUD show:nil Interaction:NO];
			[self performSelector:@selector(delayedPopToRootViewController) withObject:nil afterDelay:1.0];
		}
	}
}

- (void)delayedPopToRootViewController
{
	[ProgressHUD dismiss];
	[self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *string = [user objectForKey:@"UserInfo"];
    if (string) {
        CGSize maximumLabelSize = CGSizeMake([UIScreen mainScreen].bounds.size.width - 80,FLT_MAX);
        NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        
        CGSize expectedLabelSize = [string boundingRectWithSize:maximumLabelSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue" size:16], NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
        if (expectedLabelSize.height + 10 < 50) {
            return 50;
        }
        return expectedLabelSize.height + 10;
    }
    else return 50;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 0) && (indexPath.row == 0)) {
        NSString *string = [user objectForKey:@"UserInfo"];
        if (string) {
            cellReport.textLabel.text = string;
        }
        else cellReport.textLabel.text = @"User has not yet provided any info about himself.";

        cellReport.userInteractionEnabled = NO;
        return cellReport;
        
        
    }
	return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
