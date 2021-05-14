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


#import "JSQMessages.h"
#import "RNGridMenu.h"
#import "IQAudioRecorderController.h"
#import "ESStickersView.h"
/**
 Interface declaration of the chat view, the actual messaging viewcontroller, a subclass of the JSQMessagesViewController
 */
@interface ESChatView : JSQMessagesViewController <UIActionSheetDelegate, UIImagePickerControllerDelegate, RNGridMenuDelegate, IQAudioRecorderControllerDelegate, StickersDelegate, UIGestureRecognizerDelegate, UITextViewDelegate, JSQMessagesCollectionViewCellDelegate, UICollectionViewDelegate>
/**
 *  Custom init method of the chatview, passing the groupId and the title of the chat window (e.g. the name of the other user)
 *
 *  @param groupId_ ID of the group
 *  @param title_   title of the conversation
 *
 *  @return 
 */
- (id)initWith:(NSString *)groupId_ andTitle:(NSString *)title_;
/**
 *  Adding a user to the contacts
 */
- (void)addUser;
/**
 *  User did tap on the other user's avatar, take him to the profile page
 */
- (void) didTapAvatar;
/**
 *  Load the last 50 messages of the conversation, and then again 50, and again, and again and again as the user scrolls upwards
 */
- (void)loadMessages;
/**
 *  Add a new message to the conversation
 *
 *  @param item The item containing the message data
 *
 *  @return
 */
- (BOOL)addMessage:(NSDictionary *)item;
/**
 *  Create a new text message
 *
 *  @param item The item containg the message data
 *
 *  @return
 */
- (JSQMessage *)createTextMessage:(NSDictionary *)item;
/**
 *  Create a new video message
 *
 *  @param item The item containg the message data
 *
 *  @return
 */
- (JSQMessage *)createVideoMessage:(NSDictionary *)item;
/**
 *  Create a new picture message
 *
 *  @param item The item containg the message data
 *
 *  @return
 */
- (JSQMessage *)createPictureMessage:(NSDictionary *)item;
/**
 *  Create a new audio message
 *
 *  @param item The item containg the message data
 *
 *  @return
 */
- (JSQMessage *)createAudioMessage:(NSDictionary *)item;
/**
 *  Create a new location message
 *
 *  @param item The item containg the message data
 *
 *  @return
 */
- (JSQMessage *)createLocationMessage:(NSDictionary *)item;
/**
 *  Save the actual message to Firebase
 *
 *  @param item The item containing the message data
 */
- (void)messageSave:(NSMutableDictionary *)item;

/**
 *  Update the firebase item and indicate that there is a new message, thus we have to change the read receipts etc.
 *
 *  @param item The item containing the message data
 */
- (void)updateMessage:(NSDictionary *)item;
/**
 *  Load profile picture of the other user
 *
 *  @param senderId UserId of the other user
 */
- (void)loadAvatar:(NSString *)senderId;
/**
 *  User has hit "send", now decide what type of message it is and handle the outcome
 *
 *  @param text    The text of the message
 *  @param video   The video of the message
 *  @param picture The picture of the message
 *  @param audio   The audio of the message
 */
- (void)sendMessage:(NSString *)text withVideo:(NSURL *)video withPicture:(UIImage *)picture andWithAudio:(NSString *)audio;
/**
 *  User wants to send a normal text message
 *
 *  @param item  The item containing the data of the message
 *  @param text Actual text of the message
 */
- (void)sendTextMessage:(NSMutableDictionary *)item withText:(NSString *)text;
/**
 *  User wants to send a video message
 *
 *  @param item  The item containing the data of the message
 *  @param video NSURL of the actual video being sent
 */
- (void)sendVideoMessage:(NSMutableDictionary *)item withVideo:(NSURL *)video;
/**
 *  User wants to send a picture message
 *
 *  @param item    The item containing the data of the message
 *  @param picture UIImage of the actual picture being sent
 */
- (void)sendPictureMessage:(NSMutableDictionary *)item withPicture:(UIImage *)picture;
/**
 *  User wants to send
 *
 *  @param item  The item containing the data of the message
 *  @param audio Actual audio of the message
 */
- (void)sendAudioMessage:(NSMutableDictionary *)item andWithAudio:(NSString *)audio;
/**
 *  User wants to send his location
 *
 *  @param item  The item containing the data of the message
 */
- (void)sendLocationMessage:(NSMutableDictionary *)item;
/**
 *  Update the firebase item and indicate that there is a new message, thus we have to change the read receipts etc.
 *
 *  @param item The item containing the message data
 */
- (void)messageUpdate:(NSDictionary *)item;
/**
 *  If the other user hasn't yet read the message, you can delete it by calling this method
 */
- (void)messageDelete;
/**
 *  Display the typing indicator if the other user is currently typing
 */
- (void)typingIndicatorLoad;
/**
 *  Typing state changed, save this as a number
 *
 *  @param typing Number telling us if the user types currently or not
 */
- (void)typingIndicatorSave:(NSNumber *)typing;
@end
