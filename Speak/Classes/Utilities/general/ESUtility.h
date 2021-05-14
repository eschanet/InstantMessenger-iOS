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

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ESUtility : NSObject

#pragma mark - blocking users

+ (void)blockUser:(PFUser *)user2;
+ (void)blockUserOne:(PFUser *)user1 withUser:(PFUser *)user2;

+ (void)unblockUser:(PFUser *)user2;
+ (void)unblockUserOne:(PFUser *)user1 withUser:(PFUser *)user2;

#pragma mark - groups backend

+ (void)removeGroupMembers:(PFUser *)user1 withUser:(PFUser *)user2;

+ (void)removeGroupMember:(PFObject *)group user:(PFUser *)user;
+ (void)removeGroupItem:(PFObject *)group;

#pragma mark - contacts

+ (void)peopleSave:(PFUser *)user1 andUser:(PFUser *)user2;
+ (void)peopleDelete:(PFUser *)user1 andUser:(PFUser *)user2;

#pragma mark - push notifications 

+ (void)parsePushUserAssign;
+ (void)parsePushUserResign;

+ (void)sendPushNotificationToGroup:(NSString *)groupId withText:(NSString *)text andTitle:(NSString *)title;
+ (void)sendPushNotificationToMembers:(NSArray *)members withText:(NSString *)text andGroupId:(NSString *)groupId andTitle:(NSString *)title;

#pragma mark - chat/messages backend

+ (NSString*)startPrivateChatBetweenUser:(PFUser *)user1 andUser:(PFUser *)user2;
+ (NSString*)startMultipleChat:(NSMutableArray *)users;

+ (void)createRecentItemForUser:(PFUser *)user withGroupId:(NSString *)groupId withMembers:(NSArray *)members withDescription:(NSString *)description andOption:(NSString *)isGroup;
+ (void)createRecentItem2:(PFUser *)user withGroupId:(NSString *)groupId withMembers:(NSArray *)members withDescription:(NSString *)description andOption:(NSString *)isGroup;
+ (void)addUser:(PFUser *)user toGroup:(NSString *)groupId withMembers:(NSArray *)members;

+ (void)updateRecentCounterForChat:(NSString *)groupId withCounter:(NSInteger)amount andLastMessage:(NSString *)lastMessage;

+ (void)setReadForChat:(NSString *)groupId andStatus:(NSString *)status;
+ (void)setDeliveredForChat:(NSString *)groupId andStatus:(NSString *)status;
+ (void)setTypingForChat:(NSString *)groupId andStatus:(NSString *)status;

+ (void)clearRecentCounterForChat:(NSString *)groupId;

+ (void)deleteRecentItemsBetweenUser:(PFUser *)user1 andUser:(PFUser *)user2;
+ (void)deleteRecentChat:(NSDictionary *)recent;


#pragma mark - user reporting 

+ (void)reportUser:(PFUser *)user2;

#pragma mark - audio recording

+ (void)presentAudioRecorder:(id)target;
+ (NSNumber*)audioDurationForPath:(NSString *)path;

#pragma mark - camera

+ (BOOL)presentMultiCamera:(id)target editable:(BOOL)canEdit;
+ (BOOL)presentPhotoLibrary:(id)target editable:(BOOL)canEdit;
+ (BOOL)presentVideoLibrary:(id)target editable:(BOOL)canEdit;

#pragma mark - general

+ (void)loginUser:(id)target;
+ (void)postNotification:(NSString *)notification;

#pragma mark - converting units

+ (NSString*)convertDateToString:(NSDate *)date;
+ (NSDate*)convertStringToDate:(NSString *)dateStr;
+ (NSString*)calculateTimeInterval:(NSTimeInterval)seconds;

#pragma mark - files

+ (NSString*)applications:(NSString *)file;
+ (NSString*)caches:(NSString *)file;

#pragma mark - image backend
+ (UIImage*)squaredImage:(UIImage *)image withSize:(CGFloat)size;
+ (UIImage*)resizedImage:(UIImage *)image withWidth:(CGFloat)width withHeight:(CGFloat)height;
+ (UIImage*)croppedImage:(UIImage *)image withX:(CGFloat)x withY:(CGFloat)y withWidth:(CGFloat)width withHeight:(CGFloat)height;


#pragma mark - video backend
+ (UIImage*)videoThumbnailForURL:(NSURL *)video;
+ (NSNumber*)videoDurationForURL:(NSURL *)video;

@end

