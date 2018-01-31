//
//  ManualConfig.m
//  OneShotConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//

#import "ManualConfig.h"
#import "PackManager.h"
#import <SystemConfiguration/CaptiveNetwork.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@implementation ManualConfig
NSString* SSIDPREFIX = @"softap";
ManualConfig *instanceTcp;
int socketDiscriptor = -1;

+ (instancetype)getInstance {
    if (instanceTcp == nil) {
        instanceTcp = [[self alloc] init];
    }
    return instanceTcp;
}
+(void)setValidSSIDPrefix:(NSString*)name
{
    SSIDPREFIX = name;
}
-(void) stopTCPSocket
{
    close(socketDiscriptor);
    socketDiscriptor = -1;
}
+(BOOL)getNetStatus
{
    NSDictionary *ifs = [self fetchSSIDInfo];
    if (ifs == nil) {
        return NO;
    }//获取sid信息。
    NSString *ssid = [[ifs objectForKey:@"SSID"] lowercaseString];//获取当前连接WIFI名称
    if (!ssid) {
        return NO;
    }
    return  YES;
}

+(BOOL)isSSIDValid
{
    NSDictionary *ifs = [self fetchSSIDInfo]; //获取sid信息。
    NSString *ssidname = [ifs objectForKey:@"SSID"];//获取当前连接WIFI名称

    if(![ssidname hasPrefix:SSIDPREFIX ]){
        return NO;

    }
    
    return YES;
}

+(NSMutableArray*)preparePack:(NSString*)ssidName passWd:(NSString*)passwd
{
    NSArray *array = [[NSArray alloc] initWithObjects:
    [passwd dataUsingEncoding:NSUTF8StringEncoding],
    [NSNumber numberWithInt:1],
    [ssidName dataUsingEncoding:NSUTF8StringEncoding],
    [NSNumber numberWithInt:4],nil];
    //NSLog(@"arry count:%d",[array count]);
    
    NSMutableArray *dataArray = [PackManager preparePacks:array size:4];
    return dataArray;
}

+(int)sendPackToAddress:(NSString*)ip Port:(NSString*)port WithPackage:(NSData*)data
{
    if(-1 == socketDiscriptor) {
         socketDiscriptor = socket(AF_INET, SOCK_STREAM, 0);
    }
//    NSLog(@"创建套接字成功");
    
    //创建服务端套接字
    struct sockaddr_in socketServer;
    socketServer.sin_family = AF_INET;
    socketServer.sin_port = htons([port intValue]);
    socketServer.sin_addr.s_addr = inet_addr([ip UTF8String]);
    
//    NSLog(@"ip地址为%s",(void*)[ip UTF8String]);
    //连接
    int conResult = connect(socketDiscriptor, (struct sockaddr*)&socketServer, sizeof(struct sockaddr));
    
    if(-1 == conResult)
    {
//        NSLog(@"连接服务器失败");
//        NSLog(@"错误代码%d", errno);
        close(socketDiscriptor);
        socketDiscriptor = -1;
        return -3;                          //  -3代表连接超时
    }
    
//    NSLog(@"连接服务器成功");
    
    //发送数据
    int sendResult = (int)send(socketDiscriptor, [data bytes], [data length], 0);
  
    if (-1 == sendResult) {
//        NSLog(@"发送数据失败");
       close(socketDiscriptor);
        socketDiscriptor = -1;
        return -4;                        //     -4代表发送超时
    }
    
    close(socketDiscriptor);
    socketDiscriptor = -1;
//    NSLog(@"发送数据成功");
    return 0;
}
+ (id)fetchSSIDInfo

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
-(int)startConfig:(NSString*)ssid pwd:(NSString*)password
{
    if(![ManualConfig getNetStatus])
    {
        return -1;
    }
    else if(![ManualConfig isSSIDValid])
    {

        return -2;
    }
    else
    {
    
        NSMutableArray *packArray = [ManualConfig preparePack:ssid passWd:password];//数据封装打包返回变长数组
//        NSLog(@"打包后返回的可变数组为:%@",packArray);
//        NSLog(@"-------===========------");
//        for (id obj in packArray) {
//            NSLog(@"%@",obj);
//        }
//        NSLog(@"[nsmutablearray count] = %lu",(unsigned long)[packArray count]);
        NSString *str=@"";
        for (id ob in packArray) {
            str = [NSString stringWithFormat:@"%@%@",str,ob];
        }
//        NSLog(@"打印string========%@", str);
        int  length = (int)[str length];
        NSString *packString = [NSString stringWithFormat:@"%d\r\n%@",length,str];
        
        NSData *data  = [packString dataUsingEncoding:NSUTF8StringEncoding];
        
//        NSLog(@"发送的数据为:%@", packString);

        
        return [ManualConfig sendPackToAddress:@"192.168.1.1" Port:@"65532" WithPackage:data];
    }    
}


@end
