
/**
 *  Interface of the sticker cell, a cell used to display funny stickers
 */
@interface ESStickersCell : UICollectionViewCell

/**
 *  Binding data to the sticker cell
 *
 *  @param index the index where the image lies
 */
- (void)applyData:(NSInteger)index;

@end
