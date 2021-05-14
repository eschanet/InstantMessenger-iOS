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

#define HEXCOLOR(c) [UIColor colorWithRed:((c>>24)&0xFF)/255.0 green:((c>>16)&0xFF)/255.0 blue:((c>>8)&0xFF)/255.0 alpha:((c)&0xFF)/255.0]
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)

#define		kESFirebase							@"https://chat-eric.firebaseio.com"

#define		kESDefaultTab                       0

#define		kESVideoLength                      10

#define		kESMessageColorOut					HEXCOLOR(0x89caf4)
#define		kESMessageColorIn					HEXCOLOR(0xE6E5EAFF)

#define		MESSAGE_INVITE						@"Check out the new amazing Chat app. More info: http://codelight.lu"

#define		kESInstallationClassName			@"_Installation"		//	Class name
#define		kESInstallationObjectID             @"objectId"				//	String
#define		kESInstallationUser                 @"user"					//	Pointer to User Class

#define		kESUserClassName					@"_User"				//	Class name
#define		kESUserObjectID                     @"objectId"				//	String
#define		kESUserUsername                     @"username"				//	String
#define		kESUserPassword                     @"password"				//	String
#define		kESUserEmail						@"email"				//	String
#define		kESUserEmailCopy					@"emailCopy"			//	String
#define		kESUserFullname                     @"fullname"				//	String
#define		kESUserFullnameLower				@"fullname_lower"		//	String
#define		kESUserTwitterID					@"twitterId"			//	String
#define		kESUserFacebookID					@"facebookId"			//	String
#define		kESUserBigPicture					@"full_picture"				//	File
#define		kESUserPicture						@"picture"				//	File
#define		kESUserThumbnail					@"thumbnail"			//	File
#define		kESUserFirebaseID					@"userFireId"			//	String

#define		kESBlockedClassName                 @"Blocked"				//	Class name
#define		kESBlockedUser						@"user"					//	Pointer to User Class
#define		kESBlockedUser1                     @"user1"				//	Pointer to User Class
#define		kESBlockedUser2                     @"user2"				//	Pointer to User Class
#define		kESBlockedUserID2					@"userId2"				//	String

#define		kESGroupClassName					@"Group"				//	Class name
#define		kESGroupUser						@"user"					//	Pointer to User Class
#define		kESGroupName						@"name"					//	String
#define		kESGroupNameLower                   @"name_lower"			//	String
#define		kESGroupMembers                     @"members"				//	Array

#define		kESPeopleClassName                  @"People"				//	Class name
#define		kESPeopleUser1						@"user1"				//	Pointer to User Class
#define		kESPeopleUser2						@"user2"				//	Pointer to User Class

#define		kESReportClassName                  @"Report"				//	Class name
#define		kESReportUser1						@"user1"				//	Pointer to User Class
#define		kESReportUser2						@"user2"				//	Pointer to User Class
#define		kESNotificationAppStarted			@"NCAppStarted"
#define		kESNotificationUserLogin			@"NCUserLoggedIn"
#define		kESNotificationUserLogout           @"NCUserLoggedOut"


