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
#import "ESGroupsView.h"
#import "ESPeopleView.h"
#import "ESSettingsView.h"
#import "ESWelcomeView.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UITabBarController *tabBarController;

/**
 *  Viewcontroller displaying the recent chats
 */
@property (strong, nonatomic) ESRecentView *recentView;
/**
 *  Viewcontroller displaying the groups
 */
@property (strong, nonatomic) ESGroupsView *groupsView;
/**
 *  Viewcontroller displaying the different contacts
 */
@property (strong, nonatomic) ESPeopleView *peopleView;
/**
 *  Viewcontroller displaying a bunch of settings and your profile
 */
@property (strong, nonatomic) ESSettingsView *settingsView;
/**
 *  Welcome and Login view
 */
@property (strong, nonatomic) ESWelcomeView *welcomeView;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocationCoordinate2D coordinate;
/**
 *  Let the device register for notifications
 */
+ (void) registerForRemoteNotifications;
@end
