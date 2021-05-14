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


#import "ESMapView.h"

@interface ESMapView()
{
    /**
     *  The CLLocation we use to determine the position of the user
     */
	CLLocation *location;
}
/**
 *  The MKMapView everything in this class is all about...
 */
@property (strong, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation ESMapView

@synthesize mapView;

- (id)initWith:(CLLocation *)location_
{
	self = [super init];
	location = location_;
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"MAP";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	mapView.frame = self.view.bounds;
	MKCoordinateRegion region;
	region.center.latitude = location.coordinate.latitude;
	region.center.longitude = location.coordinate.longitude;
	region.span.latitudeDelta = 0.01;
	region.span.longitudeDelta = 0.01;
	[mapView setRegion:region animated:NO];
	MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
	[mapView addAnnotation:annotation];
	[annotation setCoordinate:location.coordinate];
}

#pragma mark - User actions

- (void)actionCancel
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
