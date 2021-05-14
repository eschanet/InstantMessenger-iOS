
/**
 *  Protocol declaration of the sticker delegate.
 */
@protocol StickersDelegate
/**
 *  The user did select a sticker. This protocol method is called and we handle the choice of the user.
 *
 *  @param sticker <#sticker description#>
 */
- (void)didSelectSticker:(NSString *)sticker;

@end
/**
 *  Interface declaration of the sticker view
 */
@interface ESStickersView : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
/**
 *  Delegate of the sticker view. Used to communicate the choice of a sticker.
 */
@property (nonatomic, assign) IBOutlet id<StickersDelegate>delegate;

@end
