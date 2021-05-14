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

#import "ESRecentCell.h"

@interface ESRecentCell()
{
    /**
     *  Dictionary of the respective recent conversation
     */
	NSDictionary *recent;
}
/**
 *  The title of the cell, usually a user's name or a name of a group
 */
@property (strong, nonatomic) IBOutlet UILabel *labelDescription;
/**
 *  The last message that has been sent in that conversation is displayed in this label
 */
@property (strong, nonatomic) IBOutlet UILabel *labelLastMessage;
/**
 *  A label indicating how much time has past since the last message
 */
@property (strong, nonatomic) IBOutlet UILabel *labelElapsed;

@property (strong, nonatomic) IBOutlet UIView *dummyView;
/**
 *  Small green dot, indicating if a user is online or net. This image is placed in the lower right corner of the profile picture.
 */
@property (strong, nonatomic) IBOutlet UIImageView *onlineIndicator;
@end

@implementation ESRecentCell

@synthesize imageUser;
@synthesize labelDescription, labelLastMessage;
@synthesize labelElapsed, badgeView, readLabel, dummyView,thinLine, onlineIndicator;

- (void)applyData:(NSDictionary *)recent_
{
	recent = recent_;
    
    labelDescription.frame = CGRectMake(70, 12, [UIScreen mainScreen].bounds.size.width - 140, 30);
    labelLastMessage.frame = CGRectMake(70, 30, [UIScreen mainScreen].bounds.size.width - 140, 30);
    labelElapsed.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 65, 12, 55, 20);
    
    NSString *firstName = [[NSString alloc]init];
    if ([recent[@"lastUser"] isEqualToString:[[PFUser currentUser] objectId]]) {
        firstName = [[[[PFUser currentUser] objectForKey:kESUserFullname] componentsSeparatedByString:@" "] objectAtIndex:0];
    }
    
    labelDescription.text = recent[@"description"];
    labelLastMessage.text = recent[@"lastMessage"];
    
    if ([labelLastMessage.text isEqualToString:@""]) {
        labelLastMessage.text = @"No new messages yet";
    } else if ([recent[@"lastMessage"] isEqualToString:[NSString stringWithFormat:@"%@ sent a picture", firstName]]) {
        labelLastMessage.text = @"You sent a picture";
    } else if ([recent[@"lastMessage"] isEqualToString:[NSString stringWithFormat:@"%@ sent a video", firstName]]) {
        labelLastMessage.text = @"You sent a video";
    } else if ([recent[@"lastMessage"] isEqualToString:[NSString stringWithFormat:@"%@ sent an audio message", firstName]]) {
        labelLastMessage.text = @"You sent an audio message";
    } else if ([recent[@"lastMessage"] isEqualToString:[NSString stringWithFormat:@"%@ sent a location", firstName]]) {
        labelLastMessage.text = @"You sent your location";
    }

	imageUser.layer.cornerRadius = imageUser.frame.size.width/2;
	imageUser.layer.masksToBounds = YES;
    imageUser.frame = CGRectMake(10, 10, 50, 50);
    
    dummyView.frame = imageUser.frame;
    dummyView.backgroundColor = [UIColor clearColor];
    
    if ([recent[@"groupId"] length] == 20 && [recent[@"isGroup"] isEqualToString:@"NO"]) {
        //[imageUser setImage:[UIImage imageNamed:@"AvatarPlaceholderProfile"]];
        NSString *groupId = recent[@"groupId"];
        NSString *otherUserId = [groupId stringByReplacingOccurrencesOfString:[PFUser currentUser].objectId withString:@""];

        PFQuery *_query = [PFQuery queryWithClassName:kESUserClassName];
        [_query whereKey:kESUserObjectID equalTo:otherUserId];
        [_query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
         {
             if (error == nil)
             {
                 onlineIndicator.frame = CGRectMake(11, 48, 12, 12);
                 [onlineIndicator setImage:[UIImage imageNamed:@"green_dot"]];
                 FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"users/%@/connections", [object objectForKey:kESUserFirebaseID]]];
                 [firebase observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
                  {
                      if (snapshot.value != [NSNull null]) {
                          onlineIndicator.hidden = NO;
                      }
                      else {
                          onlineIndicator.hidden = YES;
                      }
                      
                  }];
             }
         }];
    }
    else if ([recent[@"isGroup"] isEqualToString:@"YES"]){
        onlineIndicator.hidden = YES;
    }
    else {
        PFQuery *query = [PFQuery queryWithClassName:kESUserClassName];
        [query whereKey:kESUserObjectID equalTo:recent[@"lastUser"]];
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
        [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error)
         {
             if (error == nil)
             {
                 PFUser *user = (PFUser *)object;
                 [imageUser setFile:user[kESUserPicture]];
                 [imageUser loadInBackground];
             }
         }];

    }
    
    readLabel.hidden = YES;
    readLabel.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 60, 35, 50, 20);
    readLabel.text = @"";
    
    if ([[recent objectForKey:@"status"] isEqualToString:@"Read"] && [recent[@"lastUser"]isEqualToString:[PFUser currentUser].objectId]) {
        readLabel.hidden = NO;
        readLabel.text = NSLocalizedString(@"Read", nil);
    } else if ([[recent objectForKey:@"status"] isEqualToString:@"Delivered"] && [recent[@"lastUser"]isEqualToString:[PFUser currentUser].objectId]) {
        readLabel.hidden = NO;
        readLabel.text = NSLocalizedString(@"Delivered", nil);
    }
    
    if ([[recent objectForKey:@"statusTyping"] isEqualToString:@"Typing..."]) {
        readLabel.hidden = NO;
        readLabel.text = NSLocalizedString(@"Typing...", nil);
    } 

    NSDate *date = [ESUtility convertStringToDate:recent[@"date"]];
	NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:date];
	labelElapsed.text = [ESUtility calculateTimeInterval:seconds];
    labelElapsed.textColor = [UIColor colorWithRed:0.0863 green:0.4941 blue:0.9843 alpha:1];
	
    int counter = [recent[@"counter"] intValue];
    badgeView.hidden = YES;
    badgeView = [[JSBadgeView alloc] initWithParentView:dummyView alignment:JSBadgeViewAlignmentTopRight];
    if (counter == 0) {
        badgeView.hidden = YES;
    }
    else {
        badgeView.hidden = NO;
        badgeView.badgeText = [NSString stringWithFormat:@"%i",counter];
    }

    [self.contentView addSubview:thinLine];
    thinLine.frame = CGRectMake(20, self.contentView.frame.size.height-0.5, [UIScreen mainScreen].bounds.size.width, 0.5);
    thinLine.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1];
}
-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted){
        onlineIndicator.backgroundColor = onlineIndicator.backgroundColor;
    }
}
- (void) setSelected:(BOOL) selected animated:(BOOL) animated
{
    [super setSelected:selected animated:animated];
    
    if (selected){
        onlineIndicator.backgroundColor = onlineIndicator.backgroundColor;
    }
}
@end
