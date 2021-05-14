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

@interface ESSettingsView : UITableViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, UITextViewDelegate>
/**
 *  TextView containing the bio of the user. Editable.
 */
@property (nonatomic, strong) UITextView *bioTextview;
/**
 *  Save button in the navigation bar. When tapped, we check if the necessary information has been provided and the email is correct and then we save the user.
 */
@property (nonatomic, strong) UIBarButtonItem *saveInfoBtn;
/**
 *  Cancel button dismissing the view
 */
@property (nonatomic, strong) UIBarButtonItem *cancelBtn;

@end
