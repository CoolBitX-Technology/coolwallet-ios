//
//  TabScanTransactionViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2015/1/23.
//  Copyright (c) 2015年 CP Hsiao. All rights reserved.
//

#import "TabScanTransactionViewController.h"
#import "BRPaymentRequest.h"
#import "CwManager.h"
#import "CwCard.h"

@interface TabScanTransactionViewController () <CwManagerDelegate, AVCaptureMetadataOutputObjectsDelegate>
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preview;

@end

CwManager *cwManager;
CwCard *cwCard;

@implementation TabScanTransactionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = YES;
    // Do any additional setup after loading the view.
    
    CwManager *cwManager = [CwManager sharedManager];
    cwCard = cwManager.connectedCwCard;

    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if (! device.hasTorch) self.toolbar.items = @[self.toolbar.items[0]];
    
    [self.toolbar setBackgroundImage:[UIImage new] forToolbarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    [self.toolbar setShadowImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] == AVAuthorizationStatusDenied) {
        [[[UIAlertView alloc]
          initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"%@ is not allowed to access the camera", nil),
                         nil]
          message:[NSString stringWithFormat:NSLocalizedString(@"\nallow camera access in\n"
                                                               "Settings->Privacy->Camera->%@", nil),
                   NSBundle.mainBundle.infoDictionary[@"CFBundleDisplayName"]] delegate:nil
          cancelButtonTitle:NSLocalizedString(@"ok", nil) otherButtonTitles:nil] show];
        return;
    }
    
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    AVCaptureMetadataOutput *output = [AVCaptureMetadataOutput new];
    
    if (error) NSLog(@"%@", [error localizedDescription]);
    
    if ([device lockForConfiguration:&error]) {
        if (device.isAutoFocusRangeRestrictionSupported) {
            device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNear;
        }
        
        if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
        }
        
        [device unlockForConfiguration];
    }
    
    self.session = [AVCaptureSession new];
    if (input) [self.session addInput:input];
    [self.session addOutput:output];
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    if ([output.availableMetadataObjectTypes containsObject:AVMetadataObjectTypeQRCode]) {
        output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode];
    }
    
    self.preview = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    self.preview.frame = self.view.layer.bounds;
    [self.cameraView.layer addSublayer:self.preview];
    
    dispatch_async(dispatch_queue_create("qrscanner", NULL), ^{
        [self.session startRunning];
    });
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self.session stopRunning];
    self.session = nil;
    [self.preview removeFromSuperlayer];
    self.preview = nil;
    
    [super viewDidDisappear:animated];
}

- (void)stop
{
    [self.session removeOutput:self.session.outputs.firstObject];
}

#pragma mark - IBAction

- (IBAction)flash:(id)sender
{
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    if ([device lockForConfiguration:&error]) {
        device.torchMode = device.torchActive ? AVCaptureTorchModeOff : AVCaptureTorchModeOn;
        [device unlockForConfiguration];
    }
}

- (IBAction)done:(id)sender
{
    //back to previous controller
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection
{
    for (AVMetadataMachineReadableCodeObject *o in metadataObjects) {
        if (! [o.type isEqual:AVMetadataObjectTypeQRCode]) continue;
        
        NSString *s = o.stringValue;

        self.cameraGuide.image = [UIImage imageNamed:@"cameraguide-green"];
        [self stop];
        
        NSLog(@"%@", s);
        
        //parse string in format: bitcoin:address?amount=???&label=???
        BRPaymentRequest *request = [BRPaymentRequest requestWithString:s];

        cwCard.paymentAddress = request.paymentAddress;
        cwCard.amount = request.amount;
        cwCard.label = request.label;

        NSLog(@"address: %@", request.paymentAddress);
        NSLog(@"amount: %lld", request.amount);
        NSLog(@"label: %@", request.label);
        
        //back to previous controller
        [self.navigationController popViewControllerAnimated:YES];
        break;
    }
}


#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:@"%@ Disconnected", cardName];
    notify.soundName = UILocalNotificationDefaultSoundName;
    notify.applicationIconBadgeNumber=1;
    [[UIApplication sharedApplication] presentLocalNotificationNow: notify];
    
    // Get the storyboard named secondStoryBoard from the main bundle:
    UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    // Load the view controller with the identifier string myTabBar
    // Change UIViewController to the appropriate class
    UIViewController *listCV = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:@"CwMain"];
    // Then push the new view controller in the usual way:
    [self.parentViewController presentViewController:listCV animated:YES completion:nil];
}

@end
