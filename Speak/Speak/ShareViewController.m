//
//  ShareViewController.m
//
//  Created by Eric Schanet on 24.06.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>
#import "ItemViewController.h"
#import <Parse/Parse.h>
#import "ShareViewController.h"
#import <Firebase/Firebase.h>
#import <Social/Social.h>

@interface ShareViewController() <ItemViewDelegate>{
    SLComposeSheetConfigurationItem *_item;
    SLComposeSheetConfigurationItem *_item2;
    ItemViewController *vc;
    PFUser *user2;
    UIImage *picture;
}
@property(readonly, nonatomic) NSString *contentText;
@property(strong, nonatomic) ItemViewController *vc;

@property(copy, nonatomic) NSString *placeholder;

@end

@implementation ShareViewController
@synthesize contentText,placeholder,vc;
- (void)viewDidLoad {
    if(![Parse applicationGroupIdentifierForDataSharing]) {
        [Parse enableDataSharingWithApplicationGroupIdentifier:@"group.eric.MessengerApp.com" containingApplication:@"eric.MessengerApp.com"];
        // Setup Parse
      //  [Parse setApplicationId:@"hqUeDpRbVTDp19kmQqSx59j5FKv0G0sMpoIGSHHM" clientKey:@"QWMAZRAy8Hg0BrK9pOIYRaqKlgbIW0tLxyiGwFPc"];
        [Parse initializeWithConfiguration:[ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
            configuration.applicationId = @"hqUeDpRbVTDp19kmQqSx59j5FKv0G0sMpoIGSHHM";
            configuration.clientKey = @"QWMAZRAy8Hg0BrK9pOIYRaqKlgbIW0tLxyiGwFPc";
            configuration.server = @"https://parseapi.back4app.com";
        }]];
        
    }    vc = [[ItemViewController alloc] init];
    vc.delegate = self;

    [[[self navigationController] navigationBar] setTintColor:[UIColor whiteColor]];
    [[[self navigationController] navigationBar] setBackgroundColor:[UIColor colorWithRed:0.0f/255.0f green:129.0f/255.0f blue:188.0f/255.0f alpha:1]];

    NSExtensionItem *__item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = __item.attachments.firstObject;
    
    if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"]) {
        [itemProvider loadItemForTypeIdentifier:@"public.url"
                                        options:nil
                              completionHandler:^(NSURL *url, NSError *error) {
                                  if (!error) {
                                      _item2 = [[SLComposeSheetConfigurationItem alloc] init];
                                      [_item2 setTitle:@"URL"];
                                      [_item2 setValue:url.absoluteString];
                                  }
                              }];
    }
    else {
        self.placeholder = @"No message will be sent with \nthe image.";
    }
}

- (UIView *)loadPreviewView {
    UIView * previewView = [super loadPreviewView];
    NSExtensionItem *__item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = __item.attachments.firstObject;
    if (![itemProvider hasItemConformingToTypeIdentifier:@"public.image"]) {
        return nil;
    }
    else return previewView;
    
}
- (BOOL)isContentValid {
    // Calculate current message length
    NSInteger messageLength = [[self.contentText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
    // Determine characters remaining
    NSInteger charactersRemaining = 200 - messageLength;
    // Update automatically generated charactersRemaining field
    self.charactersRemaining = @(charactersRemaining);
    if (charactersRemaining >= 0) {
        return YES;
    }
    return NO;
}

- (void)didSelectPost {
    NSExtensionItem *__item = self.extensionContext.inputItems.firstObject;
    NSItemProvider *itemProvider = __item.attachments.firstObject;
    if ([itemProvider hasItemConformingToTypeIdentifier:@"public.url"]) {
        [itemProvider loadItemForTypeIdentifier:@"public.url"
                                        options:nil
                              completionHandler:^(NSURL *url, NSError *error) {
                                  NSString *urlString = url.absoluteString;

                                  PFUser *user1 = [PFUser currentUser];
                                                                NSString *id1 = user1.objectId;
                                  NSString *id2 = user2.objectId;
                                  
                                  NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
                                  
                                  Firebase *firebase1 = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Message/%@", kESFirebase, groupId]];
                                  
                                  
                                  Firebase *reference = [firebase1 childByAutoId];
                                  NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
                                                                item[@"userId"] = user1.objectId;
                                  item[@"name"] = user1[kESUserFullname];
                                  
                                  NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                                  [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'zzz'"];
                                  [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                                
                                  item[@"date"] = [formatter stringFromDate:[NSDate date]];
                                  item[@"status"] = @"Delivered";
                                                                item[@"video"] = item[@"thumbnail"] = item[@"picture"] = item[@"audio"] = item[@"latitude"] = item[@"longitude"] = @"";
                                  item[@"video_duration"] = item[@"audio_duration"] = @0;
                                  item[@"picture_width"] = item[@"picture_height"] = @0;
                                  //if (!self.contentText) {
                                      item[@"text"] = [NSString stringWithFormat:@"%@\n%@",self.contentText,urlString];
                                  //}
                                  //else item[@"text"] = self.contentText;

                                  item[@"type"] = @"text";
                                  item[@"key"] = reference.key;
                                                                [reference setValue:item withCompletionBlock:^(NSError *error, Firebase *ref)
                                   {
                                       if (error != nil) {
                                           [self.extensionContext completeRequestReturningItems:@[]
                                                                              completionHandler:nil];
                                       }
                                       else {

                                       }
                                   }];
                                  
                                  NSString *__title = [[PFUser currentUser] objectForKey:kESUserFullname];
                                  PFUser *user = [PFUser currentUser];
                                  NSString *message = [NSString stringWithFormat:@"%@: %@", user[kESUserFullname], item[@"text"]];
                                
                                  
                                  PFQuery *queryInstallation = [PFInstallation query];
                                  [queryInstallation whereKey:kESInstallationUser equalTo:user2.objectId];
                                  
                                  PFPush *push = [[PFPush alloc] init];
                                  [push setQuery:queryInstallation];
                                  NSDictionary *data = [NSDictionary dictionaryWithObjectsAndKeys:
                                                        message, @"alert",
                                                        @"ACTIONABLE",@"category",
                                                        @"Increment", @"badge",
                                                        @"105.caf", @"sound",
                                                        groupId, @"groupId",
                                                        __title, @"groupTitle",
                                                        [user objectId], @"sendingUserId",
                                                        item[@"text"], @"message",
                                                        nil];
                                  [push setData:data];
                                
                                 // [push sendPush:nil];
                                  
//Haven't found a straightforward fix for this yet, need to investigate further!
                                 // [ESUtility updateRecentCounterForChat:groupId withCounter:1 andLastMessage:item[@"text"]];
                                 // [ESUtility setDeliveredForChat:groupId andStatus:@"Delivered"];

                                  [self.extensionContext completeRequestReturningItems:@[]
                                                                     completionHandler:nil];
                              }];
    }
    /*
    else if ([itemProvider hasItemConformingToTypeIdentifier:@"public.image"]) {
        [itemProvider loadItemForTypeIdentifier:@"public.image"
                                        options:nil
                              completionHandler:^(UIImage *image, NSError *error) {
                                  picture = [[UIImage alloc]init];
                                  
                                  if(image) {
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          picture = image;
                                      });
                                  }
                                  
                                  PFUser *user1 = [PFUser currentUser];
                                                                NSString *id1 = user1.objectId;
                                  NSString *id2 = user2.objectId;
                                  
                                  NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
                                  
                                  Firebase *firebase1 = [[Firebase alloc] initWithUrl:[NSString stringWithFormat:@"%@/Message/%@", kESFirebase, groupId]];
                                  
                                  
                                  Firebase *reference = [firebase1 childByAutoId];
                                  NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
                                                                item[@"userId"] = user1.objectId;
                                  item[@"name"] = user1[kESUserFullname];
                                  item[@"date"] = [ESUtility convertDateToString:[NSDate date]];
                                  item[@"status"] = @"Delivered";
                                                                item[@"video"] = item[@"thumbnail"] = item[@"picture"] = item[@"audio"] = item[@"latitude"] = item[@"longitude"] = @"";
                                  item[@"video_duration"] = item[@"audio_duration"] = @0;
                                  item[@"picture_width"] = item[@"picture_height"] = @0;
                                  item[@"key"] = reference.key;
                              
                                  
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

                                           [reference setValue:item withCompletionBlock:^(NSError *error, Firebase *ref)
                                            {
                                                if (error != nil) NSLog(@"messageSave network error.");
                                                else {
                                                    NSString *__title = [[PFUser currentUser] objectForKey:kESUserFullname];
                                                    SendPushNotification1(groupId, item[@"text"], __title);
                                                    [ESUtility updateRecentCounterForChat:groupId withCounter:1 andLastMessage:item[@"text"]];
                                                    SetDelivered1(groupId, @"Delivered");
                                                }
                                            }];
                                       }

                                   }];
                                  
                                 
                                  if (self.contentText) {
                                      NSMutableDictionary *item2 = [[NSMutableDictionary alloc] init];
                                                                        item2[@"userId"] = user1.objectId;
                                      item2[@"name"] = user1[kESUserFullname];
                                      item2[@"date"] = [ESUtility convertDateToString:[NSDate date]];
                                      item2[@"status"] = @"Delivered";
                                                                        item2[@"video"] = item2[@"thumbnail"] = item2[@"picture"] = item2[@"audio"] = item2[@"latitude"] = item2[@"longitude"] = @"";
                                      item2[@"video_duration"] = item2[@"audio_duration"] = @0;
                                      item2[@"picture_width"] = item2[@"picture_height"] = @0;
                                      item2[@"text"] = self.contentText;
                                      item2[@"type"] = @"text";
                                      item2[@"key"] = reference2.key;
                                                                        [reference2 setValue:item withCompletionBlock:^(NSError *error, Firebase *ref)
                                       {
                                           if (error != nil) NSLog(@"messageSave network error.");
                                           else {
                                               NSString *__title = [[PFUser currentUser] objectForKey:kESUserFullname];
                                               SendPushNotification1(groupId, item[@"text"], __title);
                                                [ESUtility updateRecentCounterForChat:groupId withCounter:1 andLastMessage:item[@"text"]];
                                               SetDelivered1(groupId, @"Delivered");
                                           }
                                       }];

                                  }
                                  [self.extensionContext completeRequestReturningItems:@[]
                                                                     completionHandler:nil];

                              }];
    }*/
}

- (NSArray *)configurationItems {
    
    _item = [[SLComposeSheetConfigurationItem alloc] init];
    // Give your configuration option a title.
    [_item setTitle:@"Recipient"];
    // Give it an initial value.
    [_item setValue:@"None"];
    // Handle what happens when a user taps your option.
    __weak typeof(self) weakSelf = self;

    [_item setTapHandler:^(void){
        // Create an instance of your configuration view controller.
        // Transfer to your configuration view controller.
        __strong typeof(self) strongSelf = weakSelf;
        [weakSelf pushConfigurationViewController:strongSelf.vc];
    }];
    
    if (_item2) {
        return @[_item, _item2];
    }
    else return @[_item];


    // Return an array containing your item.
    
}
-(void)sendingViewController:(ItemViewController *) controller sentItem:(PFUser *) retItem {
    // Set the configuration item's value to the returned value
    [_item setValue:retItem[kESUserFullname]];

    user2 = retItem;
   
    
    [self popConfigurationViewController];
}
@end
