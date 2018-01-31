//
//  OneShotConfig.m
//  OneShotConfig

//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//
//

#import "OneShotConfig.h"
#import "PackManager.h"

@interface OneShotConfig()
@property (strong,nonatomic) UDPSocket *udpSocket;
@end

@implementation OneShotConfig
OneShotConfig *instance;
static int smartConfigPort = 9876;
static int totalIndex = 0;
static Byte sendDataPer[2];
static int sendDataPerIndex = 0;
static int totalLen = 0;

static NSString* ssid1 = @"";//(NSString*)data[0];
static NSString* psw = @"";//(NSString*)data[1];
static NSInteger timeo=60;//[data[2] intValue];
static NSThread *thread = nil;
#define Complete 0

BOOL configDone = YES;
static int package_size = 4;
static Byte dscrc_table[] = {
    0x00,0x91,0xe3,0x72,0x07,0x96,0xe4,0x75,
    0x0e,0x9f,0xed,0x7c,0x09,0x98,0xea,0x7b,
    0x1c,0x8d,0xff,0x6e,0x1b,0x8a,0xf8,0x69,
    0x12,0x83,0xf1,0x60,0x15,0x84,0xf6,0x67,
    0x38,0xa9,0xdb,0x4a,0x3f,0xae,0xdc,0x4d,
    0x36,0xa7,0xd5,0x44,0x31,0xa0,0xd2,0x43,
    0x24,0xb5,0xc7,0x56,0x23,0xb2,0xc0,0x51,
    0x2a,0xbb,0xc9,0x58,0x2d,0xbc,0xce,0x5f,
    0x70,0xe1,0x93,0x02,0x77,0xe6,0x94,0x05,
    0x7e,0xef,0x9d,0x0c,0x79,0xe8,0x9a,0x0b,
    0x6c,0xfd,0x8f,0x1e,0x6b,0xfa,0x88,0x19,
    0x62,0xf3,0x81,0x10,0x65,0xf4,0x86,0x17,
    0x48,0xd9,0xab,0x3a,0x4f,0xde,0xac,0x3d,
    0x46,0xd7,0xa5,0x34,0x41,0xd0,0xa2,0x33,
    0x54,0xc5,0xb7,0x26,0x53,0xc2,0xb0,0x21,
    0x5a,0xcb,0xb9,0x28,0x5d,0xcc,0xbe,0x2f,
    0xe0,0x71,0x03,0x92,0xe7,0x76,0x04,0x95,
    0xee,0x7f,0x0d,0x9c,0xe9,0x78,0x0a,0x9b,
    0xfc,0x6d,0x1f,0x8e,0xfb,0x6a,0x18,0x89,
    0xf2,0x63,0x11,0x80,0xf5,0x64,0x16,0x87,
    0xd8,0x49,0x3b,0xaa,0xdf,0x4e,0x3c,0xad,
    0xd6,0x47,0x35,0xa4,0xd1,0x40,0x32,0xa3,
    0xc4,0x55,0x27,0xb6,0xc3,0x52,0x20,0xb1,
    0xca,0x5b,0x29,0xb8,0xcd,0x5c,0x2e,0xbf,
    0x90,0x01,0x73,0xe2,0x97,0x06,0x74,0xe5,
    0x9e,0x0f,0x7d,0xec,0x99,0x08,0x7a,0xeb,
    0x8c,0x1d,0x6f,0xfe,0x8b,0x1a,0x68,0xf9,
    0x82,0x13,0x61,0xf0,0x85,0x14,0x66,0xf7,
    0xa8,0x39,0x4b,0xda,0xaf,0x3e,0x4c,0xdd,
    0xa6,0x37,0x45,0xd4,0xa1,0x30,0x42,0xd3,
    0xb4,0x25,0x57,0xc6,0xb3,0x22,0x50,0xc1,
    0xba,0x2b,0x59,0xc8,0xbd,0x2c,0x5e,0xcf};

+ (instancetype)getInstance {
    @synchronized(self)
    {
        if (instance == nil) {
            instance = [[OneShotConfig alloc] init];
            instance.udpSocket = [UDPSocket getInstance];
        }
        return instance;

    }
}
-(NSMutableArray*)preparePack:(NSString*)ssidName passWd:(NSString*)passwd
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
-(void) start: (NSString*)ssid key:(NSString*)key  timeout:(int) timeout;
{
    if(thread!=nil)
    {
        NSLog(@"error doing configration!");
        return;
    }
    ssid1 = ssid;
    psw = key;
    timeo = timeout;
    thread = [[NSThread alloc] initWithTarget:self selector:@selector(sendData1) object:nil];
    [thread start];
}
-(void)sendData1
{
    @autoreleasepool {
        NSDate *datenow = [NSDate date];//现在时间
        long t1 = (long)[datenow timeIntervalSince1970];
        while (1) {
            if ([NSThread currentThread].isCancelled) {
                [NSThread exit];//只会终止while循环并不会阻断本次调用时的UDP包发送
                NSLog(@"NSThread canceled exit!");
            }
            else{
                int status = [self startConfig:ssid1 pwd:psw];
                if ( status == -1) {
                    [self stopConfig];//终止当前调用中UDP包的发送
                    [thread cancel];
                }
                NSLog(@"[self smartconfig]return %i",status);
            }
            [NSThread sleepForTimeInterval:0.1];
            datenow = [NSDate date];
            long t2 = (long)[datenow timeIntervalSince1970];
            NSLog(@"send time[%i], timeout[%i]",(int)(t2 - t1), (int)timeo);
            if((t2 - t1) > (int)timeo)
            {
                [self stopConfig];//终止当前调用中UDP包的发送
                [thread cancel];
                thread = nil;
                NSLog(@"send timeout![%i]",(int)timeo);
                break;
            }
        }
    }
}
-(void) stop
{
    [self stopConfig];
    if(thread != nil)
    {
        [thread cancel];
        thread = nil;
    }
}
//////////////////////////Smart config//////////////////

-(int) startConfig: (NSString*) ssid pwd: (NSString*) password
{
//    NSLog(@"startConfig");
    configDone = NO;
    NSMutableArray *packArray = [self preparePack:ssid passWd:password];
    NSString *str=@"";
    for (id ob in packArray) {
        str = [NSString stringWithFormat:@"%@%@",str,ob];
    }
            NSLog(@"打印string========%@", str);
    totalLen = (int)[str length];
    NSData* pack = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    int s = [self sendPause:5];
    if ( s < 0) {
        return s;
    }
    s = [self sendPack:pack];
    if (s < 0) {
        return s;
    }
    s = [self sendLastByte:0x0];
    return s;
}

-(void) stopConfig {
    configDone = YES;
//    NSLog(@"<stopconfig>%@-----configDown值变为%i-------",[NSThread currentThread],configDone);
     [self.udpSocket stopUdpSocket];
}

-(NSArray*) preparePack: (Byte)sign  str: (NSString *) str
{
    NSArray *ret = [[NSArray alloc] init];
    NSData* strData = [str dataUsingEncoding:NSUTF8StringEncoding];
    
    Byte* byteArray = (Byte *)[strData bytes];
    int len = (int)strData.length;
    
    int sum = ((len%package_size == 0 && len > 0) ? (len/package_size):len/package_size + 1)&0x1F;
    Byte pack0 = (Byte) (sign * 16 + sum - 1);
    for(int i = 0; i < sum; i++){
        int size = len - i*package_size;
        if(size > package_size){
            size = package_size;
        }
        
        Byte pack[size+3];
        pack[0] = pack0;
        pack[1] = (Byte) (i*16 + (size&0xF));
        for(int j = 0; j < size; j++){
            pack[2+j] = byteArray[package_size*i + j];
        }
        pack[size+2] = [self calCRC8:pack Len:(size + 2)];//crc
        NSData *data = [NSData dataWithBytes:pack length:size+3];
        
        ret = [ret arrayByAddingObject:data];
    }
    return ret;
}

-(int) sendPack: (NSData*) pack
{
    
    //[NSThread sleepForTimeInterval:0.02];
    int status = 0;
    Byte* packBytes = (Byte*)[pack bytes];
    
    int len = (int)(pack.length);
    for (int i=0; i<len; i++) {
        if (configDone == YES) {
//            NSLog(@"i have broken in sendPack");
            return Complete;
        }
        status = [self sendByte:packBytes[i]];
        if (status == -1) {
            return status;
        }
        //[NSThread sleepForTimeInterval:0.001];
    }
    //[NSThread sleepForTimeInterval:0.02];
    return status;
}

-(int) sendByte:(Byte) bSend
{
//    NSLog(@"sendByte");
    int status = 0;
    NSString *str = @"";
    sendDataPer[sendDataPerIndex++] = bSend;
    if (sendDataPerIndex == 2) {
        sendDataPerIndex = 0;
        str = [NSString stringWithFormat:@"239.%u.%u.%u",totalIndex++, sendDataPer[0], sendDataPer[1]];
        NSLog(@"send to ip : %@", str);
        Byte sendData[1] = {0x31};
        NSData *message = [NSData dataWithBytes:sendData length:1];
        status = [self sendData:str Port:smartConfigPort Package:message];
        if (status < 0) {
            return status;
        }
    }
    return status;
}

-(int) sendLastByte:(Byte) bSend
{
    int status = 0;
    if (sendDataPerIndex == 1) {
        [self sendByte:bSend];
    }
    return status;
}

#pragma mark 每次发送后停1ms，新增方法
-(int)sendData:(NSString*)ip Port:(int)port Package:(NSData*)message
{
//    NSLog(@"sendData");
    int status = [self.udpSocket SendUDPMessage:ip port:smartConfigPort package:message withFlag:configDone];
    if (status < 0 ) {
        /*-1表示发送失败*/
        return status;
    }
    [NSThread sleepForTimeInterval:0.001];
    /*0表示发送成功*/
    return 0;
}
-(int) sendPause: (int) len
{
//    NSLog(@"sendPause");
    int i = 0;
    NSString *str = @"";
    Byte byte1[] = {0x31};
    NSData *sendData = [NSData dataWithBytes:byte1 length:1];
    int status = 0;
    totalIndex = 0;
    while(i < len){
        if (configDone == YES) {
//             NSLog(@"I have broken in sendPause");
             return Complete;
        }
        str = [NSString stringWithFormat:@"239.0.100.%u", totalLen];
        NSLog(@"send to ip : %@", str);
        status = [self sendData:str Port:smartConfigPort Package:sendData];
        if (status < 0) {
            return status;
        }
        i++;
    }
    totalIndex++;
    return status;
}

-(Byte) calCRC8: (Byte[]) ptr Len: (int) len
{   
    int i = 0;
    int crc = 0;
    while(len-- != 0)   
    {   
        int p = ptr[i++];
        p = p < 0 ? 256 - (-p) : p;
        int idx = (crc ^ p)&0xFF;
        crc = dscrc_table[idx];
    } 
    return (Byte) crc;
}
@end
