//
//  SmartConfigViewController.m
//  OneShotConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//


#import "OneShotConfigViewController.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import "AppDelegate.h"

#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>


UIAlertView *alert;
int Flag = 1;

@interface OneshotConfigViewController ()

@end
@implementation OneshotConfigViewController
@synthesize networkName,networkPassword;
@synthesize btnSecureText;
@synthesize btnStartConfig;
NSThread *thread;
//int count = 0;
int count1 =0;
NSTimer *timer;
NSString *pastIPAddr;
- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"加载view");

    communication = [OneShotConfig getInstance];
    [self.navigationItem setHidesBackButton:YES];
    self.activityIndicate.hidesWhenStopped = YES;
    networkPassword.tag = Tag_wifiPassword;
    networkPassword.delegate = self;
    networkPassword.returnKeyType = UIReturnKeyDone;
    networkPassword.secureTextEntry = NO;
    networkName.tag = Tag_wifiName;
    networkName.delegate = self;
    networkName.returnKeyType = UIReturnKeyDone;
    [networkName setBackgroundColor:[UIColor whiteColor]];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateUI) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
    //程序将进入后台时，应关闭socket套接字
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(suspendApp) name:
        UIApplicationWillResignActiveNotification object:[UIApplication sharedApplication]];
    //程序将进入前台时执行，再次检查是否连接WIFI
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resumeApp) name:
        UIApplicationWillEnterForegroundNotification object:[UIApplication sharedApplication]];
    
    //检查当前连接网络是否为WIFI
//    [self checkIsWIFI];
    
    networkName.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SSIDINFO"];
    [networkName addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    [networkPassword addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(updateWIFIName) userInfo:nil repeats:YES];
}
-(void)checkIsWIFI
{
    //确保断网超时30秒后，手机仍未自动联网。用户通过设置设置网络再切到应用后将btnstartconfig的状态设置为可用
    btnStartConfig.enabled = YES;
//    NSString *ssid = [[NSUserDefaults standardUserDefaults] objectForKey:@"SSIDINFO"];
//    ssid = [[NSUserDefaults standardUserDefaults] objectForKey:@"SSIDINFO"];
    NSString *ssid = [self getWIFIName];
    if (ssid == nil || [ssid isEqualToString:@""])
    {
        alert = [[UIAlertView alloc]initWithTitle:nil message:@"请检查你的网络连接" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
    }
}

-(void)updateUI
{
    networkName.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"SSIDINFO"];
}
-(void)suspendApp
{
    NSLog(@"暂停queue,%i",count1++);
    if ([btnStartConfig.titleLabel.text isEqualToString:@"停止"]) {
        [self smartConfig:nil];
    }
}
-(void)resumeApp
{
    //接收到UIApplicationWillResignActiveNotification通知后，resumeApp方法有时会被多次调用。原因不大明确
    //查找到原因为view页面来回切换时，没有做释放，没切换一次应用就新开一个view
    NSLog(@"继续queue");
    [self checkIsWIFI];
}
- (void)textFieldDidChange:(UITextField *)textField
{
    if (self.networkName == textField) {
        if (textField.text.length > 32) {
            textField.text = [textField.text substringToIndex:32];
        }
//        if (textField.text.length == 0) {
//            [timer setFireDate:[NSDate distantPast]];
//        }
    }
    else{
        if (textField.text.length > 64) {
            textField.text = [textField.text substringToIndex:64];
        }
    }
    
    /**/
    
}
//校验密码中是否有非ASCII码字符
-(BOOL)passwdIsValidate
{
    NSInteger strlen = [networkPassword.text length];
    NSInteger datalen = [[networkPassword.text dataUsingEncoding:NSUTF8StringEncoding] length];
    if (strlen != datalen) {
        return false;
    }
    return true;
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)secureText:(id)sender{
    
    if (btnSecureText.selected) {
       [btnSecureText setTitle:@"显示密码" forState:UIControlStateNormal];
        networkPassword.secureTextEntry = NO;
    } else {
       [btnSecureText setTitle:@"隐藏密码" forState:UIControlStateNormal];
        networkPassword.secureTextEntry = YES;
    }
    btnSecureText.selected = !btnSecureText.selected;
}

- (IBAction)loseFirstResponser:(id)sender {
    [networkName resignFirstResponder];
    [networkPassword becomeFirstResponder];
}

- (IBAction)smartConfig:(id)sender
{
    //若连接到WIFI网络则networkName.text不为空，不能在这里加[self fetchSSIDInfo]网络不为空判断否则Home中断后会多次提示
    /* */
    if (networkName.text == nil || [networkName.text isEqualToString:@""] ||[self fetchSSIDInfo] == nil)
    {
//        [timer setFireDate:[NSDate distantPast]];
        alert = [[UIAlertView alloc]initWithTitle:nil message:@"请检查你的网络连接" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    else if (true != [self passwdIsValidate])
    {
        alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"密码中不能包括中文字符" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alert show];
        return;
    }
    else
    {
        if ([btnStartConfig.titleLabel.text isEqualToString:@"一键配置"])
        {
            //开始配置时停止timer
            [timer setFireDate:[NSDate distantFuture]];
            [btnStartConfig setTitle:@"停止" forState:UIControlStateNormal];
            [self.activityIndicate startAnimating];
            [networkPassword setEnabled:NO];
            NSLog(@"线程开启");
            thread = [[NSThread alloc] initWithTarget:self selector:@selector(sendData) object:nil];
            [thread start];
            ////[communication start:@"yadu102" key:@"yadu10212" timeout:10];
        }
        else if([btnStartConfig.titleLabel.text isEqualToString:@"停止"])
        {
            //停止配置后开启timer
            [timer setFireDate:[NSDate distantPast]];
            [btnStartConfig setTitle:@"一键配置" forState:UIControlStateNormal];
            [self.activityIndicate stopAnimating];
            NSLog(@"关闭线程");
            [networkPassword setEnabled:YES];
            [communication stopConfig];//终止当前调用中UDP包的发送
            [thread cancel];
            ////[communication stop];
        }
        else{}
    }
}
-(void)sendData
{
    @autoreleasepool {
        while (1) {
            if ([NSThread currentThread].isCancelled) {
                [NSThread exit];//只会终止while循环并不会阻断本次调用时的UDP包发送
            }
            else{
                //网络出现故障
                int status = [self smartConfigDevice];
                if ( status == -1) {
                    [self performSelectorOnMainThread:@selector(showalertView) withObject:self waitUntilDone:NO];
                    
                    [communication stopConfig];//终止当前调用中UDP包的发送
                    //更新此时WIFI名称
                    networkName.text = [self getWIFIName];
                    
                    [self performSelectorOnMainThread:@selector(fireTimer) withObject:nil waitUntilDone:NO];

                    //发送失败，此时断网开启timer扫描网络状态
                                        //                    btnStartConfig.enabled = NO;
                    
                    [btnStartConfig setTitle:@"一键配置" forState:UIControlStateNormal];
                    [self.activityIndicate stopAnimating];
                    [thread cancel];
                }
                NSLog(@"[self smartconfig]返回值为%i",status);
            }
            [NSThread sleepForTimeInterval:0.1];
        }
    }
}
-(void)showalertView
{
    alert = [[UIAlertView alloc] initWithTitle:@"错误" message:@"配置失败" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil,nil];
    [alert show];

}
-(void)fireTimer
{
    [timer setFireDate:[NSDate distantPast]];
}
-(void)updateWIFIName
{
    NSString *IPAddr = [self localWiFiIPAddress];
    NSLog(@"pastIPAddr = %@, currentIPAddr = %@",pastIPAddr,IPAddr);
    //保证IP分配完成后在更新SSID名称，![IPAddr isEqualToString:pastIPAddr]
    if (IPAddr != nil) {
        NSLog(@"更新SSID名称");
        //观察到手机还未显示WIFI标志，IP为空时，networkname.text的值也即[self getWIFIName]的值不是为空值
        [self performSelectorOnMainThread:@selector(updateSSID) withObject:nil waitUntilDone:NO];
       
        NSLog(@"SSID的名称为%@",networkName.text);
        pastIPAddr = IPAddr;
    }
    else if (IPAddr == nil || [IPAddr isEqualToString:@""])
    {
        networkName.text = @"";
    }
}
-(void)updateSSID
{
     networkName.text = [self getWIFIName];
}
-(int) smartConfigDevice
{
    return [communication startConfig:networkName.text pwd:networkPassword.text];
}

#pragma mark checkValidityTextField Null
- (BOOL)checkValidityTextField
{
    if ([networkPassword text] == nil || [[networkPassword text] isEqualToString:@""]) {
        
        alert = [[UIAlertView alloc]initWithTitle:nil message:@"请输入密码！" delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        
        [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(performDismiss:) userInfo:nil repeats:NO];
        [alert show];
        
        return NO;
    }
    return YES;
}

-(void)performDismiss:(NSTimer*)timer
{
    [alert dismissWithClickedButtonIndex:0 animated:NO];
}

#pragma mark - UITextFieldDelegate Method
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    
    CGRect frame = textField.frame;
    int offset = frame.origin.y + 32 - (self.view.frame.size.height - 256.0);//键盘高度216
    
    NSTimeInterval animationDuration = 0.30f;
    [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
    [UIView setAnimationDuration:animationDuration];
    
    //将视图的Y坐标向上移动offset个单位，以使下面腾出地方用于软键盘的显示
    if(offset > 0)
        self.view.frame = CGRectMake(0.0f, -offset, self.view.frame.size.width, self.view.frame.size.height);
    
    [UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    self.view.frame =CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    switch (textField.tag) {
            
        case Tag_wifiName:
            {
                if ([textField text] != nil && [[textField text] length]!= 0) {
                    
                }
            }
            break;
        case Tag_wifiPassword:
            {
                if ([textField text] != nil && [[textField text] length]!= 0) {
                }
            }
            break;
        default:
            break;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - touchMethod
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    
    [super touchesBegan:touches withEvent:event];
    
    [self allEditActionsResignFirstResponder];
}

#pragma mark - PrivateMethod
- (void)allEditActionsResignFirstResponder{
    [[self.view viewWithTag:Tag_wifiName] resignFirstResponder];
    [[self.view viewWithTag:Tag_wifiPassword] resignFirstResponder];
}
#pragma mark 控制页面的跳转
-(void)viewWillDisappear:(BOOL)animated
{
    //停止timer
    [timer setFireDate:[NSDate distantFuture]];
    NSLog(@"view消失");
    if ([btnStartConfig.titleLabel.text isEqualToString:@"停止"]) {
        [self smartConfig:nil];
    }
}
-(void)viewWillAppear:(BOOL)animated
{
    //记录view显示后当前网络的IP地址
    pastIPAddr = [self localWiFiIPAddress];
    
    if (pastIPAddr == nil || [pastIPAddr isEqualToString:@""]) {
        networkName.text = @"";
    }
    else{
        networkName.text = [self getWIFIName];
    }
    
    [self checkIsWIFI];
    //不管网络状态均需开启timer
    [timer setFireDate:[NSDate distantPast]];
    NSLog(@"view进来");
}

- (id)fetchSSIDInfo
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    //    NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        //        NSLog(@"ifnam=%@", ifnam);
        if (info && [info count]) {
            break;
        }
    }
    return info ;
}
//获取当前WIFI名称
-(NSString*)getWIFIName
{
    NSDictionary *ifs = [self fetchSSIDInfo]; //获取sid信息。
    NSString *ssid = [ifs objectForKey:@"SSID"];//获取当前连接WIFI名称
    return ssid;
}
//获取当前网络的IP地址
- (NSString *) localWiFiIPAddress
{
    BOOL success;
    struct ifaddrs * addrs;
    const struct ifaddrs * cursor;
    
    success = getifaddrs(&addrs) == 0;
    if (success) {
        cursor = addrs;
        while (cursor != NULL) {
            // the second test keeps from picking up the loopback address
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"])  // Wi-Fi adapter
                    return [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return nil;
}

@end
