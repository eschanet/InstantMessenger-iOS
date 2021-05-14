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

#import "ESGroupTableViewCell.h"
#import "ESGroupsView.h"
#import "ESCreateGroupView.h"
#import "ESGroupSettingsView.h"
#import "NavigationController.h"

@interface ESGroupsView()
{
    /**
     *  Mutable array containing the groups fitting the entered string in the searchbar (obviously, this array contains all the groups in case there is no entry in the search bar)
     */
    NSMutableArray *groups;
    /**
     *  Mutable array containing all the groups, independent from the status of the search bar
     */
    NSMutableArray *fixGroups;
    NSMutableArray *deletionRows;
    NSMutableArray *deletionIndexPaths;
    NSMutableArray *recentConvos;
    /**
     *  Determines if the user is part of any groups, if not, we will show him an alternative view
     */
    BOOL hasGroups;
}
/**
 *  Search bar used to search through all the groups
 */
@property (nonatomic, strong) UISearchBar *searchBar;
/**
 *  View that is being displayed to the user in case there are no open groups
 */
@property (nonatomic, strong) UIView *blankTimelineView;

@end

@implementation ESGroupsView
@synthesize searchBar, blankTimelineView;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self)
	{
		[self.tabBarItem setImage:[UIImage imageNamed:@"tab_groups"]];
		self.tabBarItem.title = @"Groups";
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
    
    self.navigationItem.title = @"GROUPS";
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Groups" style:UIBarButtonItemStylePlain target:nil action:nil];


	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionNew)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(actionEdit)];
    self.tableView.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, 0.1)];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    self.tableView.allowsMultipleSelectionDuringEditing = YES;

	self.refreshControl = [[UIRefreshControl alloc] init];
	[self.refreshControl addTarget:self action:@selector(loadGroups) forControlEvents:UIControlEventValueChanged];
    groups = [[NSMutableArray alloc] init];
    fixGroups = [[NSMutableArray alloc] init];
    deletionIndexPaths = [[NSMutableArray alloc] init];
    deletionRows = [[NSMutableArray alloc] init];
    recentConvos = [[NSMutableArray alloc] init];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"Search";
    [self.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.searchBar.backgroundImage = [[UIImage alloc] init];
    self.searchBar.backgroundColor = [UIColor whiteColor];
    
    self.blankTimelineView = [[UIView alloc] initWithFrame:self.tableView.bounds];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake( [UIScreen mainScreen].bounds.size.width/2 - 105, [UIScreen mainScreen].bounds.size.height/2 - 140 - 64, 210.0f, 210.0f);    [button setBackgroundColor:[UIColor clearColor]];
    [button setImage:[UIImage imageNamed:@"logo_small_grey"] forState:UIControlStateNormal];
    button.layer.cornerRadius = 5;
    [button addTarget:self action:@selector(actionNew) forControlEvents:UIControlEventTouchUpInside];
    [self.blankTimelineView addSubview:button];
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeCustom];
    button2.frame = CGRectMake( [UIScreen mainScreen].bounds.size.width/2 - 110, [UIScreen mainScreen].bounds.size.height/2 - 64 + 10, 220.0f, 40.0f);
    [button2 setBackgroundColor:[UIColor clearColor]];
    [button2 setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
    [button2 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateHighlighted];
    [button2 setTitle:@"There are no open groups" forState:UIControlStateNormal];
    [button2.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:16]];
    button2.layer.cornerRadius = 5;
    [button2 addTarget:self action:@selector(actionNew) forControlEvents:UIControlEventTouchUpInside];
    [self.blankTimelineView addSubview:button2];

    hasGroups = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	if ([PFUser currentUser] != nil)
	{
		[self loadGroups];
	}
    else [ESUtility loginUser:self];
}
- (void)viewDidDisappear:(BOOL)animated {
    [self.searchBar resignFirstResponder];
}
- (void)viewWillAppear:(BOOL)animated {
    [self loadRecents];
    
    if (hasGroups) {
      //  [self.tableView setTableHeaderView:self.searchBar];
    }
}
#pragma mark - Backend actions

- (void)loadGroups
{
	PFUser *user = [PFUser currentUser];

	PFQuery *query = [PFQuery queryWithClassName:kESGroupClassName];
	[query whereKey:kESGroupMembers equalTo:user.objectId];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
	{
		if (error == nil)
		{
            if ([objects count] == 0) {
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
                [self.tableView setTableHeaderView:self.searchBar];
            }

            [groups removeAllObjects];
            [groups addObjectsFromArray:objects];
            [fixGroups removeAllObjects];
            [fixGroups addObjectsFromArray:objects];
			[self.tableView reloadData];
		}
		[self.refreshControl endRefreshing];
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
- (void)searchGroups:(NSString *)search
{
    [groups removeAllObjects];
    for (PFObject *group in fixGroups) {
        if ([[group objectForKey:kESGroupNameLower] containsString:[search lowercaseString]]) {
            [groups addObject:group];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - User actions

- (void)actionNew
{
	ESCreateGroupView *createGroupView = [[ESCreateGroupView alloc] init];
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:createGroupView];
	[self presentViewController:navController animated:YES completion:nil];
}

- (void)actionCleanup
{
    [groups removeAllObjects];
    [fixGroups removeAllObjects];
    [deletionRows removeAllObjects];
    [deletionIndexPaths removeAllObjects];
    [recentConvos removeAllObjects];
	[self.tableView reloadData];
}
- (void)actionEdit
{
    [self.tableView setEditing:YES animated:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(actionCancel)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(actionDelete)];
    
}
- (void)actionCancel {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionNew)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(actionEdit)];
    [self.tableView setEditing:NO animated:YES];
    
    [deletionRows removeAllObjects];
    [deletionIndexPaths removeAllObjects];
    
}
- (void)actionDelete
{
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionNew)];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(actionEdit)];
    [self.tableView setEditing:NO animated:YES];
    
    [groups removeObjectsInArray:deletionRows];
    for (PFObject *group in deletionRows) {
        PFUser *user1 = [PFUser currentUser];
        PFUser *user2 = group[kESGroupUser];
        if ([user1 isEqualTo:user2]) [ESUtility removeGroupItem:group]; else [ESUtility removeGroupMember:group user:user1];
    }
    [self.tableView deleteRowsAtIndexPaths:deletionIndexPaths withRowAnimation:UITableViewRowAnimationLeft];

    [deletionRows removeAllObjects];
    [deletionIndexPaths removeAllObjects];

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [groups count];
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	ESGroupTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) cell = [[ESGroupTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];

	PFObject *group = groups[indexPath.row];

    [cell setGroup:group];
    if (indexPath.row == [groups count] - 1 ) {
        cell.thinLine.frame = CGRectMake(0, 69.5, [UIScreen mainScreen].bounds.size.width, 0.5);
    }
//cell.detailTextLabel.text = [NSString stringWithFormat:@"%d members", (int) [group[kESGroupMembers] count]];
	//cell.detailTextLabel.textColor = [UIColor lightGrayColor];

	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	PFObject *group = groups[indexPath.row];
	[groups removeObject:group];
	PFUser *user1 = [PFUser currentUser];
	PFUser *user2 = group[kESGroupUser];
	if ([user1 isEqualTo:user2]) [ESUtility removeGroupItem:group]; else [ESUtility removeGroupMember:group user:user1];
	[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView.editing) {
        PFObject *group = groups[indexPath.row];
        [deletionRows addObject:group];
        [deletionIndexPaths addObject:indexPath];
    } else if (!tableView.editing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
            ESGroupSettingsView *groupESSettingsView = [[ESGroupSettingsView alloc] initWith:groups[indexPath.row] andRecents:recentConvos];
        groupESSettingsView.hidesBottomBarWhenPushed = YES;
        [self.navigationController pushViewController:groupESSettingsView animated:YES];

    }
}
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        PFObject *group = groups[indexPath.row];
        [deletionRows removeObject:group];
        [deletionIndexPaths removeObject:indexPath];
    }
}
#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchText length] > 0)
    {
        [self searchGroups:searchText];
    }
    else [self loadGroups];
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
    
    [self loadGroups];
}

@end
