//
//  SmartConfigViewController.h
//  OneShotConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OneShotConfig.h"
#import "MBProgressHUD.h"
enum TAG_TEXTFIELD{
    
    Tag_wifiName = 100,
    Tag_wifiPassword
};

@interface OneshotConfigViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate,
    MBProgressHUDDelegate>{
    OneShotConfig *communication;
}

@property (nonatomic, strong) IBOutlet UITextField *networkName;
@property (nonatomic, strong) IBOutlet UITextField *networkPassword;
@property (nonatomic, strong) IBOutlet UIButton *btnSecureText;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicate;
@property (nonatomic, strong) IBOutlet UIButton *btnStartConfig;
- (IBAction)loseFirstResponser:(id)sender;

- (IBAction)smartConfig:(id)sender;
- (IBAction)secureText:(id)sender;

@end
