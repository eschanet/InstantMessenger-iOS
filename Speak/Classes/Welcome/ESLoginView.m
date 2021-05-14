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

#import "JVFloatLabeledTextField.h"
#import "ESLoginView.h"

@interface ESLoginView()

/**
 *  Cell where the email of the user is entered
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellEmail;
/**
 *  Cell where the password of the user is entered
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPassword;
/**
 *  Cell containing the login button
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButton;
/**
 *  Cell containing the facebook login button
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellFacebook;

@property (strong, nonatomic) IBOutlet UITableViewCell *cellResetPassword;
/**
 *  Actual textfield holding the email address in the cell
 */
@property (strong, nonatomic) IBOutlet UITextField *fieldEmail;
/**
 *  Actual textfield holding the password in the cell
 */
@property (strong, nonatomic) IBOutlet UITextField *fieldPassword;

@end

@implementation ESLoginView

@synthesize cellEmail, cellPassword, cellButton;
@synthesize fieldEmail, fieldPassword,cellFacebook, cellResetPassword;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"LOGIN";

	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.tableView addGestureRecognizer:gestureRecognizer];
	gestureRecognizer.cancelsTouchesInView = NO;
    self.navigationController.navigationBar.hidden = NO;
    self.tableView.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    self.tableView.scrollEnabled = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:0.0f/255.0f green:129.0f/255.0f blue:188.0f/255.0f alpha:1];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	//[fieldEmail becomeFirstResponder];
}

- (void)dismissKeyboard
{
	[self.view endEditing:YES];
}

#pragma mark - User actions

- (void)actionLogin
{
	NSString *email = [fieldEmail.text lowercaseString];
	NSString *password = fieldPassword.text;
	if ([email length] == 0)	{ [ProgressHUD showError:@"Email must be set."]; return; }
	if ([password length] == 0)	{ [ProgressHUD showError:@"Password must be set."]; return; }
    

	[ProgressHUD show:@"Signing in..." Interaction:NO];
	[PFUser logInWithUsernameInBackground:email password:password block:^(PFUser *user, NSError *error)
	{
		if (user != nil)
		{
            [[FIRAuth auth] signInWithEmail:email password:password completion:^(FIRUser * _Nullable _user, NSError * _Nullable error) {
                if (error) {
                    [ProgressHUD showError:error.userInfo[@"error"]];
                } else {
                    [ESUtility parsePushUserAssign];
                    [ESUtility postNotification:kESNotificationUserLogin];
                    [ProgressHUD showSuccess:[NSString stringWithFormat:@"Welcome back %@!", user[kESUserFullname]]];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }];

        }
		else [ProgressHUD showError:error.userInfo[@"error"]];
	}];
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
    else if (alertView.tag == 12) {
        if (buttonIndex == 1) {
            NSString *mail = [[alertView textFieldAtIndex:0] text];
            
            [PFUser requestPasswordResetForEmailInBackground:mail];
            
            UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Reset password", nil) message:NSLocalizedString(@"Alright, an email will be sent to your given email address. Please check your mails in a few minutes.",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
            alert.tag = 13;
            
            [alert show];
        }
    }
}
- (void)alertView:(UIAlertView *)alertview didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertview.tag == 99) {
        if (buttonIndex == 0) {
            [self actionFacebookLogin];
        }
    }
}
-(void)actionResetPassword {
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Reset password", nil) message:NSLocalizedString(@"Please enter your email address so that we can send you a link to reset your password.",nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) otherButtonTitles:NSLocalizedString(@"Send", nil), nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = 12;

    [alert show];
}
-(void)actionAcceptTermsFacebook {
    if (![[[PFUser currentUser] objectForKey:@"acceptedTerms"] isEqualToString:@"Yes"]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Terms of Use", nil) message:NSLocalizedString(@"Please accept the terms of use before using this app",nil) delegate:self cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"I accept", nil), NSLocalizedString(@"Show terms", nil), nil];
        alert.tag = 99;

        [alert show];
        
    } else {
        [self actionFacebookLogin];
    }
}
- (void)actionFacebookLogin {
    [ProgressHUD show:@"Signing in..." Interaction:NO];
    [PFFacebookUtils logInInBackgroundWithReadPermissions:@[@"public_profile", @"email", @"user_friends"] block:^(PFUser * _Nullable user, NSError * _Nullable error) {
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
                        NSLog(@"%@",error);
                    } else {
                        
                    }
                }];
            }
        }
        else {
            [ProgressHUD showError:@"Facebook login error."];
            NSLog(@"%@",error);
        }

    }];
   
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        return 2;
    }
    else if (section == 1) {
        return 2;
    }else return 1;

    
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return 40;
    }
    if (section == 1) {
        return [UIScreen mainScreen].bounds.size.height - 350;
    }
    else return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 50;
    }
    else if (indexPath.section == 1) {
        if (indexPath.row == 1) {
            return 20;
        }
        else  return 45;
    }
    else return 45;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            fieldEmail.frame = CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 30, cellEmail.frame.size.height);
            fieldEmail.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
            fieldEmail.clearButtonMode = UITextFieldViewModeWhileEditing;

            UIView *thinLine2 = [[UIView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 0.5)];
            thinLine2.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
            [cellEmail addSubview:thinLine2];
            UIView *thinLine = [[UIView alloc]initWithFrame:CGRectMake(20, cellEmail.frame.size.height, [UIScreen mainScreen].bounds.size.width - 20, 0.5)];
            thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
            [cellEmail addSubview:thinLine];
            return cellEmail;
        }
        if (indexPath.row == 1) {
            fieldPassword.frame = CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 30, cellPassword.frame.size.height);
            fieldPassword.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18];
            fieldPassword.clearButtonMode = UITextFieldViewModeWhileEditing;

            UIView *thinLine = [[UIView alloc]initWithFrame:CGRectMake(0, cellPassword.frame.size.height, [UIScreen mainScreen].bounds.size.width, 0.5)];
            thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
            [cellPassword addSubview:thinLine];
            return cellPassword;
        }
    }
    else if (indexPath.section == 1){
        if (indexPath.row == 0) {
            cellButton.backgroundColor = [UIColor clearColor];
            UIButton *loginLabel = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width-40, 45)];
            [loginLabel setTitle: @"Log in" forState: UIControlStateNormal];
            [loginLabel addTarget:self action:@selector(actionLogin) forControlEvents:UIControlEventTouchUpInside];
            loginLabel.titleLabel.tintColor = [UIColor whiteColor];
            loginLabel.layer.cornerRadius = 4;
            loginLabel.backgroundColor = [UIColor colorWithRed:161.0f/255.0f green:171.0f/255.0f blue:182.0f/255.0f alpha:1];
            [cellButton addSubview:loginLabel];
            cellButton.selectionStyle = UITableViewCellSelectionStyleNone;
            return cellButton;
        }
        if (indexPath.row == 1) {
            cellResetPassword.backgroundColor = [UIColor clearColor];
            UIButton *resetPassword = [[UIButton alloc]initWithFrame:CGRectMake(10, 0, [UIScreen mainScreen].bounds.size.width-20, cellResetPassword.frame.size.height)];
            [resetPassword setTitle: @"Reset Password" forState: UIControlStateNormal];
            [resetPassword addTarget:self action:@selector(actionResetPassword) forControlEvents:UIControlEventTouchUpInside];
            resetPassword.titleLabel.tintColor = [UIColor whiteColor];
            resetPassword.layer.cornerRadius = 4;
            resetPassword.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:12];
            [resetPassword setTitleColor: [UIColor colorWithRed:0.0f/255.0f green:129.0f/255.0f blue:188.0f/255.0f alpha:1] forState:UIControlStateNormal];
            resetPassword.backgroundColor = [UIColor clearColor];
            [cellResetPassword addSubview:resetPassword];
            
            cellResetPassword.selectionStyle = UITableViewCellSelectionStyleNone;
            return cellResetPassword;
        }
         

        
    }
    else {
        cellFacebook.backgroundColor = [UIColor clearColor];
        UIButton *facebookLogin = [[UIButton alloc]initWithFrame:CGRectMake(25, 5, [UIScreen mainScreen].bounds.size.width-40, cellFacebook.frame.size.height)];
        [facebookLogin setTitle: @"    Log in with Facebook" forState: UIControlStateNormal];
        [facebookLogin addTarget:self action:@selector(actionAcceptTermsFacebook) forControlEvents:UIControlEventTouchUpInside];
        facebookLogin.titleLabel.tintColor = [UIColor whiteColor];
        facebookLogin.layer.cornerRadius = 4;
        // [facebookLogin setTitleColor:[UIColor colorWithRed:109.0f/255.0f green:132.0f/255.0f blue:180.0f/255.0f alpha:1.0f] forState:UIControlStateHighlighted];
        facebookLogin.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16];
        [facebookLogin setTitleColor:[UIColor colorWithRed:65.0f/255.0f green:131.0f/255.0f blue:215.0f/255.0f alpha:1.0f] forState:UIControlStateNormal];
        facebookLogin.backgroundColor = [UIColor clearColor];
        UIImageView *fbIcon = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"facebookIcon"]];
        fbIcon.frame = CGRectMake(facebookLogin.frame.size.width/4 - 25, 10 , 20, 20);
        [facebookLogin addSubview:fbIcon];
        [cellFacebook addSubview:facebookLogin];
        UIView *thinLine = [[UIView alloc]initWithFrame:CGRectMake(20, 0, [UIScreen mainScreen].bounds.size.width - 40, 0.5)];
        thinLine.backgroundColor = [UIColor colorWithWhite:0.75 alpha:1];
        [cellFacebook addSubview:thinLine];
        
        cellFacebook.selectionStyle = UITableViewCellSelectionStyleNone;
        return cellFacebook;

    }
	return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 2)
    {
    }
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == fieldEmail)
	{
		[fieldPassword becomeFirstResponder];
	}
	if (textField == fieldPassword)
	{
		[self actionLogin];
	}
	return YES;
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
         UIImage *image = (UIImage *)responseObject;
           UIImage *_fullpicture = [ESUtility resizedImage:image withWidth:400 withHeight:400];
         UIImage *_picture = [ESUtility resizedImage:image withWidth:140 withHeight:140];
         UIImage *_thumbnail = [ESUtility resizedImage:image withWidth:60 withHeight:60];
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
@end
