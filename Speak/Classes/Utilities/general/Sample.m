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

//
//---------------------------------------------------------------------------------------
//
/*
 This first example is just a very normal Parse request where we store some object in the database. We create the object, give it some attributes and values, set some read/write permission (ACL), and then upload it in the background with some block that gives us a feedback if the upload was successful or not.
 */

PFObject *videoObject = [PFObject objectWithClassName:kESPhotoClassKey];
[videoObject setObject:videoFile forKey:kESVideoFileKey];
[videoObject setObject:thumbnail forKey:kESVideoFileThumbnailKey];
[videoObject setObject:_thumbnail forKey:kESVideoFileThumbnailRoundedKey];
[videoObject setObject:kESVideoTypeKey forKey:kESVideoOrPhotoTypeKey];
[videoObject setACL:ACL]; //defined before
[videoObject setObject:[PFUser currentUser] forKey:@"user"];

[videoObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadEnds" object:nil];
    if (succeeded) {
        [ProgressHUD dismiss];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"videoUploadSucceeds" object:nil];
    }
    else if (error) {
        [ProgressHUD showError:NSLocalizedString(@"Internet connection failed", nil)];
    }
}];

//
//---------------------------------------------------------------------------------------
//
/*
 This second example shows a standard query function. You'll find those methods in TableViewControllers that display some sort of data stored in the database. The tableview controller calls this function below, which returns some Parse Network Query. The returned query is exectued in some other part of the code and returns the objects we requested. Again, the syntax makes this straightforward to understand. We first define the query, and then set some attributes that guarantee that we only get back the data we wanted (in this case some sort of feed of posts from people we followed)
 */
- (PFQuery *)queryForTable {
    if (![PFUser currentUser]) {
        PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
        [query setLimit:0];
        return query;
    }
    
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
    [query whereKey:kESActivityToUserKey equalTo:[PFUser currentUser]];
    [query whereKey:kESActivityFromUserKey notEqualTo:[PFUser currentUser]];
    [query whereKeyExists:kESActivityFromUserKey];
    
    [query setCachePolicy:kPFCachePolicyNetworkOnly];
    
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    //
    // If there is no network connection, we will hit the cache first.
    if (self.objects.count == 0 || ![[[UIApplication sharedApplication]delegate] performSelector:@selector(isParseReachable)]) {
        [query setCachePolicy:kPFCachePolicyCacheThenNetwork];
    }
    
    [query orderByDescending:@"createdAt"];
    [query includeKey:kESActivityFromUserKey];
    [query includeKey:kESActivityPhotoKey];
    
    return query;
}

//
//---------------------------------------------------------------------------------------
//
/*
 This example is just another straightforwad query where we check if some given user is already followed by the current user. We first check back with our cache, and if no cached value is found, we run this part of the code (this is not an entire method obviously, just a part of some if-else statement). The actual query is in a synchronized closure because we want to make sure that we don't make this query a dozen times. It simply checks if there are outstanding queries of this time, and then runs the query if not.
 */


@synchronized(self) {
    NSNumber *outstandingQuery = [self.outstandingFollowQueries objectForKey:indexPath];
    if (!outstandingQuery) {
        [self.outstandingFollowQueries setObject:[NSNumber numberWithBool:YES] forKey:indexPath];
        PFQuery *isFollowingQuery = [PFQuery queryWithClassName:kESActivityClassKey];
        [isFollowingQuery whereKey:kESActivityFromUserKey equalTo:[PFUser currentUser]];
        [isFollowingQuery whereKey:kESActivityTypeKey equalTo:kESActivityTypeFollow];
        [isFollowingQuery whereKey:kESActivityToUserKey equalTo:(PFObject *)obj2];
        [isFollowingQuery setCachePolicy:kPFCachePolicyCacheThenNetwork];
        
        [isFollowingQuery countObjectsInBackgroundWithBlock:^(int number, NSError *error) {
            @synchronized(self) {
                [self.outstandingFollowQueries removeObjectForKey:indexPath];
                [[ESCache sharedCache] setFollowStatus:(!error && number > 0) user:(PFUser *)obj2];
            }
            if (cell.tag == indexPath.section) {
                [cell.followButton setSelected:(!error && number > 0)];
            }
        }];
    }
}
//
//---------------------------------------------------------------------------------------
//
/*
 This last example is a very basic Firebase query example. The syntax is a bit different from the previous Parse example, because Firebase has another structure in terms of its database and in terms of how it handles data. Here, we simply set a "delivered" badge to a message that we sent, if and only if this message has gone through to the database.
 */

+ (void)setDeliveredForMessage:(NSString *)groupId andString:(NSString *)read {
    FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:@"Conversations"];
    FIRDatabaseQuery *query = [[firebase queryOrderedByChild:@"groupId"] queryEqualToValue:groupId];
    [query observeSingleEventOfType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot *snapshot)
     {
         if (snapshot.value != [NSNull null])
         {
             for (NSDictionary *recent in [snapshot.value allValues])
             {
                 PFUser *user = [PFUser currentUser];
                 if ([recent[@"userId"] isEqualToString:user.objectId] == YES) {
                     //---------------------------------------------------------------------------------------------------------------------------------------------
                     FIRDatabaseReference *firebase = [[[FIRDatabase database] reference] child:[NSString stringWithFormat:@"Conversations/%@", recent[@"recentId"]]];
                     NSDictionary *values = @{@"status":read};
                     [firebase updateChildValues:values withCompletionBlock:^(NSError * _Nullable error, FIRDatabaseReference * _Nonnull ref)
                      {
                          if (error != nil) NSLog(@"setDeliveredForMessage save error.");
                      }];
                 }
             }
         }
     }];
}



