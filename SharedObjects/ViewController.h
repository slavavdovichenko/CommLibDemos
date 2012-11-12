//
//  ViewController.h
//  SharedObjects
//
//  Created by Vyacheslav Vdovichenko on 7/29/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RTMPClient.h"
#import "ISharedObjectListener.h"

@interface ViewController : UIViewController
<UITextFieldDelegate, UIAlertViewDelegate,  IRTMPClientDelegate, ISharedObjectListener> {
	
	RTMPClient	*socket;
	int			state;
	int			alerts;
    BOOL        isRTMPS;
    
    //images
    UIImageView *infoImage;
	
	// controls
	UILabel		*protocolLabel;
	UILabel		*portLabel;
	UILabel		*appLabel;
	
	UITextField	*hostTextField;
	UITextField	*portTextField;
	UITextField	*appTextField;
    
    UIButton    *btnProtocol;
    UIButton    *btnInfo;
	
	UIButton	*btnEchoInt;
	UIButton	*btnEchoFloat;
	UIButton	*btnEchoString;
	UIButton	*btnEchoStringArray;
	UIButton	*btnEchoByteArray;
    
    //test
    id <IClientSharedObject>  clientSO;
    int         intSO;
    float       floatSO;
}

@end
