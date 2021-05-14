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

@protocol SelectMultipleDelegate

- (void)didSelectSingleUser:(PFUser *)user;

@end
/**
 *  Interface declaration of the select multiple view, used to select multiple users as contact or recipients of a conversation
 */
@interface ESSelectMultipleView : UITableViewController <UISearchBarDelegate>

@property (nonatomic, assign) IBOutlet id<SelectMultipleDelegate>delegate;

@end
