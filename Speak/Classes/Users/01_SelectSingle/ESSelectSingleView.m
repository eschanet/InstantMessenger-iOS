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

#import "ESOneLineTableViewCell.h"
#import "ESSelectSingleView.h"

@interface ESSelectSingleView()
{
    /**
     *  Mutable array containing the results of the searchbar
     */
	NSMutableArray *users;
}
/**
 *  Header containing the searchbar
 */
@property (strong, nonatomic) IBOutlet UIView *viewHeader;
/**
 *  Searchbar used to search for users
 */
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation ESSelectSingleView

@synthesize delegate;
@synthesize viewHeader, searchBar;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"SEARCH USERS";
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	self.tableView.tableHeaderView = viewHeader;
	users = [[NSMutableArray alloc] init];
	//[self loadUsers];
    
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.backgroundColor = [UIColor groupTableViewBackgroundColor];
    self.searchBar.placeholder = @"Search";
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self.view endEditing:YES];
}

#pragma mark - Backend methods

- (void)loadUsers
{
    /*
	PFUser *user = [PFUser currentUser];

	PFQuery *query1 = [PFQuery queryWithClassName:kESBlockedClassName];
	[query1 whereKey:kESBlockedUser1 equalTo:user];

	PFQuery *query2 = [PFQuery queryWithClassName:kESUserClassName];
	[query2 whereKey:kESUserObjectID notEqualTo:user.objectId];
	[query2 whereKey:kESUserObjectID doesNotMatchKey:kESBlockedUserID2 inQuery:query1];
	[query2 orderByAscending:kESUserFullname];
	[query2 setLimit:1000];
	[query2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
	{
		if (error == nil)
		{
			[users removeAllObjects];
			[users addObjectsFromArray:objects];
			[self.tableView reloadData];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
     */
    PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
    [query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
    [query includeKey:kESPeopleUser2];
    [query setLimit:1000];
    // [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             [users removeAllObjects];
             for (PFObject *object in objects) {
                 if ([[(PFUser*)[object objectForKey:@"user1"] objectId] isEqualToString:[[PFUser currentUser] objectId]]) {
                     [users addObject:(PFUser *)[object objectForKey:@"user2"]];
                 } else [users addObject:(PFUser *)[object objectForKey:@"user1"]];

             }
             [self.tableView reloadData];
         }
         else [ProgressHUD showError:@"Network error."];
     }];
    [users removeAllObjects];
    [self.tableView reloadData];

}

- (void)searchUsers:(NSString *)search
{
	PFUser *user = [PFUser currentUser];

	PFQuery *query1 = [PFQuery queryWithClassName:kESBlockedClassName];
	[query1 whereKey:kESBlockedUser1 equalTo:user];

	PFQuery *query2 = [PFQuery queryWithClassName:kESUserClassName];
	[query2 whereKey:kESUserObjectID notEqualTo:user.objectId];
	[query2 whereKey:kESUserObjectID doesNotMatchKey:kESBlockedUserID2 inQuery:query1];
	[query2 whereKey:kESUserFullnameLower containsString:[search lowercaseString]];
	[query2 orderByAscending:kESUserFullname];
	[query2 setLimit:1000];
	[query2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
	{
		if (error == nil)
		{
			[users removeAllObjects];
			[users addObjectsFromArray:objects];
			[self.tableView reloadData];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

#pragma mark - User actions

- (void)actionCancel
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([users count] == 0) {
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
    [label setText:@""];
    [view addSubview:label];
    // [view addSubview:thinLine];
    [view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];

    return view;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ESOneLineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"registeredCell"];
    if (cell == nil) cell = [[ESOneLineTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"registeredCell"];

	PFUser *user = users[indexPath.row];
	cell.textLabel.text = user[kESUserFullname];

    UIView *thinLine = [[UIView alloc]init];
    [cell.contentView addSubview:thinLine];
    thinLine.frame = CGRectMake(20, 50-0.5, [UIScreen mainScreen].bounds.size.width, 0.5);
    thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
    if (indexPath.row == [users count] - 1 ) {
        thinLine.frame = CGRectMake(0, 50-0.5, [UIScreen mainScreen].bounds.size.width, 0.5);
    }
    cell.imageView.image = [UIImage imageNamed:@"AvatarPlaceholderProfile"];
    cell.imageView.layer.cornerRadius = 20;
    cell.imageView.layer.masksToBounds = YES;
    [[user objectForKey:kESUserPicture] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            cell.imageView.image = image;
        }
    }];
    
	return cell;
    
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self dismissViewControllerAnimated:YES completion:^{
		if (delegate != nil) [delegate didSelectSingleUser:users[indexPath.row]];
	}];
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	if ([searchText length] > 0)
	{
		[self searchUsers:searchText];
	}
    else [users removeAllObjects];
;
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

	//[self loadUsers];
    [users removeAllObjects];

}

@end
