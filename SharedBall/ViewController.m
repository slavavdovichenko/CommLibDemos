//
//  ViewController.m
//  SharedBall
//
//  Created by Vyacheslav Vdovichenko on 7/29/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import "BinaryCodec.h"
#import "DEBUG.h"

#define BARBUTTON(TITLE, SELECTOR) [[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR]

@implementation ViewController

#pragma mark -
#pragma mark Private Methods 

// license

-(NSData *)licenseData {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@"bin"];    
    //NSLog(@">>>> licenseData >>>> path: %@", path);
    if (!path)
        return nil;
    
    NSData *license = [NSData dataWithContentsOfFile:path];
    NSLog(@">>> license: %@", license);
    return license;
}

// memory

-(double) getAvailableBytes
{
	vm_statistics_data_t vmStats;
	mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
	kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
	
	if (kernReturn != KERN_SUCCESS)
	{
		return NSNotFound;
	}
	
	return (vm_page_size * vmStats.free_count);
}

-(double) getAvailableKiloBytes
{
	return [self getAvailableBytes] / 1024.0;
}

-(NSString *)showMemory {
    return [NSString stringWithFormat:@"%g", [self getAvailableKiloBytes]];
}

// alert

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
        NSString *name = @"BallControl";
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

-(void)positionSO:(CGPoint)point {    
    
    if (!state || !clientSO || ![clientSO  isConnected])
        return;
    
    activeImage.center = point;
    
    // setAttributes
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];    
    [dict setValue:[NSNumber numberWithFloat:point.x] forKey:@"x"];
    [dict setValue:[NSNumber numberWithFloat:point.y] forKey:@"y"];
    [dict setValue:[self licenseData] forKey:@"l"];
    //--------------------------------
    NSMutableDictionary *ballCoord = [NSMutableDictionary dictionary];    
    [ballCoord setValue:dict forKey:@"ballCoordinates"];
    [clientSO setAttributes:ballCoord];
    
    memoryLabel.text = [self showMemory];
}

// Actions

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
    
    [self connectSO];
}

-(void)socketDisconnected {
    
    state = 0;
    clientSO = nil;
    
	self.title = @"SharedBall";
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
    
    activeImage.center = CGPointMake(160.0f, 350.0f);
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
#pragma mark  View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	//
	self.title = @"SharedBall";
	self.navigationItem.rightBarButtonItem = BARBUTTON(@"Connect", @selector(doConnect:));
	
	// images
    activeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"weborb.png"]];
    activeImage.center = CGPointMake(160.0f, 350.0f);
    activeImage.userInteractionEnabled = YES;	
    [self.view addSubview:activeImage];
    //[activeImage release];
    
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
    
	memoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(7.0, 385.0, 90.0, 25.0)];
	memoryLabel.text = [self showMemory];
    memoryLabel.hidden = YES;
	[self.view addSubview:memoryLabel];
	//[memoryLabel release];
	
	// textFields
	hostTextField = [[UITextField alloc] initWithFrame:CGRectMake(80.0, 10.0, 235.0, 30.0)];
	hostTextField.borderStyle = UITextBorderStyleRoundedRect;
	hostTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	hostTextField.placeholder = @"hostname or IP";
    hostTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	hostTextField.returnKeyType = UIReturnKeyDone;
	hostTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	//hostTextField.text = @"localhost";
	//hostTextField.text = @"10.0.1.141";
	hostTextField.text = @"10.0.1.62";
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
	//appTextField.text = @"SharedObjectsApp";
	//appTextField.text = @"SharedBall";
	appTextField.text = @"live";
	appTextField.delegate = self;
	[self.view addSubview:appTextField];
	//[appTextField release];
    
	// images
    infoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RSO.png"]];
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
    clientSO = nil;
    
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
#pragma mark UIResponder Touch Methods 

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
    UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.view];
    
    //NSLog(@"touchesBegan -> X:%g, Y:%g", point.x, point.y);
    
    [self positionSO:point];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
    UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.view];
    
    //NSLog(@"touchesMoved -> X:%g, Y:%g", point.x, point.y);
    
    [self positionSO:point];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
    UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self.view];
    
    //NSLog(@"touchesEnded -> X:%g, Y:%g", point.x, point.y);
    
    [self positionSO:point];   
}

#pragma mark -
#pragma mark UIAlertViewDelegate Methods 

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
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
    NSLog(@" $$$$$$ <IRTMPClientDelegate>> connectFailedEvent: %d = %@\n", code, description);
    
    [self performSelector:@selector(doDisconnect:) withObject:nil afterDelay:0.1f];
    
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
    
    if ([so isConnected])
        activeImage.center = CGPointMake(160.0f, 200.0f);
}

-(void)onSharedObjectDisconnect:(id <IClientSharedObject>)so {
	NSLog(@"ISharedObjectListener -> onSharedObjectDisconnect('%@')", [so getName]);
    
    if (![so isConnected])
        activeImage.center = CGPointMake(160.0f, 350.0f);
	
    [self showAlert:[NSString stringWithFormat:@"EVENT: onSharedObjectDisconnect ('%@')\n", [so getName]]];
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withKey:(id)key andValue:(id)value {
    // NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withKey:%@ andValue:%@", [so getName], key, value);
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withValues:(id <IAttributeStore>)values {
	//NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withValues:%@", [so getName], [values getAttributes]);
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withDictionary:(NSDictionary *)values {
	NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withDictionary:%@", [so getName], values);
    
    NSDictionary *ballCoord = [values valueForKey:@"ballCoordinates"];
    NSNumber *x = [ballCoord valueForKey:@"x"];
    NSNumber *y = [ballCoord valueForKey:@"y"];
    float xPoint = (x)?[x floatValue]:activeImage.center.x;
    float yPoint = (y)?[y floatValue]:activeImage.center.y;
    activeImage.center = CGPointMake(xPoint, yPoint);
    
    NSLog(@"<<< license = %@", [Base64 decode:[ballCoord valueForKey:@"l"]]);
    
    memoryLabel.text = [self showMemory];
}

-(void)onSharedObjectDelete:(id <IClientSharedObject>)so withKey:(NSString *)key {
	NSLog(@"ISharedObjectListener -> onSharedObjectDelete('%@') withKey:%@", [so getName], key);
}

-(void)onSharedObjectClear:(id <IClientSharedObject>)so {
	NSLog(@"ISharedObjectListener -> )onSharedObjectClear('%@')", [so getName]);    
}

-(void)onSharedObjectSend:(id <IClientSharedObject>)so withMethod:(NSString *)method andParams:(NSArray *)parms {
	NSLog(@"ISharedObjectListener -> onSharedObjectSend('%@') withMethod:%@ andParams:%@", [so getName], method, parms);    
}


@end
