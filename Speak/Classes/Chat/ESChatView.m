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

#import "JTSImageInfo.h"
#import "JTSImageViewController.h"
#import "GKImagePicker.h"
#import "AppDelegate.h"
#import "CRToast.h"
#import "ESAudioMediaItem.h"
#import "ESPhotoMediaItem.h"
#import "ESVideoMediaItem.h"
#import "ESRecentView.h"
#import "ESChatView.h"
#import "ESStickersView.h"
#import "ESProfileView.h"
#import "ESMapView.h"
#import "NavigationController.h"
#import "JSQMessage.h"

@interface ESChatView()  <GKImagePickerDelegate>
{
    /**
     *  the ID of the chatgroup
     */
	NSString *groupId;
    /**
     *  the title of the chat
     */
    NSString *title;
    /**
     *  Indicating the status of the user's connection (online, offline for x hrs, ...)
     */
    NSString *statusRecent;
    
    /**
     *  A simple helper bool
     */
	BOOL initialized;
    /**
     *  Indicates if the user has a picture or not
     */
    BOOL hasPicture;
    /**
     *  Indicating if the user is currently opening a profile. Used to prevent double tapping on the open profile button
     */
    BOOL opensProfile;
    /**
     *  Number of messages that should be loaded
     */
    int numberMessages;
    /**
     *  A helper variable used to decide if the user is currently typing something or not
     */
    int typingCounter;

    /**
     *  First firebase hook, checking for new messages
     */
	FIRDatabaseReference *firebase1;
    /**
     *  Second firebase hook, checking for changes of the typingIndicator
     */
	FIRDatabaseReference *firebase2;

    /**
     *  Mutable array containing the messages and all the metadata
     */
	NSMutableArray *items;
    /**
     *  Mutable array containing only the messages
     */
	NSMutableArray *messages;
    /**
     *  Mutable dictionary of the user's avatars
     */
	NSMutableDictionary *avatars;

    /**
     *  Tap gesture recognizer, used to catch taps on the title of the view (which is the other user's name)
     */
    UITapGestureRecognizer* gesture;
    
    /**
     *  If a cell is selected, we save the index of the cell in this index path
     */
	NSIndexPath *indexSelected;

    /**
     *  Simple JSQMessagesBubbleImage of an outgoing bubble
     */
	JSQMessagesBubbleImage *bubbleImageOutgoing;
    /**
     *  Simple JSQMessagesBubbleImage of an incoming bubble
     */
	JSQMessagesBubbleImage *bubbleImageIncoming;
    /**
     *  Simple JSQMessagesAvatarImage of a blank avatar
     */
	JSQMessagesAvatarImage *avatarImageBlank;

}
/**
 *  ImageView containing the user's profile picture
 */
@property (strong, nonatomic) PFImageView *profileImage;
/**
 *  A PFUser, used when the current user taps on the open profile button
 */
@property (strong, nonatomic) PFUser *user2;
/**
 *  A button above the profile image, used to intercept taps
 */
@property (strong, nonatomic) UIButton *profileImageButton;
/**
 *  Custom image picker view
 */
@property (nonatomic, strong) GKImagePicker *imagePicker;
/**
 *  If the user isn't in the contacts yet, a button pops up, prompting to add the user to the personal contacts
 */
@property (nonatomic, strong) UIButton *userAddButton;

@end
@implementation ESChatView
@synthesize profileImage, profileImageButton, imagePicker
,userAddButton, user2;
- (id)initWith:(NSString *)groupId_ andTitle:(NSString *)title_
{
	self = [super init];
	groupId = groupId_;
    title = title_;
    

	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
    
    //Registering some observers
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidReceiveRemoteNotification:) name:@"didReceiveMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(openLink:) name:@"openLinkInChat" object:nil];

    [JSQMessagesCollectionViewCell registerMenuAction:@selector(delete:)];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:groupId] && ![[[NSUserDefaults standardUserDefaults] objectForKey:groupId] isEqualToString:@"_empty_"]) {
        [self.inputToolbar.contentView.textView setText:[[NSUserDefaults standardUserDefaults] objectForKey:groupId]];
    }
    
    //Some helper bools
    hasPicture = NO;
    opensProfile = NO;

    //Profile image of the other user
    profileImage = [[PFImageView alloc]initWithImage:[UIImage imageNamed:@"chat_blank"]];
    [profileImage setFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - 48, 2, 38, 38)];
    CALayer * l = [profileImage layer];
    [l setMasksToBounds:YES];
    [l setCornerRadius:20.0];
    profileImage.alpha = 0.0f;
    [self.navigationController.navigationBar addSubview:profileImage];
    
    profileImageButton = [[UIButton alloc] initWithFrame:profileImage.frame];
    [profileImageButton addTarget:self action:@selector(didTapAvatar) forControlEvents:UIControlEventTouchDown];
    [self.navigationController.navigationBar addSubview:profileImageButton];
    

    if ([groupId length] == 20) {
        //This is actually a private conversation between two users, and not(!) a group, so let's handle this
        
        NSString *firstName = [[title componentsSeparatedByString:@" "] objectAtIndex:0];
        CGRect headerTitleSubtitleFrame = CGRectMake(0, 0, 150, 44);
        UIView* _headerTitleSubtitleView = [[UILabel alloc] initWithFrame:headerTitleSubtitleFrame];
        _headerTitleSubtitleView.backgroundColor = [UIColor clearColor];
        _headerTitleSubtitleView.autoresizesSubviews = YES;
        
        CGRect titleFrame = CGRectMake(0, 5, 150, 24);
        UILabel *titleView = [[UILabel alloc] initWithFrame:titleFrame];
        titleView.backgroundColor = [UIColor clearColor];
        titleView.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:15];
        titleView.textAlignment = NSTextAlignmentCenter;
        titleView.textColor = [UIColor grayColor];
        titleView.shadowOffset = CGSizeMake(0, -1);
        titleView.text = [firstName uppercaseString];
        titleView.adjustsFontSizeToFitWidth = YES;
        [_headerTitleSubtitleView addSubview:titleView];
        
        CGRect subtitleFrame = CGRectMake(0, 24, 150, 44-24);
        UILabel *subtitleView = [[UILabel alloc] initWithFrame:subtitleFrame];
        subtitleView.backgroundColor = [UIColor clearColor];
        subtitleView.font = [UIFont fontWithName:@"HelveticaNeue" size:10];
        subtitleView.textAlignment = NSTextAlignmentCenter;
        subtitleView.textColor = [UIColor grayColor];
        subtitleView.shadowOffset = CGSizeMake(0, -1);
        subtitleView.text = @"";
        subtitleView.adjustsFontSizeToFitWidth = YES;
        [_headerTitleSubtitleView addSubview:subtitleView];
        
        _headerTitleSubtitleView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
                                                     UIViewAutoresizingFlexibleRightMargin |
                                                     UIViewAutoresizingFlexibleTopMargin |
                                                     UIViewAutoresizingFlexibleBottomMargin);
        self.navigationItem.titleView = _headerTitleSubtitleView;
        
        gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(userTappedOnTitleName)];
        [_headerTitleSubtitleView setUserInteractionEnabled:YES];
        [_headerTitleSubtitleView addGestureRecognizer:gesture];

        NSString *userId = [groupId stringByReplacingOccurrencesOfString:[PFUser currentUser].objectId withString:@""];
        
        //Querying the user's profile picture and caching it
        PFQuery *query = [PFUser query];
        [query setCachePolicy:kPFCachePolicyCacheElseNetwork];
        [query getObjectInBackgroundWithId:userId block:^(PFObject *object, NSError *error) {
            if (object) {
                hasPicture = YES;
                [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
                    // Animate the alpha value of your imageView from 1.0 to 0.0 here
                    profileImage.alpha = 1.0f;
                } completion:^(BOOL finished) {
                }];
                
                user2 = (PFUser *)object;
                [user2 fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!error) {
                        [profileImage setFile:user2[kESUserBigPicture]];
                        [profileImage loadInBackground];
                    }
                }];
            }
        }];
         
        //Querying the user's online status, not caching this
        PFQuery *_query = [PFUser query];
        [_query getObjectInBackgroundWithId:userId block:^(PFObject *object, NSError *error) {
            if (object) {
                hasPicture = YES;
                [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
                    // Animate the alpha value of your imageView from 1.0 to 0.0 here
                    profileImage.alpha = 1.0f;
                } completion:^(BOOL finished) {
                }];
                
                user2 = (PFUser *)object;
                [user2 fetchInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                    if (!error) {
                        FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"users/%@", [object objectForKey:kESUserFirebaseID]]];

                        [firebase observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
                         {
                             if (snapshot.value != [NSNull null]) {
                                 NSDictionary *data = snapshot.value;
                                 if (data[@"connections"]) {
                                     subtitleView.text = @"online now";
                                 } else {
                                     double time = [data[@"lastonline"] doubleValue]/1000;
                                     int timeStampFromJSON = (int)time;
                                     int now = (int)[[NSDate date] timeIntervalSince1970];
                                     int dif = now - timeStampFromJSON;

                                     subtitleView.text = [ESUtility calculateTimeInterval:dif];
                                 }
                             }
                             
                         }];
                        
                        PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
                        [query whereKey:kESPeopleUser1 equalTo:[PFUser currentUser]];
                        [query whereKey:kESPeopleUser2 equalTo:user2];
                        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
                         {
                             if (!object) {
                                userAddButton = [[UIButton alloc]initWithFrame:CGRectMake(0, -40, [UIScreen mainScreen].bounds.size.width, 40)];
                                 userAddButton.backgroundColor = [UIColor colorWithRed:0.9647 green:0.9647 blue:0.9647 alpha:1];
                                 [userAddButton setTitle:@"Add To Contacts" forState:UIControlStateNormal];
                                 userAddButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:15];
                                 userAddButton.layer.cornerRadius = 0;
                                 userAddButton.alpha = 1.0f;
                                 userAddButton.layer.borderColor = [UIColor lightGrayColor].CGColor;
                                 userAddButton.layer.borderWidth = 0.5f;
                                 [userAddButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
                                 [userAddButton addTarget:self action:@selector(addUser) forControlEvents:UIControlEventTouchDown];
                                 [self.view insertSubview:userAddButton belowSubview:self.navigationController.navigationBar];

                                 
                                 UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]
                                                                          initWithTarget:self action:@selector(addUser)];
                                 [tapRecognizer setNumberOfTouchesRequired:2];
                                 [tapRecognizer setDelegate:self];
                                 [userAddButton addGestureRecognizer:tapRecognizer];
                                 
                                 [UIView animateWithDuration:0.3
                                                       delay:0
                                                     options:UIViewAnimationOptionCurveEaseOut                                                  animations:^(){
                                                      userAddButton.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width - 0, 40);
                                                      userAddButton.alpha = 1.0f;

                                                  }
                                                  completion:nil];

                             }
                             else [userAddButton removeFromSuperview];
                         }];
                    }
                }];

            }
        }];
    } else 	{
        //We're in a group conversation, things are different now...
        
        UIColor *color = [UIColor grayColor];        NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
        [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
        [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
        self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
        
        self.navigationItem.title = [title uppercaseString];
        PFQuery *query = [PFQuery queryWithClassName:kESGroupClassName];
        [query whereKey:kESGroupName equalTo:title];
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if ([objects count] > 0) {
                    hasPicture = YES;
                    [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
                        // Animate the alpha value of your imageView from 1.0 to 0.0 here
                        profileImage.alpha = 1.0f;
                        
                    } completion:^(BOOL finished) {
                    }];
                    PFObject *object = [objects firstObject];
                    [profileImage setFile:object[kESUserBigPicture]];
                    [profileImage loadInBackground];
                }
            }
        }];

    }
    
	items = [[NSMutableArray alloc] init];
	messages = [[NSMutableArray alloc] init];
	avatars = [[NSMutableDictionary alloc] init];
    
	PFUser *user = [PFUser currentUser];
	self.senderId = user.objectId;
	self.senderDisplayName = user[kESUserFullname];
	JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
	bubbleImageOutgoing = [bubbleFactory outgoingMessagesBubbleImageWithColor:kESMessageColorOut];
	bubbleImageIncoming = [bubbleFactory incomingMessagesBubbleImageWithColor:kESMessageColorIn];
	avatarImageBlank = [JSQMessagesAvatarImageFactory avatarImageWithImage:[UIImage imageNamed:@"chat_blank"] diameter:30.0];
    
    //Querying last 50 messages
    firebase1 = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Message/%@", groupId]];

    [[firebase1 queryLimitedToLast:50] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.childrenCount > 49) {
             self.showLoadEarlierMessagesHeader = YES;
         }
     }];

    [firebase1 keepSynced: YES];
    firebase2 = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Typing/%@", groupId]];
    [firebase2 keepSynced: YES];
    numberMessages = 50;
    [self loadMessages];
	[self typingIndicatorLoad];
	[self typingIndicatorSave:@NO];
    [ESUtility clearRecentCounterForChat:groupId];
    
}
- (void)addUser {
    [ESUtility peopleSave:[PFUser currentUser] andUser:user2];
    [UIView animateWithDuration:0.3 delay:0.0 options:0 animations:^{
        userAddButton.frame = CGRectMake(0, -40, [UIScreen mainScreen].bounds.size.width, 40);
    } completion:^(BOOL finished) {
        [userAddButton removeFromSuperview];
    }];
    [ProgressHUD showSuccess:@"Contact added"];
}
- (void) didTapAvatar {
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
#if TRY_AN_ANIMATED_GIF == 1
    imageInfo.imageURL = [NSURL URLWithString:@"http://media.giphy.com/media/O3QpFiN97YjJu/giphy.gif"];
#else
    imageInfo.image = profileImage.image;
#endif
    imageInfo.referenceRect = profileImage.frame;
    imageInfo.referenceView = profileImage.superview;
    imageInfo.referenceContentMode = profileImage.contentMode;
    imageInfo.referenceCornerRadius = profileImage.layer.cornerRadius;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
    
    // Present the view controller.
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
}
- (void)applicationDidReceiveRemoteNotification:(NSNotification *)note {
    NSDictionary* userInfo = note.userInfo;
    
    if ([userInfo[@"groupId"] isEqualToString:groupId]) {
        return;
    }
    PFQuery *query = [PFUser query];
    PFUser *sendingUser = (PFUser *)[query getObjectWithId:userInfo[@"sendingUserId"]];
    [[sendingUser objectForKey:kESUserPicture] getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
        if (!error) {
            UIImage *image = [UIImage imageWithData:data];
            NSMutableDictionary *options = [@{
                                              kCRToastTextKey : sendingUser[kESUserFullname],
                                              kCRToastSubtitleTextKey : userInfo[@"message"],
                                              kCRToastTextColorKey : [UIColor blackColor],
                                              kCRToastSubtitleTextColorKey : [UIColor darkGrayColor],
                                              kCRToastUnderStatusBarKey : @(NO),
                                              kCRToastFontKey : [UIFont boldSystemFontOfSize:14],
                                              kCRToastImageKey : image,
                                              kCRToastImageContentModeKey : @(UIViewContentModeScaleAspectFit),
                                              kCRToastTextAlignmentKey : @(NSTextAlignmentLeft),
                                              kCRToastSubtitleTextAlignmentKey : @(NSTextAlignmentLeft),
                                              kCRToastBackgroundColorKey : [UIColor colorWithWhite:0.98 alpha:1],
                                              kCRToastNotificationTypeKey : @(CRToastTypeNavigationBar),
                                              //kCRToastNotificationPresentationTypeKey : @(CRToastPresentationTypePush),
                                              kCRToastAnimationInTypeKey : @(CRToastAnimationTypeGravity),
                                              kCRToastAnimationOutTypeKey : @(CRToastAnimationTypeGravity),
                                              kCRToastAnimationInDirectionKey : @(CRToastAnimationDirectionTop),
                                              kCRToastAnimationOutDirectionKey : @(CRToastAnimationDirectionTop),
                                              kCRToastTimeIntervalKey : @(3),
                                              } mutableCopy];
            options[kCRToastInteractionRespondersKey] = @[[CRToastInteractionResponder interactionResponderWithInteractionType:CRToastInteractionTypeTap automaticallyDismiss:YES block:^(CRToastInteractionType interactionType){
                
                NSLog(@"Dismissed with %@ interaction", NSStringFromCRToastInteractionType(interactionType));
                
            }]];
            [CRToastManager showNotificationWithOptions:options
                                        completionBlock:^{
                                            NSLog(@"Completed");
                                        }];
            [self performSelector:@selector(dismissToast) withObject:nil afterDelay:3];
        }
    }];
    
    
}
- (void) dismissToast {
    dispatch_async(dispatch_get_main_queue(), ^{
        [CRToastManager dismissNotification:YES];
    });
}
- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
    opensProfile = NO;
	self.collectionView.collectionViewLayout.springinessEnabled = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    if (self.inputToolbar.contentView.textView.text.length != 0) {
        [[NSUserDefaults standardUserDefaults] setObject:self.inputToolbar.contentView.textView.text forKey:groupId];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setObject:@"_empty_" forKey:groupId];
    }
    [ProgressHUD dismiss];
    [UIView animateWithDuration:0.1 delay:0.0 options:0 animations:^{
        profileImage.alpha = 0.0f;
    } completion:^(BOOL finished) {
        [profileImageButton removeFromSuperview];
        [profileImage removeFromSuperview];
    }];
	if (self.isMovingFromParentViewController)
	{
        [ESUtility clearRecentCounterForChat:groupId];
		[firebase1 removeAllObservers];
	}
}
- (void)viewWillAppear:(BOOL)animated {
    gesture.enabled = YES;
    if (hasPicture) {
        [self.navigationController.navigationBar addSubview:profileImage];
        [self.navigationController.navigationBar addSubview:profileImageButton];
        [UIView animateWithDuration:0.2 delay:0.0 options:0 animations:^{
            // Animate the alpha value of your imageView from 1.0 to 0.0 here
            profileImage.alpha = 1.0f;

        } completion:^(BOOL finished) {
        }];
    }
}
#pragma mark - Backend methods
- (void)handleSingleTap {
    
}
- (void)loadMessages
{
	initialized = NO;
	self.automaticallyScrollsToMostRecentMessage = NO;
	[[firebase1 queryLimitedToLast:numberMessages] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot)
	{
		BOOL incoming = [self addMessage:snapshot.value];
		if (incoming) [self messageUpdate:snapshot.value];

		if (initialized)
		{
			if (incoming) [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
			[self finishReceivingMessage];
		}
	}];
	[[firebase1 queryLimitedToLast:numberMessages] observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) //[[firebase1 queryLimitedToLast:100]
	{
		[self updateMessage:snapshot.value];
	}];
	[[firebase1 queryLimitedToLast:numberMessages] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
	{
		[self finishReceivingMessage];
		[self scrollToBottomAnimated:NO];
		self.automaticallyScrollsToMostRecentMessage = YES;
		initialized	= YES;
	}];
}

- (BOOL)addMessage:(NSDictionary *)item
{
	JSQMessage *message;
	if ([item[@"type"] isEqualToString:@"text"])		message = [self createTextMessage:item];
	if ([item[@"type"] isEqualToString:@"video"])		message = [self createVideoMessage:item];
	if ([item[@"type"] isEqualToString:@"picture"])		message = [self createPictureMessage:item];
	if ([item[@"type"] isEqualToString:@"audio"])		message = [self createAudioMessage:item];
	if ([item[@"type"] isEqualToString:@"location"])	message = [self createLocationMessage:item];
	[items addObject:item];
	[messages addObject:message];
	return [self incoming:message];
}

- (JSQMessage *)createTextMessage:(NSDictionary *)item
{
	NSString *name = item[@"name"];
	NSString *userId = item[@"userId"];
    NSDate *date = [ESUtility convertStringToDate:item[@"date"]];
	NSString *text = item[@"text"];
	JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date text:text];
	return message;
}

- (JSQMessage *)createVideoMessage:(NSDictionary *)item
{
	NSString *name = item[@"name"];
	NSString *userId = item[@"userId"];
	NSDate *date = [ESUtility convertStringToDate:item[@"date"]];
	ESVideoMediaItem *mediaItem = [[ESVideoMediaItem alloc] initWithFileURL:[NSURL URLWithString:item[@"video"]] isReadyToPlay:NO];
	mediaItem.appliesMediaViewMaskAsOutgoing = [userId isEqualToString:self.senderId];
	JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
	NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:item[@"thumbnail"]]];
	AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
	operation.responseSerializer = [AFImageResponseSerializer serializer];
	[operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
	{
		mediaItem.isReadyToPlay = YES;
		mediaItem.image = (UIImage *)responseObject;
		[self.collectionView reloadData];
	}
	failure:^(AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"createVideoMessage picture load error.");
	}];
	[[NSOperationQueue mainQueue] addOperation:operation];
	return message;
}

- (JSQMessage *)createPictureMessage:(NSDictionary *)item
{
	NSString *name = item[@"name"];
	NSString *userId = item[@"userId"];
	NSDate *date = [ESUtility convertStringToDate:item[@"date"]];
    ESPhotoMediaItem *mediaItem = [[ESPhotoMediaItem alloc] initWithImage:nil Width:item[@"picture_width"] Height:item[@"picture_height"]];
	mediaItem.appliesMediaViewMaskAsOutgoing = [userId isEqualToString:self.senderId];
	JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:item[@"picture"]] cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:5];
    UIImage *image = [[UIImageView sharedImageCache] cachedImageForRequest:request];
    if (image == nil) {
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.responseSerializer = [AFImageResponseSerializer serializer];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject)
         {
             mediaItem.image = (UIImage *)responseObject;
             [self.collectionView reloadData];
             
             UIImage *image = (UIImage *)responseObject;
             [[UIImageView sharedImageCache] cacheImage:image forRequest:request];
         }
            failure:^(AFHTTPRequestOperation *operation, NSError *error)
         {
             NSLog(@"%@", [operation responseObject]);
         }];
        [[NSOperationQueue mainQueue] addOperation:operation];
    } else {
        mediaItem.image = image;
        [self.collectionView reloadData];
    }

    
    return message;
}

- (JSQMessage *)createAudioMessage:(NSDictionary *)item
{
	NSString *name = item[@"name"];
	NSString *userId = item[@"userId"];
	NSDate *date = [ESUtility convertStringToDate:item[@"date"]];
	ESAudioMediaItem *mediaItem = [[ESAudioMediaItem alloc] initWithFileURL:[NSURL URLWithString:item[@"audio"]] Duration:item[@"audio_duration"]];
	mediaItem.appliesMediaViewMaskAsOutgoing = [userId isEqualToString:self.senderId];
	JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
	return message;
}

- (JSQMessage *)createLocationMessage:(NSDictionary *)item
{
	NSString *name = item[@"name"];
	NSString *userId = item[@"userId"];
	NSDate *date = [ESUtility convertStringToDate:item[@"date"]];
	JSQLocationMediaItem *mediaItem = [[JSQLocationMediaItem alloc] initWithLocation:nil];
	mediaItem.appliesMediaViewMaskAsOutgoing = [userId isEqualToString:self.senderId];
	JSQMessage *message = [[JSQMessage alloc] initWithSenderId:userId senderDisplayName:name date:date media:mediaItem];
	CLLocation *location = [[CLLocation alloc] initWithLatitude:[item[@"latitude"] doubleValue] longitude:[item[@"longitude"] doubleValue]];
	[mediaItem setLocation:location withCompletionHandler:^{ [self.collectionView reloadData]; }];
	return message;
}

- (void)updateMessage:(NSDictionary *)item
{
	for (int i=0; i<[items count]; i++)
	{
		NSDictionary *temp = items[i];
		if ([item[@"key"] isEqualToString:temp[@"key"]])
		{
			items[i] = item;
			break;
		}
	}
	[self.collectionView reloadData];
}

- (void)loadAvatar:(NSString *)senderId
{
	PFQuery *query = [PFQuery queryWithClassName:kESUserClassName];
	[query whereKey:kESUserObjectID equalTo:senderId];
    [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
	[query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
	{
		if (error == nil)
		{
			if ([objects count] != 0)
			{
				PFUser *user = [objects firstObject];
				PFFile *file = user[kESUserThumbnail];
				[file getDataInBackgroundWithBlock:^(NSData *imageData, NSError *error)
				{
					if (error == nil)
					{
						UIImage *image = [UIImage imageWithData:imageData];
                        avatars[senderId] = [JSQMessagesAvatarImageFactory avatarImageWithImage:image diameter:30.0];
						[self.collectionView reloadData];
					}
				}];
			}
		}
		else NSLog(@"loadAvatar query error.");
	}];
}

- (void)sendMessage:(NSString *)text withVideo:(NSURL *)video withPicture:(UIImage *)picture andWithAudio:(NSString *)audio
{
	PFUser *user = [PFUser currentUser];
	NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
	item[@"userId"] = user.objectId;
	item[@"name"] = user[kESUserFullname];
    item[@"date"] = [ESUtility convertDateToString:[NSDate date]];
	item[@"status"] = @"Delivered";
	item[@"video"] = item[@"thumbnail"] = item[@"picture"] = item[@"audio"] = item[@"latitude"] = item[@"longitude"] = @"";
	item[@"video_duration"] = item[@"audio_duration"] = @0;
	item[@"picture_width"] = item[@"picture_height"] = @0;
	if (text != nil) [self sendTextMessage:item withText:text];
	else if (video != nil) [self sendVideoMessage:item withVideo:video];
	else if (picture != nil) [self sendPictureMessage:item withPicture:picture];
	else if (audio != nil) [self sendAudioMessage:item andWithAudio:audio];
	else [self sendLocationMessage:item];
    

}

- (void)sendTextMessage:(NSMutableDictionary *)item withText:(NSString *)text
{
	item[@"text"] = text;
	item[@"type"] = @"text";
	[self messageSave:item];
}

- (void)sendVideoMessage:(NSMutableDictionary *)item withVideo:(NSURL *)video
{
    [ProgressHUD show:@"Sending" Interaction:YES];
	UIImage *picture = [ESUtility videoThumbnailForURL:video];
    UIImage *squared = [ESUtility squaredImage:picture withSize:320];
    NSNumber *duration = [ESUtility videoDurationForURL:video];
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:video.path error:nil];
    unsigned long long fileSize = [attributes fileSize]; // result would be in bytes
    
    if(fileSize <= 10485760) {
        PFFile *fileThumbnail = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(squared, 0.5)];
        [fileThumbnail saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (error == nil)
             {
                 PFFile *fileVideo = [PFFile fileWithName:@"video.mp4" data:[[NSFileManager defaultManager] contentsAtPath:video.path]];
                 [fileVideo saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error == nil)
                      {
                          item[@"video"] = fileVideo.url;
                          item[@"video_duration"] = duration;
                          item[@"thumbnail"] = fileThumbnail.url;
                          NSString *firstName = [[[[PFUser currentUser] objectForKey:kESUserFullname] componentsSeparatedByString:@" "] objectAtIndex:0];
                          item[@"text"] = [NSString stringWithFormat:NSLocalizedString(@"%@ sent a video", nil),firstName];
                          item[@"type"] = @"video";
                          [self messageSave:item];
                          [ProgressHUD dismiss];
                      }
                      else {
                          [ProgressHUD showError:@"Error"];
                          NSLog(@"sendVideoMessage video save error.");
                      }
                  }];
             }
             else NSLog(@"sendVideoMessage picture save error.");
         }];
    }else{
        [ProgressHUD showError:@"Video is too long for upload"];
    }
	
}

- (void)sendPictureMessage:(NSMutableDictionary *)item withPicture:(UIImage *)picture
{
    [ProgressHUD show:@"Sending" Interaction:YES];
	int width = (int) picture.size.width;
	int height = (int) picture.size.height;
	PFFile *file = [PFFile fileWithName:@"picture.jpg" data:UIImageJPEGRepresentation(picture, 0.2)];
	[file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error == nil)
		{
			item[@"picture"] = file.url;
			item[@"picture_width"] = [NSNumber numberWithInt:width];
			item[@"picture_height"] = [NSNumber numberWithInt:height];
            NSString *firstName = [[[[PFUser currentUser] objectForKey:kESUserFullname] componentsSeparatedByString:@" "] objectAtIndex:0];
            item[@"text"] = [NSString stringWithFormat:NSLocalizedString(@"%@ sent a picture", nil),firstName];
			item[@"type"] = @"picture";
			[self messageSave:item];
            [ProgressHUD dismiss];
		}
        else {
            NSLog(@"sendPictureMessage picture save error.");
            [ProgressHUD showError:@"Error"];
        }
	}];
}

- (void)sendAudioMessage:(NSMutableDictionary *)item andWithAudio:(NSString *)audio
{
    [ProgressHUD show:@"Sending" Interaction:YES];
    NSNumber *duration = [ESUtility audioDurationForPath:audio];
	PFFile *file = [PFFile fileWithName:@"audio.m4a" data:[[NSFileManager defaultManager] contentsAtPath:audio]];
	[file saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
	{
		if (error == nil)
		{
			item[@"audio"] = file.url;
			item[@"audio_duration"] = duration;
            NSString *firstName = [[[[PFUser currentUser] objectForKey:kESUserFullname] componentsSeparatedByString:@" "] objectAtIndex:0];
			item[@"text"] = [NSString stringWithFormat:NSLocalizedString(@"%@ sent an audio message", nil),firstName];
            item[@"type"] = @"audio";
			[self messageSave:item];
            [ProgressHUD dismiss];
		}
        else {
            NSLog(@"sendAudioMessage audio save error.");
            [ProgressHUD showError:@"Error"];
        }
	}];
}

- (void)sendLocationMessage:(NSMutableDictionary *)item
{
	AppDelegate *app = (AppDelegate *) [[UIApplication sharedApplication] delegate];
	item[@"latitude"] = [NSNumber numberWithDouble:app.coordinate.latitude];
	item[@"longitude"] = [NSNumber numberWithDouble:app.coordinate.longitude];
    NSString *firstName = [[[[PFUser currentUser] objectForKey:kESUserFullname] componentsSeparatedByString:@" "] objectAtIndex:0];
	item[@"text"] = [NSString stringWithFormat:NSLocalizedString(@"%@ sent a location", nil),firstName];
	item[@"type"] = @"location";
	[self messageSave:item];
}

- (void)messageSave:(NSMutableDictionary *)item
{
	FIRDatabaseReference *reference = [firebase1 childByAutoId];
	item[@"key"] = reference.key;
	[reference setValue:item withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
		if (error != nil) NSLog(@"messageSave network error.");
	}];
    NSString *__title = title;
    if ([groupId length] == 20) {
        __title = [[PFUser currentUser] objectForKey:kESUserFullname];
    }
    [ESUtility sendPushNotificationToGroup:groupId withText:item[@"text"] andTitle:__title];
    [ESUtility updateRecentCounterForChat:groupId withCounter:1 andLastMessage:item[@"text"]];
    [ESUtility setDeliveredForChat:groupId andStatus:@"Delivered"];
	[JSQSystemSoundPlayer jsq_playMessageSentSound];
	[self finishSendingMessage];
}

- (void)messageUpdate:(NSDictionary *)item
{
	if ([item[@"status"] isEqualToString:@"Read"] == NO)
	{
        NSUserDefaults *defaults= [NSUserDefaults standardUserDefaults];
        if([[[defaults dictionaryRepresentation] allKeys] containsObject:[NSString stringWithFormat:@"%@-readReceipt", [PFUser currentUser].objectId]]){
            if ([[defaults objectForKey:[NSString stringWithFormat:@"%@-readReceipt", [PFUser currentUser].objectId]] isEqualToString:@"ON"]) {
                [[firebase1 child:item[@"key"]] updateChildValues:@{@"status":@"Read"} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                     if (error != nil) NSLog(@"messageUpdate network error.");
                 }];
                [ESUtility setReadForChat:groupId andStatus:@"Read"];
            }
        }
        else {
            if ([[PFUser currentUser]objectForKey:@"readReceipt"] && [[[PFUser currentUser]objectForKey:@"readReceipt"] isEqualToString:@"ON"]) {
                [[firebase1 child:item[@"key"]] updateChildValues:@{@"status":@"Read"} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                    if (error != nil) NSLog(@"messageUpdate network error.");
                }];
                
                [ESUtility setReadForChat:groupId andStatus:@"Read"];
           }
            else if (![[PFUser currentUser]objectForKey:@"readReceipt"]) {
                [[firebase1 child:item[@"key"]] updateChildValues:@{@"status":@"Read"} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                    if (error != nil) NSLog(@"messageUpdate network error.");
                }];
                [ESUtility setReadForChat:groupId andStatus:@"Read"];

            }
        }
		
	}
}

- (void)messageDelete
{
	NSDictionary *item = items[indexSelected.item];
	[[firebase1 child:item[@"key"]] removeValueWithCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
		if (error != nil) [ProgressHUD showError:@"Connection failed"];
        else {
            [items removeObjectAtIndex:indexSelected.item];
            [messages removeObjectAtIndex:indexSelected.item];
            [self.collectionView reloadData];
                    NSDictionary *last = [items lastObject];
            NSString *text = (last != nil) ? last[@"text"] : @"";
            [ESUtility updateRecentCounterForChat:groupId withCounter:-1 andLastMessage:text];
        }
	}];
	
}

- (void)typingIndicatorLoad
{
	[firebase2 observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot)
	{
		PFUser *user = [PFUser currentUser];
		if ([user.objectId isEqualToString:snapshot.key] == NO)
		{
			BOOL typing = [snapshot.value boolValue];
			self.showTypingIndicator = typing;
			if (typing) [self scrollToBottomAnimated:YES];
		}
	}];
}

- (void)typingIndicatorSave:(NSNumber *)typing
{
    [ESUtility setTypingForChat:groupId andStatus:@""];
	PFUser *user = [PFUser currentUser];
	[firebase2 updateChildValues:@{user.objectId:typing} withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
		if (error != nil) NSLog(@"typingIndicatorSave network error.");
	}];
}

#pragma mark - UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
	[self typingIndicatorStart];

    //SetTyping1(groupId, @"Typing...");

	return YES;
}

- (void)typingIndicatorStart
{
	typingCounter++;
	[self typingIndicatorSave:@YES];
	[self performSelector:@selector(typingIndicatorStop) withObject:nil afterDelay:2.0];
}

- (void)typingIndicatorStop
{
	typingCounter--;
	if (typingCounter == 0) [self typingIndicatorSave:@NO];
}

#pragma mark - JSQMessagesViewController method overrides

- (void)didPressSendButton:(UIButton *)button withMessageText:(NSString *)text senderId:(NSString *)senderId senderDisplayName:(NSString *)name date:(NSDate *)date
{
	[self sendMessage:text withVideo:nil withPicture:nil andWithAudio:nil];
}

- (void)didPressAccessoryButton:(UIButton *)sender
{
	[self.view endEditing:YES];
	NSArray *menuItems = @[[[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_camera"] title:@"Camera"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_audio"] title:@"Audio"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_pictures"] title:@"Pictures"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_videos"] title:@"Videos"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_location"] title:@"Location"],
						   [[RNGridMenuItem alloc] initWithImage:[UIImage imageNamed:@"chat_stickers"] title:@"Stickers"]];
	RNGridMenu *gridMenu = [[RNGridMenu alloc] initWithItems:menuItems];
	gridMenu.delegate = self;
	[gridMenu showInViewController:self center:CGPointMake(self.view.bounds.size.width/2.f, self.view.bounds.size.height/2.f)];
}

#pragma mark - JSQMessages CollectionView DataSource

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
	return messages[indexPath.item];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
			 messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self outgoing:messages[indexPath.item]])
	{
		return bubbleImageOutgoing;
	}
	else return bubbleImageIncoming;
}

- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView
					avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
	JSQMessage *message = messages[indexPath.item];
	if (avatars[message.senderId] == nil)
	{
		[self loadAvatar:message.senderId];
		return avatarImageBlank;
	}
	else return avatars[message.senderId];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.item % 3 == 0)
	{
		JSQMessage *message = messages[indexPath.item];
		return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:message.date];
	}
	else return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
	JSQMessage *message = messages[indexPath.item];
	if ([self incoming:message])
	{
		if (indexPath.item > 0)
		{
			JSQMessage *previous = messages[indexPath.item-1];
			if ([previous.senderId isEqualToString:message.senderId])
			{
				return nil;
			}
		}
		return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
	}
	else return nil;
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self outgoing:messages[indexPath.item]])
	{
		NSDictionary *item = items[indexPath.item];
		return [[NSAttributedString alloc] initWithString:item[@"status"]];
	}
	else return nil;
}

#pragma mark - UICollectionView DataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return [messages count];
}

- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];

	if ([self outgoing:messages[indexPath.item]])
	{
		cell.textView.textColor = [UIColor whiteColor];
	}
	else
	{
		cell.textView.textColor = [UIColor blackColor];
	}
	return cell;
}

#pragma mark - JSQMessages collection view flow layout delegate

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
				   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.item % 3 == 0)
	{
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
				   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
	JSQMessage *message = messages[indexPath.item];
	if ([self incoming:message])
	{
		if (indexPath.item > 0)
		{
			JSQMessage *previous = messages[indexPath.item-1];
			if ([previous.senderId isEqualToString:message.senderId])
			{
				return 0;
			}
		}
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
				   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
	if ([self outgoing:messages[indexPath.item]])
	{
		return kJSQMessagesCollectionViewCellLabelHeightDefault;
	}
	else return 0;
}

#pragma mark - Responding to collection view tap events

- (void)collectionView:(JSQMessagesCollectionView *)collectionView
				header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
	NSLog(@"didTapLoadEarlierMessagesButton");
    
    
    numberMessages = numberMessages + 50;
    [items removeAllObjects];
    [messages removeAllObjects];
    [firebase1 removeAllObservers];
    initialized = NO;
    self.automaticallyScrollsToMostRecentMessage = NO;
    [[firebase1 queryLimitedToLast:numberMessages] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot *snapshot) //[[firebase1 queryLimitedToLast:100]
     {
         BOOL incoming = [self addMessage:snapshot.value];
         if (incoming) [self messageUpdate:snapshot.value];
         
         if (initialized)
         {
             if (incoming) [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
             [self finishReceivingMessage];
         }
     }];
    [[firebase1 queryLimitedToLast:numberMessages] observeEventType:FIRDataEventTypeChildChanged withBlock:^(FIRDataSnapshot *snapshot) //[[firebase1 queryLimitedToLast:100]
     {
         [self updateMessage:snapshot.value];
     }];
    [[firebase1 queryLimitedToLast:numberMessages] observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if ((snapshot.childrenCount % 50) != 0) {
             self.showLoadEarlierMessagesHeader = NO;
         }
         [self finishReceivingMessage];
         self.automaticallyScrollsToMostRecentMessage = YES;
         initialized	= YES;
     }];
     /*
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:@"1" senderDisplayName:@"YO MAMA" date:[NSDate date] text:@"SOME TEST MESSAGE"];
    
    for (int i = 0; i < 10; i++) {
          [messages insertObject:message atIndex:0];
    }
    */
//    [self.collectionView.collectionViewLayout invalidateLayoutWithContext:[JSQMessagesCollectionViewFlowLayoutInvalidationContext context]];
//    [self.collectionView reloadData];
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView
		   atIndexPath:(NSIndexPath *)indexPath
{
    [self.inputToolbar.contentView.textView resignFirstResponder];
    
	PFUser *user = [PFUser currentUser];
	NSDictionary *item = items[indexPath.item];
	if ([user.objectId isEqualToString:item[@"userId"]] == NO)
	{
        [ProgressHUD show:@"Loading..."];
        PFQuery *query2 = [PFUser query];
        [query2 whereKey:@"objectId" equalTo:item[@"userId"]];
        PFUser *__user2 = (PFUser *)[query2 getObjectWithId:item[@"userId"]];
        //Search for blocked users in this group
        PFQuery *query1 = [PFQuery queryWithClassName:kESBlockedClassName];
        [query1 whereKey:kESBlockedUser2 equalTo:user];
        [query1 whereKey:kESBlockedUser1 equalTo:__user2];
        if (opensProfile == NO) {
            opensProfile = YES;
            [query1 getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
                
                //opensProfile = NO;
                
                if (!object) {
                    
                    PFQuery *userquery = [PFUser query];
                    [userquery getObjectInBackgroundWithId:item[@"userId"] block:^(PFObject *_requestedUser, NSError *error) {
                        [ProgressHUD dismiss];
                        if (!error) {
                            PFUser *requestedUser = (PFUser *)_requestedUser;
                            ESProfileView *profileView = [[ESProfileView alloc] initWith:item[@"userId"] andUser:requestedUser];
                            [self.navigationController pushViewController:profileView animated:YES];
                        }
                    }];
                } else [ProgressHUD showError:@"User has already been blocked"];
            }];
        } else [ProgressHUD dismiss];

	}
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didLongTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath {
    JSQMessage *message = messages[indexPath.item];
    NSMutableArray *activityItems = [NSMutableArray arrayWithCapacity:3];
    if ([message.media isKindOfClass:[ESPhotoMediaItem class]])
    {
        ESPhotoMediaItem *mediaItem = (ESPhotoMediaItem *)message.media;
        [activityItems addObject:mediaItem.image];
      //  [activityItems addObject:[NSURL URLWithString:[NSString stringWithFormat:@"Check out the new LuxChat Chat!"]]];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
            activityViewController.popoverPresentationController.sourceView = self.navigationController.navigationBar;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController presentViewController:activityViewController animated:YES completion:nil];
        });
    
    }
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
	JSQMessage *message = messages[indexPath.item];

	if (message.isMediaMessage)
	{
		if ([message.media isKindOfClass:[ESPhotoMediaItem class]])
		{
			ESPhotoMediaItem *mediaItem = (ESPhotoMediaItem *)message.media;
            
            JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
#if TRY_AN_ANIMATED_GIF == 1
            imageInfo.imageURL = [NSURL URLWithString:@"http://media.giphy.com/media/O3QpFiN97YjJu/giphy.gif"];
#else
            imageInfo.image = mediaItem.image;

#endif
            imageInfo.referenceRect = CGRectMake([UIScreen mainScreen].bounds.size.width/2, [UIScreen mainScreen].bounds.size.height/2, 0, 0);
            imageInfo.referenceView = self.view;
            imageInfo.referenceContentMode = UIViewContentModeScaleAspectFit;
            imageInfo.referenceCornerRadius = 10;

            // Setup view controller
            JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                                   initWithImageInfo:imageInfo
                                                   mode:JTSImageViewControllerMode_Image
                                                   backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];
            
            // Present the view controller.
            if (mediaItem.image.size.width != 105 && mediaItem.image.size.height != 105) {
                
                [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];

            }
		}
		if ([message.media isKindOfClass:[ESVideoMediaItem class]])
		{
			ESVideoMediaItem *mediaItem = (ESVideoMediaItem *)message.media;
			MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
			[self presentMoviePlayerViewControllerAnimated:moviePlayer];
			[moviePlayer.moviePlayer play];
		}
		if ([message.media isKindOfClass:[ESAudioMediaItem class]])
		{
			ESAudioMediaItem *mediaItem = (ESAudioMediaItem *)message.media;
			MPMoviePlayerViewController *moviePlayer = [[MPMoviePlayerViewController alloc] initWithContentURL:mediaItem.fileURL];
			[self presentMoviePlayerViewControllerAnimated:moviePlayer];
			[moviePlayer.moviePlayer play];
		}
		if ([message.media isKindOfClass:[JSQLocationMediaItem class]])
		{
			JSQLocationMediaItem *mediaItem = (JSQLocationMediaItem *)message.media;
			ESMapView *mapView = [[ESMapView alloc] initWith:mediaItem.location];
			NavigationController *navController = [[NavigationController alloc] initWithRootViewController:mapView];
			[self presentViewController:navController animated:YES completion:nil];
		}
	}
}

- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
	NSLog(@"didTapCellAtIndexPath %@", NSStringFromCGPoint(touchLocation));
}
- (void)messagesCollectionViewCellDidTapCell:(JSQMessagesCollectionViewCell *)cell atPosition:(CGPoint)position {
    
}
- (void)messagesCollectionViewCellDidTapAvatar:(JSQMessagesCollectionViewCell *)cell {
    
}
- (void)messagesCollectionViewCellDidLongTapMessageBubble:(JSQMessagesCollectionViewCell *)cell {
    
}
- (void)messagesCollectionViewCell:(JSQMessagesCollectionViewCell *)cell didPerformAction:(SEL)action withSender:(id)sender {
    
}
- (void)messagesCollectionViewCellDidTapMessageBubble:(JSQMessagesCollectionViewCell *)cell {
    
}
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    JSQMessage *message = messages[indexPath.item];
    if ([self outgoing:message])
    {
        NSDictionary *item = items[indexPath.item];
        if ([item[@"status"] isEqualToString:@"Read"] == NO)
        {
            indexSelected = indexPath;
            if (action == @selector(delete:)) {
                return YES;
            }
        }
    }
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
    
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(delete:)) {
        [self messageDelete];
    } else {
        [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
    }
}
#pragma mark - User actions

- (void)actionStickers
{
	ESStickersView *stickerView = [[ESStickersView alloc] init];
	stickerView.delegate = self;
	NavigationController *navController = [[NavigationController alloc] initWithRootViewController:stickerView];
	[self presentViewController:navController animated:YES completion:nil];
}

- (void)actionDelete
{
	UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel"
										  destructiveButtonTitle:@"Delete message" otherButtonTitles:nil];
	[action showInView:self.view];
    action.tag = 1;
}
- (void)openLink:(NSNotification *)note {
    [self.inputToolbar.contentView.textView resignFirstResponder];
    NSDictionary *dict = note.userInfo;
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:[dict objectForKey:@"url"]];
    [self.navigationController pushViewController:webViewController animated:YES];
}
- (void)userTappedOnTitleName{
    gesture.enabled = NO;
    [ProgressHUD show:@"Loading..."];
    [self.inputToolbar.contentView.textView resignFirstResponder];
    PFQuery *userquery = [PFUser query];
    [userquery getObjectInBackgroundWithId:user2.objectId block:^(PFObject *_requestedUser, NSError *error) {
        [ProgressHUD dismiss];
        if (!error) {
            PFUser *requestedUser = (PFUser *)_requestedUser;
            ESProfileView *profileView = [[ESProfileView alloc] initWith:user2.objectId andUser:requestedUser];
            [self.navigationController pushViewController:profileView animated:YES];
        }
    }];
}
-(void)saveToCameraRoll:(UIImage *)image
{
    UIImage *imageToBeSaved = image;
    UIImageWriteToSavedPhotosAlbum(imageToBeSaved, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
}


- (void)image:(UIImage *)image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo
{
    if (!error)
    {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"Success!" message:@"The picture was saved successfully to your Camera Roll." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
    }
}
#pragma mark - StickersDelegate

- (void)didSelectSticker:(NSString *)sticker
{
	UIImage *picture = [UIImage imageNamed:sticker];
	[self sendMessage:nil withVideo:nil withPicture:picture andWithAudio:nil];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag == 1) {
        if (buttonIndex != actionSheet.cancelButtonIndex)
        {
            [self messageDelete];
        }
    }
	
}

#pragma mark - RNGridMenuDelegate

- (void)gridMenu:(RNGridMenu *)gridMenu willDismissWithSelectedItem:(RNGridMenuItem *)item atIndex:(NSInteger)itemIndex
{
	[gridMenu dismissAnimated:NO];
    if ([item.title isEqualToString:@"Camera"])		[ESUtility presentMultiCamera:self editable:NO];
    if ([item.title isEqualToString:@"Audio"])		[ESUtility presentAudioRecorder:self];
	if ([item.title isEqualToString:@"Pictures"])	[self showResizablePicker];
    if ([item.title isEqualToString:@"Videos"])		[ESUtility presentVideoLibrary:self editable:NO];
	if ([item.title isEqualToString:@"Location"])	[self sendMessage:nil withVideo:nil withPicture:nil andWithAudio:nil];
	if ([item.title isEqualToString:@"Stickers"])	[self actionStickers];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSURL *video = info[UIImagePickerControllerMediaURL];

    UIImage *picture = [info objectForKey:UIImagePickerControllerOriginalImage];
    
	[self sendMessage:nil withVideo:video withPicture:picture andWithAudio:nil];
	[picker dismissViewControllerAnimated:YES completion:nil];
}
-(void)showResizablePicker{
    imagePicker = [[GKImagePicker alloc] init];
    self.imagePicker.cropSize = CGSizeMake([UIScreen mainScreen].bounds.size.width - 50, [UIScreen mainScreen].bounds.size.width - 50);
    self.imagePicker.delegate = self;
    self.imagePicker.resizeableCropArea = YES;

    [self presentViewController:self.imagePicker.imagePickerController animated:YES completion:nil];
        
    
}
# pragma mark GKImagePicker Delegate Methods

- (void)imagePicker:(GKImagePicker *)imagePicker pickedImage:(UIImage *)image{
    [self hideImagePicker];
    [self sendMessage:nil withVideo:nil withPicture:image andWithAudio:nil];

}
- (void)hideImagePicker{
    [self.imagePicker.imagePickerController dismissViewControllerAnimated:YES completion:nil];
}
#pragma mark - IQAudioRecorderControllerDelegate

- (void)audioRecorderController:(IQAudioRecorderController *)controller didFinishWithAudioAtPath:(NSString *)path
{
	[self sendMessage:nil withVideo:nil withPicture:nil andWithAudio:path];
}

- (void)audioRecorderControllerDidCancel:(IQAudioRecorderController *)controller
{

}

#pragma mark - Helper methods

- (BOOL)incoming:(JSQMessage *)message
{
	return ([message.senderId isEqualToString:self.senderId] == NO);
}

- (BOOL)outgoing:(JSQMessage *)message
{
	return ([message.senderId isEqualToString:self.senderId] == YES);
}
#pragma mark - UITextView Delegate

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    
    return NO;
}

@end
