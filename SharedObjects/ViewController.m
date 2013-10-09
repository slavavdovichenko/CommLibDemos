//
//  ViewController.m
//  SharedObjects
//
//  Created by Vyacheslav Vdovichenko on 7/29/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "BinaryCodec.h"
#import "DEBUG.h"

#define BARBUTTON(TITLE, SELECTOR) 	[[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR]

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

// SO

-(void)connectSO {	
    
    if (!clientSO) {
        
        printf("connectSO SEND ----> getSharedObject\n");
        
        // send "getSharedObject (+ connect)"
        NSString *name = @"SharedBall";
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

-(void)getAttributeSO {	
    
    if (!clientSO || ![clientSO isConnected]) {
        [self showAlert:@"clientSO is absent or disconnected!\n Push 'connectSO' button\n"];
        return;
    }
    
    intSO += 5;
    floatSO += 5.7f;
    
    // setAttributes
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];    
    [dict setValue:[NSString stringWithFormat:@"itIsString= %d, %g", intSO, floatSO] forKey:@"stringVal" ];
    [dict setValue:[NSNumber numberWithInt:intSO] forKey:@"intVal" ];
    [dict setValue:[NSNumber numberWithFloat:floatSO] forKey:@"floatVal" ];
    [dict setValue:[NSNumber numberWithBool:YES] forKey:@"boolVal" ];
 	
    NSLog(@"*****************>>>> getAttributeSO: %@ (attributes = %@)", [clientSO getName], dict);
    
    [clientSO setAttributes:dict];
}

-(void)removeAttributeSO {	
    
    if (!clientSO || ![clientSO isConnected]) {
        [self showAlert:@"clientSO is absent or disconnected!\n Push 'connectSO' button\n"];
        return;
    }
 	
    NSLog(@"*****************>>>> removeAttributeSO: %@ (attributes = %@)", [clientSO getName], [clientSO getAttributeNames]);
    
    // clear (removeAttributes)
    [clientSO clear];
}

-(void)sendMessageSO {	
    
    if (!clientSO || ![clientSO isConnected]) {
        [self showAlert:@"clientSO is absent or disconnected!\n Push 'connectSO' button\n"];
        return;
    }
 	
    NSLog(@"*****************>>>> sendMessageSO: %@ (attributes = %@)", [clientSO getName], [clientSO getAttributeNames]);
    
    // sendMessageSO
    NSMutableArray *array = [NSMutableArray array];    
    [array addObject:@"attrString"];
    [array addObject:[NSNumber numberWithInt:55]];
    [array addObject:[NSNumber numberWithFloat:55.7f]];
    [array addObject:[NSNumber numberWithBool:NO]];
    
    [clientSO sendMessage:@"MEGGAGE_SO" arguments:array];
}

-(void)getAttributeSOByteArray {	
    
    if (!clientSO || ![clientSO isConnected]) {
        [self showAlert:@"clientSO is absent or disconnected!\n Push 'connectSO' button\n"];
        return;
    }
 	
    NSLog(@"*****************>>>> getAttributeSOByteArray: %@ (attributes = %@)", [clientSO getName], [clientSO getAttributeNames]);
    
    // setAttribute
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];    
    [dict setValue:[Base64 encodeToStringArray:[self bigData]] forKey:@"byteArray"];
    
    [clientSO setAttributes:dict];
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
    btnEchoByteArray.hidden = NO;
}

-(void)socketDisconnected {
    
    state = 0;
    clientSO = nil;
    
	self.title = @"SharedObject";
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
    
    [DebLog setIsActive:YES];
	//
	self.title = @"SharedObjects";
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
	//hostTextField.text = @"192.168.2.63";
	//hostTextField.text = @"23.20.183.103"; 
	hostTextField.text = @"localhost";
	//hostTextField.text = @"10.0.1.14";
	//hostTextField.text = @"10.0.1.33";
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
	//appTextField.text = @"SharedBall";
	//appTextField.text = @"SharedObjectsApp";
	//appTextField.text = @"root";
	appTextField.text = @"live";
	appTextField.delegate = self;
	[self.view addSubview:appTextField];
	//[appTextField release];
	
	//buttons
	btnEchoInt = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoInt.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoInt.center = CGPointMake(160.0, 30.0);
	btnEchoInt.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoInt setTitle:@"connectSO ('SharedBall')" forState:UIControlStateNormal];
	[btnEchoInt addTarget:self action:@selector(connectSO) forControlEvents:UIControlEventTouchUpInside];
    btnEchoInt.hidden = YES;
	[self.view addSubview:btnEchoInt];
    
	btnEchoFloat = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoFloat.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoFloat.center = CGPointMake(160.0, 75.0);
	btnEchoFloat.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoFloat setTitle:@"getAttributeSO" forState:UIControlStateNormal];
	[btnEchoFloat addTarget:self action:@selector(getAttributeSO) forControlEvents:UIControlEventTouchUpInside];
	btnEchoFloat.hidden = YES;
	[self.view addSubview:btnEchoFloat];
	
	btnEchoString = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoString.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoString.center = CGPointMake(160.0, 120.0);
	btnEchoString.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
	[btnEchoString setTitle:@"removeAttributeSO" forState:UIControlStateNormal];
	[btnEchoString addTarget:self action:@selector(removeAttributeSO) forControlEvents:UIControlEventTouchUpInside];
	btnEchoString.hidden = YES;
	[self.view addSubview:btnEchoString];
	
	btnEchoStringArray = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoStringArray.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoStringArray.center = CGPointMake(160.0, 165.0);
	btnEchoStringArray.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
	[btnEchoStringArray setTitle:@"sendMessageSO" forState:UIControlStateNormal];
	[btnEchoStringArray addTarget:self action:@selector(sendMessageSO) forControlEvents:UIControlEventTouchUpInside];
	btnEchoStringArray.hidden = YES;
	[self.view addSubview:btnEchoStringArray];
	
	btnEchoByteArray = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnEchoByteArray.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnEchoByteArray.center = CGPointMake(160.0, 210.0);
	btnEchoByteArray.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnEchoByteArray setTitle:@"getByteArray ([(0, 1, 2, 0xFF), size = 100000])" forState:UIControlStateNormal];
    [btnEchoByteArray addTarget:self action:@selector(getAttributeSOByteArray) forControlEvents:UIControlEventTouchUpInside];
	btnEchoByteArray.hidden = YES;
	[self.view addSubview:btnEchoByteArray];
    
	// images
    infoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"RSO-API.png"]];
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
    intSO = 0;
    floatSO = 0.0f;
    
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
    
    [self performSelector:@selector(doDisconnect:) withObject:nil afterDelay:0.1f];
    
 	[self showAlert:@" !!! disconnectedEvent \n"];   
}

-(void)connectFailedEvent:(int)code description:(NSString *)description {
    
    [self performSelector:@selector(doDisconnect:) withObject:nil afterDelay:0.1f];
    
    if (code == -1)
        [self showAlert:[NSString stringWithFormat:
                         @"Unable to connect to the server. Make sure the hostname/IP address and port number are valid\n"]];       
    else
        [self showAlert:[NSString stringWithFormat:@" !!! connectFailedEvent: %@ \n", description]];       
}

-(void)resultReceived:(id <IServiceCall>)call {
    NSString *method = [call getServiceMethodName];
    NSArray *args = [call getArguments];
    
    if (args.count) {
        
        NSLog(@" $$$$$$ <IRTMPClientDelegate>> resultReceived <---- %@, arguments = %@ n", method, [args objectAtIndex:0]);
        
        [self showAlert:[NSString stringWithFormat:@"'%@': arguments = %@\n", method, [args objectAtIndex:0]]];
    }
    else {
        NSLog(@" $$$$$$ <IRTMPClientDelegate>> resultReceived <---- %@, arguments = 0\n", method);
        
        [self showAlert:[NSString stringWithFormat:@"'%@': arguments = 0\n", method]];       
    }
}

#pragma mark -
#pragma mark ISharedObjectListener Methods 

-(void)onSharedObjectConnect:(id <IClientSharedObject>)so {
  	
    NSLog(@"ISharedObjectListener -> onSharedObjectConnect('%@')", [so getName]);
    
    if ([so isConnected])
        [btnEchoInt setTitle:@"disconnectSO ('SharedBall')" forState:UIControlStateNormal];
	
    [self showAlert:
     [NSString stringWithFormat:@"EVENT: onSharedObjectConnect ('%@')\n", [so getName]]];
}

-(void)onSharedObjectDisconnect:(id <IClientSharedObject>)so {
    
	NSLog(@"ISharedObjectListener -> onSharedObjectDisconnect('%@')", [so getName]);
    
    if (![so isConnected])
        [btnEchoInt setTitle:@"connectSO ('SharedBall')" forState:UIControlStateNormal];
	
    [self showAlert:
     [NSString stringWithFormat:@"EVENT: onSharedObjectDisconnect ('%@')\n", [so getName]]];
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withKey:(id)key andValue:(id)value {
    
    NSString *param = key;
    if ([param isEqualToString:@"byteArray"]) {
        
        NSData *result = [Base64 decodeFromStringArray:(NSArray *)value];
        
        NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withKey: 'byteArray' -> \n%@", [so getName], result);
        
        [self showAlert:[NSString stringWithFormat:@"EVENT: onSharedObjectUpdate('%@') withKey: 'byteArray' -> \n%@", [so getName], result]];   
    }
    else {
    
        NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withKey:%@ -> %@ <%@>", [so getName], key, value, [value class]);
    
        [self showAlert:[NSString stringWithFormat:@"EVENT: onSharedObjectUpdate ('%@') withKey:%@ -> %@\n", [so getName], key, value]];
    }
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withValues:(id <IAttributeStore>)values {
    
	NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withValues:%@", [so getName], [values getAttributes]);
    
    [self showAlert:[NSString stringWithFormat:@"EVENT: onSharedObjectUpdate('%@') withValues:%@", [so getName], [values getAttributes]]];
}

-(void)onSharedObjectUpdate:(id <IClientSharedObject>)so withDictionary:(NSDictionary *)values {
    
    id data = [values objectForKey:@"byteArray"]; // IS IT BYTE ARRAY ?
    if (data) {
        
        NSData *result = [Base64 decodeFromStringArray:(NSArray *)data];
    
        NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withDictionary: key = 'byteArray' -> \n%@", [so getName], result);
    
        [self showAlert:[NSString stringWithFormat:@"EVENT: onSharedObjectUpdate('%@') withDictionary: key = 'byteArray' -> \n%@", [so getName], result]];   
    }
    else {
        
        NSLog(@"ISharedObjectListener -> onSharedObjectUpdate('%@') withDictionary:%@", [so getName], values);
        
        [self showAlert:[NSString stringWithFormat:@"EVENT: onSharedObjectUpdate('%@') withDictionary:%@", [so getName], values]];   
    }
}

-(void)onSharedObjectDelete:(id <IClientSharedObject>)so withKey:(NSString *)key {
    
	NSLog(@"ISharedObjectListener -> onSharedObjectDelete('%@') withKey:%@", [so getName], key);
    
    [self showAlert:
     [NSString stringWithFormat:@"EVENT: onSharedObjectDelete('%@') withKey:%@", [so getName], key]];  
}

-(void)onSharedObjectClear:(id <IClientSharedObject>)so {
    
	NSLog(@"ISharedObjectListener -> )onSharedObjectClear('%@')", [so getName]);
    
    [self showAlert:
     [NSString stringWithFormat:@"EVENT: onSharedObjectClear('%@')", [so getName]]];    
}

-(void)onSharedObjectSend:(id <IClientSharedObject>)so withMethod:(NSString *)method andParams:(NSArray *)parms {
    
	NSLog(@"ISharedObjectListener -> onSharedObjectSend('%@') withMethod:%@ andParams:%@", [so getName], method, parms);
    
    [self showAlert:
     [NSString stringWithFormat:@"EVENT: onSharedObjectSend('%@') withMethod:%@ andParams:%@", [so getName], method, parms]];   
}

@end
