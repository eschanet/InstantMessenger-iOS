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

#import <AVFoundation/AVFoundation.h>
#import "ESWelcomeView.h"
#import "IQAudioRecorderController.h"
#import "NavigationController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "ESConstants.h"


@implementation ESUtility

#pragma mark - blocking users

+ (void)blockUser:(PFUser *)user2
{
    PFUser *user1 = [PFUser currentUser];
    [self blockUserOne:user1 withUser:user2];
    [self blockUserOne:user2 withUser:user1];
    
    [self removeGroupMembers:user1 withUser:user2];
    [self removeGroupMembers:user2 withUser:user1];

    [self peopleDelete:user1 andUser:user2];
    [self peopleDelete:user2 andUser:user1];

    [self deleteRecentItemsBetweenUser:user1 andUser:user2];
    [self deleteRecentItemsBetweenUser:user2 andUser:user1];
}

+ (void)blockUserOne:(PFUser *)user1 withUser:(PFUser *)user2
{
    PFQuery *query = [PFQuery queryWithClassName:kESBlockedClassName];
    [query whereKey:kESBlockedUser equalTo:[PFUser currentUser]];
    [query whereKey:kESBlockedUser1 equalTo:user1];
    [query whereKey:kESBlockedUser2 equalTo:user2];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             if ([objects count] == 0)
             {
                 PFObject *object = [PFObject objectWithClassName:kESBlockedClassName];
                 object[kESBlockedUser] = [PFUser currentUser];
                 object[kESBlockedUser1] = user1;
                 object[kESBlockedUser2] = user2;
                 object[kESBlockedUserID2] = user2.objectId;
                 [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil) NSLog(@"BlockUserOne save error.");
                  }];
             }
         }
         else NSLog(@"BlockUserOne query error.");
     }];
}

+ (void)unblockUser:(PFUser *)user2
{
    PFUser *user1 = [PFUser currentUser];
    [self unblockUserOne:user1 withUser:user2];
    [self unblockUserOne:user2 withUser:user1];
}

+ (void)unblockUserOne:(PFUser *)user1 withUser:(PFUser *)user2
{
    PFQuery *query = [PFQuery queryWithClassName:kESBlockedClassName];
    [query whereKey:kESBlockedUser equalTo:[PFUser currentUser]];
    [query whereKey:kESBlockedUser1 equalTo:user1];
    [query whereKey:kESBlockedUser2 equalTo:user2];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             for (PFObject *blocked in objects)
             {
                 [blocked deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil) NSLog(@"UnblockUserOne delete error.");
                  }];
             }
         }
         else NSLog(@"UnblockUserOne query error.");
     }];
}

#pragma mark - groups backend

+ (void)removeGroupMembers:(PFUser *)user1 withUser:(PFUser *)user2
{
    PFQuery *query = [PFQuery queryWithClassName:kESGroupClassName];
    [query whereKey:kESGroupUser equalTo:user1];
    [query whereKey:kESGroupMembers equalTo:user2.objectId];
    [query setCachePolicy:kPFCachePolicyNetworkElseCache];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             for (PFObject *group in objects)
             {
                 [self removeGroupMember:group user:user2];
             }
         }
         else NSLog(@"RemoveGroupMembers query error.");
     }];
}

+ (void)removeGroupMember:(PFObject *)group user:(PFUser *)user
{
    if ([group[kESGroupMembers] containsObject:user.objectId])
    {
        [group[kESGroupMembers] removeObject:user.objectId];
        [group saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
         {
             if (error != nil) NSLog(@"RemoveGroupMember save error.");
         }];
    }
}

+ (void)removeGroupItem:(PFObject *)group
{
    [group deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error != nil) NSLog(@"RemoveGroupItem delete error.");
     }];
}

#pragma mark - contacts

+ (void)peopleSave:(PFUser *)user1 andUser:(PFUser *)user2
{
    PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
    [query whereKey:kESPeopleUser1 equalTo:user1];
    [query whereKey:kESPeopleUser2 equalTo:user2];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             if ([objects count] == 0)
             {
                 PFObject *object = [PFObject objectWithClassName:kESPeopleClassName];
                 object[kESPeopleUser1] = user1;
                 object[kESPeopleUser2] = user2;
                 [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil) NSLog(@"PeopleSave save error.");
                  }];
             }
         }
         else NSLog(@"PeopleSave query error.");
     }];
}

+ (void)peopleDelete:(PFUser *)user1 andUser:(PFUser *)user2
{
    PFQuery *query = [PFQuery queryWithClassName:kESPeopleClassName];
    [query whereKey:kESPeopleUser1 equalTo:user1];
    [query whereKey:kESPeopleUser2 equalTo:user2];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             for (PFObject *people in objects)
             {
                 [people deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error != nil) NSLog(@"PeopleDelete delete error.");
                  }];
             }
         }
         else NSLog(@"PeopleDelete query error.");
     }];
}

#pragma mark - push notifications

+ (void)parsePushUserAssign
{
    PFInstallation *installation = [PFInstallation currentInstallation];
    installation[kESInstallationUser] = [PFUser currentUser];
    [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"ParsePushUserAssign save error.");
         }
     }];
}

+ (void)parsePushUserResign
{
    PFInstallation *installation = [PFInstallation currentInstallation];
    [installation removeObjectForKey:kESInstallationUser];
    [installation saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"ParsePushUserResign save error.");
         }
     }];
}

+ (void)sendPushNotificationToGroup:(NSString *)groupId withText:(NSString *)text andTitle:(NSString *)title
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             NSArray *recentConvos = [snapshot.value allValues];
             NSMutableArray *recipients = [[NSMutableArray alloc]init];
             for (NSDictionary *recent in recentConvos)
             {
                 if (recent != nil && [recent[@"deleted"] isEqualToString:@"NO"]) {
                     [recipients addObject:recent[@"userId"]];
                 }
             }
             [self sendPushNotificationToMembers:recipients withText:text andGroupId:groupId andTitle:title];
         }
     }];
}

+ (void)sendPushNotificationToMembers:(NSArray *)members withText:(NSString *)text andGroupId:(NSString *)groupId andTitle:(NSString *)title
{
    PFUser *user = [PFUser currentUser];
    NSString *message = [NSString stringWithFormat:@"%@: %@", user[kESUserFullname], text];
    
    PFQuery *query = [PFQuery queryWithClassName:kESUserClassName];
    [query whereKey:kESUserObjectID containedIn:members];
    [query whereKey:kESUserObjectID notEqualTo:user.objectId];
    [query setLimit:1000];
    
    PFQuery *queryInstallation = [PFInstallation query];
    [queryInstallation whereKey:kESInstallationUser matchesQuery:query];
    
    //PFPush *push = [[PFPush alloc] init];
    //[push setQuery:queryInstallation];
    /*NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                          message, @"alert",
                          @"ACTIONABLE",@"category",
                          @"Increment", @"badge",
                          @"105.caf", @"sound",
                          groupId, @"groupId",
                          title, @"groupTitle",
                          [user objectId], @"sendingUserId",
                          text, @"message",
                          nil];
    [push setData:data];
    [push sendPushInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
     {
         if (error != nil)
         {
             NSLog(@"SendPushNotification send error with %@",error);
         }
     }];*/
    NSLog(@"members: %@", members);
    [PFCloud callFunctionInBackground:@"sendPushToUser"
                       withParameters:@{@"message": message,
                                        @"members": members,
                                        @"groupId" : groupId,
                                        @"groupTitle":title,
                                        @"sendingUserId":user.objectId,
                                        @"alert":message,
                                        @"text":text
                                        }
                                block:^(NSString *success, NSError *error) {
                                    if (!error) {
                                        // Push sent successfully
                                    }
                                }];

}

#pragma mark - chat/messages backend

+ (NSString*)startPrivateChatBetweenUser:(PFUser *)user1 andUser:(PFUser *)user2;
{
    NSString *id1 = user1.objectId;
    NSString *id2 = user2.objectId;
    NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
    NSArray *members = @[user1.objectId, user2.objectId];
    [self createRecentItemForUser:user1 withGroupId:groupId withMembers:members withDescription:user2[kESUserFullname] andOption:@"NO"];
    [self createRecentItemForUser:user2 withGroupId:groupId withMembers:members withDescription:user1[kESUserFullname] andOption:@"NO"];

    return groupId;
}

+ (NSString*)startMultipleChat:(NSMutableArray *)users
{
    NSString *groupId = @"";
    NSString *description = @"";
    [users addObject:[PFUser currentUser]];
    NSMutableArray *userIds = [[NSMutableArray alloc] init];
    for (PFUser *user in users)
    {
        [userIds addObject:user.objectId];
    }
    NSArray *sorted = [userIds sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *userId in sorted)
    {
        groupId = [groupId stringByAppendingString:userId];
    }
    for (PFUser *user in users)
    {
        if ([description length] != 0) description = [description stringByAppendingString:@" & "];
        description = [description stringByAppendingString:user[kESUserFullname]];
    }
    for (PFUser *user in users)
    {
        [self createRecentItemForUser:user withGroupId:groupId withMembers:userIds withDescription:description andOption:@"NO"];
    }
    return groupId;
}
+ (void)addUser:(PFUser *)user toGroup:(NSString *)groupId withMembers:(NSArray *)members
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 FIRDatabaseReference *_firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];

                 NSDictionary *values = @{@"members":members};
                 [_firebase updateChildValues:values withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                      if (error != nil) NSLog(@"UpdateRecentCounter2 save error.");
                  }];
             }
         }
     }];
    
}
+ (void)createRecentItemForUser:(PFUser *)user withGroupId:(NSString *)groupId withMembers:(NSArray *)members withDescription:(NSString *)description andOption:(NSString *)isGroup
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         BOOL create = YES;
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 if ([recent[@"isGroup"] isEqualToString:isGroup]) {
                     if ([recent[@"userId"] isEqualToString:user.objectId]) create = NO;
                 }
             }
         }
         if (create) [self createRecentItem2:user withGroupId:groupId withMembers:members withDescription:description andOption:isGroup];
     }];
}

+ (void)createRecentItem2:(PFUser *)user withGroupId:(NSString *)groupId withMembers:(NSArray *)members withDescription:(NSString *)description andOption:(NSString *)isGroup
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseReference *reference = [firebase childByAutoId];
    NSString *recentId = reference.key;
    PFUser *lastUser = [PFUser currentUser];
    NSString *date = [ESUtility convertDateToString:[NSDate date]];
    NSDictionary *recent = @{@"recentId":recentId, @"userId":user.objectId, @"groupId":groupId, @"members":members, @"description":description,
                             @"lastUser":lastUser.objectId, @"lastMessage":@"", @"counter":@0, @"date":date, @"deleted":@"NO", @"isGroup":isGroup};
    [reference setValue:recent withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
         if (error != nil) NSLog(@"CreateRecentItem2 save error.");
     }];
}

+ (void)updateRecentCounterForChat:(NSString *)groupId withCounter:(NSInteger)amount andLastMessage:(NSString *)lastMessage
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 PFUser *user = [PFUser currentUser];
                 NSString *date = [ESUtility convertDateToString:[NSDate date]];
                 NSInteger counter = [recent[@"counter"] integerValue];
                 if ([recent[@"userId"] isEqualToString:user.objectId] == NO) counter += amount;
                 FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];
                 [firebase keepSynced:YES];
                 NSDictionary *values = @{@"lastUser":user.objectId, @"lastMessage":lastMessage, @"counter":@(counter), @"date":date, @"deleted":@"NO"};
                 [firebase updateChildValues:values withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                      if (error != nil) NSLog(@"UpdateRecentCounter2 save error.");
                  }];
             }
         }
     }];
}
+ (void)setDeliveredForChat:(NSString *)groupId andStatus:(NSString *)status
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 PFUser *user = [PFUser currentUser];
                 if ([recent[@"userId"] isEqualToString:user.objectId] == YES) {
                     FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];
                     NSDictionary *values = @{@"status":status};
                     [firebase updateChildValues:values withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                          if (error != nil) NSLog(@"UpdateRecentCounter2 save error.");
                      }];
                 }
             }
         }
     }];
}
+ (void)setTypingForChat:(NSString *)groupId andStatus:(NSString *)status
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 PFUser *user = [PFUser currentUser];
                 if ([recent[@"userId"] isEqualToString:user.objectId] == NO) {
                     FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];
                     NSDictionary *values = @{@"statusTyping":status};
                     [firebase updateChildValues:values withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                          if (error != nil) NSLog(@"UpdateRecentCounter2 save error.");
                      }];
                 }
             }
         }
     }];
}
+ (void)setReadForChat:(NSString *)groupId andStatus:(NSString *)status
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 PFUser *user = [PFUser currentUser];
                 if ([recent[@"userId"] isEqualToString:user.objectId] == NO) {
                     FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];
                     NSDictionary *values = @{@"status":status};
                     [firebase updateChildValues:values withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                          if (error != nil) NSLog(@"UpdateRecentCounter2 save error.");
                      }];
                 }
             }
         }
     }];
}
+ (void)clearRecentCounterForChat:(NSString *)groupId
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             PFUser *user = [PFUser currentUser];
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 if ([recent[@"userId"] isEqualToString:user.objectId])
                 {
                     FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];
                     [firebase keepSynced:YES];
                     [firebase updateChildValues:@{@"counter":@0, @"deleted":@"NO"}  withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                          if (error != nil) NSLog(@"ClearRecentCounter2 save error.");
                      }];
                 }
             }
         }
     }];
}

+ (void)deleteRecentItemsBetweenUser:(PFUser *)user1 andUser:(PFUser *)user2
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"userId"] queryEqualToValue:user1.objectId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 if ([recent[@"members"] containsObject:user2.objectId])
                 {
                     FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];
                     [firebase removeValueWithCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref) {
                          if (error != nil) NSLog(@"DeleteRecentItem delete error.");
                      }];
                 }
             }
         }
     }];
}

+ (void)deleteRecentChat:(NSDictionary *)recent
{
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", recent[@"recentId"]]];
    [firebase updateChildValues:@{@"deleted":@"YES",@"counter":@0} withCompletionBlock:^(NSError *error, FIRDatabaseReference *ref)
     {
         if (error != nil) NSLog(@"DeleteRecentItem delete error.");
     }];
    
    FIRDatabaseReference *_firebase = [[[FIRDatabase database] reference] child:@"Recent"];
    FIRDatabaseQuery *query = [[_firebase queryOrderedByChild:@"userId"] queryEqualToValue:[[PFUser currentUser] objectId]];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             int i = 0;
             NSString *idToDelete = [[NSString alloc]init];
             BOOL duplicate = NO;
             BOOL second = NO;
             for (NSDictionary *_recent in [snapshot.value allValues])
             {
                 if ([_recent[@"userId"] isEqualToString:recent[@"userId"]] && [_recent[@"isGroup"] isEqualToString:recent[@"isGroup"]] && [_recent[@"description"] isEqualToString:recent[@"description"]] && [_recent[@"lastMessage"] isEqualToString:recent[@"lastMessage"]] && [_recent[@"lastUser"] isEqualToString:recent[@"lastUser"]]) {
                     i++;
                     if (duplicate == NO) {
                         if (second == YES) {
                             idToDelete = _recent[@"recentId"];
                             duplicate = YES;
                         }
                         second = YES;
                     }
                 }
             }
             if (i > 1) {
                 FIRDatabaseReference *__firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Recent/%@", idToDelete]];
                 [__firebase removeValueWithCompletionBlock:^(NSError *error, FIRDatabaseReference *ref)
                  {
                      if (error != nil) NSLog(@"DeleteRecentItem delete error.");
                  }];
             }
         }
     }];
    
}

#pragma mark - user reporting

+ (void)reportUser:(PFUser *)user2
{
    PFUser *user1 = [PFUser currentUser];
    
    PFQuery *query = [PFQuery queryWithClassName:kESReportClassName];
    [query whereKey:kESReportUser1 equalTo:user1];
    [query whereKey:kESReportUser2 equalTo:user2];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
     {
         if (error == nil)
         {
             if ([objects count] == 0)
             {
                 PFObject *object = [PFObject objectWithClassName:kESReportClassName];
                 object[kESReportUser1] = user1;
                 object[kESReportUser2] = user2;
                 [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                  {
                      if (error == nil)
                      {
                          [ProgressHUD showSuccess:@"User reported."];
                      }
                      else NSLog(@"ReportUser save error.");
                  }];
             }
             else [ProgressHUD showError:@"User already reported."];
         }
         else NSLog(@"ReportUser query error.");
     }];
}

#pragma mark - audio recording

+ (void)presentAudioRecorder:(id)target
{
    IQAudioRecorderController *controller = [[IQAudioRecorderController alloc] init];
    controller.delegate = target;
    [target presentViewController:controller animated:YES completion:nil];
}

+ (NSNumber*)audioDurationForPath:(NSString *)path;
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
    int duration = (int) round(CMTimeGetSeconds(asset.duration));
    return [NSNumber numberWithInt:duration];
}

#pragma mark - camera

+ (BOOL)presentMultiCamera:(id)target editable:(BOOL)canEdit
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] == NO) return NO;
    NSString *type1 = (NSString *)kUTTypeImage;
    NSString *type2 = (NSString *)kUTTypeMovie;
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]
        && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera] containsObject:type1])
    {
        imagePicker.mediaTypes = @[type1, type2];
        imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePicker.videoMaximumDuration = kESVideoLength;
        
        if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear])
        {
            imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        }
        else if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront])
        {
            imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        }
    }
    else return NO;
    imagePicker.allowsEditing = canEdit;
    imagePicker.showsCameraControls = YES;
    imagePicker.delegate = target;
    [target presentViewController:imagePicker animated:YES completion:nil];
    return YES;
}

+ (BOOL)presentPhotoLibrary:(id)target editable:(BOOL)canEdit
{
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
         && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) return NO;
    NSString *type = (NSString *)kUTTypeImage;
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
        && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:type])
    {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = [NSArray arrayWithObject:type];
    }
    else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
             && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:type])
    {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        imagePicker.mediaTypes = [NSArray arrayWithObject:type];
    }
    else return NO;
    imagePicker.allowsEditing = canEdit;
    imagePicker.delegate = target;
    [target presentViewController:imagePicker animated:YES completion:nil];
    return YES;
}

+ (BOOL)presentVideoLibrary:(id)target editable:(BOOL)canEdit
{
    if (([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary] == NO
         && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum] == NO)) return NO;
    NSString *type = (NSString *)kUTTypeMovie;
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.videoMaximumDuration = kESVideoLength;
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]
        && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypePhotoLibrary] containsObject:type])
    {
        imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePicker.mediaTypes = [NSArray arrayWithObject:type];
    }
    else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeSavedPhotosAlbum]
             && [[UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeSavedPhotosAlbum] containsObject:type])
    {
        imagePicker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
        imagePicker.mediaTypes = [NSArray arrayWithObject:type];
    }
    else return NO;
    imagePicker.allowsEditing = canEdit;
    imagePicker.delegate = target;
    [target presentViewController:imagePicker animated:YES completion:nil];
    return YES;
}

#pragma mark - general

+ (void)loginUser:(id)target
{
    NavigationController *navigationController = [[NavigationController alloc] initWithRootViewController:[[ESWelcomeView alloc] init]];
    [target presentViewController:navigationController animated:YES completion:nil];
}

+ (void)postNotification:(NSString *)notification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:notification object:nil];
}

#pragma mark - converting units

+ (NSString*)convertDateToString:(NSDate *)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return [formatter stringFromDate:date];
}

+ (NSDate*)convertStringToDate:(NSString *)dateStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    return [formatter dateFromString:dateStr];
}

+ (NSString*)calculateTimeInterval:(NSTimeInterval)seconds
{
    NSString *elapsed;
    if (seconds < 60)
    {
        elapsed = @"Just now";
    }
    else if (seconds < 60 * 60)
    {
        int minutes = (int) (seconds / 60);
        elapsed = [NSString stringWithFormat:@"%d %@", minutes, (minutes > 1) ? @"mins" : @"min"];
    }
    else if (seconds < 24 * 60 * 60)
    {
        int hours = (int) (seconds / (60 * 60));
        elapsed = [NSString stringWithFormat:@"%d %@", hours, (hours > 1) ? @"hours" : @"hour"];
    }
    else
    {
        int days = (int) (seconds / (24 * 60 * 60));
        elapsed = [NSString stringWithFormat:@"%d %@", days, (days > 1) ? @"days" : @"day"];
    }
    return elapsed;
}

#pragma mark - files

+ (NSString*)applications:(NSString *)file
{
    NSString *path = [[NSBundle mainBundle] resourcePath];
    if (file != nil) path = [path stringByAppendingPathComponent:file];
    return path;
}

+ (NSString*)caches:(NSString *)file
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if (file != nil) path = [path stringByAppendingPathComponent:file];
    return path;
}

#pragma mark - image backend

+ (UIImage*)squaredImage:(UIImage *)image withSize:(CGFloat)size
{
    UIImage *cropped;
    if (image.size.height > image.size.width)
    {
        CGFloat ypos = (image.size.height - image.size.width) / 2;
        cropped = [self croppedImage:image withX:0 withY:ypos withWidth:image.size.width withHeight:image.size.width];
    }
    else
    {
        CGFloat xpos = (image.size.width - image.size.height) / 2;
        cropped = [self croppedImage:image withX:xpos withY:0 withWidth:image.size.height withHeight:image.size.height];
    }
    UIImage *resized = [ESUtility resizedImage:cropped withWidth:size withHeight:size];
    return resized;
}

+ (UIImage*)resizedImage:(UIImage *)image withWidth:(CGFloat)width withHeight:(CGFloat)height
{
    CGSize size = CGSizeMake(width, height);
    CGRect rect = CGRectMake(0, 0, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    [image drawInRect:rect];
    UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resized;
}

+ (UIImage*)croppedImage:(UIImage *)image withX:(CGFloat)x withY:(CGFloat)y withWidth:(CGFloat)width withHeight:(CGFloat)height
{
    CGRect rect = CGRectMake(x, y, width, height);
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return cropped;
}

#pragma mark - video backend

+ (UIImage*)videoThumbnailForURL:(NSURL *)video
{
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:video options:nil];
	AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
	generator.appliesPreferredTrackTransform = YES;
	CMTime time = [asset duration]; time.value = 0;
	NSError *error = nil;
	CMTime actualTime;
	CGImageRef image = [generator copyCGImageAtTime:time actualTime:&actualTime error:&error];
	UIImage *thumbnail = [[UIImage alloc] initWithCGImage:image];
	CGImageRelease(image);
	return thumbnail;
}

+ (NSNumber*)videoDurationForURL:(NSURL *)video
{
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:video options:nil];
	int duration = (int) round(CMTimeGetSeconds(asset.duration));
	return [NSNumber numberWithInt:duration];
}
@end
