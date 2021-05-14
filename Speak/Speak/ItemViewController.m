//
//  ItemViewController.m
//  app
//
//  Created by Eric Schanet on 24.06.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import "ItemViewController.h"
#import <Parse/Parse.h>
#import "ESTableViewCell.h"

@interface ItemViewController () {
    NSMutableArray *users2;
    NSMutableArray *userIds;
    NSMutableArray *sections;

}
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

@end

@implementation ItemViewController
@synthesize activityIndicator, delegate;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    {
     
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Contacts";
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSForegroundColorAttributeName :[UIColor whiteColor]}];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    users2 = [[NSMutableArray alloc] init];
    userIds = [[NSMutableArray alloc] init];
    sections = [[NSMutableArray alloc] init];
    
}
- (void)viewWillAppear:(BOOL)animated {
    [self loadPeople];
}
- (void)loadPeople
{
    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicator.frame = CGRectMake(self.view.frame.size.width - 35 , 10, 20, 20);
    activityIndicator.color = [UIColor whiteColor];
    [self.navigationController.navigationBar addSubview:activityIndicator];
    [activityIndicator startAnimating];
 
    PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
    [query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
    [query includeKey:kESPeopleUser2];
    [query setLimit:1000];
    // [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             int userCount = (int)[users2 count];
             [users2 removeAllObjects];
             for (PFUser *people in objects)
             {
                 PFUser *user = people[kESPeopleUser2];
                 [users2 addObject:user];
                 [userIds addObject:user.objectId];
                 [self setObjects:users2];
             }
             if ([users2 count] != userCount) {
                 [self.tableView reloadData];
             }
         }
         [activityIndicator stopAnimating];
     }];
    
}
- (void)setObjects:(NSArray *)objects
{
    
    if (sections != nil) [sections removeAllObjects];
    NSArray *sorted = [objects sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2)
                       {
                           PFUser *user1 = (PFUser *)obj1;
                           PFUser *user2 = (PFUser *)obj2;
                           return [user1[kESUserFullname] compare:user2[kESUserFullname]];
                       }];
    for (PFUser *object in sorted)
    {
        
        [sections addObject:object];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return [users2 count];
    return 0;
}
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0;
}
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"registeredCell"];
        if (cell == nil) cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"registeredCell"];
        
        PFUser *user = sections[indexPath.row];
        cell.textLabel.text = user[kESUserFullname];
        cell.detailTextLabel.text = user[kESUserEmailCopy];
        cell.imageView.image = [UIImage imageNamed:@"AvatarPlaceholderProfile"];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        return cell;
    }
    return nil;
}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return YES;
    } else return NO;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    PFUser *user2 = sections[indexPath.row];
    
    [delegate sendingViewController:self sentItem:user2];
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
