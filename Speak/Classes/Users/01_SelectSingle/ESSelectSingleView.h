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

@protocol SelectSingleDelegate

- (void)didSelectSingleUser:(PFUser *)user;

@end
/**
 *  Interface declaration of the select single view, used to select a single recipient for a conversation or as a contact
 */
@interface ESSelectSingleView : UITableViewController <UISearchBarDelegate>

@property (nonatomic, assign) IBOutlet id<SelectSingleDelegate>delegate;

@end
