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

#import "ESPageViewController.h"
#import "ESWelcomeView.h"
#import "ESLoginView.h"
#import "ESRegisterView.h"

@interface ESWelcomeView()

/**
 *  Takes the user to the login page
 */
@property (strong, nonatomic) IBOutlet UIButton *loginButton;
/**
 *  Takes the user to the signup page
 */
@property (strong, nonatomic) IBOutlet UIButton *signupButton;
/**
 *  The horizontal gray spacer
 */
@property (strong, nonatomic) IBOutlet UIView *spacer1;
/**
 *  The vertical gray spacer
 */
@property (strong, nonatomic) IBOutlet UIView *spacer2;
/**
 *  Icon of the project
 */
@property (strong, nonatomic) IBOutlet UIImageView *icon;

@end
@implementation ESWelcomeView
@synthesize loginButton,signupButton,spacer1,spacer2,icon, pageController,arrPageImages,arrPageTitles, arrPageSubTitles;
- (void)viewDidLoad
{
	[super viewDidLoad];
    arrPageTitles = @[@"Free Instant Messaging",@" Instant Sharing",@"It's Secure"];
    arrPageSubTitles = @[@"LuxChat is the worlds fastest instant messenger.",@"Share videos, images and voice notes in under 100ms.",@"All messages are encrypted and your chats are not visible to others."];
    arrPageImages =@[@"slide-1",@"slide-3",@"slide-2"];
    
    // Create page view controller
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];

    self.pageController.dataSource = self;
    ESPageViewController *startingViewController = [self viewControllerAtIndex:0];
    NSArray *viewControllers = [NSArray arrayWithObject:startingViewController];
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    // Change the size of page view controller
    self.pageController.view.frame = CGRectMake(0, 70, self.view.frame.size.width, self.view.frame.size.height - 85);
    [self addChildViewController:self.pageController];
  //  [self.view addSubview:self.pageController.view];
    [self.pageController didMoveToParentViewController:self];
    for (UIView *subview in self.pageController.view.subviews) {
        if ([subview isKindOfClass:[UIPageControl class]]) {
            UIPageControl *pageControl = (UIPageControl *)subview;
            pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
            pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
            pageControl.backgroundColor = [UIColor clearColor];
        }
    }   
    
	self.title = @"Welcome";
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.view.backgroundColor = [UIColor whiteColor];
    self.loginButton.frame = CGRectMake(0, 30, 100, 40);
    self.loginButton.hidden = YES;
    [self.signupButton setTitle:@"Start Messaging" forState:UIControlStateNormal];
    self.signupButton.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2-100, [UIScreen mainScreen].bounds.size.height - 70, 200, 40);
    [self.signupButton setTitleColor:[UIColor colorWithRed:0.0f/255.0f green:129.0f/255.0f blue:188.0f/255.0f alpha:1] forState:UIControlStateNormal];
    [self.signupButton setTitleColor:[UIColor colorWithRed:0.0f/255.0f green:60.0f/255.0f blue:100.0f/255.0f alpha:1] forState:UIControlStateHighlighted];
    [self.signupButton setImage:[UIImage imageNamed:@"Arrows-Back-icon"] forState:UIControlStateNormal];
    self.signupButton.titleEdgeInsets = UIEdgeInsetsMake(0, -self.signupButton.imageView.frame.size.width, 0, self.signupButton.imageView.frame.size.width);
    self.signupButton.imageEdgeInsets = UIEdgeInsetsMake(1, self.signupButton.titleLabel.frame.size.width + 5, -1, -self.signupButton.titleLabel.frame.size.width - 5);
    
    
    self.icon.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 100, [UIScreen mainScreen].bounds.size.height/4, 200, 200);
    self.icon.layer.cornerRadius = 20;
    self.icon.layer.masksToBounds = YES;
    
    self.loginButton.layer.cornerRadius = 4;
    self.signupButton.layer.cornerRadius = 4;
    
    self.loginButton.backgroundColor = [UIColor clearColor];
    self.signupButton.backgroundColor = [UIColor clearColor];
    
    UIImageView *img = [[UIImageView alloc]initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 100, [UIScreen mainScreen].bounds.size.height/4 - 70, 200, 200)];
    [img setImage:[UIImage imageNamed:@"iTunesArtwork"]];
    img.layer.cornerRadius = 100;
    img.layer.masksToBounds = YES;
    [self.view addSubview:img];
    
    UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(0, [UIScreen mainScreen].bounds.size.height / 2 + 10, [UIScreen mainScreen].bounds.size.width, 40)];
    title.text = @"LuxChat";
    title.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22];
    [self.view addSubview:title];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [UIColor darkGrayColor];

    UILabel *subTitle = [[UILabel alloc]initWithFrame:CGRectMake(20, [UIScreen mainScreen].bounds.size.height / 2 + 55, [UIScreen mainScreen].bounds.size.width-40, 50)];
    subTitle.numberOfLines = 3;
    subTitle.text = @"Luxembourg's first private messenger.";
    subTitle.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    subTitle.textAlignment = NSTextAlignmentCenter;
    subTitle.textColor = [UIColor darkGrayColor];

    [self.view addSubview:subTitle];
    
}
- (void) viewWillAppear:(BOOL)animated {
    self.navigationController.navigationBar.hidden = YES;
}

#pragma mark - User actions
- (IBAction)actionRegister:(id)sender
{
	ESRegisterView *registerView = [[ESRegisterView alloc] init];
	[self.navigationController pushViewController:registerView animated:YES];
}

- (IBAction)actionLogin:(id)sender
{
	ESLoginView *loginView = [[ESLoginView alloc] init];
	[self.navigationController pushViewController:loginView animated:YES];
}
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSUInteger index = ((ESPageViewController*) viewController).pageIndex;
    if ((index == 0) || (index == NSNotFound))
    {
        return nil;
    }
    index--;
    return [self viewControllerAtIndex:index];
   }

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSUInteger index = ((ESPageViewController*) viewController).pageIndex;
    if (index == NSNotFound)
    {
        return nil;
    }
    index++;
    if (index == [self.arrPageTitles count])
    {
        return nil;
    }
    return [self viewControllerAtIndex:index];
}
- (ESPageViewController *)viewControllerAtIndex:(NSUInteger)index {
    
    if (([self.arrPageTitles count] == 0) || (index >= [self.arrPageTitles count])) {
        return nil;
    }
    ESPageViewController *pageContentViewController = [[ESPageViewController alloc] initWithNibName:@"ESPageViewController" bundle:nil];
    pageContentViewController.imgFile = self.arrPageImages[index];
    pageContentViewController.txtTitle = self.arrPageTitles[index];
    pageContentViewController.subTxtTitle = self.arrPageSubTitles[index];
    pageContentViewController.pageIndex = index;
    return pageContentViewController;
}

-(NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController
{
    return [self.arrPageTitles count];
}

- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController
{
    return 0;
}
@end
