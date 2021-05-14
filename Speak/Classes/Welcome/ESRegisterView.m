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

#import "ESRegisterView.h"
#import "ESLoginView.h"

@interface ESRegisterView() {
    /**
     *  A new user must set a profile picture, this bool is used to control that the user has actually set a profile picture
     */
    BOOL profilePictureSet;
}
/**
 *  Cell containing a textfield for the first name and for the last name as well as the profile picture
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellNameFirst;
/**
 *  Cell containing a textfield for the password
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPassword;
/**
 *  Cell containing a textfield for the email address
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellEmail;
/**
 *  Cell containing the sign up button
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButton;
/**
 *  Cell containing the facebook sign up button
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellFacebook;
/**
 *  Textfield containing the first name
 */
@property (strong, nonatomic) IBOutlet UITextField *fieldNameFirst;
/**
 *  Textfield containing the last name
 */
@property (strong, nonatomic) IBOutlet UITextField *fieldNameLast;
/**
 *  Textfield containing the password
 */
@property (strong, nonatomic) IBOutlet UITextField *fieldPassword;
/**
 *  Textfield containing the email address
 */
@property (strong, nonatomic) IBOutlet UITextField *fieldEmail;
/**
 *  Imageview containing the profile picture
 */
@property (strong, nonatomic) IBOutlet UIImageView *profilePicture;
@property (strong, nonatomic) UIImage *picture;
@property (strong, nonatomic) UIImage *thumbnail;
@property (strong, nonatomic) UIImage *full_picture;
@property (strong, nonatomic) UIView *placeholder;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIImageView *image;

@end

@implementation ESRegisterView

@synthesize cellPassword, cellEmail, cellButton, placeholder,image,titleLabel;
@synthesize fieldNameFirst,fieldNameLast,cellNameFirst, fieldPassword, fieldEmail, cellFacebook, profilePicture, picture,thumbnail,full_picture;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"REGISTER";
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Register" style:UIBarButtonItemStylePlain target:nil action:nil];

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.tableView addGestureRecognizer:gestureRecognizer];
    gestureRecognizer.cancelsTouchesInView = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.tableView.scrollEnabled = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0f/255.0f green:129.0f/255.0f blue:188.0f/255.0f alpha:1];
    profilePictureSet = NO;

}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    placeholder = [[UIView alloc]initWithFrame:CGRectMake(self.navigationController.navigationBar.frame.size.width - 100, 0, 100, self.navigationController.navigationBar.frame.size.height)];
    [self.navigationController.navigationBar addSubview:placeholder];
    titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(27, 9, 60, 25)];
    titleLabel.text = @"Login";
    titleLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:129.0f/255.0f blue:188.0f/255.0f alpha:1];
    [placeholder addSubview:titleLabel];
    image = [[UIImageView alloc] initWithFrame:CGRectMake(65, 5, 35, 35)];
    [image setImage:[UIImage imageNamed:@"icon-ios-forward"]];
    [placeholder addSubview:image];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(actionLogin:)];
    [placeholder addGestureRecognizer:tap];
    
    placeholder.alpha = 0;
    [UIView animateWithDuration:0.600f animations:^{
        placeholder.alpha = 1.0f;
    }];


}
- (void)viewWillDisappear:(BOOL)animated {
    [placeholder removeFromSuperview];
}

- (void)dismissKeyboard
{
	[self.view endEditing:YES];
}

#pragma mark - User actions
- (IBAction)actionLogin:(id)sender
{
    ESLoginView *loginView = [[ESLoginView alloc] init];
    [self.navigationController pushViewController:loginView animated:YES];
    
    [placeholder removeFromSuperview];
}
- (void)actionRegister
{
    NSString *nameFirst		= fieldNameFirst.text;
    NSString *nameLast		= [NSString stringWithFormat:@" %@",fieldNameLast.text];
    NSString *fullName = [NSString stringWithFormat:@"%@%@", nameFirst,nameLast];
	NSString *password	= fieldPassword.text;
	NSString *email		= [fieldEmail.text lowercaseString];
	if ([fullName length] < 5)		{ [ProgressHUD showError:@"Name is too short."]; return; }
	if ([password length] == 0)	{ [ProgressHUD showError:@"Password must be set."]; return; }
	if ([email length] == 0)	{ [ProgressHUD showError:@"Email must be set."]; return; }
    if (profilePictureSet == NO) {
        [ProgressHUD showError:@"Profile picture must be set."]; return;
    }
	[ProgressHUD show:@"Please wait..." Interaction:NO];
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
    //-----------------------------------------------------------------------------------------------------------------------------------------
    PFFile *fileThumbnail = [PFFile fileWithName:@"thumbnail.jpg" data:UIImageJPEGRepresentation(thumbnail, 0.6)];
    [fileThumbnail saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error != nil) [ProgressHUD showError:@"Network error."];
     }];
    //-----------------------------------------------------------------------------------------------------------------------------------------

    [[FIRAuth auth] createUserWithEmail:email password:password completion:^(FIRUser * _Nullable _user, NSError * _Nullable error) {

    if (error) {
        [ProgressHUD showError:@"Email already in use or password too unsecure."];
    } else {
        FIRDatabaseReference *_ref = [[FIRDatabase database] reference];
        [[FIRAuth auth] signInWithEmail:email password:password completion:^(FIRUser * _Nullable _user, NSError * _Nullable error) {
            if (error) {
                [ProgressHUD showError:error.userInfo[@"error"]];
            } else {
                NSDictionary *alanisawesome = @{@"full_name" : fullName, @"userFireId":_user.uid};
                [[[_ref child:@"users"] child:_user.uid] setValue:alanisawesome];

                
                PFUser *user = [PFUser user];
                user.username = email;
                user.password = password;
                user.email = email;
                user[kESUserEmailCopy] = email;
                user[kESUserFullname] = fullName;
                user[kESUserFullnameLower] = [fullName lowercaseString];
                user[kESUserPicture] = filePicture;
                user[kESUserBigPicture] = fileFullPicture;
                user[kESUserThumbnail] = fileThumbnail;
                user[kESUserFirebaseID] = _user.uid;
                user[@"showOnline"] = @"ON";
                user[@"receivePushes"] = @"ON";
                user[@"readReceipt"] = @"ON";
                user[@"acceptedTerms"] = @"Yes";

                [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                 {
                     if (error == nil)
                     {
                         [ESUtility parsePushUserAssign];
                         [ESUtility postNotification:kESNotificationUserLogin];
                         [ProgressHUD showSuccess:@"Succeed."];
                         [self dismissViewControllerAnimated:YES completion:nil];
                     }
                     else [ProgressHUD showError:error.userInfo[@"error"]];
                 }];
                
            }
        }];
    
    }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
   return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 20;
    }
    if (section == 1) {
        return 15;
    }
    if (section == 3) {
        return [UIScreen mainScreen].bounds.size.height - 450;
    }
    if (section == 4) {
        return 10;
    }
    else return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 100;
    }
    if (indexPath.section == 3) {
        return 45;
    }
    else if (indexPath.section == 4) {
        return 45;
    }
    else return 50;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            fieldNameFirst.frame = CGRectMake(75, 0, [UIScreen mainScreen].bounds.size.width - 85, cellNameFirst.frame.size.height/2 - 10);
            fieldNameFirst.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
            fieldNameLast.frame = CGRectMake(75, cellNameFirst.frame.size.height/2 -10, [UIScreen mainScreen].bounds.size.width - 85, cellNameFirst.frame.size.height/2 -10);
            fieldNameLast.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
            UIView *thinLine = [[UIView alloc]initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 0.5)];
            thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
            UIView *thinLine2 = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0.5)];
            thinLine2.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
            [cellNameFirst addSubview:thinLine2];
            UIView *thinLine3 = [[UIView alloc]initWithFrame:CGRectMake(75, 50, [UIScreen mainScreen].bounds.size.width-70, 0.5)];
            thinLine3.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
            [cellNameFirst addSubview:thinLine3];
            [cellNameFirst addSubview:thinLine];
            
            profilePicture.frame = CGRectMake(5, 20, 60, 60);
            profilePicture.layer.cornerRadius = 30;
            profilePicture.layer.masksToBounds = YES;

            [cellNameFirst addSubview:profilePicture];
            
            fieldNameLast.clearButtonMode = UITextFieldViewModeWhileEditing;
            fieldNameFirst.clearButtonMode = UITextFieldViewModeWhileEditing;
            
            UIButton *imageButton = [[UIButton alloc]initWithFrame:profilePicture.frame];
            [cellNameFirst addSubview:imageButton];
            [imageButton addTarget:self action:@selector(actionPhoto:) forControlEvents:UIControlEventTouchDown];
            return cellNameFirst;
        }
    }
    else if (indexPath.section == 1) {
        fieldPassword.frame = CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 30, cellPassword.frame.size.height);
        fieldPassword.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        fieldPassword.clearButtonMode = UITextFieldViewModeWhileEditing;

        UIView *thinLine = [[UIView alloc]initWithFrame:CGRectMake(0, cellPassword.frame.size.height, [UIScreen mainScreen].bounds.size.width, 0.5)];
        thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
        [cellPassword addSubview:thinLine];
        UIView *thinLine2 = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0.5)];
        thinLine2.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
        [cellPassword addSubview:thinLine2];
        return cellPassword;
    }
    else if (indexPath.section == 2) {
        fieldEmail.frame = CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 30, cellEmail.frame.size.height);
        fieldEmail.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
        fieldEmail.clearButtonMode = UITextFieldViewModeWhileEditing;
        UIView *thinLine = [[UIView alloc]initWithFrame:CGRectMake(0, cellEmail.frame.size.height, [UIScreen mainScreen].bounds.size.width, 0.5)];
        thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
        [cellEmail addSubview:thinLine];
        UIView *thinLine2 = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0.5)];
        thinLine2.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
        [cellEmail addSubview:thinLine2];
        return cellEmail;
    }
    else if (indexPath.section == 4) {
        cellFacebook.backgroundColor = [UIColor clearColor];
        UIButton *facebookLogin = [[UIButton alloc]initWithFrame:CGRectMake(25, 0, [UIScreen mainScreen].bounds.size.width-40, cellFacebook.frame.size.height)];
        [facebookLogin setTitle: @"    Log in with Facebook" forState: UIControlStateNormal];
        [facebookLogin addTarget:self action:@selector(actionAcceptTermsFacebook) forControlEvents:UIControlEventTouchUpInside];
        facebookLogin.titleLabel.tintColor = [UIColor whiteColor];
        facebookLogin.layer.cornerRadius = 4;
        // [facebookLogin setTitleColor:[UIColor colorWithRed:109.0f/255.0f green:132.0f/255.0f blue:180.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        facebookLogin.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        [facebookLogin setTitleColor:[UIColor colorWithRed:65.0f/255.0f green:131.0f/255.0f blue:215.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        facebookLogin.backgroundColor = [UIColor clearColor];
        UIImageView *fbIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"facebookIcon"]];
        fbIcon.frame = CGRectMake(facebookLogin.frame.size.width/4 - 25, 15 , 20, 20);
        [facebookLogin addSubview:fbIcon];
        [cellFacebook addSubview:facebookLogin];
        UIView *thinLine = [[UIView alloc]initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 40, 0.5)];
        thinLine.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1];
        [cellFacebook addSubview:thinLine];
        
        cellFacebook.selectionStyle = UITableViewCellSelectionStyleNone;
        return cellFacebook;
    }
    else if (indexPath.section == 3) {
        cellButton.backgroundColor = [UIColor clearColor];
        UIButton *loginLabel = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width-40, 45)];
        [loginLabel setTitle: @"Sign up" forState: UIControlStateNormal];
        [loginLabel addTarget:self action:@selector(actionAcceptTerms) forControlEvents:UIControlEventTouchUpInside];
        loginLabel.titleLabel.tintColor = [UIColor whiteColor];
        loginLabel.layer.cornerRadius = 4;
        loginLabel.backgroundColor = [UIColor colorWithRed:161.0f/255.0f green:171.0f/255.0f blue:182.0f/255.0f alpha:1];
        [cellButton addSubview:loginLabel];
        cellButton.selectionStyle = UITableViewCellSelectionStyleNone;
        return cellButton;
    }

	return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == fieldNameFirst)
    {
        [fieldNameLast becomeFirstResponder];
    }
    if (textField == fieldNameLast)
    {
        [fieldPassword becomeFirstResponder];
    }
	if (textField == fieldPassword)
	{
		[fieldEmail becomeFirstResponder];
	}
	if (textField == fieldEmail)
	{
		[self actionAcceptTerms];
	}
	return YES;
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 99) {
        if (buttonIndex == 0) {

        }
        else {
            TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:@"http://codelight.lu/terms-luxchat/"]];
            webViewController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:webViewController animated:YES];
            
        }
    }
    else if (alertView.tag == 100) {
        if (buttonIndex == 0) {

        }
        else {
            TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[NSURL URLWithString:@"http://codelight.lu/terms-luxchat/"]];
            webViewController.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:webViewController animated:YES];
            
        }
    }
    
}
- (void)alertView:(UIAlertView *)alertview didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if (alertview.tag == 99) {
            [self actionRegister];

        }
        if (alertview.tag == 100) {
            [self actionFacebookLogin];
        }
    }
}
-(void)actionAcceptTerms {
    if (![[[PFUser currentUser] objectForKey:@"acceptedTerms"] isEqualToString:@"Yes"]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Terms of Use", nil) message:NSLocalizedString(@"Please accept the terms of use before using this app",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"I accept", nil), NSLocalizedString(@"Show terms", nil), nil];
        [alert show];
        alert.tag = 99;
        
    }
}
-(void)actionAcceptTermsFacebook {
    if (![[[PFUser currentUser] objectForKey:@"acceptedTerms"] isEqualToString:@"Yes"]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Terms of Use", nil) message:NSLocalizedString(@"Please accept the terms of use before using this app",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"I accept", nil), NSLocalizedString(@"Show terms", nil), nil];
        [alert show];
        alert.tag = 100;
        
    } else {
        [self actionFacebookLogin];
    }
}
- (void)actionFacebookLogin {
    [ProgressHUD show:@"Signing in..." Interaction:NO];
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"public_profile", @"email", @"user_friends"] block:^(PFUser *user, NSError *error)
     {
         if (user != nil)
         {
             if (user[kESUserFacebookID] == nil)
             {
                 [self requestFacebook:user];
             }
             else {
                 [self userLoggedIn:user];
                 FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                                  credentialWithAccessToken:[FBSDKAccessToken currentAccessToken]
                                                  .tokenString];
                 
                 [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser *_user, NSError *error) {
                            if (error) {
                                    [ProgressHUD showError:@"Error Code: 601"];
                            } else {

                            }
                        }];
             }
         }
         else [ProgressHUD showError:@"Facebook login error."];
     }];
}
- (void)requestFacebook:(PFUser *)user
{
    if ([FBSDKAccessToken currentAccessToken] != nil) {
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"me" parameters:@{@"fields": @"id, name, email"}]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             
             if (error == nil)
             {
                 NSDictionary *userData = (NSDictionary *)result;
                 [self processFacebook:user UserData:userData];
             }
             else
             {
                 [PFUser logOut];
                 [[UIApplication sharedApplication] unregisterForRemoteNotifications];
                 [ProgressHUD showError:@"Failed to fetch Facebook user data."];
             }
             
         }];
    }
}

- (void)processFacebook:(PFUser *)user UserData:(NSDictionary *)userData
{
    NSString *link = [NSString stringWithFormat:@"http://graph.facebook.com/%@/picture?type=large", userData[@"id"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:link]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    operation.responseSerializer = [AFImageResponseSerializer serializer];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
     {
         UIImage *img = (UIImage *)responseObject;
           UIImage *_fullpicture = [ESUtility resizedImage:img withWidth:400 withHeight:400];
         UIImage *_picture = [ESUtility resizedImage:img withWidth:140 withHeight:140];
         UIImage *_thumbnail = [ESUtility resizedImage:img withWidth:60 withHeight:60];
           PFFile *fileFullPicture = [PFFile fileWithName:@"fullpicture.jpg" data:UIImageJPEGRepresentation(_fullpicture, 0.8)];
         [fileFullPicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
          {
              if (error != nil) [ProgressHUD showError:@"Network error."];
          }];
         PFFile *filePicture = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(_picture, 0.6)];
         [filePicture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
          {
              if (error != nil) [ProgressHUD showError:@"Network error."];
          }];
           PFFile *fileThumbnail = [PFFile fileWithName:@"thumbnail.jpg" data:UIImageJPEGRepresentation(_thumbnail, 0.6)];
         [fileThumbnail saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
          {
              if (error != nil) [ProgressHUD showError:@"Network error."];
          }];
           
         if (userData[@"email"]) {
             user[kESUserEmailCopy] = userData[@"email"];
         }
         else {
             NSString *name = [[userData[@"name"] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
             user[kESUserEmailCopy] = [NSString stringWithFormat:@"%@@facebook.com",name];
         }
         user[kESUserFullname] = userData[@"name"];
         user[kESUserFullnameLower] = [userData[@"name"] lowercaseString];
         user[kESUserFacebookID] = userData[@"id"];
         user[kESUserPicture] = filePicture;
         user[kESUserBigPicture] = fileFullPicture;
         user[kESUserThumbnail] = fileThumbnail;
         user[@"showOnline"] = @"ON";
         user[@"receivePushes"] = @"ON";
         user[@"readReceipt"] = @"ON";
         user[@"acceptedTerms"] = @"Yes";

         
         
         //NSString *token = [[FBSDKAccessToken currentAccessToken] tokenString];
         FIRAuthCredential *credential = [FIRFacebookAuthProvider
                                          credentialWithAccessToken:[FBSDKAccessToken currentAccessToken]
                                          .tokenString];
         
         [[FIRAuth auth] signInWithCredential:credential completion:^(FIRUser *_user, NSError *error) {
             if (error) {
                 [ProgressHUD showError:@"Error Code: 602"];
             } else {
                 FIRDatabaseReference *ref = [[FIRDatabase database] reference];

                 NSDictionary *alanisawesome = @{@"full_name" : userData[@"name"], @"userFireId":_user.uid};
                 [[[ref child:@"users"] child:_user.uid] setValue:alanisawesome];
                 user[kESUserFirebaseID] = _user.uid;
                 [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil)
                      {
                          [PFUser logOut];
                          [[UIApplication sharedApplication] unregisterForRemoteNotifications];
                          [ProgressHUD showError:@"Error Code: 603"];
                      }
                      else [self userLoggedIn:user];
                  }];

             }
         }];
              }
                                     failure:^(AFHTTPRequestOperation *operation, NSError *error)
     {
         [PFUser logOut];
         [[UIApplication sharedApplication] unregisterForRemoteNotifications];
         [ProgressHUD showError:@"Failed to fetch Facebook profile picture."];
     }];
    [[NSOperationQueue mainQueue] addOperation:operation];
}
- (void)userLoggedIn:(PFUser *)user
{
    [ESUtility parsePushUserAssign];
    [ESUtility postNotification:kESNotificationUserLogin];
    [ProgressHUD showSuccess:[NSString stringWithFormat:@"Welcome back %@!", user[kESUserFullname]]];
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)actionPhoto:(id)sender {
    [ESUtility presentPhotoLibrary:self editable:YES];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *img = info[UIImagePickerControllerEditedImage];
    full_picture = [ESUtility resizedImage:img withWidth:400 withHeight:400];
    picture = [ESUtility resizedImage:img withWidth:140 withHeight:140];
    thumbnail = [ESUtility resizedImage:img withWidth:60 withHeight:60];

    [profilePicture setImage:picture];
    profilePictureSet = YES;

    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
