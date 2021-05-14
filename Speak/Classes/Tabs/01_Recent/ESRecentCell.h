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

#import "JSBadgeView.h"

@interface ESRecentCell : PFTableViewCell
/**
 *  iOS styled badge in the upper right corner of the user's profile picture, indicating how many unread messages a conversation has
 */
@property (strong, nonatomic) JSBadgeView *badgeView;
/**
 *  If a message has been read, this will be indicated via a small label in the cell
 */
@property (strong, nonatomic) IBOutlet UILabel *readLabel;
/**
 *  Cells are divided one from another with this small grey line
 */
@property (strong, nonatomic) IBOutlet UIView *thinLine;
/**
 *  This is the user's profile picture
 */
@property (strong, nonatomic) IBOutlet PFImageView *imageUser;
/**
 *  At creation of the cell, we call this method to actually bind all the data to the cell, to populate it.
 */
- (void)applyData:(NSDictionary *)recent_;

@end
