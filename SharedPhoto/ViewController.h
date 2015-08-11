//
//  ViewController.h
//  SharedPhoto
//
//  Created by Vyacheslav Vdovichenko on 7/17/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController {
    
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
}

-(IBAction)connectControl:(id)sender;
-(IBAction)toggleCameras:(id)sender;
-(IBAction)toggleViews:(id)sender;
-(IBAction)photoControl:(id)sender;

@end
