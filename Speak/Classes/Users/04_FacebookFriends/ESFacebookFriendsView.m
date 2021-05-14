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

#import "ESFacebookFriendsView.h"

@interface ESFacebookFriendsView()
{
	NSMutableArray *users;
}
@property (nonatomic, strong) UIView *blankTimelineView;
@end

@implementation ESFacebookFriendsView

@synthesize delegate;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"FACEBOOK FRIENDS";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	users = [[NSMutableArray alloc] init];
    
    
    self.blankTimelineView = [[UIView alloc] initWithFrame:self.tableView.bounds];
    
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake( [UIScreen mainScreen].bounds.size.width/2 -130, 60, 260.0f, 40.0f)];
    label.text = @"No registered facebook friends";
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor darkGrayColor];
    label.font = [UIFont fontWithName:@"HelvecticaNeue" size:16];
    
    [self.blankTimelineView addSubview:label];

	[self loadFacebook];
    
    
}

#pragma mark - Backend methods

- (void)loadFacebook
{
    if ([FBSDKAccessToken currentAccessToken]) {
        NSMutableDictionary* parameters = [NSMutableDictionary dictionary];
        [parameters setValue:@"friends" forKey:@"fields"];
        
        [[[FBSDKGraphRequest alloc] initWithGraphPath:@"/me/friends" parameters:parameters]
         startWithCompletionHandler:^(FBSDKGraphRequestConnection *connection, id result, NSError *error) {
             if (!error) {
                 NSLog(@"fetched users:%@", result);
                 
                 NSMutableArray *fbids = [[NSMutableArray alloc] init];
                 NSDictionary *userData = (NSDictionary *)result;
                 NSArray *fbusers = [userData objectForKey:@"data"];
                 
                 
                 for (NSDictionary *fbuser in fbusers)
                 {
                     [fbids addObject:[fbuser valueForKey:@"id"]];
                 }
                 [self loadUsers:fbids];

             }
             else {
                 NSLog(@"facebook fetch error: %@", error);

             }
         }];
    }
    
}

- (void)loadUsers:(NSMutableArray *)fbids
{
	PFUser *user = [PFUser currentUser];

	PFQuery *query1 = [PFQuery queryWithClassName:kESBlockedClassName];
	[query1 whereKey:kESBlockedUser1 equalTo:user];

	PFQuery *query2 = [PFQuery queryWithClassName:kESUserClassName];
	[query2 whereKey:kESUserObjectID doesNotMatchKey:kESBlockedUserID2 inQuery:query1];
	[query2 whereKey:kESUserFacebookID containedIn:fbids];
	[query2 orderByAscending:kESUserFullname];
	[query2 setLimit:1000];
	[query2 findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
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
                self.tableView.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, 0.1)];
            }
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [users count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];

	PFUser *user = users[indexPath.row];
	cell.textLabel.text = user[kESUserFullname];

	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	[self dismissViewControllerAnimated:YES completion:^{
		if (delegate != nil) [delegate didSelectFacebookUser:users[indexPath.row]];
	}];
}

@end
