
#import "ESStickersCell.h"

@interface ESStickersCell()
/**
 *  The actual image that is being displayed in the cell, taken from a list of images.
 */
@property (strong, nonatomic) IBOutlet UIImageView *imageItem;

@end

@implementation ESStickersCell

@synthesize imageItem;

- (void)applyData:(NSInteger)index
{
	NSString *sticker = [NSString stringWithFormat:@"sticker%02d", (int) index+1];
	imageItem.image = [UIImage imageNamed:sticker];
}

@end
