
#import "AppDelegate.h"

#import "ESStickersView.h"
#import "ESStickersCell.h"

@interface ESStickersView()
/**
 *  CollectionView where all the different stickers are being displayed.
 */
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation ESStickersView

@synthesize delegate;

- (void)viewDidLoad
{
	[super viewDidLoad];
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    
    self.navigationItem.title = @"STICKERS";
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self
																						  action:@selector(actionCancel)];
	[self.collectionView registerNib:[UINib nibWithNibName:@"ESStickersCell" bundle:nil] forCellWithReuseIdentifier:@"ESStickersCell"];
	AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
	self.collectionView.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height-64);
}

#pragma mark - User actions

- (void)actionCancel
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return 79;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	ESStickersCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ESStickersCell" forIndexPath:indexPath];
	[cell applyData:indexPath.item];
	return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	[collectionView deselectItemAtIndexPath:indexPath animated:YES];
	NSString *sticker = [NSString stringWithFormat:@"stickersend%02d", (int) indexPath.item+1];
	if (delegate != nil) [delegate didSelectSticker:sticker];
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
