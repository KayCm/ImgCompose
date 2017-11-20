//
//  CustomQRCode.h
//  ImgCompose
//
//  Created by KayCM on 2017/11/20.
//  Copyright © 2017年 KayCM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface CustomQRCode : NSObject


/**
 */
-(UIImage *)QRCodeForString:(NSString *)string withSize:(CGFloat)QRImgSize withQRColor:(UIColor*)QRColor withLogoImage:(UIImage*)LogoImg withLogoBgColor:(UIColor*)LogoBgColor withLogoSize:(CGFloat)logoImgSize;
@end
