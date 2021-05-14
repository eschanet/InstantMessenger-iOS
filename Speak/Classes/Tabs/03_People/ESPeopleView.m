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

#import "ESPeopleView.h"
#import "ESChatView.h"
#import "ESSelectSingleView.h"
#import "ESSelectMultipleView.h"
#import "ESPhoneBook.h"
#import "ESFacebookFriendsView.h"
#import "NavigationController.h"
#import "ESTableViewCell.h"
#import "CRNInitialsImageView.h"

@interface ESPeopleView()
{
    /**
     *  Bool indicating whether we should skip loading or not
     */
	BOOL skipLoading;
    /**
     *  Mutable array containing all the userIds
     */
	NSMutableArray *userIds;
    /**
     *  Mutable array containing the necessary data that is being displayed in every cell. This array is modified as the searchbar is used
     */
    NSMutableArray *sections;
    /**
     *  Mutable array containing the necessary data that is being displayed in every cell. This array is NOT modified as the searchbar is used
     */
    NSMutableArray *fixsections;
    /**
     *  Mutable array containing the users that are being displayed from the phone contacts. This array is modified as the searchbar is used.
     */
    NSMutableArray *users1;
    /**
     *  Mutable array containg the users that are contacts from within the app. This array is modified as the searchbar is used.
     */
    NSMutableArray *users2;
    /**
     *  Mutable array that is a static copy of the users1 array and is not being altered by the search bar
     */
    NSMutableArray *fixusers1;
    /**
     *  Mutable array that is a static copy of the users2 array and is not being altered by the search bar
     */
    NSMutableArray *fixusers2;
    /**
     *  Mutable array containing the recent conversations with all the metadata.
     */
    NSMutableArray *recentConvos;
    /**
     *  If a user is selected, we need to keep track of the selected index, so we save it in this variable.
     */
    NSIndexPath *indexSelected;

}
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation ESPeopleView
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	{
		[self.tabBarItem setImage:[UIImage imageNamed:@"tab_people"]];
		self.tabBarItem.title = @"Contacts";
 		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCleanup) name:kESNotificationUserLogout object:nil];
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"CONTACTS";

    self.tableView.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Contacts" style:UIBarButtonItemStylePlain target:nil action:nil];

	self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionShare)];

    userIds = [[NSMutableArray alloc] init];
    sections = [[NSMutableArray alloc]init];
    fixsections = [[NSMutableArray alloc]init];
    users1 = [[NSMutableArray alloc] init];
    users2 = [[NSMutableArray alloc] init];
    fixusers1 = [[NSMutableArray alloc] init];
    fixusers2 = [[NSMutableArray alloc] init];
    recentConvos = [[NSMutableArray alloc] init];
    

   
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.backgroundColor = [UIColor whiteColor];
   //  self.tableView.tableHeaderView = self.searchBar;

}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
}
- (void)viewWillAppear:(BOOL)animated {
    [self loadRecents];
    
    if ([PFUser currentUser] != nil)
    {
        if (skipLoading) skipLoading = NO;
        else {
            skipLoading =YES;
            ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
                                                     {
                                                         dispatch_async(dispatch_get_main_queue(), ^{
                                                             if (granted) [self loadAddressBook];
                                                         });
                                                     });
        };
    }
    else [ESUtility loginUser:self];

    self.searchBar.placeholder = @"Search";
    self.searchBar.text = nil;

}
- (void)viewWillDisappear:(BOOL)animated {
    [ProgressHUD dismiss];
}
#pragma mark - User actions
#pragma mark - Backend methods

- (void)loadAddressBook
{
    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
    {
        CFErrorRef *error = NULL;
        ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
        ABRecordRef sourceBook = ABAddressBookCopyDefaultSource(addressBook);
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeopleInSourceWithSortOrdering(addressBook, sourceBook, kABPersonFirstNameProperty);
        CFIndex personCount = CFArrayGetCount(allPeople);
        
        [users1 removeAllObjects];
        [fixusers1 removeAllObjects];
        for (int i=0; i<personCount; i++)
        {
            ABMultiValueRef tmp;
            ABRecordRef person = CFArrayGetValueAtIndex(allPeople, i);
            
            NSString *first = @"";
            tmp = ABRecordCopyValue(person, kABPersonFirstNameProperty);
            if (tmp != nil) first = [NSString stringWithFormat:@"%@", tmp];
            
            NSString *last = @"";
            tmp = ABRecordCopyValue(person, kABPersonLastNameProperty);
            if (tmp != nil) last = [NSString stringWithFormat:@"%@", tmp];
            
            NSMutableArray *emails = [[NSMutableArray alloc] init];
            ABMultiValueRef multi1 = ABRecordCopyValue(person, kABPersonEmailProperty);
            for (CFIndex j=0; j<ABMultiValueGetCount(multi1); j++)
            {
                tmp = ABMultiValueCopyValueAtIndex(multi1, j);
                if (tmp != nil) [emails addObject:[NSString stringWithFormat:@"%@", tmp]];
            }
            
            NSMutableArray *phones = [[NSMutableArray alloc] init];
            ABMultiValueRef multi2 = ABRecordCopyValue(person, kABPersonPhoneProperty);
            for (CFIndex j=0; j<ABMultiValueGetCount(multi2); j++)
            {
                tmp = ABMultiValueCopyValueAtIndex(multi2, j);
                if (tmp != nil) [phones addObject:[NSString stringWithFormat:@"%@", tmp]];
            }
            
            NSString *name = [NSString stringWithFormat:@"%@ %@", first, last];
            [users1 addObject:@{@"name":name, @"emails":emails, @"phones":phones}];
            [fixusers1 addObject:@{@"name":name, @"emails":emails, @"phones":phones}];
        }
        [self.tableView reloadData];
        CFRelease(allPeople);
        CFRelease(addressBook);
        [self loadPeople];
        [self loadRecents];
    }
}

- (void)loadPeople
{
	PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
	[query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
    [query includeKey:kESPeopleUser2];
	[query setLimit:1000];
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
	{
        if (error == nil)
        {
            int userCount = (int)[users2 count];
            [users2 removeAllObjects];
            [fixusers2 removeAllObjects];

            for (PFUser *people in objects)
            {
                PFUser *user = people[kESPeopleUser2];
                [users2 addObject:user];
                [fixusers2 addObject:user];
                [userIds addObject:user.objectId];
                [self removeUser:user[kESUserEmailCopy]];
                [self setObjects:users2];
            }
            if ([users2 count] != userCount) {
                [self.tableView reloadData];
            }
        }
        else [ProgressHUD showError:@"Network error."];
	}];

}
- (void)loadRecents {
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *fquery = [[firebase queryOrderedByChild:@"userId"] queryEqualToValue:[[PFUser currentUser] objectId]];
    [fquery observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         [recentConvos removeAllObjects];
         if (snapshot.value != [NSNull null])
         {
           //  self.tableView.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0.1)];
             NSArray *sorted = [[snapshot.value allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
                                {
                                    NSDictionary *recent1 = (NSDictionary *)obj1;
                                    NSDictionary *recent2 = (NSDictionary *)obj2;
                                    NSDate *date1 = [ESUtility convertStringToDate:recent1[@"date"]];
                                    NSDate *date2 = [ESUtility convertStringToDate:recent2[@"date"]];
                                    return [date2 compare:date1];
                                }];
             for (NSDictionary *recent in sorted)
             {
                 //  if (![recent[@"lastMessage"] isEqualToString:@""]) {
                 [recentConvos addObject:recent];
                 //  }
             }
         }
     }];
}
- (void)removeUser:(NSString *)email_
{
    NSMutableArray *remove = [[NSMutableArray alloc] init];
    for (NSDictionary *user in users1)
    {
        for (NSString *email in user[@"emails"])
        {
            if ([email isEqualToString:email_])
            {
                [remove addObject:user];
                break;
            }
        }
    }
    for (NSDictionary *user in remove)
    {
        [users1 removeObject:user];
        [fixusers1 removeObject:user];
    }
}

- (void)setObjects:(NSArray *)objects
{
    
    if (sections != nil) {
        [sections removeAllObjects];
        [fixsections removeAllObjects];
    }
	NSArray *sorted = [objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
	{
		PFUser *user1 = (PFUser *)obj1;
		PFUser *user2 = (PFUser *)obj2;
		return [user1[kESUserFullname] compare:user2[kESUserFullname]];
	}];
	for (PFUser *object in sorted)
	{
		
        [sections addObject:object];
        [fixsections addObject:object];
	}
}

#pragma mark - User actions

- (void)actionCleanup
{
	[userIds removeAllObjects];
    [sections removeAllObjects];
    [fixsections removeAllObjects];
	//[self.tableView reloadData];
}
- (void)actionShare {
    UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:@"Share the app with your friends" delegate:self cancelButtonTitle:@"Cancel"
                                          destructiveButtonTitle:nil otherButtonTitles:@"Share on Facebook", @"Share on Twitter", nil];
    [action showInView:self.view];
    action.tag = 5;
    }
- (void)shareFacebook {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook])
    {
        SLComposeViewController *fbPostSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
        [fbPostSheet addURL:[NSURL URLWithString:@"http://codelight.lu"]];
        [self presentViewController:fbPostSheet animated:YES completion:nil];
    } else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't post right now, make sure your device has an internet connection and you have at least one facebook account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }

}
- (void)shareTwitter {
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
    {
        SLComposeViewController *tweetSheet = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
        [tweetSheet addURL:[NSURL URLWithString:@"http://codelight.lu"]];
        [tweetSheet setInitialText:@"Check out the new instant messenger #LuxChat!"];
        [self presentViewController:tweetSheet animated:YES completion:nil];
        
    }
    else
    {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Sorry"
                                  message:@"You can't send a tweet right now, make sure your device has an internet connection and you have at least one Twitter account setup"
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }
}
- (void)actionAdd
{
    ESSelectSingleView *selectSingleView = [[ESSelectSingleView alloc] init];
    selectSingleView.delegate = self;
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectSingleView];
    [self presentViewController:navController animated:YES completion:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1) {
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		skipLoading = YES;
		if (buttonIndex == 0)
		{
			ESSelectSingleView *selectSingleView = [[ESSelectSingleView alloc] init];
			selectSingleView.delegate = self;
			NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectSingleView];
			[self presentViewController:navController animated:YES completion:nil];
		}
		if (buttonIndex == 1)
		{
			ESSelectMultipleView *selectMultipleView = [[ESSelectMultipleView alloc] init];
			selectMultipleView.delegate = self;
			NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectMultipleView];
			[self presentViewController:navController animated:YES completion:nil];
		}
		if (buttonIndex == 2)
		{
			ESFacebookFriendsView *facebookFriendsView = [[ESFacebookFriendsView alloc] init];
			facebookFriendsView.delegate = self;
			NavigationController *navController = [[NavigationController alloc] initWithRootViewController:facebookFriendsView];
			[self presentViewController:navController animated:YES completion:nil];
		}
	}
    }
    else if (actionSheet.tag == 5) {
        if (buttonIndex == 0) [self shareFacebook];
        if (buttonIndex == 1) [self shareTwitter];
    }
    else {
        if (buttonIndex == actionSheet.cancelButtonIndex) return;
            NSDictionary *user = users1[indexSelected.row];
        if (buttonIndex == 0) [self sendMail:user];
        if (buttonIndex == 1) [self sendSMS:user];
    }
}

#pragma mark - SelectSingleDelegate

- (void)didSelectSingleUser:(PFUser *)user
{
	[self addUser:user];
}

#pragma mark - SelectMultipleDelegate

- (void)didSelectMultipleUsers:(NSMutableArray *)users_
{
	for (PFUser *user in users_)
	{
		[self addUser:user];
	}
}

#pragma mark - AddressBookDelegate

- (void)didSelectAddressBookUser:(PFUser *)user
{
	[self addUser:user];
}

#pragma mark - FacebookFriendsDelegate

- (void)didSelectFacebookUser:(PFUser *)user
{
	[self addUser:user];
}

#pragma mark - Helper methods

- (void)addUser:(PFUser *)user
{
	if ([userIds containsObject:user.objectId] == NO)
	{
        [ESUtility peopleSave:[PFUser currentUser] andUser:user];
        [users2 addObject:user];
        [fixusers2 addObject:user];
		[userIds addObject:user.objectId];
		[self setObjects:users2];
		[self.tableView reloadData];
	}
}

#pragma mark - Table view data source

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 2;
    if (section == 1) return [users2 count];
    if (section == 2) return [users1 count];
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([users2 count] == 0 && section == 1) {
        return 0;
    }
    if ([users1 count] == 0 && section == 2) {
        return 0;
    }
    return 40;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
    UIView *thinLine = [[UIView alloc] initWithFrame:CGRectMake(0, 39.5, tableView.frame.size.width, 0.5)];
    UIColor *separatorColor = self.tableView.separatorColor;
    thinLine.backgroundColor = separatorColor;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, tableView.frame.size.width, 18)];
    [label setFont:[UIFont fontWithName:@"HelveticaNeue" size:14]];
    label.textColor = [UIColor colorWithWhite:0.6 alpha:1];
    if (section == 1) [label setText:@"MY CONTACTS"];
    else if (section == 2) [label setText:@"NON-REGISTERED USERS"];
    [view addSubview:label];
   // [view addSubview:thinLine];
    [view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    if ([users2 count] == 0 && section == 1) {
        return nil;
    }
    if ([users1 count] == 0 && section == 2) {
        return nil;
    }
    if (section == 0) {
        return nil;
    }
    return view;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        if  (indexPath.row == 0) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"staticCell"];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"staticCell"];
            cell.textLabel.text = @"Find People";
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.shadowColor = [UIColor clearColor];
          //  cell.imageView.image = [UIImage imageNamed:@"addcontact"];
            return cell;
        }
        else if (indexPath.row == 1) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"staticCell"];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"staticCell"];
            cell.textLabel.text = @"Facebook Friends";
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.shadowColor = [UIColor clearColor];
         //   cell.imageView.image = [UIImage imageNamed:@"facebookcontacts"];
            return cell;
        }
    }
    if (indexPath.section == 1)
    {
        ESTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"registeredCell"];
        if (cell == nil) cell = [[ESTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"registeredCell"];

        PFUser *user = sections[indexPath.row];
        cell.textLabel.text = user[kESUserFullname];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        cell.textLabel.shadowColor = [UIColor clearColor];
        cell.detailTextLabel.text = user[kESUserEmailCopy];
        cell.imageView.image = [UIImage imageNamed:@"AvatarPlaceholderProfile"];
      /*  CGSize itemSize = CGSizeMake(40, 40);
        UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
        CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
        [cell.imageView.image drawInRect:imageRect];
        cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();*/
        cell.imageView.layer.cornerRadius = 20;
        cell.imageView.layer.masksToBounds = YES;
        [[user objectForKey:kESUserPicture] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
            if (!error) {
                UIImage *image = [UIImage imageWithData:data];
                cell.imageView.image = image;
            }
        }];

        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        return cell;
    }
    if (indexPath.section == 2)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.textLabel.shadowColor = [UIColor clearColor];
        NSDictionary *user = users1[indexPath.row];
        NSString *email = [user[@"emails"] firstObject];
        NSString *phone = [user[@"phones"] firstObject];
        cell.textLabel.text = user[@"name"];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        cell.detailTextLabel.text = (email != nil) ? email : phone;
        
        CGFloat red = arc4random() % 100;
        CGFloat blue = 150 + arc4random() % 105;
        CGFloat green = 100 + arc4random() % 120;
        CRNInitialsImageView *crnImageView = [[CRNInitialsImageView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
        crnImageView.initialsBackgroundColor = [UIColor colorWithRed:red/255 green:green/255 blue:blue/255 alpha:1];
        crnImageView.initialsTextColor = [UIColor whiteColor];
        crnImageView.initialsFont = [UIFont fontWithName:@"HelveticaNeue" size:18];
        crnImageView.useCircle = TRUE;
        NSString *firstName = [[user[@"name"] componentsSeparatedByString:@" "] objectAtIndex:0];
        NSString *lastname = [user[@"name"] stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@ ",firstName] withString:@""];
        if (![firstName isEqualToString:@""] && ![firstName isEqualToString:@" "]) crnImageView.firstName = firstName;
        else crnImageView.firstName = user[@"name"];
        if (![lastname isEqualToString:@""] && ![lastname isEqualToString:@" "]) crnImageView.lastName = lastname;
        else crnImageView.lastName = @" ";
        [crnImageView drawImage];
        cell.imageView.image = crnImageView.image;
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        return cell;
    }
    return nil;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        return YES;
    } else return NO;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1) {
        
	PFUser *user = sections[indexPath.row];
        [ESUtility peopleDelete:[PFUser currentUser] andUser:user];
        [users2 removeObject:user];
        [fixusers2 removeObject:user];
	[userIds removeObject:user.objectId];
	[self setObjects:users2];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadData];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self actionAdd];
        } else if (indexPath.row == 1) {
            ESFacebookFriendsView *facebookFriendsView = [[ESFacebookFriendsView alloc] init];
            facebookFriendsView.delegate = self;
            NavigationController *navController = [[NavigationController alloc] initWithRootViewController:facebookFriendsView];
            [self presentViewController:navController animated:YES completion:nil];
        }
    }
    if (indexPath.section == 1)
    {
        PFUser *user1 = [PFUser currentUser];
            PFUser *user2 = sections[indexPath.row];
        NSString *id1 = user1.objectId;
        NSString *id2 = user2.objectId;
            BOOL createNew = YES;
        for (NSDictionary *recent in recentConvos) {
            if ([recent[@"members"] count] == 2) {
                for (NSString *objectID in recent[@"members"]) {
                    if ([objectID isEqualToString:id1]) {
                        for (NSString *objectID in recent[@"members"]) {
                            if ([objectID isEqualToString:id2]) {
                                createNew = NO;
                                break;
                            }
                        }
                    }
                    
                }
            }
            
        }

            NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
            NSArray *members = @[user1.objectId, user2.objectId];
            if (createNew) {
                [ESUtility createRecentItemForUser:user1 withGroupId:groupId withMembers:members withDescription:user2[kESUserFullname] andOption:@"NO"];
                [ESUtility createRecentItemForUser:user2 withGroupId:groupId withMembers:members withDescription:user1[kESUserFullname] andOption:@"NO"];
        }
            ESChatView *chatView = [[ESChatView alloc] initWith:groupId andTitle:[user2 objectForKey:kESUserFullname]];
        chatView.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:chatView animated:YES];
    }
    if (indexPath.section == 2)
    {
        indexSelected = indexPath;
        [self inviteUser:users1[indexPath.row]];
    }
}
#pragma mark - Invite helper method

- (void)inviteUser:(NSDictionary *)user
{
    if (([user[@"emails"] count] != 0) && ([user[@"phones"] count] != 0))
    {
        UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
                                              destructiveButtonTitle:nil otherButtonTitles:@"Email invitation", @"SMS invitation", nil];
        [action showInView:self.view];
    }
    else if (([user[@"emails"] count] != 0) && ([user[@"phones"] count] == 0))
    {
        [self sendMail:user];
    }
    else if (([user[@"emails"] count] == 0) && ([user[@"phones"] count] != 0))
    {
        [self sendSMS:user];
    }
    else [ProgressHUD showError:@"This contact does not have enough information to be invited."];
}


#pragma mark - Mail sending method

- (void)sendMail:(NSDictionary *)user
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailCompose = [[MFMailComposeViewController alloc] init];
        [mailCompose setToRecipients:user[@"emails"]];
        [mailCompose setSubject:@""];
        [mailCompose setMessageBody:MESSAGE_INVITE isHTML:YES];
        mailCompose.mailComposeDelegate = self;
        [self presentViewController:mailCompose animated:YES completion:nil];
    }
    else [ProgressHUD showError:@"Please configure your mail first."];
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if (result == MFMailComposeResultSent)
    {
        [ProgressHUD showSuccess:@"Mail sent successfully."];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - SMS sending method

- (void)sendSMS:(NSDictionary *)user
{
    if ([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController *messageCompose = [[MFMessageComposeViewController alloc] init];
        messageCompose.recipients = user[@"phones"];
        messageCompose.body = MESSAGE_INVITE;
        messageCompose.messageComposeDelegate = self;
        [self presentViewController:messageCompose animated:YES completion:nil];
    }
    else [ProgressHUD showError:@"SMS cannot be sent from this device."];
}

#pragma mark - MFMessageComposeViewControllerDelegate

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultSent)
    {
        [ProgressHUD showSuccess:@"SMS sent successfully."];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar_
{
    [searchBar_ setShowsCancelButton:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar_
{
    [searchBar_ setShowsCancelButton:NO animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar_
{
    [self searchBarCancelled];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar_
{
    [searchBar_ resignFirstResponder];
}

- (void)searchBarCancelled
{

}

@end
