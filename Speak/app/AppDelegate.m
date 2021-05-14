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



#import "AppDelegate.h"
#import "ESRecentView.h"
#import "ESGroupsView.h"
#import "ESPeopleView.h"
#import "ESSettingsView.h"
#import "NavigationController.h"

NSString * const NotificationCategoryIdent  = @"ACTIONABLE";
NSString * const NotificationActionOneIdent = @"ACTION_ONE";
NSString * const NotificationActionTwoIdent = @"ACTION_TWO";

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
   // [Parse enableDataSharingWithApplicationGroupIdentifier:@"group.eric.MessengerApp.com"];
	//[Parse setApplicationId:@"hqUeDpRbVTDp19kmQqSx59j5FKv0G0sMpoIGSHHM" clientKey:@"QWMAZRAy8Hg0BrK9pOIYRaqKlgbIW0tLxyiGwFPc"];
    
    [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
        configuration.applicationId = @"eP19w7fsnBibU3GmITL5pR4qYg0jJfkdVaM37kZi";
        configuration.clientKey = @"9oYSZZlbNHfTRGnUHJWUadMxz8yATSR8bED7ABVN";
        configuration.server = @"https://parseapi.back4app.com";
    }]];
    
    [FIRApp configure];
    [FIRDatabase database].persistenceEnabled = YES;
    //[PFTwitterUtils initializeWithConsumerKey:@"kS83MvJltZwmfoWVoyE1R6xko" consumerSecret:@"YXSupp9hC2m1rugTfoSyqricST9214TwYapQErBcXlP1BrSfND"];
	[PFFacebookUtils initializeFacebookWithApplicationLaunchOptions:launchOptions];
	
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(registerForRemoteNotifications) name:@"registerForNotifications" object:nil];
    
    [self checkPermissions];
    [AppDelegate registerForRemoteNotifications];
    if (![PFUser currentUser]) {
        [self initialpush];
    }
    else [self handlePush:launchOptions];

	[PFImageView class];
    
    NSURLCache *URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:50 * 1024 * 1024 diskPath:nil];
    [NSURLCache setSharedURLCache:URLCache];
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

	self.recentView = [[ESRecentView alloc] initWithNibName:@"ESRecentView" bundle:nil];
	self.groupsView = [[ESGroupsView alloc] initWithNibName:@"ESGroupsView" bundle:nil];
	self.peopleView = [[ESPeopleView alloc] initWithNibName:@"ESPeopleView" bundle:nil];
	self.settingsView = [[ESSettingsView alloc] initWithNibName:@"ESSettingsView" bundle:nil];

	NavigationController *navController1 = [[NavigationController alloc] initWithRootViewController:self.recentView];
	NavigationController *navController2 = [[NavigationController alloc] initWithRootViewController:self.groupsView];
	NavigationController *navController3 = [[NavigationController alloc] initWithRootViewController:self.peopleView];
	NavigationController *navController4 = [[NavigationController alloc] initWithRootViewController:self.settingsView];    
    
	self.tabBarController = [[UITabBarController alloc] init];
	self.tabBarController.viewControllers = @[navController1, navController2, navController3, navController4];
	self.tabBarController.tabBar.translucent = NO;
	self.tabBarController.selectedIndex = kESDefaultTab;

	self.window.rootViewController = self.tabBarController;
	[self.window makeKeyAndVisible];

    
    [[UINavigationBar appearance] setBarTintColor:[UIColor colorWithRed:0.9647 green:0.9647 blue:0.9647 alpha:1]];
    [[UITabBar appearance] setBarTintColor:[UIColor colorWithRed:0.9647 green:0.9647 blue:0.9647 alpha:1]];
    [[UITabBar appearance] setTintColor:[UIColor colorWithRed:60.0f/255.0f green:133.0f/255.0f blue:255.0f/255.0f alpha:1.0f]];
    [[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:60.0f/255.0f green:133.0f/255.0f blue:255.0f/255.0f alpha:1.0f]];
    
    return YES;
}
- (void)checkPermissions {
    NSUserDefaults *defaults= [NSUserDefaults standardUserDefaults];

    if([[[defaults dictionaryRepresentation] allKeys] containsObject:[NSString stringWithFormat:@"%@-showOnline", [PFUser currentUser].objectId]]){
        
    }
    else {
        
    }
    if([[[defaults dictionaryRepresentation] allKeys] containsObject:[NSString stringWithFormat:@"%@-readReceipt", [PFUser currentUser].objectId]]){
        
    }
    else {
        
    }

}
- (void) initialpush {
    UIApplication *application = [UIApplication sharedApplication];
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIMutableUserNotificationAction *action1;
        action1 = [[UIMutableUserNotificationAction alloc] init];
        [action1 setActivationMode:UIUserNotificationActivationModeForeground];
        [action1 setTitle:@"Reply"];
        [action1 setIdentifier:NotificationActionOneIdent];
        [action1 setDestructive:NO];
        [action1 setAuthenticationRequired:NO];
        
        UIMutableUserNotificationAction *action2;
        action2 = [[UIMutableUserNotificationAction alloc] init];
        [action2 setActivationMode:UIUserNotificationActivationModeBackground];
        [action2 setTitle:@"Ignore"];
        [action2 setIdentifier:NotificationActionTwoIdent];
        [action2 setDestructive:NO];
        [action2 setAuthenticationRequired:NO];
        
        UIMutableUserNotificationCategory *actionCategory;
        actionCategory = [[UIMutableUserNotificationCategory alloc] init];
        [actionCategory setIdentifier:NotificationCategoryIdent];
        [actionCategory setActions:@[action1]
                        forContext:UIUserNotificationActionContextDefault];
        
        NSSet *categories = [NSSet setWithObject:actionCategory];
        UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                        UIUserNotificationTypeSound|
                                        UIUserNotificationTypeBadge);
        
        UIUserNotificationSettings *settings;
        settings = [UIUserNotificationSettings settingsForTypes:types
                                                     categories:categories];
        
        [application registerUserNotificationSettings:settings];
        [application registerForRemoteNotifications];
    }
}
+ (void) registerForRemoteNotifications {
    UIApplication *application = [UIApplication sharedApplication];
    if  ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications]) return;
    
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
    {
        UIMutableUserNotificationAction *action1;
        action1 = [[UIMutableUserNotificationAction alloc] init];
        [action1 setActivationMode:UIUserNotificationActivationModeForeground];
        [action1 setTitle:@"Reply"];
        [action1 setIdentifier:NotificationActionOneIdent];
        [action1 setDestructive:NO];
        [action1 setAuthenticationRequired:NO];
        
        UIMutableUserNotificationAction *action2;
        action2 = [[UIMutableUserNotificationAction alloc] init];
        [action2 setActivationMode:UIUserNotificationActivationModeBackground];
        [action2 setTitle:@"Ignore"];
        [action2 setIdentifier:NotificationActionTwoIdent];
        [action2 setDestructive:NO];
        [action2 setAuthenticationRequired:NO];
        
        UIMutableUserNotificationCategory *actionCategory;
        actionCategory = [[UIMutableUserNotificationCategory alloc] init];
        [actionCategory setIdentifier:NotificationCategoryIdent];
        [actionCategory setActions:@[action1]
                        forContext:UIUserNotificationActionContextDefault];
        
        NSSet *categories = [NSSet setWithObject:actionCategory];
        UIUserNotificationType types = (UIUserNotificationTypeAlert|
                                        UIUserNotificationTypeSound|
                                        UIUserNotificationTypeBadge);
        
        UIUserNotificationSettings *settings;
        settings = [UIUserNotificationSettings settingsForTypes:types
                                                     categories:categories];
        
        NSUserDefaults *defaults= [NSUserDefaults standardUserDefaults];
        if([[[defaults dictionaryRepresentation] allKeys] containsObject:[NSString stringWithFormat:@"%@-receivePushes", [PFUser currentUser].objectId]]){
            if ([[defaults objectForKey:[NSString stringWithFormat:@"%@-receivePushes", [PFUser currentUser].objectId]] isEqualToString:@"ON"]) {
                [[PFUser currentUser] setObject:@"ON" forKey:@"receivePushes"];
                [[PFUser currentUser] saveInBackground];
                [application registerUserNotificationSettings:settings];
                [application registerForRemoteNotifications];
            }
        }
        else {
            if ([[PFUser currentUser]objectForKey:@"receivePushes"] && [[[PFUser currentUser]objectForKey:@"receivePushes"] isEqualToString:@"ON"]) {
                [application registerUserNotificationSettings:settings];
                [application registerForRemoteNotifications];
            }
            else if (![[PFUser currentUser]objectForKey:@"receivePushes"]) {
                [[PFUser currentUser] setObject:@"ON" forKey:@"receivePushes"];
                [[PFUser currentUser] saveInBackground];
                [application registerUserNotificationSettings:settings];
                [application registerForRemoteNotifications];
            }
        }
    }
 
}
- (void)applicationWillResignActive:(UIApplication *)application
{
	
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"appActive" object:nil userInfo:nil];

    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    currentInstallation.badge = 0;
    [currentInstallation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            [currentInstallation saveEventually];
        }
    }];
    
    [ESUtility postNotification:kESNotificationAppStarted];
	[self locationManagerStart];
    [FBSDKAppEvents activateApp];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	
}

#pragma mark - Facebook responses

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return [[FBSDKApplicationDelegate sharedInstance] application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
}

#pragma mark - Push notification methods

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	PFInstallation *currentInstallation = [PFInstallation currentInstallation];
	[currentInstallation setDeviceTokenFromData:deviceToken];
	[currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	//NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    UIApplicationState state = [application applicationState];
    if (state != UIApplicationStateActive) [[NSNotificationCenter defaultCenter] postNotificationName:@"openChat" object:nil userInfo:userInfo];
    else {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"didReceiveMessage" object:nil userInfo:userInfo];
    }

    /*
	//[PFPush handlePush:userInfo];
    UITabBarItem *tabBarItem = [[self.tabBarController.viewControllers objectAtIndex:0] tabBarItem];
    
    NSString *currentBadgeValue = tabBarItem.badgeValue;
    
    
    if (currentBadgeValue && currentBadgeValue.length > 0) {
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        NSNumber *badgeValue = [numberFormatter numberFromString:currentBadgeValue];
        NSNumber *newBadgeValue = [NSNumber numberWithInt:[badgeValue intValue] + 1];
        tabBarItem.badgeValue = [numberFormatter stringFromNumber:newBadgeValue];
    } else {
        tabBarItem.badgeValue = @"1";
    }
     */
}
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {
    
    if ([identifier isEqualToString:NotificationActionOneIdent]) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"openChat" object:nil userInfo:userInfo];
    }
    else if ([identifier isEqualToString:NotificationActionTwoIdent]) {
        
        NSLog(@"You chose action 2.");
    }
    if (completionHandler) {
        
        completionHandler();
    }
}
- (void)handlePush:(NSDictionary *)launchOptions {
    
    // If the app was launched in response to a push notification, we'll handle the payload here
    NSDictionary *remoteNotificationPayload = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if (remoteNotificationPayload) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"openChat" object:nil userInfo:remoteNotificationPayload];
        
    }
}

#pragma mark - Location manager methods

- (void)locationManagerStart
{
	if (self.locationManager == nil)
	{
		self.locationManager = [[CLLocationManager alloc] init];
		[self.locationManager setDelegate:self];
		[self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
		[self.locationManager requestWhenInUseAuthorization];
	}
	[self.locationManager startUpdatingLocation];
}

- (void)locationManagerStop
{
	[self.locationManager stopUpdatingLocation];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	self.coordinate = newLocation.coordinate;
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	
}

@end
