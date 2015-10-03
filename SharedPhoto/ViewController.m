//
//  ViewController.m
//  SharedPhoto
//
//  Created by Vyacheslav Vdovichenko on 7/17/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "DEBUG.h"
#import "BinaryCodec.h"
#import "RTMPClient.h"
#import "ISharedObjectListener.h"


#define SO_ATTRIBUTE_DATA @"photoData"
#define SO_ATTRIBUTE_ORIENTATION @"photoOrientation"


#pragma mark -
#pragma mark ViewController implementations

@interface ViewController () <UIAlertViewDelegate, UITextFieldDelegate,  IRTMPClientDelegate, ISharedObjectListener> {
    
    RTMPClient                  *socket;
    id <IClientSharedObject>    clientSO;
    
    int                         alerts;
    
    AVCaptureSession            *session;
    AVCaptureVideoDataOutput    *videoDataOutput;
    AVCaptureVideoPreviewLayer  *previewLayer;
    dispatch_queue_t            videoDataOutputQueue;
    AVCaptureStillImageOutput   *stillImageOutput;
    UIView                      *flashView;
    BOOL                        isUsingFrontFacingCamera;
    BOOL                        isPhotoPicking;
}

@end

@interface ViewController (MediaProcessing) <AVCaptureVideoDataOutputSampleBufferDelegate>
-(void)setupAVCapture;
-(void)teardownAVCapture;
-(UIImageOrientation)imageOrientation;
-(void)playImageData:(NSData *)data orientation:(UIImageOrientation)orientation;
-(void)switchCameras;
-(void)takePicture;
@end

@implementation ViewController

#pragma mark -
#pragma mark  View lifecycle

-(void)viewDidLoad {
    
    [super viewDidLoad];
    
    hostTextField.text = @"rtmp://10.0.1.62:1935/live";
    hostTextField.delegate = self;
    
    nameTextField.text = @"SharedPhoto";
	nameTextField.delegate = self;
    
    socket = nil;
    clientSO = nil;
    alerts = 100;
    
    session = nil;
    
    [DebLog setIsActive:YES];
    
}

-(void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void)dealloc {
    
    if (socket) {
        [self teardownAVCapture];
        [socket release];
    }
	
    [super dealloc];
}

#pragma mark -
#pragma mark Private Methods 

// ALERT

-(void)showAlert:(NSString *)message {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	alerts++;
	av.tag = alerts;
    [av show];
}

// SO

-(void)connectSO {	
    
    if (!clientSO) {
        
        printf("connectSO SEND ----> getSharedObject\n");
        
        // send "getSharedObject (+ connect)"
        NSString *name = [NSString stringWithString:nameTextField.text];
        clientSO = [socket getSharedObject:name persistent:NO owner:self];
    }
    else 
        if (![clientSO isConnected]) {
            
            printf("connectSO SEND ----> connect\n");
            
            // send "connect"
            [clientSO connect];
        }
        else {
            
            printf("connectSO SEND ----> disconnect\n");
            
            // send "disconnect"
            [clientSO disconnect];
        }
}

-(void)sendImageFrame:(NSData *)data {	
    
    if (!data)
        return;
    
    if (!clientSO || ![clientSO isConnected]) {
        [self showAlert:@"clientSO is absent or disconnected!"];
        return;
    }
 	
    [DebLog log:@"*****************>>>> sendImageFrame: %@ (attributes = %@)", [clientSO getName], [clientSO getAttributeNames]];
    
    // setAttributes
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];    
    [dict setValue:[NSNumber numberWithInt:[self imageOrientation]] forKey:SO_ATTRIBUTE_ORIENTATION];
    [dict setValue:[Base64 encodeToStringArray:data] forKey:SO_ATTRIBUTE_DATA];
    
    [clientSO setAttributes:dict];
}

// RTMP

-(void)socketConnected {
    
    [self setupAVCapture];
    
    [self connectSO];
    
    hostTextField.hidden = YES;
    nameTextField.hidden = YES;
    saveAlbumLabel.hidden = YES;
    saveAlbumSwitch.hidden = YES;
    
    previewView.hidden = NO;
    photoView.hidden = YES;
    
    btnConnect.title = @"Disconnect";
    btnToggleCameras.enabled = YES;
    btnToggleViews.enabled = YES;
    btnPhoto.enabled = YES;
}

-(void)socketDisconnected {
    
    clientSO = nil;

    hostTextField.hidden = NO;
    nameTextField.hidden = NO;
    saveAlbumLabel.hidden = NO;
    saveAlbumSwitch.hidden = NO;
    
    previewView.hidden = YES;
    photoView.hidden = YES;
    
    btnConnect.title = @"Connect";
    btnToggleCameras.enabled = NO;
    btnToggleViews.enabled = NO;
    btnPhoto.enabled = NO;
}

-(void)doConnect {		
    
    NSString *url = hostTextField.text;
    
    if (socket)
        [socket connect:url];
    else {
        socket = [[RTMPClient alloc] init:url];
        socket.delegate = self;
        [socket connect];
    }
}

-(void)doDisconnect {	
    
    if (!socket) 
        return;
    
    [self teardownAVCapture];
    
    [self socketDisconnected];
    [socket disconnect:self];
    [socket release];
    socket = nil;
}

// MEDIA

-(void)imageSaved:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"-> imageSaved: error = %ld <%@>", (long)error.code, error.localizedDescription);
}

-(void)showPhoto:(UIImage *)image {
    
    photoView.image = image;
    
    if (saveAlbumSwitch.on)
        UIImageWriteToSavedPhotosAlbum(image, self, @selector(imageSaved:didFinishSavingWithError:contextInfo:), nil);
}

#pragma mark -
#pragma mark Public Methods 

// ACTIONS

-(IBAction)connectControl:(id)sender {
    
    (!socket) ? [self doConnect] : [self doDisconnect];
    
}

-(IBAction)toggleCameras:(id)sender {
    
    [self switchCameras];
    
    btnToggleCameras.title = (isUsingFrontFacingCamera) ? @"Back" : @"Front";
   
    if (previewView.hidden) {
        previewView.hidden = NO;
        photoView.hidden = YES;
        btnToggleViews.title = @"Photo";
    }
}

-(IBAction)toggleViews:(id)sender {
    
    if (previewView.hidden) {
        
        if (!session)
            [self setupAVCapture];
        
        previewView.hidden = NO;
        photoView.hidden = YES;
        btnToggleViews.title = @"Photo";
    }
    else {
        previewView.hidden = YES;
        photoView.hidden = NO;
        btnToggleViews.title = @"Preview";
    }
}

-(IBAction)photoControl:(id)sender {
    
    previewView.hidden = YES;
    photoView.hidden = NO;
    btnToggleViews.title = @"Preview";

    [self takePicture];
}


#pragma mark -
#pragma mark UIAlertViewDelegate Methods 

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	[alertView release];	
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods 

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}


#pragma mark -
#pragma mark IRTMPClientDelegate Methods 

-(void)connectedEvent {
	
    NSLog(@" $$$$$$ <IRTMPClientDelegate>> connectedEvent\n");
    
    [self socketConnected];
}

-(void)disconnectedEvent {
    
    [self performSelector:@selector(doDisconnect) withObject:nil afterDelay:0.1f];
    
 	[self showAlert:@" !!! disconnectedEvent \n"];
}

-(void)connectFailedEvent:(int)code description:(NSString *)description {
    
    [self performSelector:@selector(doDisconnect) withObject:nil afterDelay:0.1f];
    
    if (code == -1)
        [self showAlert:[NSString stringWithFormat:
                         @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid\n"]];       
    else
        [self showAlert:[NSString stringWithFormat:@" !!! connectFailedEvent: %@ \n", description]];       
}

-(void)resultReceived:(id <IServiceCall>)call {
    NSLog(@" $$$$$$ <IRTMPClientDelegate>> resultReceived\n");
}

#pragma mark -
#pragma mark ISharedObjectListener Methods 

-(void)onSharedObjectConnect:(id <IClientSharedObject>)so {
    NSLog(@"ISharedObjectListener -> onSharedObjectConnect('%@')", [so getName]);
}

-(void)onSharedObjectDisconnect:(id <IClientSharedObject>)so {
	NSLog(@"ISharedObjectListener -> onSharedObjectDisconnect('%@')", [so getName]);
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withKey:(id)key andValue:(id)value {
    
    NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withKey: %@", [so getName], key);
        
    if (![(NSString *)key isEqualToString:SO_ATTRIBUTE_DATA]) 
        return;
        
    NSData *frame = [Base64 decodeFromStringArray:(NSArray *)value];
    if (frame) [self playImageData:frame orientation:[self imageOrientation]];
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withValues:(id <IAttributeStore>)values {
	NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withValues:%@", [so getName], [values getAttributes]);
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withDictionary:(NSDictionary *)values {
    
    NSData *frame = nil;
    UIImageOrientation orientation = UIImageOrientationRight;
    
    NSArray *keys = [values allKeys];
    for (NSString *key in keys) {
        
        [DebLog log:@"ISharedObjectListener -> onSharedObjectUpdate('%@') withDictionary: key = %@", [so getName], key];
        
        id value = [values objectForKey:key];
        if ([key isEqualToString:SO_ATTRIBUTE_DATA] && [value isKindOfClass:NSArray.class])
            frame = [Base64 decodeFromStringArray:(NSArray *)value];
        else      
            if ([key isEqualToString:SO_ATTRIBUTE_ORIENTATION] && [value isKindOfClass:NSNumber.class])
                orientation = [(NSNumber *)value intValue];
    }
    
    if (frame) [self playImageData:frame orientation:orientation];
}

-(void)onSharedObjectDelete:(id <IClientSharedObject>)so withKey:(NSString *)key {
    
	NSLog(@"ISharedObjectListener -> onSharedObjectDelete('%@') withKey:%@", [so getName], key);
    
    [self showAlert:
     [NSString stringWithFormat:@"EVENT: onSharedObjectDelete('%@') withKey:%@", [so getName], key]];  
}

-(void)onSharedObjectClear:(id <IClientSharedObject>)so {    
	NSLog(@"ISharedObjectListener -> onSharedObjectClear('%@')", [so getName]);
}

-(void)onSharedObjectSend:(id <IClientSharedObject>)so withMethod:(NSString *)method andParams:(NSArray *)parms {
    
	NSLog(@"ISharedObjectListener -> onSharedObjectSend('%@') withMethod:%@ andParams:%@", [so getName], method, parms);
    
    [self showAlert:
     [NSString stringWithFormat:@"EVENT: onSharedObjectSend('%@') withMethod:%@ andParams:%@", [so getName], method, parms]];   
}

@end


#pragma mark-
#pragma mark statics  

#define PRESET_LOW_BYTEPERROW 768
#define PRESET_LOW_HEIGHT 144
#define PRESET_LOW_WIDTH 192
#define PRESET_LOW_SCALE 1.0f

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";


@implementation ViewController (MediaProcessing)

-(void)setupAVCapture {
    
    isUsingFrontFacingCamera = YES;
    isPhotoPicking = NO;
	
	// Create the session
    session = [AVCaptureSession new];
    // We use low quality
    [session setSessionPreset:AVCaptureSessionPresetLow];
    
    // Select a video device, make an input
    NSError *error = nil;
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	if (error) {
        [session release];
        [self showAlert:[error localizedDescription]];
        return;
	}
	
	if ([session canAddInput:deviceInput])
		[session addInput:deviceInput];
	
    // Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:AVCaptureStillImageIsCapturingStillImageContext];
	if ( [session canAddOutput:stillImageOutput] )
		[session addOutput:stillImageOutput];
     
    // Make a video data output
	videoDataOutput = [AVCaptureVideoDataOutput new];
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[videoDataOutput setVideoSettings:rgbOutputSettings];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
	videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
	// we create a serial queue to handle the processing of our frames
    if ([session canAddOutput:videoDataOutput])
		[session addOutput:videoDataOutput];
    
    previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	CALayer *rootLayer = [previewView layer];
	[rootLayer setMasksToBounds:YES];
	[previewLayer setFrame:[rootLayer bounds]];
	[rootLayer addSublayer:previewLayer];
    
    [session commitConfiguration];
    [self switchCameras];
    [session startRunning];
}

// clean up capture setup
-(void)teardownAVCapture {
    
    if (![socket connected])
        return;
    
    [DebLog logN:@">>>>>>>>>> teardownAVCapture <<<<<<<<<<<<<<<<"];
    
	[videoDataOutput release];
	if (videoDataOutputQueue)
		dispatch_release(videoDataOutputQueue);
	
    [stillImageOutput removeObserver:self forKeyPath:@"capturingStillImage"];
	[stillImageOutput release];
 	
    [previewLayer removeFromSuperlayer];
	[previewLayer release];
   
	[session release];
    session = nil;
    
}

-(UIImageOrientation)imageOrientation {
    return (isUsingFrontFacingCamera) ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
}

-(void)publishPixelBuffer:(CVPixelBufferRef)_frameBuffer {
    
    if (!isPhotoPicking)
        return;
    
    isPhotoPicking = NO;
    
    // Lock the image buffer
    CVPixelBufferLockBaseAddress(_frameBuffer, 0); 
    
    // Get the base address of the pixel buffer. 
    uint8_t *baseAddress = CVPixelBufferGetBaseAddress(_frameBuffer);
    // Get the data size for contiguous planes of the pixel buffer. 
    size_t bufferSize = CVPixelBufferGetDataSize(_frameBuffer);
    // Get the number of bytes per row for the pixel buffer. 
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(_frameBuffer); 
    // Get the pixel buffer width and height. 
    size_t width = CVPixelBufferGetWidth(_frameBuffer); 
    size_t height = CVPixelBufferGetHeight(_frameBuffer);    
    
    [DebLog log:@"-> publishPixelBuffer: size = %ld, width = %ld, height = %ld, bytesPerRow = %ld, thread = %@", bufferSize, width, height, bytesPerRow, [NSThread isMainThread]?@"MAIN":@"NOT MAIN"];
    
    // Send the frame to the server    
    NSData *data = [NSData dataWithBytes:baseAddress length:bufferSize];
    [DebLog logN:@"\n-----------------------------\n%@\n-----------------------------\n", data];
    [self performSelectorOnMainThread:@selector(sendImageFrame:) withObject:data waitUntilDone:NO]; // MAIN THREAD
    
    // Unlock the  image buffer
    CVPixelBufferUnlockBaseAddress(_frameBuffer, 0);        
}

-(void)objectRelease:(id)obj {
    [obj release];
}

-(void)playImageData:(NSData *)data orientation:(UIImageOrientation)orientation {
    
    if (!data) 
        return;
    
    // Create a device-dependent RGB color space. 
    static CGColorSpaceRef colorSpace = NULL; 
    if (colorSpace == NULL) {
        colorSpace = CGColorSpaceCreateDeviceRGB(); 
        if (colorSpace == NULL) { 
            [DebLog log:@"-> playImageData: (ERROR) Can't create a device-dependent RGB color space"];
            return;
        }
    }
    
    [DebLog logN:@"-> playImageData: size = %d, orientation = %u", data.length, orientation];
    [DebLog logN:@"\n-----------------------------\n%@\n-----------------------------\n", data];
    
    [data retain];
    
    // Create a Quartz direct-access data provider that uses data we supply.
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, (void *)data.bytes, data.length, NULL); 
    // Create a bitmap image from data supplied by the data provider. 
    CGImageRef cgImage = CGImageCreate(PRESET_LOW_WIDTH, PRESET_LOW_HEIGHT, 8, 32, PRESET_LOW_BYTEPERROW, colorSpace, 
                                       kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, 
                                       dataProvider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(dataProvider);
    
    // Create an image object to represent the Quartz image. 
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:PRESET_LOW_SCALE orientation:orientation]; 
    CGImageRelease(cgImage);
    
    [DebLog log:@"-> playImageData: image -> width = %g, height = %g, scale = %g, orientation = %u, thread = %@", image.size.width, image.size.height, image.scale, image.imageOrientation, [NSThread isMainThread]?@"MAIN":@"NOT MAIN"];
    
    [self showPhoto:image];    
    [self performSelector:@selector(objectRelease:) withObject:data afterDelay:0.2f];
}

// use front/back camera
-(void)switchCameras {
	
    AVCaptureDevicePosition desiredPosition = (isUsingFrontFacingCamera) ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
	for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([device position] == desiredPosition) {
			[session beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
			for (AVCaptureInput *oldInput in [session inputs]) {
				[session removeInput:oldInput];
			}
			[session addInput:input];
			[session commitConfiguration];
			break;
		}
	}
	
    isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

// main action method to take an image 
-(void)takePicture {
    
    isPhotoPicking = YES;
	
	// Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                                                  completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                      if (error) {
                                                          NSLog(@"-> takePicture: error = %ld %@@>", (long)error.code, error.localizedDescription);
                                                      }
                                                  }
 	 ];
}

#pragma mark -
#pragma mark KVO observation of the @"capturingStillImage" property 

// perform a flash bulb animation using KVO to monitor the value of the capturingStillImage property of the AVCaptureStillImageOutput class
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
    if ( context == AVCaptureStillImageIsCapturingStillImageContext ) {
		BOOL isCapturingStillImage = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
		
		if ( isCapturingStillImage ) {
			// do flash bulb like animation
			flashView = [[UIView alloc] initWithFrame:[previewView frame]];
			[flashView setBackgroundColor:[UIColor whiteColor]];
			[flashView setAlpha:0.f];
			[[[self view] window] addSubview:flashView];
			
			[UIView animateWithDuration:.4f
							 animations:^{
								 [flashView setAlpha:1.f];
							 }
			 ];
		}
		else {
			[UIView animateWithDuration:.4f
							 animations:^{
								 [flashView setAlpha:0.f];
							 }
							 completion:^(BOOL finished){
								 [flashView removeFromSuperview];
								 [flashView release];
								 flashView = nil;
							 }
			 ];
		}
	}
}

#pragma mark -
#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate Methods 

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {	
    
    if (socket && (captureOutput == videoDataOutput)) {
        [DebLog logN:@">>>>>>>>>> captureOutput: <<<<<<<<<<<<<<<<"];
        [self publishPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];
    }
}

@end
