//
//  ViewController.h
//  SharedBall
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
    
    //image
    UIImageView *infoImage;
    UIImageView *activeImage;
	
	// controls
	UILabel		*protocolLabel;
	UILabel		*portLabel;
	UILabel		*appLabel;
	UILabel		*memoryLabel;
	
	UITextField	*hostTextField;
	UITextField	*portTextField;
	UITextField	*appTextField;
    
    UIButton    *btnProtocol;
    UIButton    *btnInfo;
    
    // shared object
    id <IClientSharedObject>  clientSO;
}

@end
