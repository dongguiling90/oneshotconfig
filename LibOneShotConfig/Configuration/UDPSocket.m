//
//  UDPSocket.m
//  OneShotConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//

#import "UDPSocket.h"

@implementation UDPSocket
static UDPSocket *instance =nil;
int i=0;
extern bool configDone;
#define Complete 10
@synthesize socketFileDescriptor;
@synthesize socketParameters;
+(id)getInstance
{
    if (instance == nil) {
        instance = [[UDPSocket alloc] init];
        instance.socketFileDescriptor = -1;
    }
    return instance;
}
-(void) stopUdpSocket
{
//    NSLog(@"关闭套接字,%i",configDone);
    close(socketFileDescriptor);
    socketFileDescriptor = -1;
}

-(int)SendUDPMessage: (NSString*) host port: (int) port package:(NSData*) msg withFlag:(BOOL)flag
{
//    NSLog(@"SendUDPMessage");
    //使socket可以复用，不必每次都创建
    if ( 0 >= socketFileDescriptor) {
        int so_broadcast=1;
//        NSLog(@"jiu套接字描述符%i",socketFileDescriptor);
        socketFileDescriptor = socket(AF_INET, SOCK_DGRAM, 0);
        setsockopt(socketFileDescriptor,SOL_SOCKET,SO_BROADCAST,&so_broadcast,sizeof(so_broadcast));
    }
//    else
    {
        struct sockaddr_in socketParameter;
        socketParameter.sin_family = AF_INET;
        const char * a =[host UTF8String];
        socketParameter.sin_addr.s_addr = inet_addr(a);
        NSLog(@"host===%s, ip======%x",a, socketParameter.sin_addr.s_addr);
        socketParameter.sin_port = htons(9876);
        //        NSLog(@"socket端口号%d",socketParameters.sin_port);
        //        NSLog(@"xin套接字描述符%i",socketFileDescriptor);

        int status = (int)sendto(socketFileDescriptor, [msg bytes], [msg length], 0,
                                 (struct sockaddr*)&socketParameter, sizeof(socketParameter));
        if(status<0){
            [self stopUdpSocket];
            int so_broadcast=1;
            //        NSLog(@"jiu套接字描述符%i",socketFileDescriptor);
            socketFileDescriptor = socket(AF_INET, SOCK_DGRAM, 0);
            setsockopt(socketFileDescriptor,SOL_SOCKET,SO_BROADCAST,&so_broadcast,sizeof(so_broadcast));
            
            status = (int)sendto(socketFileDescriptor, [msg bytes], [msg length], 0,
                                 (struct sockaddr*)&socketParameter, sizeof(socketParameter));
        }
        
        if (status >= 0) {
//            NSLog(@"%@发送UDP成功",[NSThread currentThread]);
//            NSLog(@"%@发送数据成功%i,configdown= %i",[NSThread currentThread],i++,configDone);
        }
        else{
//            NSLog(@"%@发送UDP失败",[NSThread currentThread]);
            [self stopUdpSocket];
        }
        /*sendto函数调用成功返回发送的字节数
         发送失败，-1
         */
        return status;
    }
}
@end
