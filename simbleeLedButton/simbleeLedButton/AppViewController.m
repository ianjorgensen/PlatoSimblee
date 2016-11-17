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
#include "Util.h"

#import <QuartzCore/QuartzCore.h>

#import "UIAlertViewBlock.h"

#import "AppDelegate.h"
#import "OTABootloaderViewController.h"
#import "AppViewController.h"

@interface AppViewController ()
{
    AppDelegate *appDelegate;
    bool lockState;
    UIBarButtonItem *disconnectItem;
    UIBarButtonItem *lockItem;
    UIBarButtonItem *unlockItem;
    IBOutlet UIView *OpenMode;
    IBOutlet UIView *CloseMode;
    IBOutlet UILabel *openCountdownLabel;
    IBOutlet UILabel *zoomModeCurrentLabel;
    
    IBOutlet UILabel *createModeCurrentLabel;
    IBOutlet UILabel *anodeZoomModeLabel;
    IBOutlet UILabel *cathodeZoomModeLabel;
    IBOutlet UILabel *anodeCreateModeLabel;
    IBOutlet UILabel *cathodeCreateModeLabel;
    IBOutlet UILabel *clockCountdownCreateLabel;
    IBOutlet UILabel *clockCountdownZoomLabel;
}
@end

@implementation AppViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        appDelegate = [[UIApplication sharedApplication] delegate];
        
        [appDelegate appViewController:self lockState:&lockState];
        
        self.navigationItem.hidesBackButton = YES;
        
        UIImage *leftImage = [UIImage imageNamed:@"disconnect.png"];
        disconnectItem = [[UIBarButtonItem alloc] initWithImage:leftImage
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(disconnect:)];
        
        UIImage *lockImage = [UIImage imageNamed:@"lock.png"];
        lockItem = [[UIBarButtonItem alloc] initWithImage:lockImage
                                                    style:UIBarButtonItemStylePlain
                                                   target:self
                                                   action:@selector(unlock:)];
        
        UIImage *unlockImage = [UIImage imageNamed:@"unlock.png"];
        unlockItem = [[UIBarButtonItem alloc] initWithImage:unlockImage
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(lock:)];
        
        [[self navigationItem] setLeftBarButtonItem:(lockState ? nil : disconnectItem)];
        [[self navigationItem] setTitle:@"Plato Aplha 3"];
        [[self navigationItem] setRightBarButtonItem:(lockState ? lockItem : unlockItem)];
        
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
    }

    return self;
}

- (void)iPhone5PortraitLayout
{
    label1.frame = CGRectMake(51,100,218,84);
    button1.frame = CGRectMake(124,192,73,44);
    
    label2.frame = CGRectMake(51,319,218,84);
    image1.frame = CGRectMake(123,411,75,75);
}

- (void)iPhone5LandscapeLayout
{
    label1.frame = CGRectMake(20,65,218,84);
    button1.frame = CGRectMake(93,173,73,44);
    
    label2.frame = CGRectMake(330,65,218,84);
    image1.frame = CGRectMake(402,157,75,75);
}

- (void)iPhone4SPortraitLayout
{
    label1.frame = CGRectMake(51,84,218,84);
    button1.frame = CGRectMake(124,176,73,44);
    
    label2.frame = CGRectMake(51,261,218,84);
    image1.frame = CGRectMake(123,353,75,75);
}

- (void)iPhone4SLandscapeLayout
{
    label1.frame = CGRectMake(20,75,218,84);
    button1.frame = CGRectMake(93,183,73,44);
    
    label2.frame = CGRectMake(262,75,218,84);
    image1.frame = CGRectMake(334,167,75,75);
}

- (void)iPadPortraitLayout
{
    label1.frame = CGRectMake(91,218,587,28);
    button1.frame = CGRectMake(343,262,73,44);
    
    label2.frame = CGRectMake(113,668,543,38);
    image1.frame = CGRectMake(347,714,75,75);
}

- (void)iPadLandscapeLayout
{
    label1.frame = CGRectMake(224,164,587,28);
    button1.frame = CGRectMake(476,208,73,44);
    
    label2.frame = CGRectMake(241,482,543,38);
    image1.frame = CGRectMake(475,528,75,75);
}

- (bool)isLandscape
{
    UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
    return (statusBarOrientation == UIInterfaceOrientationLandscapeLeft || statusBarOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)manualLayout
{
    CGRect rect = [[UIScreen mainScreen] bounds];
    
    if ([self isLandscape]) {
        if (rect.size.width >= 1024) {
            [self iPadLandscapeLayout];
        } else if (rect.size.width >= 568) {
            [self iPhone5LandscapeLayout];
        } else {
            [self iPhone4SLandscapeLayout];
        }
    } else {
        if (rect.size.height >= 1024) {
            [self iPadPortraitLayout];
        } else if (rect.size.height >= 568) {
            [self iPhone5PortraitLayout];
        } else {
            [self iPhone4SPortraitLayout];
        }
    }
}

- (void)viewDidLayoutSubviews {
    [self manualLayout];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self manualLayout];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
 
    _simblee.delegate = self;

    /*
    UIColor *start = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.15];
    UIColor *stop = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.45];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    //gradient.frame = [self.view bounds];
    gradient.frame = CGRectMake(0.0, 0.0, 1024.0, 1024.0);
    gradient.colors = [NSArray arrayWithObjects:(id)start.CGColor, (id)stop.CGColor, nil];
    [self.view.layer insertSublayer:gradient atIndex:0];
    */
    
    off = [UIImage imageNamed:@"off.jpg"];
    on = [UIImage imageNamed:@"on.jpg"];

    // via Simblee advertisementData, services or connectedService
    NSString *data = [[NSString alloc] initWithData:_simblee.advertisementData encoding:NSUTF8StringEncoding];

    // update is not available if the ledbtn sketch is used without OTA
    if (![data isEqualToString:@""] && ![data hasPrefix:@"Alpha 3"]) {
        // only offer upgrade if they are not using a version 2 sketch
        // (version 2, is the LedBtnWithOTABootloader sketch, with a blue led instead of green)
        UIAlertViewBlock *alert = [[UIAlertViewBlock alloc]
                                   initWithTitle:@"Update available"
                                                message:@"Would you like to install the update?"
                                                  block:^(NSInteger buttonIndex) {
                                                      if (buttonIndex == 1)
                                                          [self startOTABootloader];
                                                  }
                                      cancelButtonTitle:@"No"
                                      otherButtonTitles:@"Yes", nil];
            [alert show];
    }
}

- (void)startOTABootloader {
    DLog(@"startOTABootloader");
    
    OTABootloaderViewController *viewController = [[OTABootloaderViewController alloc] init];
    viewController.simblee = _simblee;
    [[self navigationController] pushViewController:viewController animated:true];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)disconnect:(id)sender
{
    DLog(@"");
    //[appDelegate appViewController:self disconnectSimblee:_simblee];
}

- (IBAction)lock:(id)sender
{
    DLog(@"");
    [appDelegate appViewController:self lockSimblee:_simblee];
    lockState = true;
    [[self navigationItem] setLeftBarButtonItem:(lockState ? nil : disconnectItem)];
    [[self navigationItem] setRightBarButtonItem:(lockState ? lockItem : unlockItem)];
}

- (IBAction)unlock:(id)sender
{
    DLog(@"");
    [appDelegate appViewController:self unlockSimblee:_simblee];
    lockState = false;
    [[self navigationItem] setLeftBarButtonItem:(lockState ? nil : disconnectItem)];
    [[self navigationItem] setRightBarButtonItem:(lockState ? lockItem : unlockItem)];
}

#pragma mark - SimbleeDelegate methods

- (void)didConnectSimblee:(Simblee *)simblee
{
    [appDelegate appViewController:self didConnectSimblee:simblee];
}

- (void)didNotConnectSimblee:(Simblee *)simblee
{
    [appDelegate appViewController:self didNotConnectSimblee:simblee];
}

- (void)didLooseConnectSimblee:(Simblee *)simblee
{
    [appDelegate appViewController:self didLooseConnectSimblee:simblee];
}

- (void)didDisconnectSimblee:(Simblee *)simblee
{
    [appDelegate appViewController:self didDisconnectSimblee:simblee];
}

- (void)sendByte:(uint8_t)byte
{
    uint8_t tx[1] = { byte };
    NSData *data = [NSData dataWithBytes:(void*)&tx length:1];
    [_simblee send:data];
}
- (IBAction)closemodecancel:(id)sender {
    [self sendByte:0];
    [CloseMode removeFromSuperview];
}
- (IBAction)openmodecancel:(id)sender {
    [self sendByte:1];
    [OpenMode removeFromSuperview];
}
- (IBAction)closeModeStart:(id)sender {
    [self sendByte:0];
    [self.view addSubview : CloseMode];

    [openCountdownLabel setText:@"00:00"];

    DLog(@"Button pressed");
}
- (IBAction)openModeStart:(id)sender {
    [self sendByte:1];
    [self.view addSubview : OpenMode];
    [openCountdownLabel setText:@"00:00"];
}

- (IBAction)buttonTouchDown:(id)sender
{
    DLog(@"Button pressed");
}

- (IBAction)buttonTouchUpInside:(id)sender
{
    DLog(@"");
}

- (void)didReceive:(NSData *)data
{
    DLog(@"");
    
    
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    if (dataString == nil) {
        return;
    }
    
    NSArray *array = [dataString componentsSeparatedByString:@","];
    
    float x = [array[0] floatValue];
    
    if (x > 0) {
        NSString *currentString = [NSString stringWithFormat:@"%0.2f:1.30 %@", x/100, @"ma"];
        createModeCurrentLabel.text = currentString;
        zoomModeCurrentLabel.text = currentString;
    } else {
        createModeCurrentLabel.text = @"";
        zoomModeCurrentLabel.text = @"";
    }
    
    NSArray *electrodes = @[@"F3", @"F4", @"Pz"];
    
    anodeZoomModeLabel.text = electrodes[[array[1] intValue]];
    cathodeZoomModeLabel.text = electrodes[[array[2] intValue]];
    
    anodeCreateModeLabel.text = electrodes[[array[1] intValue]];
    cathodeCreateModeLabel.text = electrodes[[array[2] intValue]];
    
    int arraySize = [array count];
    
    if(arraySize == 6) {
        clockCountdownZoomLabel.text = array[5];
        clockCountdownCreateLabel.text = array[5];
    }
    
    
    // 0: no stimuli  1: zoom , 2: create
    int stimuliInProgress = [array[3] intValue];
    int stimuliState = [array[4] intValue];
    
    if (stimuliInProgress == 0) {
        [OpenMode removeFromSuperview];
        [CloseMode removeFromSuperview];
    }
    
    if (stimuliInProgress == 1 && stimuliState == 1) {
        [self.view addSubview : CloseMode];
    }
    
    if (stimuliInProgress == 1 && stimuliState == 2) {
        [self.view addSubview : OpenMode];
    }
}

@end
