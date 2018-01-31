//
//  AppDelegate.m
//  OneShotConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//
#import "AppDelegate.h"
#import <SystemConfiguration/CaptiveNetwork.h>
@interface AppDelegate ()
-(id)fetchSSIDInfo;
@end

@implementation AppDelegate

- (id)fetchSSIDInfo
{
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
   NSLog(@"%s: Supported interfaces: %@", __func__, ifs);
    id info = nil;
    for (NSString *ifnam in ifs) {
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        NSLog(@"数组中字典%@",info);
        if (info && [info count]) {
            break;
        }
    }
    return info ;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _Mpasswd = @"";
    _Musername=@"";
//    NSLog(@"localWiFiIPAddress = %@",[self localWiFiIPAddress ]);
    NSLog(@"加载加载%@",[self fetchSSIDInfo]);
    self.window.backgroundColor = [UIColor whiteColor];
    NSDictionary *ifs = [self fetchSSIDInfo]; //获取sid信息。
    NSString *ssid = [ifs objectForKey:@"SSID"];//获取当前连接WIFI名称
    [[NSUserDefaults standardUserDefaults] setObject:ssid forKey:@"SSIDINFO"];

    NSLog(@"i didFinishLaunching");
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"i resignActive");
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    NSLog(@"i didenterBackgroud");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    NSLog(@"i willenterforegroud");
    //用户切换到设置连接WIFI后再次进入时更新WIFI信息
    NSDictionary *ifs = [self fetchSSIDInfo]; //获取sid信息。
    NSString *ssid = [ifs objectForKey:@"SSID"];//获取当前连接WIFI名称
    [[NSUserDefaults standardUserDefaults] setObject:ssid forKey:@"SSIDINFO"];

}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    NSLog(@"didBecomActive");
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"wiiTerminate");
}
@end
