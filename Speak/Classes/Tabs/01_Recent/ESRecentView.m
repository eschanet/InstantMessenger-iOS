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

#import "ESRecentView.h"
#import "ESRecentCell.h"
#import "ESChatView.h"
#import "ESSelectSingleView.h"
#import "ESSelectMultipleView.h"
#import "ESPhoneBook.h"
#import "ESFacebookFriendsView.h"
#import "NavigationController.h"

@interface ESRecentView()
{
    /**
     *  Hook to Firebase, checking for incoming messagesa and defining an appropriate reaction
     */
	FIRDatabaseReference *firebase;
    /**
     *  Mutable array containing all the recent conversations that haven't been deleted
     */
    NSMutableArray *recentConvos;
    /**
     *  Copy of the recentConvos mutable array
     */
    NSMutableArray *fixRecentConvos;
    /**
     *  Mutable array containing all the recent conversations
     */
    NSMutableArray *allRecentConvos;

    NSMutableArray *deletionRows;
    NSMutableArray *deletionIndexPaths;
    /**
     *  Containing the profile pictures, used as a cache to preven unnecessary reloading of images
     */
    NSMutableDictionary *cachedImages;
}

@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator2;
/**
 *  Placeholder view displayed when no conversations are open
 */
@property (nonatomic, strong) UIView *blankTimelineView;
/**
 *  A search bar the user can use to search for a specific conversation
 */
@property (nonatomic, strong) UISearchBar *searchBar;
@end

@implementation ESRecentView
@synthesize activityIndicator, blankTimelineView,activityIndicator2, searchBar;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	{
		[self.tabBarItem setImage:[UIImage imageNamed:@"tab_recent"]];
		self.tabBarItem.title = @"Chats";

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadRecents) name:kESNotificationAppStarted object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadRecents) name:kESNotificationUserLogin object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionCleanup) name:kESNotificationUserLogout object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveRemoteNotification:) name:@"openChat" object:nil];

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
    
    self.navigationItem.title = @"CHATS";
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self
																						   action:@selector(actionCompose)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self
																						   action:@selector(actionEdit)];
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Chats" style:UIBarButtonItemStylePlain target:nil action:nil];
	
    [self.tableView registerNib:[UINib nibWithNibName:@"ESRecentCell" bundle:nil] forCellReuseIdentifier:@"ESRecentCell"];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

    recentConvos = [[NSMutableArray alloc] init];
    fixRecentConvos = [[NSMutableArray alloc] init];
    allRecentConvos = [[NSMutableArray alloc] init];
    deletionRows = [[NSMutableArray alloc] init];
    deletionIndexPaths = [[NSMutableArray alloc] init];
    cachedImages = [[NSMutableDictionary alloc]init];
    
    self.blankTimelineView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake( [UIScreen mainScreen].bounds.size.width/2 - 105, [UIScreen mainScreen].bounds.size.height/2 - 140 - 64, 210.0f, 210.0f);
    [button setBackgroundColor:[UIColor clearColor]];
    [button setImage:[UIImage imageNamed:@"logo_small_grey"] forState:UIControlStateNormal];
    button.layer.cornerRadius = 5;
    [button addTarget:self action:@selector(actionPeople) forControlEvents:UIControlEventTouchUpInside];
    [self.blankTimelineView addSubview:button];
    
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake( [UIScreen mainScreen].bounds.size.width/2 - 110, [UIScreen mainScreen].bounds.size.height/2 - 64 + 10, 220.0f, 40.0f);
    [button2 setBackgroundColor:[UIColor clearColor]];
    [button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    [button2 setTitle:@"You have no conversations" forState:UIControlStateNormal];
    [button2.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    button2.layer.cornerRadius = 5;
    [button2 addTarget:self action:@selector(actionPeople) forControlEvents:UIControlEventTouchUpInside];
    [self.blankTimelineView addSubview:button2];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.backgroundColor = [UIColor whiteColor];
    self.searchBar.placeholder = @"Search";
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    if ([PFUser currentUser] != nil) {}
	else [ESUtility loginUser:self];
}
- (void)viewWillDisappear:(BOOL)animated {
    [activityIndicator stopAnimating];
}
- (void)viewDidDisappear:(BOOL)animated {
    [activityIndicator stopAnimating];
}
- (void)viewWillAppear:(BOOL)animated {
    [self.tableView reloadData];
}
#pragma mark - Backend methods

- (void)loadRecents
{
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 75 , 13, 20, 20);
    [self.navigationController.navigationBar addSubview:activityIndicator];
    
    [activityIndicator startAnimating];
    self.navigationItem.title = @"Connecting...";

	PFUser *user = [PFUser currentUser];
	if ((user != nil) && (firebase == nil))
	{
        firebase = [[[FIRDatabase database] reference] child:@"Recent"];
		FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"userId"] queryEqualToValue:user.objectId];
		[query observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
		{
			[recentConvos removeAllObjects];
            [fixRecentConvos removeAllObjects];
            [allRecentConvos removeAllObjects];
			if (snapshot.value != [NSNull null])
			{
                
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
                    if  ([recent[@"deleted"] isEqualToString:@"NO"] ) {
                    [recentConvos addObject:recent];
                    [fixRecentConvos addObject:recent];
                    }
                    [allRecentConvos addObject:recent];
                }
			}
            self.tableView.tableHeaderView = self.searchBar;
			[self.tableView reloadData];
            
            [activityIndicator stopAnimating];
            [activityIndicator2 stopAnimating];
            
            self.navigationItem.title = @"CHATS";
			
            [self updateTabCounter];
            
            if ([recentConvos count] == 0) {
                if (!self.blankTimelineView.superview) {
                    self.tableView.scrollEnabled = NO;
                    self.blankTimelineView.alpha = 0.0f;
                    self.tableView.tableHeaderView = self.blankTimelineView;
                    
                    [UIView animateWithDuration:0.200f animations:^{
                        self.blankTimelineView.alpha = 1.0f;
                    }];
                }
            } else {
                self.tableView.scrollEnabled = YES;
                [self.blankTimelineView removeFromSuperview];
            }

		}];
    } else {
        self.tableView.scrollEnabled = YES;
        [activityIndicator stopAnimating];
        [activityIndicator2 stopAnimating];
        self.navigationItem.title = @"CHATS";
        [self.tableView reloadData];
    }
    [activityIndicator stopAnimating];
}

- (void)searchRecents:(NSString *)search
{
    [recentConvos removeAllObjects];
    for (PFObject *recent in fixRecentConvos) {
        NSString *name_lower = [recent[@"description"] lowercaseString];
        NSString *lastMessage_lower = [recent[@"lastMessage"] lowercaseString];
        if ([name_lower containsString:[search lowercaseString]] || [lastMessage_lower containsString:[search lowercaseString]]) {
            [recentConvos addObject:recent];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Helper methods

- (void)updateTabCounter
{
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
	int total = 0;
	for (NSDictionary *recent in recentConvos)
	{
		total += [recent[@"counter"] intValue];
	}
	UITabBarItem *item = self.tabBarController.tabBar.items[0];
    if (total == 0) {
        currentInstallation.badge = 0;
        item.badgeValue = nil;
    } else {
        item.badgeValue = [NSString stringWithFormat:@"%i", total];
        currentInstallation.badge = total;
    }
    [currentInstallation saveEventually];
}
- (void)changeBackTitle:(NSString*)title
{
    self.navigationItem.backBarButtonItem.title = title;
}
#pragma mark - User actions

- (void)actionChat:(NSString *)groupId withTitle:(NSString *)title
{
	ESChatView *chatView = [[ESChatView alloc] initWith:groupId andTitle:title];
	chatView.hidesBottomBarWhenPushed = YES;
	[self.navigationController pushViewController:chatView animated:YES];
}

- (void)actionCleanup
{
	[firebase removeAllObservers];
	firebase = nil;
    [recentConvos removeAllObjects];
    [fixRecentConvos removeAllObjects];
    [allRecentConvos removeAllObjects];
    [deletionRows removeAllObjects];
    [deletionIndexPaths removeAllObjects];
	[self.tableView reloadData];
	[self updateTabCounter];
}

- (void)actionCompose
{
    ESPhoneBook *addressBookView = [[ESPhoneBook alloc] init];
    addressBookView.delegate = self;
    NavigationController *navController = [[NavigationController alloc] initWithRootViewController:addressBookView];
    [self presentViewController:navController animated:YES completion:nil];}

- (void)actionPeople
{
    [self.tabBarController setSelectedIndex:2];
}
- (void)actionEdit
{
    [self.tableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(actionDelete)];

}
- (void)actionCancel {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionCompose)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(actionEdit)];
    [self.tableView setEditing:NO animated:YES];
    
    [deletionRows removeAllObjects];
    [deletionIndexPaths removeAllObjects];

}
- (void)actionDelete
{
   
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionCompose)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(actionEdit)];
    [self.tableView setEditing:NO animated:YES];

    [recentConvos removeObjectsInArray:deletionRows];
    [self updateTabCounter];
    [self.tableView deleteRowsAtIndexPaths:deletionIndexPaths withRowAnimation:UITableViewRowAnimationLeft];
    
    for (NSDictionary *recent in deletionRows) {
        [ESUtility deleteRecentChat:recent];
    }
    
    [deletionRows removeAllObjects];
    [deletionIndexPaths removeAllObjects];
}
#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
		if (buttonIndex == 0)
		{
			ESSelectSingleView *selectSingleView = [[ESSelectSingleView alloc] init];
			selectSingleView.delegate = self;
			NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectSingleView];
			[self presentViewController:navController animated:YES completion:nil];
		}
	/*	if (buttonIndex == 1)
		{
			ESSelectMultipleView *selectMultipleView = [[ESSelectMultipleView alloc] init];
			selectMultipleView.delegate = self;
			NavigationController *navController = [[NavigationController alloc] initWithRootViewController:selectMultipleView];
			[self presentViewController:navController animated:YES completion:nil];
		}*/
		if (buttonIndex == 1)
		{
			ESPhoneBook *addressBookView = [[ESPhoneBook alloc] init];
			addressBookView.delegate = self;
			NavigationController *navController = [[NavigationController alloc] initWithRootViewController:addressBookView];
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

#pragma mark - SelectSingleDelegate
- (BOOL) conversationInexistant:(NSString *)id1 andOtherUser:(NSString *)id2 {
    
    for (NSDictionary *recent in allRecentConvos) {
        if ([recent[@"isGroup"] isEqualToString:@"NO"]) {
        if ([recent[@"members"] count] == 2) {
            for (NSString *objectID in recent[@"members"]) {
                if ([objectID isEqualToString:id1]) {
                    for (NSString *objectID in recent[@"members"]) {
                        if ([objectID isEqualToString:id2]) {
                            return NO;
                        }
                    }
                }
                
            }
        }
        }
    }
    return YES;
}
- (void)didSelectSingleUser:(PFUser *)user2
{   PFUser *user1 = [PFUser currentUser];
    NSString *id1 = user1.objectId;
    NSString *id2 = user2.objectId;
    BOOL createNew = [self conversationInexistant:id1 andOtherUser:id2];
    
    NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
    NSArray *members = @[user1.objectId, user2.objectId];
    if (createNew) {
        [ESUtility createRecentItemForUser:user1 withGroupId:groupId withMembers:members withDescription:user2[kESUserFullname] andOption:@"NO"];
        [ESUtility createRecentItemForUser:user2 withGroupId:groupId withMembers:members withDescription:user1[kESUserFullname] andOption:@"NO"];
    }
    
    [self actionChat:groupId withTitle:user2[kESUserFullname]];
    
    PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
    [query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
    [query whereKey:kESPeopleUser2 equalTo:user2];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         if (!object) {
             [ESUtility peopleSave:[PFUser currentUser] andUser:user2];
         }
     }];
}

#pragma mark - SelectMultipleDelegate

- (void)didSelectMultipleUsers:(NSMutableArray *)users
{
    NSString *groupId = [ESUtility startMultipleChat:users];
	[self actionChat:groupId withTitle:@"Group"];
    
    for (PFUser *user2 in users) {
        PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
        [query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
        [query whereKey:kESPeopleUser2 equalTo:user2];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
         {
             if (!object) {
                 [ESUtility peopleSave:[PFUser currentUser] andUser:user2];
             }
         }];
    }
}

#pragma mark - AddressBookDelegate

- (void)didSelectAddressBookUser:(PFUser *)user2
{
    PFUser *user1 = [PFUser currentUser];
    NSString *id1 = user1.objectId;
    NSString *id2 = user2.objectId;
    BOOL createNew = [self conversationInexistant:id1 andOtherUser:id2];
    
    NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
    NSArray *members = @[user1.objectId, user2.objectId];
    if (createNew) {
        [ESUtility createRecentItemForUser:user1 withGroupId:groupId withMembers:members withDescription:user2[kESUserFullname] andOption:@"NO"];
        [ESUtility createRecentItemForUser:user2 withGroupId:groupId withMembers:members withDescription:user1[kESUserFullname] andOption:@"NO"];
    }
    [self actionChat:groupId withTitle:user2[kESUserFullname]];

    
    PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
    [query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
    [query whereKey:kESPeopleUser2 equalTo:user2];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         if (!object) {
             [ESUtility peopleSave:[PFUser currentUser] andUser:user2];
         }
     }];
}

#pragma mark - FacebookFriendsDelegate

- (void)didSelectFacebookUser:(PFUser *)user2
{
    PFUser *user1 = [PFUser currentUser];
    NSString *id1 = user1.objectId;
    NSString *id2 = user2.objectId;
    BOOL createNew = [self conversationInexistant:id1 andOtherUser:id2];

    NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
    NSArray *members = @[user1.objectId, user2.objectId];
    if (createNew) {
        [ESUtility createRecentItemForUser:user1 withGroupId:groupId withMembers:members withDescription:user2[kESUserFullname] andOption:@"NO"];
        [ESUtility createRecentItemForUser:user2 withGroupId:groupId withMembers:members withDescription:user1[kESUserFullname] andOption:@"NO"];
    }
    [self actionChat:groupId withTitle:user2[kESUserFullname]];
    
    
    PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
    [query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
    [query whereKey:kESPeopleUser2 equalTo:user2];
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
     {
         if (!object) {
             [ESUtility peopleSave:[PFUser currentUser] andUser:user2];
         }
     }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [recentConvos count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return CGFLOAT_MIN;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ESRecentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ESRecentCell" forIndexPath:indexPath];
    
    cell.tag = indexPath.row;
    NSDictionary *recent = recentConvos[indexPath.row];
    
    if ([recent[@"groupId"] length] == 20 && [recent[@"isGroup"] isEqualToString:@"NO"]) {

        NSString *groupId = recent[@"groupId"];
        NSString *otherUserId = [groupId stringByReplacingOccurrencesOfString:[PFUser currentUser].objectId withString:@""];

        PFQuery *query = [PFQuery queryWithClassName:kESUserClassName];
        [query whereKey:kESUserObjectID equalTo:otherUserId];
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
        if (![cachedImages objectForKey:otherUserId]) {
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
             {
                 if (error == nil)
                 {
                     PFUser *user = (PFUser *)object;
                     if (user[kESUserPicture]) {
                         if (cell.tag == indexPath.row) {
                             [cell.imageUser setFile:user[kESUserPicture]];
                             [cell.imageUser loadInBackground:^(UIImage *image, NSError *error){
                                 if (!error) {
                                     NSData *imgData = UIImageJPEGRepresentation(image, 1.0f);
                                     [cachedImages setObject:imgData forKey:otherUserId];

                                 }
                             }];
                         }
                     }
                 }
             }];
        }
        else {
            UIImage *profilepicture = [UIImage imageWithData:[cachedImages objectForKey:otherUserId]];
            cell.imageUser.image = profilepicture;
            
        }
        
    } else if ([recent[@"isGroup"] isEqualToString:@"YES"]){
        [cell.imageUser setImage:[UIImage imageNamed:@"group_placeholder"]];
        
        PFQuery *query = [PFQuery queryWithClassName:kESGroupClassName];
        [query whereKey:kESGroupName equalTo:recent[@"description"]];
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
        
        if (![cachedImages objectForKey:recent[@"description"]]) {
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
             {
                 if (error == nil)
                 {
                     if (object[kESUserPicture]) {
                         if (cell.tag == indexPath.row) {
                             [cell.imageUser setFile:object[kESUserPicture]];
                             [cell.imageUser loadInBackground:^(UIImage *image, NSError *error){
                                 if (!error) {
                                     NSData *imgData = UIImageJPEGRepresentation(image, 1.0f);
                                     [cachedImages setObject:imgData forKey:recent[@"description"]];
                                     
                                 }
                             }];
                         }
                         
                         
                     }
                 }
             }];
        }
        else {
            UIImage *profilepicture = [UIImage imageWithData:[cachedImages objectForKey:recent[@"description"]]];
            cell.imageUser.image = profilepicture;
        }
    }
	[cell applyData:recentConvos[indexPath.row]];
    if (indexPath.row == [recentConvos count] - 1 ) {
        cell.thinLine.frame = CGRectMake(0, cell.contentView.frame.size.height-0.5, [UIScreen mainScreen].bounds.size.width, 0.5);
    }
    [cell.imageUser setNeedsDisplay];
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary *recent = recentConvos[indexPath.row];
	[recentConvos removeObject:recent];
	[self updateTabCounter];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [ESUtility deleteRecentChat:recent];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        NSDictionary *recent = recentConvos[indexPath.row];
        [deletionRows addObject:recent];
        [deletionIndexPaths addObject:indexPath];
    }
    if (!tableView.editing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        NSDictionary *recent = recentConvos[indexPath.row];
        
        NSString *groupId = recent[@"groupId"];
        if ([groupId length] == 20) {
            [self actionChat:groupId withTitle:recent[@"description"]];
        }
        else {
            [self actionChat:recent[@"groupId"] withTitle:recent[@"description"]];
            
        }
    }
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        NSDictionary *recent = recentConvos[indexPath.row];
        [deletionRows removeObject:recent];
        [deletionIndexPaths removeObject:indexPath];
    }
}
#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0)
    {
        [self searchRecents:searchText];
    }
    else {
        [recentConvos removeAllObjects];
        [recentConvos addObjectsFromArray:fixRecentConvos];
        [self.tableView reloadData];
    };
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
    searchBar.text = @"";
    [searchBar resignFirstResponder];
    
    [recentConvos removeAllObjects];
    [recentConvos addObjectsFromArray:fixRecentConvos];
    [self.tableView reloadData];

}
- (void)applicationDidReceiveRemoteNotification:(NSNotification *)note {
    NSDictionary* userInfo = note.userInfo;
    NSString *objectId = [userInfo objectForKey:@"groupId"];
    NSString *title = [userInfo objectForKey:@"groupTitle"];
    [self.navigationController popToRootViewControllerAnimated:NO];
    [self actionChat:objectId withTitle:title];
}
@end
