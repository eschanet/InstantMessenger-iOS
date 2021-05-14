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

#import "ESPrivacyView.h"

@interface ESPrivacyView()
/**
 *  Webview used to display the html file of the privacy terms
 */
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ESPrivacyView

@synthesize webView;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"PRIVACY POLICY";}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	webView.frame = self.view.bounds;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[ESUtility applications:@"privacy.html"]]]];
}

@end