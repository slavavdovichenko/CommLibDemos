//
//  ViewController.h
//  PubSubChat
//
//  Created by Vyacheslav Vdovichenko on 5/11/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WeborbClient.h"
#import "MemoryTicker.h"

@interface ViewController : UIViewController
<UITextFieldDelegate, UIAlertViewDelegate> {
    
    WeborbClient *client;
	
    MemoryTicker *memoryTicker;
    int			alerts;
    
	// controls	
	UITextField	*hostTextField;
	UITextField	*destTextField;
	UITextField	*chatTextField;
	UITextField	*subtopicTextField;
	UITextField	*selectorTextField;
    UITextView  *chatTextView;
    
    // labels
    UILabel		*memoryLabel;
    
    // buttons
	UIButton	*btnPublish;
	UIButton	*btnSubscribe;
	UIButton	*btnUnsubscribe;
}

@end
