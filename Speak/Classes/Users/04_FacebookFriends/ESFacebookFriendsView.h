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

@protocol FacebookFriendsDelegate

- (void)didSelectFacebookUser:(PFUser *)user;

@end
/**
 *  Interface declaration of the facebook friends view, used to display the facebook friends in case a user has connected to facebook
 */
@interface ESFacebookFriendsView : UITableViewController <UISearchBarDelegate>

@property (nonatomic, assign) IBOutlet id<FacebookFriendsDelegate>delegate;

@end