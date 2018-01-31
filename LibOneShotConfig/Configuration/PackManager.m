//
//  PackManager.m
//  SmartConfig
//
//  Created by codebat on 15/1/22.
//  Copyright (c) 2015年 Winnermicro. All rights reserved.
//

#import "PackManager.h"

@implementation PackManager
//Byte *bf;
//Byte * newbs;
//下面这俩的内存空间没释放
//Byte *cd;
//Byte *cl;
static  char dscrc_table[] = {
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
    0xba,0x2b,0x59,0xc8,0xbd,0x2c,0x5e,0xcf
};

+(Byte)calCRC8:(Byte[] )ptr len:(int) len
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

+(NSString*)convertDataWithS:(int)s G:(int)g Dll:(Byte*)dll Data:(Byte*)data size:(int)dll_len
{
//    NSLog(@"%s,lenth%lu", dll, strlen((const char*)dll));

    int tl = 6 + dll_len;
    int dl = 0;
    for(int i = 0; i< dll_len; i++){
        tl += dll[i];
        dl += dll[i];
    }

   // Byte *bf = (Byte*)malloc((tl) * sizeof(Byte));
    Byte bf[tl];
    //bf.put((byte) (property.channel + 64));
    bf[0] = (Byte)65;
    //bf.put((byte) 120);
    bf[1] = (Byte)120;
    //bf.put((byte) (s + 64));
    bf[2] = (Byte)(s+64);
    //bf.put((byte) (g + 64));
    bf[3] = (Byte)(g+64);
    for(int i=0;i<dll_len;i++){
        bf[4+i]= (Byte) (dll[i] + 64);
    }
    int length = dl / 2;
    for(int i=0;i<length;i++){
        Byte temp = data[2*i];
        if((temp&0xF) == 0xF || (data[2*i + 1]&0xF) == 0xF){
            continue;
        }
        data[2*i] = (Byte) ((data[2*i + 1]&0xF0) | (temp&0xF));
        data[2*i + 1] = (Byte) ((temp&0xF0) | (data[2*i + 1]&0xF));
    }
    
    for(int i=0;i<dl;i++){
        if((data[i] & 0xF)  <=  7){
            data[i] = (Byte) (data[i] + (data[i]&0xF));
        }
        else
        {
            data[i] = (Byte) (data[i] - (0xF - (data[i]&0xF)));
        }
        bf[4+dll_len+i] = (data[i]);        //隐患处
    }
    
    bf[4+dll_len+dl] = (Byte) 120;
    bf[4+dll_len+dl+1] = ((Byte) 120);
//    NSLog(@"00000000000000000000数组内容为%s",bf);
//    NSLog(@"我被调用了");
    
    NSData *da = [NSData dataWithBytes:bf length:tl];
    NSString *result=[[NSString alloc] initWithData:da encoding:NSUTF8StringEncoding];
   // NSLog(@"打印NSData的内容%@", da);
  //  NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding (kCFStringEncodingGB_18030_2000);
    //NSString *result = [NSString stringWithUTF8String:(const void*)bf];
//    NSString *result = [[NSString alloc] initWithData:da encoding:NSUTF8StringEncoding];
//    NSLog(@"xxxxxx= %@", result);
    return result;
}

+(NSArray *)encodePacks:(NSArray*)bytesArry size:(int)size
{
    Byte *bytes[4];
    bytes[0] = (Byte*)[[bytesArry objectAtIndex:0] bytes];
    
    Byte tempa[1];
    tempa[0] = [[bytesArry objectAtIndex:1] intValue];
    bytes[1] = tempa;
    
    bytes[2] = (Byte*)[[bytesArry objectAtIndex:2] bytes];
    
    Byte tempb[1];
    tempb[0] = [[bytesArry objectAtIndex:3] intValue];
    bytes[3] = tempb;
    
    NSMutableArray *resultArray =[[NSMutableArray alloc] initWithArray:bytesArry];
//    NSLog(@"mutablearray的大小为:%d",[resultArray count]);
    Byte** ret = bytes;
    int length = size;
    for(int i = 0; i < length; i++){
        Byte *bs =bytes[i];
        if(i%2 == 1 || bytes[i+1][0] == 1){
            ret[i] = bs;
            continue;
        }
        //int len = (int)strlen((const void*)bs);
        unsigned long len = (i%2 == 1) ? (1) : ([[bytesArry objectAtIndex:i] length]);
//        NSLog(@"len的长度%d", (int)len);
        int newlen = (int)(len/3)*4 + (len%3 > 0 ? len%3 + 1 : 0);
        //Byte * newbs = (Byte*)malloc(newlen*sizeof(Byte));/////////////////////////////////////////////////
        Byte newbs[newlen];
        for(int j = 0; j < newlen; j++){
            switch(j%4){
				case 0:
					newbs[j] = (Byte) (((bs[j/4*3] >> 2) & 0x3F) + 63);
					break;
				case 1:
					newbs[j] = (Byte) ((((bs[j/4*3] << 4) & 0x30) | ((bs[j/4*3+1] >> 4) & 0xF)) + 63);
					break;
				case 2:
					newbs[j] = (Byte) ((((bs[j/4*3+1] << 2) & 0x3C) | ((bs[j/4*3+2] >> 6) & 0x3)) + 63);
					break;
				case 3:
					newbs[j] = (Byte) ((bs[j/4*3+2] & 0x3F) + 63);
					break;
            }
        }
        //ret[i] = newbs;
        [resultArray replaceObjectAtIndex:i withObject:[NSData dataWithBytes:newbs length:newlen]];
       // free(newbs);
    }
    return resultArray;
}
+(NSMutableArray*)preparePacks:(NSArray*)bytesArry size:(int)size
{
//    NSLog(@"preparepacks方法被调用了");
    int s = 0;
    int ps = 0;
    int pl = 0;
 //   Byte **bytes;
    
    bytesArry = [PackManager encodePacks:bytesArry size:size];
    
    Byte *bytes[4];
    bytes[0] = (Byte*)[[bytesArry objectAtIndex:0] bytes];
//    NSLog(@"转化后长度:%d",[[bytesArry objectAtIndex:0] length]);
    Byte tempa[1];
    tempa[0] = [[bytesArry objectAtIndex:1] intValue];
    bytes[1] = tempa;
    
    bytes[2] = (Byte*)[[bytesArry objectAtIndex:2] bytes];
//    NSLog(@"转化后长度:%d",[[bytesArry objectAtIndex:2] length]);

    Byte tempb[1];
    tempb[0] = [[bytesArry objectAtIndex:3] intValue];
    bytes[3] = tempb;

    
    //free(newbs);//释放在encodepack中分配的堆空间
    //int bl = size /2 ;
    int bl = size /2;
    NSMutableArray *k = [[NSMutableArray alloc] init];
    
    for(int n = 0; n < bl; n++){
        int m = n*2;
        //int l = (int)strlen((void*)bytes[m]) ;
        int l = (int)[((NSData*)[bytesArry objectAtIndex:m]) length] ;
//        NSLog(@"bytes[%d]=%s,长度为%d",m,[bytesArry[m] bytes], [((NSData*)[bytesArry objectAtIndex:m]) length]);
        
        //int cf = (Byte)bytes[m + 1][0];
        int cf = (Byte)[[bytesArry objectAtIndex:(m+1)] intValue];
//       NSLog(@"bytes[%d][0] = %c",m+1, bytes[m+1][0]);
        int g = cf;
        int rl = 32 - 7 - ps - pl;
        if(l < rl && n < (bl-1) && ps == 0)
        {
            ps++;
            pl += l;
            continue;
        }
        else if(l < rl){
            rl = l;
        }
        int o = 0;
        while(ps > 0 || rl >= 25 || (n == (bl-1) && rl > 0)){
            int q = (rl >= 25 ? (32 - 7 - ps) : (rl + pl));
            Byte *cd = (Byte*)malloc(q * sizeof(Byte));
            Byte *cl = (Byte*)malloc((ps+1) * sizeof(Byte));
            int temp = ps+1;
            int curIdx = 0;
            if(ps > 0){
                for(int i = ps; i > 0; i--){
                    g = g | bytes[((n-i)*2 + 1)][0];
                    //int w = (int)strlen((void*)bytes[((n-i)*2)]);
                    int w = (int)[[bytesArry objectAtIndex:((n-i)*2)] length];
                    for(int j = 0; j< pl; j++){
                        cd[j] = bytes[((n-i)*2)][w - pl + j];
                    }
                    cl[curIdx++] = (Byte) pl;
                }
                for(int i = 0; i < rl; i++){
                    cd[i+pl] = bytes[(n*2)][i];
                }
                cl[curIdx++] = (Byte) rl;
                ps = 0;
                pl = 0;
                o += rl;
                rl = l - rl;
        
                [k addObject:[PackManager convertDataWithS:s G:g Dll:cl Data:cd size:temp]];
//                NSLog(@"duidudidu===%@",[PackManager convertDataWithS:s G:g Dll:cl Data:cd size:temp]);
                s++;
            }
            else{
                g = bytes[((n)*2 + 1)][0];
                for(int i = 0; i < q; i++){
                    cd[i] = bytes[(n*2)][i+o];
                }
                cl[curIdx++] = (Byte)q;
                o +=q;
                rl = l - o;
                [k addObject:[PackManager convertDataWithS:s G:g Dll:cl Data:cd size:temp]];
//                NSLog(@"duidudidu===%@",[PackManager convertDataWithS:s G:g Dll:cl Data:cd size:temp]);
                s++;
            }
            
            free(cd);
            free(cl);
        }
        if(rl > 0){
            ps++;
            pl += rl;
        }
    }
    
//    for (id onj in k) {
//        NSLog(@"k+++%@",onj);
//    }
    
//    NSLog(@"[k count] =%d",[k count]);
//    NSLog(@"未替换前packManager生成数组内容:%@",k);

    for(int i=0; i<[k count]; i++){
       
        Byte *bs = (Byte*)([[k objectAtIndex:i] UTF8String]);
        int len = (int)strlen((void*)bs);
        bs[1] = (Byte) (s + 64);
       // calCRC8:(Byte[] )ptr len:(int) len
        Byte crc =[PackManager calCRC8:bs len:len-2];
        bs[len-2] = crc;//
        Byte crc2 =[PackManager calCRC8:bs len:len-1];
        bs[len-2] = (Byte) ((crc&0x3F)+63);
        bs[len-1] = (Byte) ((crc2&0x3F)+63);
        //k.set(i, new String(bs));
       // NSData *data =  [NSData dataWithBytes:bs length:len];
        //[k replaceObjectAtIndex:i withObject:[NSData dataWithBytes:bs length:len]];
        //[k replaceObjectAtIndex:i withObject:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
        [k replaceObjectAtIndex:i withObject:[NSString stringWithCString:(const char *)bs encoding:NSUTF8StringEncoding]];
    }
//   NSLog(@"packManager生成数组内容:%@",k);
    return k;
}
@end
