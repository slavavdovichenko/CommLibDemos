//
//  ViewController.m
//  ClientInvoke
//
//  Created by Vyacheslav Vdovichenko on 7/29/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "BinaryCodec.h"
#import "DEBUG.h"

#define BARBUTTON(TITLE, SELECTOR) [[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR]

#define STATUS_PENDING 0x01


@implementation ViewController

#pragma mark -
#pragma mark Private Methods 

-(void)showAlert:(NSString *)message {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	alerts++;
	av.tag = alerts;
    [av show];
}

// BIG DATA - ARRAY OF BYTES

-(NSData *)bigData {
    
    int len = 100000;
    char *buf = malloc(len);
    
    for (int i = 0; i < len; i++)
        buf[i] = (char)i%256;
    
    NSData *data = [NSData dataWithBytes:buf length:len];
    
    free(buf);
    
    return data;
}

// CALLBACKS

-(void)onEchoInt:(id)result {
    
    NSLog(@"onEchoInt = %@\n", result);
    
    [self showAlert:[NSString stringWithFormat:@"onEchoInt = %@\n", result]];
}

-(void)onEchoFloat:(id)result {
    
    NSLog(@"onEchoFloat = %@\n", result);
    
    [self showAlert:[NSString stringWithFormat:@"onEchoFloat = %@\n", result]];
}

-(void)onEchoString:(id)result {
    
    NSLog(@"onEchoString = %@", result);
    
    [self showAlert:[NSString stringWithFormat:@"onEchoString = %@\n", result]];
}

-(void)onEchoStringArray:(id)result {
    
    NSLog(@"onEchoStringArray = %@", result);
    
    [self showAlert:[NSString stringWithFormat:@"onEchoStringArray = %@\n", result]];
}

-(void)onEchoIntArray:(id)result {
    
    NSLog(@"onEchoIntArray = %@", result);
    
    [self showAlert:[NSString stringWithFormat:@"onEchoIntArray = %@\n", result]];
}

-(void)onEchoArrayList:(id)result {
    
    NSLog(@"onEchoArrayList = %@", result);
    
    [self showAlert:[NSString stringWithFormat:@"onEchoArrayList = %@\n", result]];
}

-(void)onEchoByteArray:(id)result {
    
    NSData *data = [Base64 decodeFromStringArray:result];
    
    NSLog(@"onEchoByteArray = %@", data);
    
    [self showAlert:[NSString stringWithFormat:@"onEchoByteArray = %@\n", data]];
}

// INVOKE

-(void)echoInt {	
	
	printf(" SEND ----> echoInt\n");
	
	// set call parameters
	NSMutableArray *args = [NSMutableArray array];
	NSString *method = @"echoInt";
	[args addObject:[NSNumber numberWithInt:12]];
	// send invoke
	[socket invoke:method withArgs:args responder:[AsynCall call:self method:@selector(onEchoInt:)]];
}

-(void)echoFloat {	
	
	printf(" SEND ----> echoFloat\n");
	
	NSMutableArray *args = [NSMutableArray array];
	// set call parameters
	NSString *method = @"echoFloat";
	[args addObject:[NSNumber numberWithDouble:17.5f]];
	// send invoke
	[socket invoke:method withArgs:args responder:[AsynCall call:self method:@selector(onEchoFloat:)]];
}

-(void)echoString {	
	
	printf(" SEND ----> echoString\n");
	
	NSMutableArray *args = [NSMutableArray array];
	// set call parameters
	NSString *method = @"echoString";
	//[args addObject:@"Hello, WebORB!"];
	[args addObject:@"Привет, ВебОРБ!"];
	// sendinvoke
	[socket invoke:method withArgs:args responder:[AsynCall call:self method:@selector(onEchoString:)]];
}

-(void)echoStringArray {	
	
	printf(" SEND ----> echoStringArray\n");
	
	NSMutableArray *args = [NSMutableArray array];
	// set call parameters
	NSString *method = @"echoStringArray";
	NSMutableArray *param1 = [NSMutableArray array];
	[param1 addObject:@"FIRST"];
	[param1 addObject:@"SECOND"];
	[param1 addObject:@"THIRD"];
	[args addObject:param1];
	// send invoke
	[socket invoke:method withArgs:args responder:[AsynCall call:self method:@selector(onEchoStringArray:)]];
}

-(void)echoIntArray {	
	
	printf(" SEND ----> echoIntArray\n");
	
	NSMutableArray *args = [NSMutableArray array];
	// set call parameters
	NSString *method = @"echoIntArray";
	NSMutableArray *param1 = [NSMutableArray array];
	[param1 addObject:[NSNumber numberWithInt:10]];
	[param1 addObject:[NSNumber numberWithInt:200]];
	[param1 addObject:[NSNumber numberWithInt:3300]];
	[param1 addObject:[NSNumber numberWithInt:45000]];
	[param1 addObject:[NSNumber numberWithInt:58]];
	[param1 addObject:[NSNumber numberWithInt:6977]];
	[param1 addObject:[NSNumber numberWithInt:100001]];
	[args addObject:param1];
	// send invoke
	[socket invoke:method withArgs:args responder:[AsynCall call:self method:@selector(onEchoIntArray:)]];
}

-(void)echoArrayList {	
	
	printf(" SEND ----> echoArrayList\n");
	
	NSMutableArray *args = [NSMutableArray array];
	// set call parameters
	NSString *method = @"echoArrayList";
	NSMutableArray *param1 = [NSMutableArray array];
	[param1 addObject:@"FIRST"];
	[param1 addObject:[NSNumber numberWithInt:10]];
	[param1 addObject:@"SECOND"];
	[param1 addObject:[NSNumber numberWithDouble:5.5f]];
	[param1 addObject:@"THIRD"];
	[args addObject:param1];
	// send invoke
	[socket invoke:method withArgs:args responder:[AsynCall call:self method:@selector(onEchoArrayList:)]];
}

-(void)echoByteArray {	
	
	printf(" SEND ----> echoByteArray\n");
	
	NSMutableArray *args = [NSMutableArray array];
	// set call parameters
	NSString *method = @"echoStringArray";
	[args addObject:[Base64 encodeToStringArray:[self bigData]]];
	// send invoke
	[socket invoke:method withArgs:args responder:[AsynCall call:self method:@selector(onEchoByteArray:)]];
}

// ACTIONS

-(void)socketConnected {
    
    state = 1;
    
    self.title = [NSString stringWithFormat:@"%@:%@/%@", hostTextField.text, portTextField.text, appTextField.text];
    self.navigationItem.rightBarButtonItem = BARBUTTON(@"Disconnect", @selector(doDisconnect:));
    
    btnProtocol.hidden = YES;
    protocolLabel.hidden = YES;
    portLabel.hidden = YES;
    appLabel.hidden = YES;
    hostTextField.hidden = YES;
    portTextField.hidden = YES;
    appTextField.hidden = YES;
    
    infoImage.hidden = YES;
    btnInfo.hidden = YES;
    
    btnEchoInt.hidden = NO;
    btnEchoFloat.hidden = NO;
    btnEchoString.hidden = NO;
    btnEchoStringArray.hidden = NO;
    btnEchoIntArray.hidden = NO;
    btnEchoArrayList.hidden = NO;
    btnEchoByteArray.hidden = NO;
}

-(void)socketDisconnected {
    
    state = 0;
    
	self.title = @"ClientInvoke";
	self.navigationItem.rightBarButtonItem = BARBUTTON(@"Connect", @selector(doConnect:));
    
    btnProtocol.hidden = NO;
    protocolLabel.hidden = NO;
    portLabel.hidden = NO;
    appLabel.hidden = NO;
    hostTextField.hidden = NO;
    portTextField.hidden = NO;
    appTextField.hidden = NO;
    
    infoImage.hidden = YES;
    [btnInfo setTitle:@"Info" forState:UIControlStateNormal];
    btnInfo.hidden = NO;
    
    btnEchoInt.hidden = YES;
    btnEchoFloat.hidden = YES;
    btnEchoString.hidden = YES;
    btnEchoStringArray.hidden = YES;
    btnEchoIntArray.hidden = YES;
    btnEchoArrayList.hidden = YES;
    btnEchoByteArray.hidden = YES;
}

-(void)doConnect:(id)sender {				
    
    NSString *protocol = (isRTMPS) ? @"rtmps://%@:%d/%@" : @"rtmp://%@:%d/%@";
    NSString *url = [NSString stringWithFormat:protocol, hostTextField.text, [portTextField.text intValue], appTextField.text];
    
    if (socket)
        [socket connect:url];
    else {
        socket = [[RTMPClient alloc] init:url];
        socket.delegate = self;
        [socket connect];
    }
}

-(void)doDisconnect:(id)sender {	
    
    if (state == 0) 
        return;
    
    [self socketDisconnected];
    [socket disconnect];
    socket = nil;
}

-(void)doInfo {
    infoImage.hidden = (infoImage.hidden)?NO:YES;
    [btnInfo setTitle:(infoImage.hidden)?@"Info":@"Close" forState:UIControlStateNormal];
    
    BOOL active = (infoImage.hidden)?NO:YES;
    btnProtocol.hidden = active;
    hostTextField.hidden = active;
    portTextField.hidden = active;
    appTextField.hidden = active;
}

-(void)doProtocol {
    isRTMPS = (isRTMPS)?NO:YES;    
    [btnProtocol setTitle:(isRTMPS)?@"rtmps":@"rtmp" forState:UIControlStateNormal];
}

#pragma mark -
#pragma mark View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    //
	self.title = @"ClientInvoke";
	self.navigationItem.rightBarButtonItem = BARBUTTON(@"Connect", @selector(doConnect:));
    
	//button
	btnProtocol = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnProtocol.frame = CGRectMake(0.0, 0.0, 50.0, 30.0);
	btnProtocol.center = CGPointMake(35.0, 25.0);
	btnProtocol.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnProtocol setTitle:@"rtmp" forState:UIControlStateNormal];
	[btnProtocol addTarget:self action:@selector(doProtocol) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnProtocol];
    
	//labels
	protocolLabel = [[UILabel alloc] initWithFrame:CGRectMake(62.0, 10.0, 23.0, 30.0)];
	protocolLabel.text = @"://";
	[self.view addSubview:protocolLabel];
	//[protocolLabel release];
    
	portLabel = [[UILabel alloc] initWithFrame:CGRectMake(7.0, 50.0, 5.0, 30.0)];
	portLabel.text = @":";
	[self.view addSubview:portLabel];
	//[portLabel release];
	
	appLabel = [[UILabel alloc] initWithFrame:CGRectMake(7.0, 90.0, 10.0, 30.0)];
	appLabel.text = @"/";
	[self.view addSubview:appLabel];
	//[appLabel release];
	
	// textFields
	hostTextField = [[UITextField alloc] initWithFrame:CGRectMake(80.0, 10.0, 235.0, 30.0)];
	hostTextField.borderStyle = UITextBorderStyleRoundedRect;
	hostTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	hostTextField.placeholder = @"hostname or IP";
    hostTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	hostTextField.returnKeyType = UIReturnKeyDone;
	hostTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	//hostTextField.text = @"examples.themidnightcoders.com";
	//hostTextField.text = @"10.0.1.141";
	hostTextField.text = @"192.168.2.63";
	hostTextField.delegate = self;
	[self.view addSubview:hostTextField];
	//[hostTextField release];
	
	portTextField = [[UITextField alloc] initWithFrame:CGRectMake(15.0, 50.0, 80.0, 30.0)];
	portTextField.borderStyle = UITextBorderStyleRoundedRect;
	portTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	portTextField.placeholder = @"port";
    portTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	portTextField.returnKeyType = UIReturnKeyDone;
	portTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	//portTextField.text = @"2037";
	portTextField.text = @"1935";
	portTextField.delegate = self;
	[self.view addSubview:portTextField];
	//[portTextField release];
	
	appTextField = [[UITextField alloc] initWithFrame:CGRectMake(15.0, 90.0, 300.0, 30.0)];
	appTextField.borderStyle = UITextBorderStyleRoundedRect;
	appTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	appTextField.placeholder = @"app";
	appTextField.returnKeyType = UIReturnKeyDone;
	appTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	appTextField.text = @"ClientInvoke";
	//appTextField.text = @"MethodInvocation";
	appTextField.delegate = self;
	[self.view addSubview:appTextField];
	//[appTextField release];
	
	//buttons
	btnEchoInt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoInt.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoInt.center = CGPointMake(160.0, 30.0);
	btnEchoInt.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoInt setTitle:@"echoInt (12)" forState:UIControlStateNormal];
    [btnEchoInt addTarget:self action:@selector(echoInt) forControlEvents:UIControlEventTouchUpInside];
    btnEchoInt.hidden = YES;
	[self.view addSubview:btnEchoInt];
    
	btnEchoFloat = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoFloat.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoFloat.center = CGPointMake(160.0, 75.0);
	btnEchoFloat.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoFloat setTitle:@"echoFloat (17.5)" forState:UIControlStateNormal];
    [btnEchoFloat addTarget:self action:@selector(echoFloat) forControlEvents:UIControlEventTouchUpInside];
	btnEchoFloat.hidden = YES;
	[self.view addSubview:btnEchoFloat];
	
	btnEchoString = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoString.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoString.center = CGPointMake(160.0, 120.0);
	btnEchoString.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoString setTitle:@"echoString ('Hello, WebORB!')" forState:UIControlStateNormal];
    [btnEchoString addTarget:self action:@selector(echoString) forControlEvents:UIControlEventTouchUpInside];
	btnEchoString.hidden = YES;
	[self.view addSubview:btnEchoString];
	
	btnEchoStringArray = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoStringArray.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoStringArray.center = CGPointMake(160.0, 165.0);
	btnEchoStringArray.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoStringArray setTitle:@"echoStringArray (['FIRST','SECOND','THIRD'])" forState:UIControlStateNormal];
    [btnEchoStringArray addTarget:self action:@selector(echoStringArray) forControlEvents:UIControlEventTouchUpInside];
	btnEchoStringArray.hidden = YES;
	[self.view addSubview:btnEchoStringArray];
	
    btnEchoIntArray = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnEchoIntArray.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
    btnEchoIntArray.center = CGPointMake(160.0, 210.0);
    btnEchoIntArray.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoIntArray setTitle:@"echoIntArray ([10,200,3300,4500,58,6977,100001])" forState:UIControlStateNormal];
    [btnEchoIntArray addTarget:self action:@selector(echoIntArray) forControlEvents:UIControlEventTouchUpInside];
    btnEchoIntArray.hidden = YES;
    [self.view addSubview:btnEchoIntArray];
    
    btnEchoArrayList = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btnEchoArrayList.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
    btnEchoArrayList.center = CGPointMake(160.0, 255.0);
    btnEchoArrayList.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoArrayList setTitle:@"echoArrayList ({'FIRST',10,'SECOND',5.5,'THIRD'})" forState:UIControlStateNormal];
    [btnEchoArrayList addTarget:self action:@selector(echoArrayList) forControlEvents:UIControlEventTouchUpInside];
    btnEchoArrayList.hidden = YES;
    [self.view addSubview:btnEchoArrayList];
	
	btnEchoByteArray = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoByteArray.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoByteArray.center = CGPointMake(160.0, 300.0);
	btnEchoByteArray.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoByteArray setTitle:@"echoByteArray ([cycle = (0, 1, 2, 0xFF), size = 100000])" forState:UIControlStateNormal];
    [btnEchoByteArray addTarget:self action:@selector(echoByteArray) forControlEvents:UIControlEventTouchUpInside];
	btnEchoByteArray.hidden = YES;
	[self.view addSubview:btnEchoByteArray];
    
	// images
    infoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RMI.png"]];
    infoImage.hidden = YES;
    [self.view addSubview:infoImage];
    //[infoImage release];
	
	//button
	btnInfo = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnInfo.frame = CGRectMake(0.0, 0.0, 80.0, 30.0);
	btnInfo.center = CGPointMake(270.0, 390.0);
	btnInfo.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnInfo setTitle:@"Info" forState:UIControlStateNormal];
	[btnInfo addTarget:self action:@selector(doInfo) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnInfo];
	
    isRTMPS = NO;
	alerts = 100;
	state = 0;
    socket = nil;
    
    [DebLog setIsActive:YES];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    [self doDisconnect:nil];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods 

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(int)index {
	//[alertView release];	
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
    NSLog(@" $$$$$$ <IRTMPClientDelegate>> disconnectedEvent\n");
    
    [self performSelector:@selector(doDisconnect:) withObject:nil afterDelay:0.1f];    
 	[self showAlert:@" !!! disconnectedEvent \n"];   
}

-(void)connectFailedEvent:(int)code description:(NSString *)description {	
    NSLog(@" $$$$$$ <IRTMPClientDelegate>> connectFailedEvent: %d = '%@'\n", code, description);
    
    [self performSelector:@selector(doDisconnect:) withObject:nil afterDelay:0.1f];
    
    if (code == -1)
        [self showAlert:[NSString stringWithFormat:
                         @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid\n"]];       
    else
        [self showAlert:[NSString stringWithFormat:@" !!! connectFailedEvent: %@ \n", description]];       
}

-(void)resultReceived:(id <IServiceCall>)call {
    
    int status = [call getStatus];
    if (status != STATUS_PENDING) // this call is not a server response
        return;
    
    NSString *method = [call getServiceMethodName];
    NSArray *args = [call getArguments];
    int invokeId = [call getInvokeId];
    id result = (args.count) ? [args objectAtIndex:0] : nil;
    
    NSLog(@" $$$$$$ <IRTMPClientDelegate>> resultReceived <---- status=%d, invokeID=%d, method='%@' arguments=%@\n", status, invokeId, method, result);
    
    [self showAlert:[NSString stringWithFormat:@"'%@': arguments = %@\n", method, result]];    
}

@end
