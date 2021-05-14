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

#import "ESSettingsView.h"
#import "ESBlockedView.h"
#import "ESPrivacyView.h"
#import "ESTermsView.h"
#import "NavigationController.h"
#import "RFAboutViewController.h"

#import "AppDelegate.h"

#define MAX_LENGTH 110

@interface ESSettingsView() {
    FIRDatabaseReference *con;
    FIRDatabaseReference *lastOnlineRef;
}
/**
 *  Header of the view, containing the information about the user
 */
@property (strong, nonatomic) IBOutlet UIView *viewHeader;
/**
 *  Profile picture of the user, contained in the header view
 */
@property (strong, nonatomic) IBOutlet PFImageView *imageUser;
@property (strong, nonatomic) IBOutlet UIButton *imageUserButton;
/**
 *  Name of the user
 */
@property (strong, nonatomic) IBOutlet UILabel *labelName;
/**
 *  Header picture, currently a blurred version of the profile picture
 */
@property (strong, nonatomic) UIImageView *blurredBackground;
/**
 *  Cell that is taking the user to the view containing the blocked users
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellBlocked;
/**
 *  Cell with a switch defining if the user wants to receive push notifications or not
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPushes;
/**
 *  Cell with a switch defining if the user wants to appear as online or not
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellOnlineIndicator;
/**
 *  Cell with a switch defining if the user wants to send read receipts in the chat or not
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellReadLabel;
/**
 *  Cell that initially contained the privacy html but now contains the bio textview
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPrivacy;
/**
 *  Cell taking the user to the about view
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellTerms;
/**
 *  Cell used to log the user out
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellLogout;

@property (strong, nonatomic) UISwitch *switchPushes;
@property (strong, nonatomic) UISwitch *switchOnlineIndicator;
@property (strong, nonatomic) UISwitch *switchReadLabel;

@end

@implementation ESSettingsView

@synthesize viewHeader, imageUser, imageUserButton, labelName, saveInfoBtn, cancelBtn;
@synthesize cellBlocked, cellPrivacy, cellTerms, cellLogout, bioTextview, cellOnlineIndicator,cellPushes,cellReadLabel,switchOnlineIndicator,switchPushes,switchReadLabel, blurredBackground;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		[self.tabBarItem setImage:[UIImage imageNamed:@"tab_settings"]];
		self.tabBarItem.title = @"Settings";
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userOnline) name:kESNotificationAppStarted object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userOnline) name:kESNotificationUserLogin object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userOffline) name:kESNotificationUserLogout object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userOffline) name:UIApplicationWillResignActiveNotification object:nil];

	}
	return self;
}
- (void)userOnline {
    
    
    if ([PFUser currentUser]) {
        NSUserDefaults *defaults= [NSUserDefaults standardUserDefaults];
        if([[[defaults dictionaryRepresentation] allKeys] containsObject:[NSString stringWithFormat:@"%@-showOnline", [PFUser currentUser].objectId]]){
            if ([[defaults objectForKey:[NSString stringWithFormat:@"%@-showOnline", [PFUser currentUser].objectId]] isEqualToString:@"ON"]) {
                [self setOnline];
            }
        }
        else {
            if ([[PFUser currentUser]objectForKey:@"showOnline"] && [[[PFUser currentUser]objectForKey:@"showOnline"] isEqualToString:@"ON"]) {
                [self setOnline];
            }
            else if (![[PFUser currentUser]objectForKey:@"showOnline"]) {
                [self setOnline];
            }
        }
    }
}
- (void) setOnline {
    FIRDatabaseReference *myConnectionsRef = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"users/%@/connections", [[PFUser currentUser] objectForKey:kESUserFirebaseID]]];

    lastOnlineRef = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"users/%@/lastonline", [[PFUser currentUser] objectForKey:kESUserFirebaseID]]];
    
    FIRDatabaseReference *connectedRef = [[[FIRDatabase database] reference] child:@".info/connected"];

    [connectedRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot) {
        if([snapshot.value boolValue]) {
            
            con = [myConnectionsRef childByAutoId];
            [con setValue:@YES];
            
            [con onDisconnectRemoveValue];
            
            [lastOnlineRef onDisconnectSetValue:[FIRServerValue timestamp]];
        }
    }];
}
- (void)userOffline {
    NSUserDefaults *defaults= [NSUserDefaults standardUserDefaults];
    if([[[defaults dictionaryRepresentation] allKeys] containsObject:[NSString stringWithFormat:@"%@-showOnline", [PFUser currentUser].objectId]]){
        if ([[defaults objectForKey:[NSString stringWithFormat:@"%@-showOnline", [PFUser currentUser].objectId]] isEqualToString:@"ON"]) {
            [lastOnlineRef setValue:[FIRServerValue timestamp]];
            [[FIRAuth auth] signOut:nil];
        }
    }
    else {
        if ([[PFUser currentUser]objectForKey:@"showOnline"] && [[[PFUser currentUser]objectForKey:@"showOnline"] isEqualToString:@"ON"]) {
            [lastOnlineRef setValue:[FIRServerValue timestamp]];
            [[FIRAuth auth] signOut:nil];
        }
        else if (![[PFUser currentUser]objectForKey:@"showOnline"]) {
            [lastOnlineRef setValue:[FIRServerValue timestamp]];
            [[FIRAuth auth] signOut:nil];
        }
    }

    FIRDatabaseReference *myConnectionsRef = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"users/%@/connections", [[PFUser currentUser] objectForKey:kESUserFirebaseID]]];
    [myConnectionsRef removeValue];

}
- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"SETTINGS";
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Settings" style:UIBarButtonItemStylePlain target:nil action:nil];

	self.tableView.tableHeaderView = viewHeader;
    viewHeader.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 140);
    labelName.frame = CGRectMake(0, 95, viewHeader.frame.size.width, 30);
	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
    imageUser.frame = CGRectMake(viewHeader.frame.size.width/2 - 35, 15, 70, 70);
    
    imageUserButton.frame = imageUser.frame;
    [imageUserButton addTarget:self action:@selector(actionPhoto:) forControlEvents:UIControlEventTouchDown];
    [self.view bringSubviewToFront:imageUserButton];
    
    
    saveInfoBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(actionSaveInformation)];
    self.navigationItem.rightBarButtonItem = saveInfoBtn;
    saveInfoBtn.enabled = NO;
    saveInfoBtn.tintColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    
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
	if ([PFUser currentUser] != nil)
	{
		[self loadUser];
	}
	else [ESUtility loginUser:self];
}

#pragma mark - Backend actions

- (void)loadUser
{
	PFUser *user = [PFUser currentUser];
    [user fetchInBackground];
    
	[imageUser setFile:user[kESUserBigPicture]];
    [imageUser loadInBackground:^(UIImage *image, NSError *error){
        if (!error) {
            blurredBackground.image = image;
        }
    }];

	labelName.text = user[kESUserFullname];
}

#pragma mark - User actions

- (void)actionBlocked
{
	ESBlockedView *blockedView = [[ESBlockedView alloc] init];
	blockedView.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:blockedView animated:YES];
}

- (void)actionBio
{
	
}

- (void)actionAbout
{
    UINavigationController *aboutNavigation = [UINavigationController new];
    
    RFAboutViewController *aboutView = [[RFAboutViewController alloc] initWithAppName:nil appVersion:nil appBuild:nil copyrightHolderName:@"Eric Schanet, All Rights Reserved" contactEmail:@"eric@codelight.lu" titleForEmail:@"Contact us" websiteURL:[NSURL URLWithString:@"http://codelight.lu"] titleForWebsiteURL:@"codelight.lu" andPublicationYear:nil];
    
    aboutView.headerBackgroundColor = [UIColor blackColor];
    aboutView.headerBorderColor = [UIColor clearColor];
    aboutView.tableViewTextColor = [UIColor colorWithWhite:0.2 alpha:1];
    aboutView.headerTextColor = [UIColor whiteColor];
    aboutView.blurStyle = UIBlurEffectStyleLight;
    aboutView.headerBackgroundImage = [UIImage imageNamed:@"about_header_bg.jpg"];
    aboutView.showAcknowledgements = NO;

    [aboutView addAdditionalButtonWithTitle:@"Privacy Policy" andContent:@""];
    [aboutView addAdditionalButtonWithTitle:@"Terms of Service" andContent:@""];
    [aboutView addAdditionalButtonWithTitle:@"Third Parties" andContent:@""];
    [aboutView addAdditionalButtonWithTitle:@"Third Parties" andContent:@""];

    [aboutNavigation setViewControllers:@[aboutView]];
    
    [self presentViewController:aboutNavigation animated:YES completion:nil];
}
- (void)actionCancel {
    [bioTextview resignFirstResponder];
    saveInfoBtn.enabled = NO;
    saveInfoBtn.tintColor = [UIColor lightGrayColor];

    if ([[PFUser currentUser] objectForKey:@"UserInfo"]) {
        bioTextview.text = [[PFUser currentUser] objectForKey:@"UserInfo"];
        bioTextview.textColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1];
    } else {
        bioTextview.text = NSLocalizedString(@" Place your bio here", nil);
        bioTextview.textColor=[UIColor lightGrayColor];
    }
    self.navigationItem.leftBarButtonItem = nil;
}
- (void)actionCleanup
{
	imageUser.image = [UIImage imageNamed:@"settings_blank"];
	labelName.text = nil;
}

- (void)actionLogout
{
	UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
										  destructiveButtonTitle:@"Log out" otherButtonTitles:nil];
	[action showFromTabBar:[[self tabBarController] tabBar]];
}
- (void)actionSaveInformation {

    [bioTextview resignFirstResponder];
    self.navigationItem.leftBarButtonItem = nil;
    [[PFUser currentUser] setObject:[bioTextview text] forKey:@"UserInfo"];
    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [ProgressHUD showSuccess:@"Bio successfully saved"];
            saveInfoBtn.enabled = NO;
            saveInfoBtn.tintColor = [UIColor lightGrayColor];
        }
        else {
            [ProgressHUD showError:@"Connection error. Please try again later."];
        }
    }];
}
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
        [ESUtility parsePushUserResign];
        
        [ESUtility postNotification:kESNotificationUserLogout];
		[self actionCleanup];
        [PFUser logOut];
        [[UIApplication sharedApplication] unregisterForRemoteNotifications];
        [ESUtility loginUser:self];

	}
}

- (IBAction)actionPhoto:(id)sender
{
    [ESUtility presentPhotoLibrary:self editable:YES];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	UIImage *image = info[UIImagePickerControllerEditedImage];
    UIImage *full_picture = [ESUtility resizedImage:image withWidth:400 withHeight:400];
    UIImage *picture = [ESUtility resizedImage:image withWidth:140 withHeight:140];
    UIImage *thumbnail = [ESUtility resizedImage:image withWidth:60 withHeight:60];
	imageUser.image = full_picture;
    blurredBackground.image = full_picture;

    PFFile *fileFullPicture = [PFFile fileWithName:@"fullpicture.jpg" data:UIImageJPEGRepresentation(full_picture, 0.8)];
    [fileFullPicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error != nil) [ProgressHUD showError:@"Network error."];
     }];
	PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(picture, 0.6)];
	[filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil) [ProgressHUD showError:@"Network error."];
	}];
	PFFile *fileThumbnail = [PFFile fileWithName:@"thumbnail.jpg" data:UIImageJPEGRepresentation(thumbnail, 0.6)];
	[fileThumbnail saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil) [ProgressHUD showError:@"Network error."];
	}];
	PFUser *user = [PFUser currentUser];
    user[kESUserPicture] = filePicture;
    user[kESUserBigPicture] = fileFullPicture;
	user[kESUserThumbnail] = fileThumbnail;
	[user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error != nil) [ProgressHUD showError:@"Network error."];
	}];
	[picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
    if (section == 1) return 3;
    if (section == 2) return 2;
	if (section == 3) return 1;
	return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 0) return 45;
    }

    return 45;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ((indexPath.section == 2) && (indexPath.row == 0)) {
       // cellBlocked.imageView.image = [UIImage imageNamed:@"X_Button_64"];
        cellBlocked.textLabel.text = @"Blocked users";
        return cellBlocked;
    }
    else if ((indexPath.section == 2) && (indexPath.row == 1)) {
       // cellTerms.imageView.image = [UIImage imageNamed:@"Written_conversation_speech_bubble_with_letter_i_inside_of_information_for_interface_64"];
        return cellTerms;
    }
    else if ((indexPath.section == 0) && (indexPath.row == 0)) {

        bioTextview=[[UITextView alloc] initWithFrame:CGRectMake(10, 5, [UIScreen mainScreen].bounds.size.width - 20, 30)];
        bioTextview.font = [UIFont systemFontOfSize:16.0];
        bioTextview.text = NSLocalizedString(@" Place your bio here", nil);
        bioTextview.textColor=[UIColor lightGrayColor];
        [[PFUser currentUser] fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            if (!error) {
                if ([[PFUser currentUser] objectForKey:@"UserInfo"] && ![[[PFUser currentUser] objectForKey:@"UserInfo"] isEqualToString:@" Place your bio here"]) {
                    bioTextview.text = [[PFUser currentUser] objectForKey:@"UserInfo"];
                    bioTextview.textColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1];
                } else {
                    bioTextview.text = NSLocalizedString(@" Place your bio here", nil);
                    bioTextview.textColor=[UIColor lightGrayColor];
                }
            }
            else {
                [ProgressHUD showError:@"Connection error"];
                if ([[PFUser currentUser] objectForKey:@"UserInfo"] && ![[[PFUser currentUser] objectForKey:@"UserInfo"] isEqualToString:@" Place your bio here"]) {
                    bioTextview.text = [[PFUser currentUser] objectForKey:@"UserInfo"];
                    bioTextview.textColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1];
                } else {
                    bioTextview.text = NSLocalizedString(@" Place your bio here", nil);
                    bioTextview.textColor=[UIColor lightGrayColor];
                }
            }
        }];
        bioTextview.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        bioTextview.backgroundColor = [UIColor clearColor];
        bioTextview.editable=YES;
        bioTextview.keyboardType = UIKeyboardTypeDefault;
        bioTextview.returnKeyType = UIReturnKeyDone;
        bioTextview.autocorrectionType = UITextAutocorrectionTypeNo; // no auto correction support
        bioTextview.textAlignment = NSTextAlignmentLeft;
        bioTextview.delegate = self;
        
        
        [cellPrivacy.contentView addSubview:bioTextview];

        return cellPrivacy;
    }
    else if ((indexPath.section == 1) && (indexPath.row == 0)) {
        switchPushes = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchPushes.onTintColor = [UIColor colorWithRed:66.0f/255.0f green:172.0f/255.0f blue:254.0f/255.0f alpha:1.0f];
        cellPushes.accessoryView = switchPushes;
        
        if ([[[PFUser currentUser] objectForKey:@"receivePushes"] isEqualToString:@"OFF"]) [switchPushes setOn:NO animated:NO];
        else if ([[[PFUser currentUser] objectForKey:@"receivePushes"] isEqualToString:@"ON"])[switchPushes setOn:YES animated:NO];
        else if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) [switchPushes setOn:YES animated:NO];
        else [switchPushes setOn:NO animated:NO];
    
        [switchPushes addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];


        return cellPushes;
    }
    else if ((indexPath.section == 1) && (indexPath.row == 1)) {
        switchOnlineIndicator = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchOnlineIndicator.onTintColor = [UIColor colorWithRed:66.0f/255.0f green:172.0f/255.0f blue:254.0f/255.0f alpha:1.0f];

        cellOnlineIndicator.accessoryView = switchOnlineIndicator;

        if ([[[PFUser currentUser] objectForKey:@"showOnline"] isEqualToString:@"OFF"]) [switchOnlineIndicator setOn:NO animated:NO];
        else [switchOnlineIndicator setOn:YES animated:NO];

        [switchOnlineIndicator addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

        
        return cellOnlineIndicator;
    }
    else if ((indexPath.section == 1) && (indexPath.row == 2)) {
        switchReadLabel = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchReadLabel.onTintColor = [UIColor colorWithRed:66.0f/255.0f green:172.0f/255.0f blue:254.0f/255.0f alpha:1.0f];

        cellReadLabel.accessoryView = switchReadLabel;

        if ([[[PFUser currentUser] objectForKey:@"readReceipt"] isEqualToString:@"OFF"]) [switchReadLabel setOn:NO animated:NO];
        else [switchReadLabel setOn:YES animated:NO];

        [switchReadLabel addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];

        
        return cellReadLabel;
    }
    if ((indexPath.section == 3) && (indexPath.row == 0)) {
        return cellLogout;
    }
	return nil;
}

- (void) switchChanged:(id)sender {
    if (sender == switchReadLabel) {
        UIActivityIndicatorView *spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.frame = CGRectMake(switchReadLabel.frame.origin.x - 40, switchReadLabel.frame.origin.y+5, 20, 20);
        [cellReadLabel addSubview:spinner];
        [spinner startAnimating];
        
        switchReadLabel.userInteractionEnabled = NO;
        [[PFUser currentUser] setObject:(switchReadLabel.on ? @"ON" : @"OFF") forKey:@"readReceipt"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            switchReadLabel.userInteractionEnabled = YES;
            if (!error) {
                [spinner stopAnimating];
                [[NSUserDefaults standardUserDefaults] setObject:(switchReadLabel.on ? @"ON" : @"OFF") forKey:[NSString stringWithFormat:@"%@-readReceipt", [PFUser currentUser].objectId]];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
            else {
                [spinner stopAnimating];
                if (switchReadLabel.on) [switchReadLabel setOn:NO animated:YES];
                else [switchReadLabel setOn:YES animated:YES];

            }
        }];
    }
    else if (sender == switchPushes) {
        UIActivityIndicatorView *spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.frame = CGRectMake(switchPushes.frame.origin.x - 40, switchPushes.frame.origin.y+5, 20, 20);
        [cellPushes addSubview:spinner];
        [spinner startAnimating];
        
        switchPushes.userInteractionEnabled = NO;
        [[PFUser currentUser] setObject:(switchPushes.on ? @"ON" : @"OFF") forKey:@"receivePushes"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            switchPushes.userInteractionEnabled = YES;
            if (!error) {
                [spinner stopAnimating];
                [[NSUserDefaults standardUserDefaults] setObject:(switchPushes.on ? @"ON" : @"OFF") forKey:[NSString stringWithFormat:@"%@-receivePushes", [PFUser currentUser].objectId]];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (switchPushes.on) {
                    [AppDelegate registerForRemoteNotifications];
                }
                else {
                    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
                }
            }
            else {
                [spinner stopAnimating];
                if (switchPushes.on) [switchPushes setOn:NO animated:YES];
                else [switchPushes setOn:YES animated:YES];
                
            }
        }];
    }
    else if (sender == switchOnlineIndicator) {
        UIActivityIndicatorView *spinner=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        spinner.frame = CGRectMake(switchOnlineIndicator.frame.origin.x - 40, switchOnlineIndicator.frame.origin.y+5, 20, 20);
        [cellOnlineIndicator addSubview:spinner];
        [spinner startAnimating];
        
        switchOnlineIndicator.userInteractionEnabled = NO;
        [[PFUser currentUser] setObject:(switchOnlineIndicator.on ? @"ON" : @"OFF") forKey:@"showOnline"];
        [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            switchOnlineIndicator.userInteractionEnabled = YES;
            if (!error) {
                [spinner stopAnimating];
                [[NSUserDefaults standardUserDefaults] setObject:(switchOnlineIndicator.on ? @"ON" : @"OFF") forKey:[NSString stringWithFormat:@"%@-showOnline", [PFUser currentUser].objectId]];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (switchOnlineIndicator.on) [self setOnline];
                else [self userOffline];
            }
            else {
                [spinner stopAnimating];
                if (switchOnlineIndicator.on) [switchOnlineIndicator setOn:NO animated:YES];
                else [switchOnlineIndicator setOn:YES animated:YES];
                
            }
        }];    }
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if ((indexPath.section == 2) && (indexPath.row == 0)) [self actionBlocked];
	if ((indexPath.section == 0) && (indexPath.row == 0)) [self actionBio];
	if ((indexPath.section == 2) && (indexPath.row == 1)) [self actionAbout];
	if ((indexPath.section == 3) && (indexPath.row == 0)) [self actionLogout];
}

#pragma mark - UITextView delegate 

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    else {
        saveInfoBtn.enabled = YES;
        cancelBtn = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStyleDone target:self action:@selector(actionCancel)];
        self.navigationItem.leftBarButtonItem = cancelBtn;
        saveInfoBtn.tintColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1];
        bioTextview.textColor = [UIColor colorWithRed:32.0f/255.0f green:131.0f/255.0f blue:251.0f/255.0f alpha:1];
    }
    if ([bioTextview.text isEqualToString:@" Place your bio here"]) {
        bioTextview.text = @"";
        return YES;
    }
    if (range.location == 0 && range.length == 1 && [text isEqualToString:@""]) {
        bioTextview.text = @" Place your bio here";
        bioTextview.textColor = [UIColor lightGrayColor];
        return NO;
    }
    NSUInteger newLength = (textView.text.length - range.length) + text.length;
    if(newLength <= MAX_LENGTH)
    {
        return YES;
    } else {
        NSUInteger emptySpace = MAX_LENGTH - (textView.text.length - range.length);
        textView.text = [[[textView.text substringToIndex:range.location]
                          stringByAppendingString:[text substringToIndex:emptySpace]]
                         stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
        return NO;
    }
  return YES;
}

@end
