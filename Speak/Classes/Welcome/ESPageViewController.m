//
//  ESPageViewController.m
//  app
//
//  Created by Eric Schanet on 30.05.15.
//  Copyright (c) 2015 KZ. All rights reserved.
//

#import "ESPageViewController.h"

@interface ESPageViewController ()

@end

@implementation ESPageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Custom initialization
    }

    return self;
    
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
      self.ivScreenImage.image = [UIImage imageNamed:self.imgFile];
    if (IS_IPHONE_6) {
        self.ivScreenImage.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 221.5, 10, 443, 380);
        self.lblScreenLabel.frame = CGRectMake(30, 410, [UIScreen mainScreen].bounds.size.width - 60, 40);
        self.lblScreenSubLabel.frame = CGRectMake(30, 420, [UIScreen mainScreen].bounds.size.width - 60, 100);
    }
    else if (IS_IPHONE_5) {
        self.ivScreenImage.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 175, 10, 350, 300);
        self.lblScreenLabel.frame = CGRectMake(30, 320, [UIScreen mainScreen].bounds.size.width - 60, 40);
        self.lblScreenSubLabel.frame = CGRectMake(30, 330, [UIScreen mainScreen].bounds.size.width - 60, 100);
    }
    else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.ivScreenImage.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 160, 70, 320, 320);
        self.lblScreenLabel.frame = CGRectMake(30, 410, [UIScreen mainScreen].bounds.size.width - 60, 40);
        self.lblScreenSubLabel.frame = CGRectMake(30, 420, [UIScreen mainScreen].bounds.size.width - 60, 100);
    }
    else if (IS_IPHONE_6P) {
        self.ivScreenImage.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 221.5, 30, 455, 390);
        self.lblScreenLabel.frame = CGRectMake(30, 460, [UIScreen mainScreen].bounds.size.width - 60, 40);
        self.lblScreenSubLabel.frame = CGRectMake(30, 470, [UIScreen mainScreen].bounds.size.width - 60, 100);

    }
    else {
        self.ivScreenImage.frame = CGRectMake([UIScreen mainScreen].bounds.size.width/2 - 151.5, 0, 303, 260);
        self.lblScreenLabel.frame = CGRectMake(30, 250, [UIScreen mainScreen].bounds.size.width - 60, 40);
        self.lblScreenSubLabel.frame = CGRectMake(30, 260, [UIScreen mainScreen].bounds.size.width - 60, 100);

    }
    self.lblScreenLabel.text = self.txtTitle;
    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    paragraph.alignment = NSTextAlignmentCenter;
    
    NSDictionary *attributes = @{ NSParagraphStyleAttributeName : paragraph,
                                  NSFontAttributeName : self.lblScreenSubLabel.font,
                                  NSBaselineOffsetAttributeName : [NSNumber numberWithFloat:0] };
    
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:self.subTxtTitle
                                                              attributes:attributes];
    
    self.lblScreenSubLabel.attributedText = str;
    self.view.backgroundColor = [UIColor colorWithRed:0.1843 green:0.4314 blue:0.8980 alpha:1];

}


- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
}

@end
