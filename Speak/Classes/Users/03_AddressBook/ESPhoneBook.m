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

#import <AddressBook/AddressBook.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>

#import "ESTableViewCell.h"
#import "CRNInitialsImageView.h"
#import "ESPhoneBook.h"

@interface ESPhoneBook()
{
    BOOL skipLoading;
    NSMutableArray *users;
    NSMutableArray *userIds;
    NSMutableArray *sections;
    NSMutableArray *fixsections;
    NSMutableArray *users1;
    NSMutableArray *users2;
    NSMutableArray *fixusers1;
    NSMutableArray *fixusers2;
    NSMutableArray *recentConvos;
    
    NSIndexPath *indexSelected;
}
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation ESPhoneBook

@synthesize delegate;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"ADDRESS BOOK";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
    users = [[NSMutableArray alloc] init];
    userIds = [[NSMutableArray alloc] init];
    sections = [[NSMutableArray alloc]init];
    fixsections = [[NSMutableArray alloc]init];
    users1 = [[NSMutableArray alloc] init];
    users2 = [[NSMutableArray alloc] init];
    fixusers1 = [[NSMutableArray alloc] init];
    fixusers2 = [[NSMutableArray alloc] init];
    recentConvos = [[NSMutableArray alloc] init];	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, nil);
	ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
	{
		dispatch_async(dispatch_get_main_queue(), ^{
			if (granted) [self loadAddressBook];
		});
	});
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.tableView.tableHeaderView = self.searchBar;
}

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
        CFRelease(allPeople);
        CFRelease(addressBook);
        [self loadUsers];
    }
}

- (void)loadUsers
{
	NSMutableArray *emails = [[NSMutableArray alloc] init];
	for (NSDictionary *user in users1)
	{
		[emails addObjectsFromArray:user[@"emails"]];
	}
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
	}
}

#pragma mark - User actions

- (void)actionCancel
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) return [users2 count];
	if (section == 1) return [users1 count];
	return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ((section == 0) && ([users2 count] != 0)) return @"MY CONTACTS";
	if ((section == 1) && ([users1 count] != 0)) return @"NON-REGISTERED USERS";
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        ESTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"registeredCell"];
        if (cell == nil) cell = [[ESTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"registeredCell"];
        
        PFUser *user = users2[indexPath.row];
        cell.textLabel.text = user[kESUserFullname];
        cell.detailTextLabel.text = user[kESUserEmailCopy];
        cell.imageView.image = [UIImage imageNamed:@"AvatarPlaceholderProfile"];

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
    if (indexPath.section == 1)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        
        NSDictionary *user = users1[indexPath.row];
        NSString *email = [user[@"emails"] firstObject];
        NSString *phone = [user[@"phones"] firstObject];
        cell.textLabel.text = user[@"name"];
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 0)
	{
		[self dismissViewControllerAnimated:YES completion:^{
			if (delegate != nil) [delegate didSelectAddressBookUser:users2[indexPath.row]];
		}];
	}
	if (indexPath.section == 1)
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

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex == actionSheet.cancelButtonIndex) return;
	NSDictionary *user = users1[indexSelected.row];
	if (buttonIndex == 0) [self sendMail:user];
	if (buttonIndex == 1) [self sendSMS:user];
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
- (void)searchGroups:(NSString *)search
{
    [users1 removeAllObjects];
    [sections removeAllObjects];
    [users2 removeAllObjects];
    for (NSDictionary *user in fixusers1) {
        if ([[user[@"name"] lowercaseString] containsString:[search lowercaseString]]) {
            [users1 addObject:user];
        }
    }
    for (PFUser *user in fixsections) {
        if ([[user objectForKey:kESUserFullnameLower] containsString:[search lowercaseString]]) {
            [sections addObject:user];
            [users2 addObject:user];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0)
    {
        [self searchGroups:searchText];
    }
    else {
        [self loadUsers];
        [self loadAddressBook];
    }
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
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];
    
    [self loadUsers];
    [self loadAddressBook];

}

@end
