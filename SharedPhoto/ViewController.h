//
//  ViewController.h
//  SharedPhoto
//
//  Created by Vyacheslav Vdovichenko on 7/17/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "RTMPClient.h"
#import "ISharedObjectListener.h"

@interface ViewController : UIViewController <UIAlertViewDelegate, UITextFieldDelegate,  IRTMPClientDelegate, ISharedObjectListener> {
    
    IBOutlet UITextField        *hostTextField;
    IBOutlet UITextField        *nameTextField;
    IBOutlet UILabel            *saveAlbumLabel;
    IBOutlet UISwitch           *saveAlbumSwitch;
    IBOutlet UIView             *previewView;
    IBOutlet UIImageView        *photoView;
    IBOutlet UIBarButtonItem    *btnConnect;
    IBOutlet UIBarButtonItem    *btnToggleCameras;
    IBOutlet UIBarButtonItem    *btnToggleViews;
    IBOutlet UIBarButtonItem    *btnPhoto;
    
    AVCaptureSession            *session;
	AVCaptureVideoDataOutput    *videoDataOutput;
	AVCaptureVideoPreviewLayer  *previewLayer;
	dispatch_queue_t            videoDataOutputQueue;
	AVCaptureStillImageOutput   *stillImageOutput;
	UIView                      *flashView;
	BOOL                        isUsingFrontFacingCamera;
    BOOL                        isPhotoPicking;

	RTMPClient                  *socket;
    id <IClientSharedObject>    clientSO;
	
    int                         alerts;

}

-(IBAction)connectControl:(id)sender;
-(IBAction)toggleCameras:(id)sender;
-(IBAction)toggleViews:(id)sender;
-(IBAction)photoControl:(id)sender;

@end
