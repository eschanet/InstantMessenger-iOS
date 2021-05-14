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

#import "ESSelectMultipleView.h"
#import "ESGroupSettingsView.h"
#import "ESChatView.h"

@interface ESGroupSettingsView()
{
    /**
     *  The actual group object this view is all about
     */
	PFObject *group;
    /**
     *  Mutable array containing the users that are part of the group
     */
    NSMutableArray *users;
    /**
     *  In this view, we have to query all the recent conversations. Those conversations are stored in this mutable array
     */
    NSMutableArray *recentConvos;
}
/**
 *  Tableview cell leading to the conversation related to the group when tapped
 */
@property (strong, nonatomic) IBOutlet UITableViewCell *cellName;
/**
 *  Imageview containing the profile picture of the group
 */
@property (strong, nonatomic) IBOutlet PFImageView *profilePicture;
/**
 *  Name of the group. Included in the header.
 */
@property (strong, nonatomic) IBOutlet UILabel *labelName;
/**
 *  Header of the view, containing the group's profile picture, header picture and name label
 */
@property (strong, nonatomic) IBOutlet UIView *groupHeader;
/**
 *  Blurred profile picture, used as the header picture
 */
@property (strong, nonatomic) UIImageView *blurredBackground;


@end

@implementation ESGroupSettingsView

@synthesize cellName;
@synthesize labelName,profilePicture,groupHeader,blurredBackground;

- (id)initWith:(PFObject *)group_ andRecents:(NSMutableArray *)recentConvos_
{
	self = [super init];
	group = group_;
    recentConvos = recentConvos_;
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"GROUP SETTINGS";
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"Groups" style:UIBarButtonItemStylePlain target:nil action:nil];

	users = [[NSMutableArray alloc] init];

    self.tableView.tableHeaderView = groupHeader;
    profilePicture.layer.cornerRadius = profilePicture.frame.size.width/2;
    profilePicture.layer.masksToBounds = YES;
    profilePicture.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 35, 15, 70, 70);
    labelName.frame = CGRectMake(5, 95, [UIScreen mainScreen].bounds.size.width - 10, 30);
    groupHeader.frame = CGRectMake(groupHeader.frame.origin.x, groupHeader.frame.origin.y, [UIScreen mainScreen].bounds.size.width, 140);
    

    profilePicture.image = [UIImage imageNamed:@"group_placeholder@2x.png"];
    [profilePicture setFile:group[kESUserPicture]];
    [profilePicture loadInBackground:^(UIImage *image, NSError *error){
       
        if (!error) {
            blurredBackground = [[UIImageView alloc]initWithImage:profilePicture.image];
            blurredBackground.frame = groupHeader.frame;
            blurredBackground.contentMode = UIViewContentModeScaleToFill;
            [groupHeader insertSubview:blurredBackground atIndex:0];
            
            UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
            
            UIVisualEffectView *effectView = [[UIVisualEffectView alloc]initWithEffect:blur];
            effectView.frame = blurredBackground.frame;
            
            [blurredBackground addSubview:effectView];
        }
    }];

	[self loadGroup];
	[self loadUsers];
}

#pragma mark - Backend actions

- (void)loadGroup
{
	labelName.text = group[kESGroupName];
}

- (void)loadUsers
{
	PFQuery *query = [PFQuery queryWithClassName:kESUserClassName];
	[query whereKey:kESUserObjectID containedIn:group[kESGroupMembers]];
	[query orderByAscending:kESUserFullname];
	[query setLimit:1000];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
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

- (void)actionChat
{
	NSString *groupId = group.objectId;
    BOOL isNew = YES;
    for (NSDictionary *recent in recentConvos) {
        if ([recent[@"groupId"] isEqualToString:groupId]) {
            isNew = NO;
            break;
        }
    }
    if (isNew) {
        for (PFUser *user in users) {
            [ESUtility createRecentItemForUser:user withGroupId:groupId withMembers:group[kESGroupMembers] withDescription:group[kESGroupName] andOption:@"YES"];
        }
    }
	ESChatView *chatView = [[ESChatView alloc] initWith:groupId andTitle:group[@"name"]];
	[self.navigationController pushViewController:chatView animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([[group[kESGroupUser] objectId] isEqualToString:[PFUser currentUser].objectId]) return 3;
    else return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[group[kESGroupUser] objectId] isEqualToString:[PFUser currentUser].objectId]) {
        if (section == 0) return 1;
        if (section == 1) return 1;
        if (section == 2) return [users count]+1;
        return 0;
    } else {
        if (section == 0) return 1;
        if (section == 1) return [users count];
        return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[group[kESGroupUser] objectId] isEqualToString:[PFUser currentUser].objectId]) {
        if (section == 2) return @"Members";
        if (section == 1) return @"Group picture";
    } else {
        if (section == 1) return @"Members";
    }
	return nil;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[group[kESGroupUser] objectId] isEqualToString:[PFUser currentUser].objectId]) {
        if (indexPath.section == 1) {
            return 45;
        }
        else return 45;
    } else return 45;

}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ((indexPath.section == 0) && (indexPath.row == 0)) return cellName;
    if (indexPath.section == 1) {
        if ([[group[kESGroupUser] objectId] isEqualToString:[PFUser currentUser].objectId]) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
        if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        
        
        UIButton *imageButton = [[UIButton alloc]initWithFrame:profilePicture.frame];
       // [cell addSubview:imageButton];
        [imageButton addTarget:self action:@selector(actionPhoto) forControlEvents:UIControlEventTouchDown];
        cell.textLabel.text = @"Change group picture";
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
        
        return cell;
        } else {
            if (indexPath.row == [users count]) {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadCell"];
                if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"loadCell"];
                cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
                cell.textLabel.text = @"Add more users...";
                cell.textLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1];
                return cell;
            }
            else {
                UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
                if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
                cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
                PFUser *user = users[indexPath.row];
                cell.textLabel.text = user[kESUserFullname];
                return cell;
                
            }
        }

    }
    if ([[group[kESGroupUser] objectId] isEqualToString:[PFUser currentUser].objectId]) {

	if (indexPath.section == 2)
	{
        
        if (indexPath.row == [users count]) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadCell"];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"loadCell"];
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];

            cell.textLabel.text = @"Add more users...";
            cell.textLabel.textColor = [UIColor colorWithRed:0.0f/255.0f green:122.0f/255.0f blue:255.0f/255.0f alpha:1];
            return cell;
        }
        else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
            if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
            cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];

            PFUser *user = users[indexPath.row];
            cell.textLabel.text = user[kESUserFullname];
            return cell;
            
        }
	}
    }
	return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if ((indexPath.section == 0) && (indexPath.row == 0)) [self actionChat];
    if ([[group[kESGroupUser] objectId] isEqualToString:[PFUser currentUser].objectId]) {
    if (indexPath.section == 1) {
        PFUser *user1 = [PFUser currentUser];
        PFUser *user2 = group[kESGroupUser];
        if ([user1 isEqualTo:user2]) [self actionPhoto];
    }
    if (indexPath.section == 2) {
        if (indexPath.row == [users count]) {
            [self addNewUsers];
        }
    }
    }
}
- (void)addNewUsers {
    ESSelectMultipleView *selectSingleView = [[ESSelectMultipleView alloc] init];
    selectSingleView.delegate = self;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:selectSingleView];
    [self presentViewController:navController animated:YES completion:nil];

}
#pragma mark - SelectSingleDelegate

- (void)didSelectSingleUser:(PFUser *)user2
{
    [ProgressHUD show:@"Adding..."];
    NSMutableArray *members = group[kESGroupMembers];
    for (NSString *objectId in members) {
        if ([objectId isEqualToString:user2.objectId]) {
            [ProgressHUD showError:@"This user is already part of the group"];
            return;
        }
    }

    [members addObject:user2.objectId];
    [group setObject:members forKey:kESGroupMembers];
    [group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [ProgressHUD dismiss];
            [users addObject:user2];
            [ESUtility createRecentItemForUser:user2 withGroupId:group.objectId withMembers:group[kESGroupMembers] withDescription:group[kESGroupName] andOption:@"YES"];
            [ESUtility addUser:user2 toGroup:group.objectId withMembers:members];
            [self.tableView reloadData];
        

        }
        else [ProgressHUD showError:@"Connection error"];
    }];
    

}

- (void)actionPhoto
{
    [ESUtility presentPhotoLibrary:self editable:YES];
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = info[UIImagePickerControllerEditedImage];
    UIImage *full_picture = [ESUtility resizedImage:image withWidth:400 withHeight:400];
    UIImage *picture = [ESUtility resizedImage:image withWidth:140 withHeight:140];
    UIImage *thumbnail = [ESUtility resizedImage:image withWidth:60 withHeight:60];
    profilePicture.image = picture;
    blurredBackground.image = picture;
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
    group[kESUserPicture] = filePicture;
    group[kESUserBigPicture] = fileFullPicture;
    group[kESUserThumbnail] = fileThumbnail;
    [group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error != nil) [ProgressHUD showError:@"Network error."];
     }];
    [picker dismissViewControllerAnimated:YES completion:nil];

}


@end
