//
//  ViewController.m
//  HttpRemoting
//
//  Created by Vyacheslav Vdovichenko on 7/29/11.
//  Copyright 2011 The Midnight Coders, Inc. All rights reserved.
//

#import "ViewController.h"
#import "Responder.h"

// TEST CLASSES - Custom Client Classes

#pragma mark -
#pragma mark Test Classes 


typedef enum eye_color EyeColorEnum;
enum eye_color
{
    Blue, Brown, Green, Transparent, Red
};

@interface Identity : NSObject {
    NSString    __weak *name;
    NSNumber    __weak *age;
    NSString    __weak *sex;
    NSString    __weak *eyeColor;
    //
    EyeColorEnum eyeColorEnum;
}
@property (nonatomic, weak) NSString *name;
@property (nonatomic, weak) NSNumber *age;
@property (nonatomic, weak) NSString *sex;
@property (nonatomic, weak) NSString *eyeColor;
@end

 
@implementation Identity
@synthesize name, age, sex, eyeColor;

-(id)init {	
	if ( (self=[super init]) ) {
        name = nil;
        age = nil;
        sex = nil;
        eyeColor = nil;
        eyeColorEnum = 0;
	}
	
	return self;
}

@end

@interface Weather : NSObject {
    NSNumber    __weak *Temperature;
    NSString    __weak *Condition;
}
@property (nonatomic, weak) NSNumber *Temperature;
@property (nonatomic, weak) NSString *Condition;
@end

@implementation Weather
@synthesize Temperature, Condition;

-(id)init {	
	if ( (self=[super init]) ) {
        Temperature = nil;
        Condition = nil;
	}
	
	return self;
}

@end


@implementation ViewController

#pragma mark -
#pragma mark Private Methods 

-(void)showAlert:(NSString *)message {
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Receive" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
	alerts++;
	av.tag = alerts;
    [av show];
}

// ERRORS

-(void)errorHandler:(Fault *)fault {
    
    NSString *error = [NSString stringWithFormat:@"errorHandler:\nmessage:\n%@\ndetail:\n%@", fault.message,fault.detail];
    [self showAlert:error];
    
    NSLog(@"errorHandler: %@", error);  
}

// CALLBACKS

-(void)onCalculate:(id)response {
    
    NSString *message = [NSString stringWithFormat:@"onCalculate:\n%@\n\n", response];
    [self showAlert:message];
    
    NSLog(@"onCalculate = %@", message);    
}

-(void)onGetCustomers:(id)response {
    
    NSString *message = [NSString stringWithFormat:@"onGetCustomers:\n%@\n\n", response];
    [self showAlert:message];
    
    NSLog(@"onGetCustomers = %@", message);    
}

-(void)onHideIdentity:(id)response {
    
    Identity *obj = (Identity *)response;
    NSString *message = [NSString stringWithFormat:@"onHideIdentity:\nname=%@, age=%@, sex=%@, eyeColor=%@\n\n", obj.name, obj.age, obj.sex, obj.eyeColor];
    [self showAlert:message];
    
    NSLog(@"onHideIdentity = %@", message);    
}

-(void)onGetWeather:(id)response {
    
    Weather *obj = (Weather *)response;
    NSString *message = [NSString stringWithFormat:@"onGetWeather:\nTemperature=%@, Condition=%@\n\n", obj.Temperature, obj.Condition];
    [self showAlert:message];
    
    NSLog(@"onGetWeather = %@", message);    
}

// INVOKE

-(void)calculate {	
	
	printf(" SEND ----> calculate\n");
    
    service = @"Weborb.Examples.BasicService";   
	method = @"Calculate";   //
    //service = [NSString stringWithString:@"weborb.examples.BasicService"];   
	//method = [NSString stringWithString:@"Calculate"];
    //
    args = [NSMutableArray array];
	[args addObject:[NSNumber numberWithInt:4]];
	[args addObject:[NSNumber numberWithInt:2]];
	[args addObject:[NSNumber numberWithInt:1]];
    //
    Responder *responder = [Responder responder:self selResponseHandler:@selector(onCalculate:) selErrorHandler:@selector(errorHandler:)];
	[client invoke:service method:method args:args responder:responder];
}

-(void)getCustomers {	
	
	printf(" SEND ----> getCustomers\n");
 	
    service = @"Weborb.Examples.DataBinding";
	method = @"getCustomers";
 	//
    //service = [NSString stringWithString:@"weborb.examples.DataBinding"];   
	//method = [NSString stringWithString:@"getCustomers"];
	//
    args = nil;
    //
    Responder *responder = [Responder responder:self selResponseHandler:@selector(onGetCustomers:) selErrorHandler:@selector(errorHandler:)];
    [client invoke:service method:method args:args responder:responder];
}

-(void)hideIdentity {	
	
	printf(" SEND ----> hideIdentity\n");
    
    service = @"Weborb.Examples.IdentityService";
    method = @"HideIdentity";
    // set the mapping of the custom client class to the server type
    [client setClientClass:[Identity class] forServerType:@"Weborb.Examples.Identity"];
    //
    //service = [NSString stringWithString:@"weborb.examples.IdentityService"];   
    //method = [NSString stringWithString:@"HideIdentity"];
    // set the mapping of the custom client class to the server type
    //[client setClientClass:[Identity class] forServerType:@"weborb.examples.Identity"];
    //
    args = [NSMutableArray array];
    Identity *obj = [[Identity alloc] init];
    obj.name = @"John Lennon is the best!";
    obj.age = [NSNumber numberWithInt:40];
    obj.sex = @"real man";
    obj.eyeColor = @"Blue";
    [args addObject:obj];
    //
    Responder *responder = [Responder responder:self selResponseHandler:@selector(onHideIdentity:) selErrorHandler:@selector(errorHandler:)];
    [client invoke:service method:method args:args responder:responder];
}

-(void)getWeather {	
	
	printf(" SEND ----> getWeather\n");
    
    service = @"Weborb.Examples.WeatherService";
    method = @"GetWeather";
    // set the mapping of the custom client class to the server type
    [client setClientClass:[Weather class] forServerType:@"Weborb.Examples.Weather"];
    //
    //service = [NSString stringWithString:@"weborb.examples.WeatherService"];   
    //method = [NSString stringWithString:@"GetWeather"];
    // set the mapping of the custom client class to the server type
    //[client setClientClass:[Weather class] forServerType:@"weborb.examples.Weather"];
    //
    args = [NSMutableArray array];
    [args addObject:@"What's about weather?"];    //
    Responder *responder = [Responder responder:self selResponseHandler:@selector(onGetWeather:) selErrorHandler:@selector(errorHandler:)];
    [client invoke:service method:method args:args responder:responder];
}

// ACTIONS

-(void)doInfo {
    
    infoImage.hidden = (infoImage.hidden)?NO:YES;
    [btnInfo setTitle:(infoImage.hidden)?@"Info":@"Close" forState:UIControlStateNormal];
    
    BOOL active = (infoImage.hidden)?NO:YES;
    hostTextField.hidden = active;
    btnCalculate.hidden = active;
    btnGetCustomers.hidden = active;
    btnHideIdentity.hidden = active;
    btnGetWeather.hidden = active;
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
	// Do any additional setup after loading the view, typically from a nib.
	//
	self.title = @"HttpRemoting";
	
	// textFields
	hostTextField = [[UITextField alloc] initWithFrame:CGRectMake(5.0, 10.0, 310.0, 30.0)];
	hostTextField.borderStyle = UITextBorderStyleRoundedRect;
	hostTextField.autocorrectionType = UITextAutocorrectionTypeNo;
	hostTextField.placeholder = @"application URL";
    hostTextField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
	hostTextField.returnKeyType = UIReturnKeyDone;
	hostTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	hostTextField.text = @"http://examples.themidnightcoders.com/weborb.aspx";
	//hostTextField.text = @"http://localhost:8080/weborb.wo";
	hostTextField.delegate = self;
	[self.view addSubview:hostTextField];
	//[hostTextField release];
	
	//buttons
	btnCalculate = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnCalculate.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnCalculate.center = CGPointMake(160.0, 75.0);
	btnCalculate.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnCalculate setTitle:@"Calculate (4 - 1)" forState:UIControlStateNormal];
    [btnCalculate addTarget:self action:@selector(calculate) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnCalculate];
    
	btnGetCustomers = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnGetCustomers.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnGetCustomers.center = CGPointMake(160.0, 120.0);
	btnGetCustomers.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnGetCustomers setTitle:@"GetCustomers" forState:UIControlStateNormal];
    [btnGetCustomers addTarget:self action:@selector(getCustomers) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnGetCustomers];
	
	btnHideIdentity = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnHideIdentity.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnHideIdentity.center = CGPointMake(160.0, 165.0);
	btnHideIdentity.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnHideIdentity setTitle:@"HideIdentity" forState:UIControlStateNormal];
    [btnHideIdentity addTarget:self action:@selector(hideIdentity) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnHideIdentity];
	
	btnGetWeather = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	btnGetWeather.frame = CGRectMake(0.0, 0.0, 300.0, 30.0);
	btnGetWeather.center = CGPointMake(160.0, 210.0);
	btnGetWeather.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    [btnGetWeather setTitle:@"GetWeather" forState:UIControlStateNormal];
    [btnGetWeather addTarget:self action:@selector(getWeather) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:btnGetWeather];
    
	// images
    infoImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"weborb.png"]];
    infoImage.center = CGPointMake(160.0, 200.0);
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
    
	alerts = 100;
    NSString *url = [NSString stringWithString:hostTextField.text];
    client = [[WeborbClient alloc] initWithUrl:url];
    NSLog(@" <INIT> Client of application %@", url);
}

/*/
-(void)dealloc {		
	
	NSLog(@"ViewController DEALLOC >>>>>");
    
    [client release];
	
	[super dealloc];
}
/*/

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

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)index {
	//[alertView release];	
}

#pragma mark -
#pragma mark UITextFieldDelegate Methods 

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    
    //[client release];
    client = [[WeborbClient alloc] initWithUrl:hostTextField.text];
    NSLog(@" <CHANGE> Client of application %@", hostTextField.text);
    
	[textField resignFirstResponder];
	return YES;
}

@end
