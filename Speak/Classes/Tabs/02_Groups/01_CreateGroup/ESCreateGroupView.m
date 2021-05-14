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

#import "ESCreateGroupView.h"

@interface ESCreateGroupView()
{
    /**
     * After loading the users, they are stored in this mutable array
     */
	NSMutableArray *users;
    /**
     *  After setting the users array, we put the complete information of the users in this mutable array, so that we can handle them easier afterwards
     */
	NSMutableArray *sections;
    /**
     *  Storing the selected users in this mutable array before creating the group
     */
	NSMutableArray *selection;
}
/**
 *  The header of the view, containing a textfield used to search for a specific user
 */
@property (strong, nonatomic) IBOutlet UIView *viewHeader;
/**
 *  Textfield that is contained in the view header and where the user types in a specific user he wants to search for
 */
@property (strong, nonatomic) IBOutlet UITextField *fieldName;

@end

@implementation ESCreateGroupView

@synthesize viewHeader, fieldName;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor grayColor];
    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"CREATE GROUP";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self
																						   action:@selector(actionDone)];
	UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
	[self.tableView addGestureRecognizer:gestureRecognizer];
	gestureRecognizer.cancelsTouchesInView = NO;
	self.tableView.tableHeaderView = viewHeader;
	self.tableView.tableFooterView = [[UIView alloc] init];
	users = [[NSMutableArray alloc] init];
	selection = [[NSMutableArray alloc] init];
	[self loadPeople];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[fieldName becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[self dismissKeyboard];
}

- (void)dismissKeyboard
{
	[self.view endEditing:YES];
}

#pragma mark - Backend actions

- (void)loadPeople
{
	PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
	[query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
	[query includeKey:kESPeopleUser2];
	[query setLimit:1000];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
	{
		if (error == nil)
		{
			[users removeAllObjects];
			for (PFObject *people in objects)
			{
				PFUser *user = people[kESPeopleUser2];
				[users addObject:user];
			}
			[self setObjects:users];
			[self.tableView reloadData];
		}
		else [ProgressHUD showError:@"Network error."];
	}];
}

- (void)setObjects:(NSArray *)objects
{
	if (sections != nil) [sections removeAllObjects];
	NSInteger sectionTitlesCount = [[[UILocalizedIndexedCollation currentCollation] sectionTitles] count];
	sections = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
	for (NSUInteger i=0; i<sectionTitlesCount; i++)
	{
		[sections addObject:[NSMutableArray array]];
	}
	NSArray *sorted = [objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
	{
		PFUser *user1 = (PFUser *)obj1;
		PFUser *user2 = (PFUser *)obj2;
		return [user1[kESUserFullname] compare:user2[kESUserFullname]];
	}];
	for (PFUser *object in sorted)
	{
		NSInteger section = [[UILocalizedIndexedCollation currentCollation] sectionForObject:object collationStringSelector:@selector(fullname)];
		[sections[section] addObject:object];
	}
}

#pragma mark - User actions

- (void)actionCancel
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionDone
{
	NSString *name = fieldName.text;
	if ([name length] == 0)		{
        [ProgressHUD showError:@"Group name must be set."];
        return;
    }
	if ([selection count] == 0) {
        [ProgressHUD showError:@"Please select some users."];
        return;
    }
    PFQuery *nameQuery = [PFQuery queryWithClassName:kESGroupClassName];
    [nameQuery whereKey:kESGroupName equalTo:name];
    [nameQuery findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
            if ([objects count] == 0) {
                PFUser *user = [PFUser currentUser];
                [selection addObject:user.objectId];
                            PFObject *object = [PFObject objectWithClassName:kESGroupClassName];
                object[kESGroupUser] = [PFUser currentUser];
                object[kESGroupName] = name;
                object[kESGroupNameLower] = [name lowercaseString];
                object[kESGroupMembers] = selection;
                [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                 {
                     if (error == nil)
                     {
                         [self dismissViewControllerAnimated:YES completion:nil];
                     }
                     else [ProgressHUD showError:@"Network error."];
                 }];
            }
            else [ProgressHUD showError:@"Group name already exists."];
        }
        else [ProgressHUD showError:@"Network error."];
    }];
	
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return [sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [sections[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ([sections[section] count] != 0)
	{
		return [[[UILocalizedIndexedCollation currentCollation] sectionTitles] objectAtIndex:section];
	}
	else return nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	return [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	return [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];

	NSMutableArray *userstemp = sections[indexPath.section];
	PFUser *user = userstemp[indexPath.row];
	cell.textLabel.text = user[kESUserFullname];

	BOOL selected = [selection containsObject:user.objectId];
	cell.accessoryType = selected ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;

	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSMutableArray *userstemp = sections[indexPath.section];
	PFUser *user = userstemp[indexPath.row];
	BOOL selected = [selection containsObject:user.objectId];
	if (selected) [selection removeObject:user.objectId]; else [selection addObject:user.objectId];
	[self.tableView reloadData];
}

@end
