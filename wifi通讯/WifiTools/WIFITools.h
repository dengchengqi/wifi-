//
//  WIFITools.h
//  wifi通讯
//
//  Created by 晓坤张 on 2017/8/12.
//  Copyright © 2017年 晓坤张. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WIFITools : NSObject

//获取当前wifi名称
+(NSString *)currentWifiSSID;

//获取当前wifi ip地址
+(NSString *)localWiFiIPAddress;

@end
