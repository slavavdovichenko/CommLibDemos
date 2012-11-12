//
//  ViewController.m
//  PubSubChat
//
//  Created by Vyacheslav Vdovichenko on 5/11/12.
//  Copyright (c) 2012 The Midnight Coders, Inc. All rights reserved.
//


#import "ViewController.h"
#import "Responder.h"

#define BARBUTTON(TITLE, SELECTOR) [[UIBarButtonItem alloc] initWithTitle:TITLE style:UIBarButtonItemStylePlain target:self action:SELECTOR]


@implementation ViewController

#pragma mark -
#pragma mark Private Methods 

// ALERTS

-(void)showAlert:(NSString *)message title:(NSString *)title {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	alerts++;
	av.tag = alerts;
    [av show];
}

// MEMORY INDICATOR

-(void)sizeMemory:(NSNumber *)memory {
    memoryLabel.text = [NSString stringWithFormat:@"%d", [memory intValue]];
}

// RESPONDERS

-(void)subscribedHandler:(NSString *)info {
    NSLog(@">>>>>>>>>>> subscribedHandler: info = %@", info);
    [self showAlert:info title:@"Subscription:"];
}

-(void)publishResponseHandler:(id)response {
    NSLog(@">>>>>>>>>>> publishResponseHandler: response = %@", response);
}

-(void)publishErrorHandler:(Fault *)fault {
    NSLog(@">>>>>>>>>>> publishErrorHandler: message = '%@', detail = '%@'", fault.message, fault.detail);    
    [self showAlert:fault.detail title:@"publishErrorHandler:"];
}

-(void)subscribeResponseHandler:(id)response {
    NSLog(@">>>>>>>>>>> subscribeResponseHandler: response = %@", response);
    SubscribeResponse *message = (SubscribeResponse *)response;
    NSString *clientId = [message.headers objectForKey:@"WebORBClientId"];
    chatTextView.text = [NSString stringWithFormat:@"%@ : '%@'\n%@", (clientId)?clientId:@"Anonymous", message.response, chatTextView.text];
}

-(void)subscribeErrorHandler:(Fault *)fault {
    NSLog(@">>>>>>>>>>> subscribeErrorHandler: message = %@, detail = %@", fault.message, fault.detail);    
    [self showAlert:fault.detail title:@"subscribeErrorHandler:"];
}

// ACTIONS

-(void)publish {
    
    [client publish:chatTextField.text 
          responder:[Responder responder:self 
                      selResponseHandler:@selector(publishResponseHandler:) 
                         selErrorHandler:@selector(publishErrorHandler:)] 
           subtopic:subtopicTextField.text];
    
}

-(void)subscribe {
    
    [client subscribe:[SubscribeResponder responder:self 
                                 selResponseHandler:@selector(subscribeResponseHandler:) 
                                    selErrorHandler:@selector(subscribeErrorHandler:)] 
             subtopic:subtopicTextField.text 
             selector:selectorTextField.text];
    
}

-(void)unsubscribe {
    [client unsubscribe:subtopicTextField.text selector:selectorTextField.text];
}

-(void)clientConnected {
    
    self.navigationItem.rightBarButtonItem = BARBUTTON(@"Disconnect", @selector(doDisconnect:));
    
    hostTextField.hidden = YES;
    destTextField.hidden = YES;
    subtopicTextField.hidden = NO;
    selectorTextField.hidden = NO;
    chatTextField.hidden = NO;
    
    btnPublish.hidden = NO;
    btnSubscribe.hidden = NO;
    btnUnsubscribe.hidden = NO;
    chatTextView.hidden = NO;
    
    chatTextView.text = nil;
}

-(void)clientDisconnected {
    
	self.navigationItem.rightBarButtonItem = BARBUTTON(@"Connect", @selector(doConnect:));
    
    hostTextField.hidden = NO;
    destTextField.hidden = NO;
    subtopicTextField.hidden = YES;
    selectorTextField.hidden = YES;
    chatTextField.hidden = YES;
    
    btnPublish.hidden = YES;
    btnSubscribe.hidden = YES;
    btnUnsubscribe.hidden = YES;
    chatTextView.hidden = YES;
}

-(void)doConnect:(id)sender {	
    
    if (!client) {
        
        NSString *url = hostTextField.text;
        NSString *destination = destTextField.text;
        
        NSLog(@"\n\n***************** doConnect: url = %@, destination = %@ *************\n\n", url, destination);
        
        client = (destination.length) ? 
        [[WeborbClient alloc] initWithUrl:url destination:destination] : [[WeborbClient alloc] initWithUrl:url];
        client.subscribedHandler = [SubscribedHandler responder:self selSubscribedHandler:@selector(subscribedHandler:)];
        
        [self clientConnected];
    }
}

-(void)doDisconnect:(id)sender {	
    
    if (client) {
        
        printf("\n********************************************* doDisconnect *********************************************\n\n");
        
        [self clientDisconnected];
        
        [client stop];
        client = nil;
    }
}


#pragma mark - View lifecycle

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    //
	self.title = @"PubSubChat";
	self.navigationItem.rightBarButtonItem = BARBUTTON(@"Connect", @selector(doConnect:));
	
	// textFields
	hostTextField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 5.0, 310.0, 30.0)];
	hostTextField.borderStyle = UITextBorderStyleRoundedRect;
	hostTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	hostTextField.placeholder = @"application URL";
    hostTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	hostTextField.returnKeyType = UIReturnKeyDone;
	hostTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	hostTextField.text = @"http://examples.themidnightcoders.com/weborb.aspx";
	//hostTextField.text = @"rtmp://examples.themidnightcoders.com:2037/root";
	//hostTextField.text = @"http://10.0.1.141/weborb5/weborb.aspx";
	//hostTextField.text = @"rtmp://10.0.1.141:2037/root";
	hostTextField.delegate = self;
	[self.view addSubview:hostTextField];
	//[hostTextField release];
	
    destTextField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 40.0, 310.0, 30.0)];
	destTextField.borderStyle = UITextBorderStyleRoundedRect;
	destTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	destTextField.placeholder = @"destination";
	destTextField.returnKeyType = UIReturnKeyDone;
	destTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	destTextField.text = @"WdmfMessagingDestination";
	//destTextField.text = @"SimplePolliingDestination";
	destTextField.delegate = self;
	[self.view addSubview:destTextField];
	//[destTextField release];
	
    chatTextField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 5.0, 310.0, 30.0)];
	chatTextField.borderStyle = UITextBorderStyleRoundedRect;
	chatTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	chatTextField.placeholder = @"type a chat text here";
	chatTextField.returnKeyType = UIReturnKeyDone;
	chatTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	chatTextField.text = @"Hello, WebORB!";
	chatTextField.delegate = self;
    chatTextField.hidden = YES;
	[self.view addSubview:chatTextField];
	//[chatTextField release];
	
    subtopicTextField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 75.0, 153.0, 30.0)];
	subtopicTextField.borderStyle = UITextBorderStyleRoundedRect;
	subtopicTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	subtopicTextField.placeholder = @"subTopic";
	subtopicTextField.returnKeyType = UIReturnKeyDone;
	subtopicTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	subtopicTextField.delegate = self;
    subtopicTextField.hidden = YES;
	[self.view addSubview:subtopicTextField];
	//[subtopicTextField release];
	
    selectorTextField = [[UITextField alloc] initWithFrame:CGRectMake(162.0, 75.0, 153.0, 30.0)];
	selectorTextField.borderStyle = UITextBorderStyleRoundedRect;
	selectorTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	selectorTextField.placeholder = @"selector";
	selectorTextField.returnKeyType = UIReturnKeyDone;
	selectorTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	selectorTextField.delegate = self;
    selectorTextField.hidden = YES;
	[self.view addSubview:selectorTextField];
	//[selectorTextField release];
	
    chatTextView = [[UITextView alloc] initWithFrame:CGRectMake(5.0, 145.0, 310.0, 240.0)];
    chatTextView.backgroundColor = [UIColor lightGrayColor];
    chatTextView.editable = NO;
    chatTextView.hidden = YES;
	[self.view addSubview:chatTextView];
	//[chatTextView release];
	
	//buttons
	btnPublish = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnPublish.frame = CGRectMake(0.0, 0.0, 310.0, 30.0);
	btnPublish.center = CGPointMake(160.0, 55.0);
	btnPublish.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnPublish setTitle:@"Publish" forState:UIControlStateNormal];
    [btnPublish addTarget:self action:@selector(publish) forControlEvents:UIControlEventTouchUpInside];
    btnPublish.hidden = YES;
	[self.view addSubview:btnPublish];
    
	btnSubscribe = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnSubscribe.frame = CGRectMake(0.0, 0.0, 152.0, 30.0);
	btnSubscribe.center = CGPointMake(82.0, 125.0);
	btnSubscribe.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnSubscribe setTitle:@"Subscribe" forState:UIControlStateNormal];
    [btnSubscribe addTarget:self action:@selector(subscribe) forControlEvents:UIControlEventTouchUpInside];
    btnSubscribe.hidden = YES;
	[self.view addSubview:btnSubscribe];
    
	btnUnsubscribe = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnUnsubscribe.frame = CGRectMake(0.0, 0.0, 152.0, 30.0);
	btnUnsubscribe.center = CGPointMake(238.0, 125.0);
	btnUnsubscribe.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnUnsubscribe setTitle:@"Unsubscribe" forState:UIControlStateNormal];
    [btnUnsubscribe addTarget:self action:@selector(unsubscribe) forControlEvents:UIControlEventTouchUpInside];
    btnUnsubscribe.hidden = YES;
	[self.view addSubview:btnUnsubscribe];
    
	memoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(7.0, 385.0, 90.0, 25.0)];
	memoryLabel.text = [MemoryTicker showAvailableMemoryInKiloBytes];
	[self.view addSubview:memoryLabel];
	//[memoryLabel release];
    
    memoryTicker = [[MemoryTicker alloc] initWithResponder:self andMethod:@selector(sizeMemory:)];
    memoryTicker.asNumber = YES;
	
    alerts = 100;
    
	// Do any additional setup after loading the view, typically from a nib.
}

-(void)dealloc {
    
    [self doDisconnect:nil];
    //[memoryTicker release];
	
    //[super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
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
    
    if (textField == chatTextField) 
        [self publish];
    
	[textField resignFirstResponder];
	return YES;
}

@end
