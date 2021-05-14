//
//  RFAboutViewController.m
//  RFAboutView
//
//  Created by René Fouquet on 10/05/15.
//  Copyright (c) 2015 René Fouquet. All rights reserved.
//

#import "RFAboutViewController.h"
#import "RFAboutViewDetailViewController.h"
#include <sys/sysctl.h>
#import "ESTermsView.h"
#import "ESPrivacyView.h"
#import "ESDependenciesView.h"
#import "ESChatView.h"
#import "TOWebViewController.h"
#import "ProgressHUD.h"
#import "ESConstants.h"

@interface RFAboutViewController ()
@property (nonatomic, strong) NSArray *acknowledgements;
@property (nonatomic, strong) NSDictionary *metrics;
@property (nonatomic, strong) NSLayoutConstraint *scrollViewContainerWidth;
@property (nonatomic, strong) NSMutableArray *additionalButtons;
@end

@implementation RFAboutViewController

- (id)init {
    return [self initWithAppName:nil
                      appVersion:nil
                        appBuild:nil
             copyrightHolderName:nil
                    contactEmail:nil
                   titleForEmail:nil
                      websiteURL:nil
              titleForWebsiteURL:nil
              andPublicationYear:nil];
}

- (id)initWithAppName:(NSString *)appName
           appVersion:(NSString *)appVersion
             appBuild:(NSString *)appBuild
  copyrightHolderName:(NSString *)copyrightHolderName
         contactEmail:(NSString *)contactEmail
        titleForEmail:(NSString *)contactEmailTitle
           websiteURL:(NSURL *)websiteURL
   titleForWebsiteURL:(NSString *)websiteURLTitle
   andPublicationYear:(NSString *)pubYear {
    
    self = [super init];
    if (self) {
        
        // Set the default values for the properties
        
        _additionalButtons = [NSMutableArray new];
        
        _closeButtonImage = [UIImage imageNamed:@"RFAboutViewCloseX"];
        UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:_closeButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(close)];
        self.navigationItem.leftBarButtonItem = leftItem;

        _headerBorderColor = [UIColor lightGrayColor];
        _headerBackgroundColor = [UIColor whiteColor];
        _tintColor = [UIColor blackColor];
        _headerTextColor = [UIColor blackColor];
        _backgroundColor = [UIColor colorWithRed:0.94 green:0.94 blue:0.94 alpha:1];
        _acknowledgementsHeaderColor = [UIColor blackColor];
        _tableViewBackgroundColor = [UIColor whiteColor];
        _tableViewTextColor = [UIColor blackColor];
        
        self.navigationViewBackgroundColor = self.navigationController.view.backgroundColor; // Set from system default
        self.navigationBarBarTintColor = self.navigationController.navigationBar.barTintColor; // Set from system default
        self.navigationBarTintColor = self.tintColor; // Set from system default
        self.navigationBarTitleTextColor = [UIColor blackColor];
        
        _acknowledgementsFilename = @"Acknowledgements";
        
        _showAcknowledgements = YES;
        _blurHeaderBackground = YES;
        _includeDiagnosticInformationInEmail = YES;
        _showsScrollIndicator = YES;
        
        _blurStyle = UIBlurEffectStyleLight;
        
        // Get the values from the init parameters
        
        _appName = appName;
        _appVersion = appVersion;
        _appBuild = appBuild;
        _contactEmail = contactEmail;
        _contactEmailTitle = contactEmailTitle;
        _websiteURLTitle = websiteURLTitle;
        _copyrightHolderName = copyrightHolderName;
        _websiteURL = websiteURL;
        
        if (!appName) _appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        if (!appVersion) _appVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        if (!appBuild) _appBuild = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
        if (!contactEmailTitle) _contactEmailTitle = _contactEmail;
        if (!copyrightHolderName) _copyrightHolderName = @"Some Developer";
        if (!websiteURLTitle) _websiteURLTitle = [NSString stringWithFormat:@"%@", _websiteURL];

        if (!pubYear) _pubYear = [NSString stringWithFormat:@"%ld",(long)[[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]] year]];
    }
    return self;

}

- (void)loadView {
    [super loadView];
    
    NSString *ackFile = [[NSBundle mainBundle] pathForResource:self.acknowledgementsFilename ofType:@"plist"];
    
    self.acknowledgements = [self reformatAcknowledgementsDictionary:[NSDictionary dictionaryWithContentsOfFile:ackFile]];
    
    // Set up the view
    
    self.view.backgroundColor = self.backgroundColor;
    self.view.tintColor = self.tintColor;
    self.navigationItem.leftBarButtonItem.tintColor = self.view.tintColor;
    self.navigationController.view.backgroundColor = self.navigationViewBackgroundColor;
    self.navigationController.navigationBar.barTintColor = self.navigationBarBarTintColor;
    self.navigationController.navigationBar.tintColor = self.navigationBarTintColor;
    
    UIScrollView *mainScrollView = [UIScrollView new];
    mainScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    mainScrollView.backgroundColor = [UIColor clearColor];
    mainScrollView.showsHorizontalScrollIndicator = NO;
    mainScrollView.showsVerticalScrollIndicator = self.showsScrollIndicator;
    [self.view addSubview:mainScrollView];

    UIView *scrollViewContainer = [UIView new];
    scrollViewContainer.translatesAutoresizingMaskIntoConstraints = NO;
    scrollViewContainer.backgroundColor = [UIColor clearColor];
    [mainScrollView addSubview:scrollViewContainer];
    
    UIView *headerView = [UIView new];
    headerView.translatesAutoresizingMaskIntoConstraints = NO;
    headerView.backgroundColor = self.headerBackgroundColor;
    headerView.layer.borderColor = self.headerBorderColor.CGColor;
    headerView.layer.borderWidth = 0.5;
    headerView.clipsToBounds = YES;
    [scrollViewContainer addSubview:headerView];
    
    UIImageView *headerBackground = [UIImageView new];
    headerBackground.translatesAutoresizingMaskIntoConstraints = YES;
    headerBackground.image = self.headerBackgroundImage;
    headerBackground.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, headerView.bounds.size.height);
    headerBackground.contentMode = UIViewContentModeScaleAspectFill;
    headerBackground.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [headerView addSubview:headerBackground];
    
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:self.blurStyle]];
    visualEffectView.translatesAutoresizingMaskIntoConstraints = YES;
    visualEffectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:self.blurStyle]];
    visualEffectView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);

    if (self.blurHeaderBackground) {
        [headerBackground addSubview:visualEffectView];
    }

    UILabel *appName = [UILabel new];
    appName.translatesAutoresizingMaskIntoConstraints = NO;
    appName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[self sizeForPercent:5.625]];
    appName.userInteractionEnabled = NO;
    appName.numberOfLines = 0;
    appName.backgroundColor = [UIColor clearColor];
    appName.textAlignment = NSTextAlignmentCenter;
    appName.text = self.appName;
    appName.textColor = self.headerTextColor;
    [headerView addSubview:appName];
    [appName sizeToFit];
    [appName layoutIfNeeded];

    UILabel *copyrightInfo = [UILabel new];
    copyrightInfo.translatesAutoresizingMaskIntoConstraints = NO;
    copyrightInfo.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[self sizeForPercent:4.375]];
    copyrightInfo.userInteractionEnabled = NO;
    copyrightInfo.numberOfLines = 0;
    copyrightInfo.textColor = self.headerTextColor;
    copyrightInfo.backgroundColor = [UIColor clearColor];
    copyrightInfo.textAlignment = NSTextAlignmentCenter;
    copyrightInfo.text = [NSString stringWithFormat:@"Version %@ (%@)\n© %@ %@", self.appVersion, self.appBuild, self.pubYear, self.copyrightHolderName];
    [headerView addSubview:copyrightInfo];
    [copyrightInfo sizeToFit];
    [copyrightInfo layoutIfNeeded];
    
    UIButton *websiteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    
    if (self.websiteURL) {
        websiteButton.translatesAutoresizingMaskIntoConstraints = NO;
        [websiteButton setTitle:self.websiteURLTitle forState:UIControlStateNormal];
        websiteButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[self sizeForPercent:4.375]];
        [websiteButton setTitleColor:self.headerTextColor forState:UIControlStateNormal];
        [websiteButton addTarget:self action:@selector(goToWebsite) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:websiteButton];
    }

    UIButton *emailButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    if (self.contactEmail) {
        emailButton.translatesAutoresizingMaskIntoConstraints = NO;
        [emailButton setTitle:self.contactEmailTitle forState:UIControlStateNormal];
        emailButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[self sizeForPercent:4.375]];
        [emailButton setTitleColor:self.headerTextColor forState:UIControlStateNormal];
        [emailButton addTarget:self action:@selector(email) forControlEvents:UIControlEventTouchUpInside];
        [headerView addSubview:emailButton];
    }
    
    UITableView *additionalButtonsTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];

    additionalButtonsTable.translatesAutoresizingMaskIntoConstraints = NO;
    additionalButtonsTable.clipsToBounds = NO;
    additionalButtonsTable.delegate = self;
    additionalButtonsTable.dataSource = self;
    additionalButtonsTable.scrollEnabled = NO;
    additionalButtonsTable.contentInset = UIEdgeInsetsMake(-35, 0, 0, 0);
    additionalButtonsTable.backgroundColor = [UIColor clearColor];
    additionalButtonsTable.rowHeight = UITableViewAutomaticDimension;
    additionalButtonsTable.estimatedRowHeight = [self sizeForPercent:12.5];
    if (self.additionalButtons.count > 0) {
        [scrollViewContainer addSubview:additionalButtonsTable];
    }
    

    /*
     A word of warning!
     Here comes all the Autolayout mess. Seriously, it's horrible. It's ugly, hard to follow and hard to maintain.
     But that'spretty much the only way to do it in code without external Autolayout wrappers like Masonry.
     Do yourself a favor and don't set up constraints like that if you can help it. You will save yourself a
     lot of headaches.
    */
    
    CGSize currentScreenSize = [UIScreen mainScreen].bounds.size;
    CGFloat padding = [self sizeForPercent:3.125];
    CGFloat tableViewHeight = ([self sizeForPercent:12.5] * self.acknowledgements.count);
    CGFloat additionalButtonsTableHeight = ([self sizeForPercent:12.5] * self.additionalButtons.count);
    
    self.metrics = @{
                     @"padding":@(padding),
                     @"doublePadding":@(padding * 2),
                     @"additionalButtonsTableHeight":@(additionalButtonsTableHeight),
                     @"tableViewHeight":@(tableViewHeight)
                     };
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(mainScrollView,scrollViewContainer,headerView,headerBackground,visualEffectView,appName,copyrightInfo,emailButton,websiteButton,additionalButtonsTable);

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mainScrollView]|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mainScrollView]|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
    
    // We need to save the constraint to manually change the constant when the screen rotates:
    
    self.scrollViewContainerWidth = [NSLayoutConstraint constraintWithItem:scrollViewContainer
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.0
                                                                  constant:currentScreenSize.width];
    
    [mainScrollView addConstraint:self.scrollViewContainerWidth];
    
    [mainScrollView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scrollViewContainer]|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
    
    [scrollViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[headerView]|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];

    NSString *firstFormatString = @"";
    
    if (self.additionalButtons.count > 0) {
        [scrollViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[additionalButtonsTable]|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
        firstFormatString = [firstFormatString stringByAppendingString:@"-doublePadding-[additionalButtonsTable(==additionalButtonsTableHeight)]"];
    }
    
    if (self.showAcknowledgements) {
        [scrollViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[tableHeaderLabel]-padding-|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
        [scrollViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[acknowledgementsTableView]|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
        firstFormatString = [firstFormatString stringByAppendingString:@"-doublePadding-[tableHeaderLabel]-padding-[acknowledgementsTableView(==tableViewHeight)]-doublePadding-"];
    } else {
    }
    
    [scrollViewContainer addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|[headerView]%@|",firstFormatString] options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
    
    NSString *secondFormatString = @"";
  
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[appName]-padding-|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[copyrightInfo]-padding-|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];

    if (self.websiteURL) {
        [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[websiteButton]-padding-|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
        secondFormatString = [secondFormatString stringByAppendingString:@"-padding-[websiteButton]"];
    }
    if (self.contactEmail) {
        [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-padding-[emailButton]-padding-|" options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];
        if (!self.websiteURL) {
            secondFormatString = [secondFormatString stringByAppendingString:@"-padding-[emailButton]"];
        } else {
            secondFormatString = [secondFormatString stringByAppendingString:@"-0-[emailButton]"];
        }
    }
    [headerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-doublePadding-[appName]-padding-[copyrightInfo]%@-doublePadding-|",secondFormatString] options:NSLayoutFormatAlignAllCenterX metrics:self.metrics views:viewsDictionary]];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.titleTextAttributes = @{ NSForegroundColorAttributeName: self.navigationBarTitleTextColor };
    UIColor *color = [UIColor darkGrayColor];    NSMutableDictionary *navBarTextAttributes = [NSMutableDictionary dictionaryWithCapacity:1];
    [navBarTextAttributes setObject:color forKey:NSForegroundColorAttributeName ];
    [navBarTextAttributes setObject:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15] forKey:NSFontAttributeName ];
    self.navigationController.navigationBar.titleTextAttributes = navBarTextAttributes;
    self.navigationItem.backBarButtonItem=[[UIBarButtonItem alloc] initWithTitle:@"About" style:UIBarButtonItemStylePlain target:nil action:nil];

    self.navigationItem.title = NSLocalizedString(@"ABOUT", @"UINavigationBar Title");
}

- (void)addAdditionalButtonWithTitle:(NSString *)title andContent:(NSString *)content {
    [self.additionalButtons addObject:@{
                                        @"title":title,
                                        @"content":content
                                        }];
}

#pragma mark - UITableView delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
        if (section == 0) {
            return 1;
        }
        else return 3;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[self sizeForPercent:4.688]];

        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        

        
        NSString *title = nil;
            if (indexPath.section == 0) {
                title = @"Get Help";
            }
            else title = self.additionalButtons[(NSUInteger)indexPath.row][@"title"];
            /*
            if (indexPath.row == 1) cell.imageView.image = [UIImage imageNamed:@"Security_On_64"];
            else if (indexPath.row == 2) cell.imageView.image = [UIImage imageNamed:@"Verification_of_delivery_list_clipboard_symbol_64"];
            else if (indexPath.row == 3) cell.imageView.image = [UIImage imageNamed:@"Written_conversation_speech_bubble_with_letter_i_inside_of_information_for_interface_64"];
*/

        cell.textLabel.text = title;
        cell.textLabel.textColor = self.tableViewTextColor;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.selected = NO;
    
    
        if (indexPath.row == 0 && indexPath.section == 0) {
            PFUser *user1 = [PFUser currentUser];
            NSString *id1 = user1.objectId;
                    
                                    PFQuery *query = [PFUser query];
            [ProgressHUD show:@"Loading..." Interaction:NO];
            [query whereKey:@"specialUser" equalTo:@"help"];
            [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error){
                [ProgressHUD dismiss];
                if (!error) {
                    PFUser *user2 = (PFUser *)object;
                    NSString *id2 = user2.objectId;
                    NSString *groupId = ([id1 compare:id2] < 0) ? [NSString stringWithFormat:@"%@%@", id1, id2] : [NSString stringWithFormat:@"%@%@", id2, id1];
                    NSArray *members = @[user1.objectId, id2];

                    [ESUtility createRecentItemForUser:user2 withGroupId:groupId withMembers:members withDescription:user1[kESUserFullname] andOption:@"NO"];
                    
                    ESChatView *chatView = [[ESChatView alloc] initWith:groupId andTitle:@"Help"];
                    chatView.hidesBottomBarWhenPushed = YES;
                    [self.navigationController pushViewController:chatView animated:YES];
                }
            }];
           
        }
        else if (indexPath.row == 0 && indexPath.section == 1) {
            ESPrivacyView *privacyView = [[ESPrivacyView alloc] init];
            privacyView.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:privacyView animated:YES];
        }
        else if (indexPath.row == 1 && indexPath.section == 1) {
            ESTermsView *termsView = [[ESTermsView alloc] init];
            termsView.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:termsView animated:YES];
        }
        else if (indexPath.row == 2 && indexPath.section == 1) {
            ESDependenciesView *thirdParties = [[ESDependenciesView alloc] init];
            thirdParties.hidesBottomBarWhenPushed = YES;
            [self.navigationController pushViewController:thirdParties animated:YES];
        }


   
}
#pragma mark - Action methods

- (void)goToWebsite {
    TOWebViewController *webViewController = [[TOWebViewController alloc] initWithURL:self.websiteURL];
    [self.navigationController pushViewController:webViewController animated:YES];
}

- (void)email {
    NSString *iosVersion = [UIDevice currentDevice].systemVersion;
    NSString *device = [UIDevice currentDevice].model;
    NSString *deviceString = [self platformRawString];
    NSString *lang = [NSLocale preferredLanguages][0];
    NSString *messageString = nil;

    if (self.includeDiagnosticInformationInEmail) {
        messageString = [NSString stringWithFormat:NSLocalizedString(@"<p>[Please insert your message here]</p><p><em>For support inquiries, please include the following information. These make it easier for us to help you. Thank you!</em><p><hr><p><strong>Support Information</strong></p></p>%@ Version %@ (%@)<br>%@ (%@)<br>iOS %@ (%@)</p><hr>", @"Prefilled Email message text"), self.appName, self.appVersion, self.appBuild, device, deviceString, iosVersion, lang];
    }
    NSString *subject = [NSString stringWithFormat:@"%@ %@", self.appName, self.appVersion];
    
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    mailController.mailComposeDelegate = self;
    if ([MFMailComposeViewController canSendMail]) {
        [mailController setSubject:subject];
        [mailController setMessageBody:messageString isHTML:YES];
        [mailController setToRecipients:@[self.contactEmail]];
        [self presentViewController:mailController animated:YES completion:nil];
    } else {
        __block NSString *supportText = [NSString stringWithFormat:@"\"%@ Version %@ (%@), %@ (%@), iOS %@ (%@)\"",self.appName, self.appVersion, self.appBuild, device, deviceString, iosVersion, lang];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Cannot send Email",@"Cannot send Email") message:[NSString stringWithFormat:NSLocalizedString(@"Unfortunately there are no Email accounts available on your device.\n\nFor support questions, please send an Email to %@ and include the following information: %@.\n\nTab the 'Copy info' button to copy this information to your pasteboard. Thank you!", @"Error message: no email accounts available"), self.contactEmail, supportText, lang] preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Dismiss",@"Dismiss error message") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action){
            [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }];
        UIAlertAction *copyInfoAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Copy Info",@"Copy diagnostic info to pasteboard") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
            [UIPasteboard generalPasteboard].string = supportText;
            [alert.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }];
        [alert addAction:dismissAction];
        [alert addAction:copyInfoAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:^{
        if (result == MFMailComposeResultFailed) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Message Failed!",@"Sending email message failed") message:NSLocalizedString(@"Your email has failed to send.",@"Sending email message failed body") delegate:self cancelButtonTitle:NSLocalizedString(@"Dismiss",@"Dismiss error message") otherButtonTitles:nil];
            [alert show];
        }
    }];
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Autorotation stuff

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // Changes the scroll view container width constant to the new width. Because AutoLayout.
    
    self.scrollViewContainerWidth.constant = size.width;
    [UIView animateWithDuration:0.2 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - Helper stuff

/*!
 *  Gives a float value based on the given percentage of the screen width. For iPad, this had to change a bit because it just looks wrong because of the large screen. Seems OK on iPhone 6 Plus.
 */
- (CGFloat)sizeForPercent:(CGFloat)percent {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return (CGFloat)ceil(((self.view.frame.size.width * 0.7) * (percent / 100)));
    } else {
        return (CGFloat)ceil(self.view.frame.size.width * (percent / 100));
    }
}

/*!
 *  Gets the raw platform id (e.g. iPhone7,1)
 *  Props to http://stackoverflow.com/questions/26040779/how-to-get-current-device-current-platform-in-ios
 */
- (NSString *)platformRawString {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

/*!
 *  Prepare the source plist for the acknowledgements by applying some ugly hacking that
 *  will probably brake with the next Cocoapods update. This is why we reformat the
 *  data here. If anything changes, we just need to change this method.
 */
- (NSArray *)reformatAcknowledgementsDictionary:(NSDictionary *)originalDict {
    NSMutableArray *theDict = [originalDict[@"PreferenceSpecifiers"] mutableCopy];
   // [theDict removeObject:[theDict firstObject]];
   // [theDict removeObject:[theDict lastObject]];

    NSMutableArray *outputArray = [NSMutableArray new];
    
    for (NSDictionary *innerDict in theDict) {
        [outputArray addObject:@{
                                 @"title":innerDict[@"Title"],
                                 @"content":innerDict[@"FooterText"]
                                 }];
    }
    return outputArray;
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
