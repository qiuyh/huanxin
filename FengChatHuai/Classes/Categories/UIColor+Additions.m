//
//  UIColor+Additions.m
//  FengChatHuai
//
//  Created by iMacQIU on 16/5/19.
//  Copyright © 2016年 iMacQIU. All rights reserved.
//

#import "UIColor+Additions.h"

@implementation UIColor (Additions)



+ (UIColor*)colorWithHexString:(NSString*)hex{
    NSString *cString = [[hex stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    if ( cString.length < 6 ) {
        return [UIColor whiteColor];
    }
    if ( [cString hasPrefix:@"0x"] ) {
        cString = [cString substringFromIndex:2];
    }
    if ( [cString hasPrefix:@"#"] ) {
        cString = [cString substringFromIndex:1];
    }
    if ( cString.length != 6 ) {
        return [UIColor whiteColor];
    }
    
    NSRange range = NSMakeRange(0, 2);
    NSString * rString = [cString substringWithRange:range];
    range.location = 2;
    NSString * gString = [cString substringWithRange:range];
    range.location = 4;
    NSString * bString = [cString substringWithRange:range];
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f)
                           green:((float) g / 255.0f)
                            blue:((float) b / 255.0f)
                           alpha:1.0f];
}


+ (UIColor *)colorWithHexNumber:(NSInteger)rgbValue{
    return [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0
                           green:((float)((rgbValue & 0xFF00) >> 8))/255.0
                            blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0];
}

+ (UIColor *)HFPinkColor{
    return [UIColor colorWithHexNumber:0xed19a4];
}

+ (UIColor *) colorWithHex:(int)color {
    
    float red = (color & 0xff000000) >> 24;
    float green = (color & 0x00ff0000) >> 16;
    float blue = (color & 0x0000ff00) >> 8;
    float alpha = (color & 0x000000ff);
    
    return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha/255.0];
}


@end
