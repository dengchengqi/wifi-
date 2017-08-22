//
//  WIFITools.m
//  wifi通讯
//
//  Created by 晓坤张 on 2017/8/12.
//  Copyright © 2017年 晓坤张. All rights reserved.
//

#import "WIFITools.h"

//系统配置框架（网络配置也在该框架中）
#import <SystemConfiguration/CaptiveNetwork.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <net/if.h>
#include <ifaddrs.h>
#import <dlfcn.h>

@implementation WIFITools


//只对真机wifi连接有效，如果是模拟器和真机4G网络则都为nil
+(NSString *)currentWifiSSID
{
    //1.获取网络底层监视的所有接口列表，返回的是一个BSD接口名称
    NSArray *ifs = (__bridge id)CNCopySupportedInterfaces();
    
    id info = nil;
    for (NSString *ifnam in ifs) {
        
        //2.通过BSD接口名称获取网络信息，返回的是一个字典。其中包含 1.wifi名称字符串  2.mac地址 3.wifi名称二进制数据
        info = (__bridge id)CNCopyCurrentNetworkInfo((__bridge CFStringRef)ifnam);
        if (info && [info count]) {
            break;
        }
    }
    
    //3.获取字典
    NSDictionary *dctySSID = (NSDictionary *)info;
    
    //4.字典的SSID键对应的值就是wifi的名称
    //注意：  1. 模拟器获取不到wifi名称 返回为nil  2.真机的话如果没有连接wifi而是使用4G，返回的也是nil
    NSString *ssid = [dctySSID objectForKey:@"SSID"];//wifi名称
    
//     NSString *bssid = [dctySSID objectForKey:@"BSSID"];//mac地址，苹果返回的是一个无效的mac地址，与手机实际mac地址不一致，主要用于保护用户隐私
    
    return ssid;
    
}


//获取本机在当前wifi中的ip地址，模拟器真机均可获取
+(NSString *)localWiFiIPAddress
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
