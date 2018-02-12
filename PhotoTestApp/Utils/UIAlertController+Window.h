//
//  UIAlertController+Window.h
//  DrawingDesk
//
//  Created by evgeniy on 15/09/16.
//  Copyright © 2016 evgeniy. All rights reserved.
//
@import UIKit;

@interface UIAlertController (Window)

+ (void)showSimpleAlertWithTitle:(NSString *)title message:(NSString *)message;
- (void)show;
- (void)show:(BOOL)animated;

@end
