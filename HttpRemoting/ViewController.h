//
//  ViewController.h
//  HttpRemoting
//
//  Created by Vyacheslav Vdovichenko on 7/29/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WeborbClient.h"

@interface ViewController : UIViewController
<UITextFieldDelegate, UIAlertViewDelegate> {
    
    WeborbClient *client;
    NSString    *service;
    NSString    *method; 
    NSMutableArray *args;
	
    int			alerts;
    
    //images
    UIImageView *infoImage;
	
	// controls	
	UITextField	*hostTextField;
    
    // buttons
    UIButton    *btnInfo;
	
	UIButton	*btnCalculate;
	UIButton	*btnGetCustomers;
	UIButton	*btnHideIdentity;
	UIButton	*btnGetWeather;
}

@end
