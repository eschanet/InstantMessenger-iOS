//
//  ESDependenciesView.m
//  app
//
//  Created by Eric Schanet on 02.07.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import "ESDependenciesView.h"

@interface ESDependenciesView ()
/**
 *  Webview used to display the html file of the dependencies
 */
@property (strong, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ESDependenciesView
@synthesize webView;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Third Parties Notice";

    // Do any additional setup after loading the view from its nib.
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    webView.frame = self.view.bounds;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:[ESUtility applications:@"dependencies.html"]]]];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
