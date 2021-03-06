/*
 * Copyright (c) 2015 RF Digital Corp. All Rights Reserved.
 *
 * The source code contained in this file and all intellectual property embodied in
 * or covering the source code is the property of RF Digital Corp. or its licensors.
 * Your right to use this source code and intellectual property is non-transferable,
 * non-sub licensable, revocable, and subject to terms and conditions of the
 * SIMBLEE SOFTWARE LICENSE AGREEMENT.
 * http://www.simblee.com/licenses/SimbleeSoftwareLicenseAgreement.txt
 *
 * THE SOURCE CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.
 *
 * This heading must NOT be removed from this file.
 */

#include "DLog.h"

#import "UIAlertViewBlock.h"
#import "SimbleeManager.h"
#import "DFUHelper.h"
#import "UnzipFirmware.h"
#import "OTABootloaderViewController.h"

#import "AppDelegate.h"

@interface OTABootloaderViewController ()
{
    id previousPeripheralDelegate;
    id previousCentralManagerDelegate;
}

@property(strong, nonatomic) DFUOperations *dfuOperations;
@property (strong, nonatomic) DFUHelper *dfuHelper;

@property BOOL isTransferring;
@property BOOL isTransfered;
@property BOOL isTransferCancelled;
@property BOOL isConnected;
@property BOOL isErrorKnown;

@end

@implementation OTABootloaderViewController

+ (NSURL *)hexFileURL
{
    NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resourcePath error:nil];
    for (NSString *file in contents) {
        if ([file hasSuffix:@".hex"]) {
            DLog(@"application: %@", file);
            return [[NSBundle mainBundle] URLForResource:file withExtension:nil];
        }
    }
    return nil;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //PACKETS_NOTIFICATION_INTERVAL = [[[NSUserDefaults standardUserDefaults] valueForKey:@"dfu_number_of_packets"] intValue];
        DLog(@"PACKETS_NOTIFICATION_INTERVAL %d",PACKETS_NOTIFICATION_INTERVAL);
        
        /*
        // Custom initialization
        UIButton *backButton = [UIButton buttonWithType:101];  // left-pointing shape
        [backButton setTitle:@"Disconnect" forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(disconnect:) forControlEvents:UIControlEventTouchUpInside];
        
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithCustomView:backButton];
        [[self navigationItem] setLeftBarButtonItem:backItem];
         */
        [[self navigationItem] setHidesBackButton:YES];
        
        [[self navigationItem] setTitle:@"OTA Bootloader"];
        
        _dfuOperations = [[DFUOperations alloc] initWithDelegate:self];
        _dfuHelper = [[DFUHelper alloc] initWithData:_dfuOperations];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    UIColor *start = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.15];
    UIColor *stop = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.45];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    //gradient.frame = [self.view bounds];
    gradient.frame = CGRectMake(0.0, 0.0, 1024.0, 1024.0);
    gradient.colors = @[(id)start.CGColor, (id)stop.CGColor];
    [self.view.layer insertSublayer:gradient atIndex:0];

    // increase width
    [progress setTransform:CGAffineTransformMakeScale(1.0, 3.0)];

    previousPeripheralDelegate = _simblee.peripheral.delegate;
    
    CBCentralManager *central = _simblee.simbleeManager.central;
    previousCentralManagerDelegate = central.delegate;
    [_dfuOperations setCentralManager:_simblee.simbleeManager.central];

    [self clearUI];
    self.dfuHelper.applicationURL = [OTABootloaderViewController hexFileURL];
    [self performDFU];
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:YES];
    //if DFU peripheral is connected and user press Back button then disconnect it
    if (/*[self isMovingFromParentViewController] &&*/ self.isConnected) {
        // DLog(@"isMovingFromParentViewController");
        [_dfuOperations cancelDFU];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)appDidEnterBackground:(NSNotification *)_notification
{
    DLog();
    if (self.isConnected && self.isTransferring) {
        //[Utility showBackgroundNotification:[self.dfuHelper getUploadStatusMessage]];
    }
}

-(void)appDidEnterForeground:(NSNotification *)_notification
{
    DLog();
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

- (void)clearUI
{
    progress.progress = 0.0f;
    // progress.hidden = YES;
    progressLabel.text = @"0%";
    // progressLabel.hidden = YES;
    uploadStatus.text = @"waiting ...";
    // uploadStatus.hidden = YES;
    activityIndicator.hidden = YES;
    [uploadButton setTitle:@"Upload" forState:UIControlStateNormal];
    uploadButton.enabled = YES;
    [self enableOtherButtons];
}

-(void)enableUploadButton
{
    uploadButton.enabled = YES;
}

-(void)enableOtherButtons
{
}

-(void)disableOtherButtons
{
}

- (IBAction)uploadPressed:(id)sender
{
    DLog();
    if (self.isTransferring) {
        [_dfuOperations cancelDFU];
    }
    else {
        [self performDFU];
    }
}

-(void)performDFU
{
    DLog();

    dispatch_async(dispatch_get_main_queue(), ^{
        [self disableOtherButtons];
        progress.hidden = NO;
        progressLabel.hidden = NO;
        uploadStatus.hidden = NO;
        activityIndicator.hidden = NO;
        uploadButton.enabled = NO;
    });

    // [self.dfuHelper checkAndPerformDFU];

    if (! self.isConnected) {
        uploadStatus.text = @"connecting...";
        [_dfuOperations connectDevice:_simblee.peripheral];
    } else {
        uploadStatus.text = @"starting...";
        [_dfuOperations performDFUOnFile:self.dfuHelper.applicationURL firmwareType:APPLICATION];
    }
}

#pragma mark DFUOperations delegate methods

-(void)onDeviceConnected:(CBPeripheral *)peripheral
{
    DLog(@"%@",peripheral.name);

    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = NO;
    // [self enableUploadButton];
    [self performDFU];
    //Following if condition display user permission alert for background notification
    /*
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)onDeviceConnectedWithVersion:(CBPeripheral *)peripheral
{
    DLog(@"%@",peripheral.name);

    self.isConnected = YES;
    self.dfuHelper.isDfuVersionExist = YES;
    // [self enableUploadButton];
    [self performDFU];
    //Following if condition display user permission alert for background notification
    /*
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeSound categories:nil]];
    }
    */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterForeground:) name:UIApplicationDidBecomeActiveNotification object:nil];
}

-(void)onDeviceDisconnected:(CBPeripheral *)peripheral
{
    DLog(@"%@",peripheral.name);

    self.isTransferring = NO;
    self.isConnected = NO;
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.dfuHelper.dfuVersion != 1) {
            [self clearUI];
            
            if (!self.isTransfered && !self.isTransferCancelled && !self.isErrorKnown) {
                if ([Utility isApplicationStateInactiveORBackground]) {
                    [Utility showBackgroundNotification:[NSString stringWithFormat:@"%@ peripheral is disconnected.",peripheral.name]];
                }
                else {
                    [Utility showAlert:@"The connection has been lost"];
                }
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
                [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
            }
            
            self.isTransferCancelled = NO;
            self.isTransfered = NO;
            self.isErrorKnown = NO;
        }
        else {
            double delayInSeconds = 3.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [_dfuOperations connectDevice:peripheral];
            });
        }
    });
}

-(void)onReadDFUVersion:(int)version
{
    DLog(@"%d",version);
    
    self.dfuHelper.dfuVersion = version;
    DLog(@"DFU Version: %d",self.dfuHelper.dfuVersion);
    if (self.dfuHelper.dfuVersion == 1) {
        [_dfuOperations setAppToBootloaderMode];
    }
    // [self enableUploadButton];
}

-(void)onDFUStarted
{
    DLog();

    self.isTransferring = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [uploadButton setTitle:@"Cancel" forState:UIControlStateNormal];
        uploadButton.enabled = YES;
        NSString *uploadStatusMessage = [self.dfuHelper getUploadStatusMessage];
        if ([Utility isApplicationStateInactiveORBackground]) {
            [Utility showBackgroundNotification:uploadStatusMessage];
        }
        else {
            uploadStatus.text = uploadStatusMessage;
        }
    });
}

-(void)onDFUCancelled
{
    DLog();

    self.isTransferring = NO;
    self.isTransferCancelled = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self enableOtherButtons];
    });
}

-(void)onSoftDeviceUploadStarted
{
    DLog();
}

-(void)onSoftDeviceUploadCompleted
{
    DLog();
}

-(void)onBootloaderUploadStarted
{
    DLog();

    dispatch_async(dispatch_get_main_queue(), ^{
        if ([Utility isApplicationStateInactiveORBackground]) {
            [Utility showBackgroundNotification:@"uploading bootloader ..."];
        }
        else {
            uploadStatus.text = @"uploading bootloader ...";
        }
    });
}

-(void)onBootloaderUploadCompleted
{
    DLog();
}

-(void)onTransferPercentage:(int)percentage
{
    DLog(@"%d",percentage);

    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        progressLabel.text = [NSString stringWithFormat:@"%d %%", percentage];
        [progress setProgress:((float)percentage/100.0) animated:YES];
    });
}

-(void)onSuccessfulFileTranferred
{
    DLog();

    // once a DFU is started:
    // [_dfuOperations canceDFU] should be called to abort
    // [_dfuOperations.dfuRequests activateAndReset] should be called to complete (the dual mode swap)

    // this delegate is called by [DFUOperations processValidateFirmwareResponseStatus]
    // which does the [_dfuOperations.dfuRequests activeAndReset] for us
    
    // calling [central cancelPeripheralConnection:simblee] creates a race condition:
    // - if the cancel completes before the activateAndReset, then the old dual mode app will be restored!
    
    // Scanner uses other queue to send events. We must edit UI in the main queue
    dispatch_async(dispatch_get_main_queue(), ^{
        self.isTransferring = NO;
        self.isTransfered = YES;
        NSString* message = [NSString stringWithFormat:@"%lu bytes transfered in %lu seconds", (unsigned long)_dfuOperations.binFileSize, (unsigned long)_dfuOperations.uploadTimeInSeconds];
        if ([Utility isApplicationStateInactiveORBackground]) {
            [Utility showBackgroundNotification:message];
        }
        else {
            // [Utility showAlert:message];
            UIAlertViewBlock *alert = [[UIAlertViewBlock alloc]
                                       initWithTitle:@"DFU"
                                       message:message
                                       block:^(NSInteger buttonIndex) {
                                           CBCentralManager *central = _simblee.simbleeManager.central;
                                           central.delegate = previousCentralManagerDelegate;

                                           _simblee.peripheral.delegate = previousPeripheralDelegate;
                                           
                                           AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];

                                           [appDelegate otaBootloaderViewController:self onSuccessfulFileTransferred:_simblee];
                                           
                                       }
                                       cancelButtonTitle:@"OK"
                                       otherButtonTitles:nil];
            [alert show];
        }
    });
}

-(void)onError:(NSString *)errorMessage
{
    DLog(@"%@",errorMessage);

    self.isErrorKnown = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [Utility showAlert:errorMessage];
        [self clearUI];
    });
}

@end
