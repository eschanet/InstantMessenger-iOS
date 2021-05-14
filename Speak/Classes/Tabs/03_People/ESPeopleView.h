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

#import "ESSelectSingleView.h"
#import "ESSelectMultipleView.h"
#import "ESPhoneBook.h"
#import "ESFacebookFriendsView.h"
#import <AddressBook/AddressBook.h>

/**
 *  Interface declaration of the people view, the view that is used to display the contacts from your phonebook and from within the app
 */
@interface ESPeopleView : UITableViewController <UISearchBarDelegate,UIActionSheetDelegate, SelectSingleDelegate, SelectMultipleDelegate, AddressBookDelegate, FacebookFriendsDelegate,MFMailComposeViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@end
