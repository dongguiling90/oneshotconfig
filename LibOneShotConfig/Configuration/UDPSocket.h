//
//  UDPSocket.h
//  OneShotConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@interface UDPSocket : NSObject

@property (assign, nonatomic) int socketFileDescriptor;
@property (assign, nonatomic) struct sockaddr_in socketParameters;
+(id)getInstance;
-(void) stopUdpSocket;

-(int)SendUDPMessage: (NSString*) host port: (int) port package:(NSData*) msg withFlag:(BOOL)flag;

@end
