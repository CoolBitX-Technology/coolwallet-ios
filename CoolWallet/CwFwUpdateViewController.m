//
//  CwFwUpdateViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2015/4/17.
//  Copyright (c) 2015年 CP Hsiao. All rights reserved.
//

#import "CwFwUpdateViewController.h"
#import "CwManager.h"

@interface CwFwUpdateViewController () <CwManagerDelegate, CwCardDelegate>
@property CwManager *cwManager;

@property (weak, nonatomic) IBOutlet UILabel *lblFwInfo;
@property (weak, nonatomic) IBOutlet UILabel *lblProgress;
@property (weak, nonatomic) IBOutlet UIProgressView *prgFwUpdate;
@property (weak, nonatomic) IBOutlet UITextField *txtBlOtp;

@property NSString *blOtp;
@property NSString *fwHexURL;

- (IBAction)btnUpdateFw:(id)sender;
- (IBAction)btnResetSe:(id)sender;
- (IBAction)btnBackTo7816Loader:(id)sender;


@end

@implementation CwFwUpdateViewController


- (NSData *) HTTPRequestUsingPostMethodFrom:(NSString*)url Data:(NSString*)postData
{
    NSError *err;
    NSURLResponse *response;
    
    NSString *urlStr = [NSString stringWithFormat:@"%@", url];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    [request setHTTPBody:[postData dataUsingEncoding:NSUTF8StringEncoding]];
    [request setHTTPMethod:@"POST"];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
    
    return data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    //find CW via BLE
    self.cwManager = [CwManager sharedManager];
    
    //get firnware info from the server
    self.lblFwInfo.text = @"";
    //get json from the web: http://60.250.111.124/CoolWalletFirmware.php
    NSString *fwUrl=@"http://60.250.111.124/CoolWalletFirmware.php";
    NSData *fwData = [self HTTPRequestUsingPostMethodFrom: fwUrl Data: nil];
    
    NSError *error;
    
    NSDictionary *JSON =[NSJSONSerialization JSONObjectWithData:fwData options:0 error:&error];
    
    self.blOtp = JSON[@"FirmwareOtp"];
    self.fwHexURL = JSON[@"FirmwareFile"];
    
    NSString *fwInfo = [NSString stringWithFormat:@"Version: %@\nDate: %@\nURL: %@\nBLOTP: %@", JSON[@"FirmwareVersion"], JSON[@"FirmwareDate"], JSON[@"FirmwareFile"], JSON[@"FirmwareOtp"]];
    
    self.lblFwInfo.text = fwInfo;
    
}

- (void) viewWillAppear:(BOOL)animated
{
    self.cwManager.delegate = self;
    self.cwManager.connectedCwCard.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma marks Actions

- (IBAction)btnUpdateFw:(id)sender {
    //download files from server
    NSData *fwHex = [NSData dataWithContentsOfURL: [NSURL URLWithString:self.fwHexURL]];
    
    if (fwHex==nil) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Firmware Update",nil)
                                                       message: NSLocalizedString(@"Can't find firmware",nil)
                                                      delegate: nil
                                             cancelButtonTitle: nil
                                             otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
        [alert show];
        return;
    }
    
    //update progress bar
    self.lblProgress.hidden=NO;
    
    NSNumber *prog = [[NSNumber alloc] initWithFloat:0.0];
    [NSThread detachNewThreadSelector:@selector(updateProgress:) toTarget:self withObject:prog];
    
    [self.cwManager.connectedCwCard updateFirmwareWithOtp:self.blOtp HexData:fwHex];
}

- (IBAction)btnResetSe:(id)sender {
    
    [self.cwManager.connectedCwCard resetSe];
    
}

- (IBAction)btnBackTo7816Loader:(id)sender {
    [self.cwManager.connectedCwCard backToLoader: self.txtBlOtp.text];
    [self.cwManager.connectedCwCard backTo7816FromLoader];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma marks Update Firmware Delegates

-(void) didCwCardCommandError:(NSInteger)cmdId ErrString:(NSString *)errString
{
    NSString *msg = [NSString stringWithFormat:NSLocalizedString(@"Cmd %02lX %@",nil), (long)cmdId, errString];
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Command Error",nil)
                                                   message: msg
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
    
    [alert show];
}

-(void) updateProgress: (NSNumber *)prog
{
    self.prgFwUpdate.progress= prog.floatValue;
    self.lblProgress.text = [NSString stringWithFormat:@"%4.2f%%", prog.floatValue*100 ];
    
}

-(void) didUpdateFirmwareProgress: (float)progress
{
    //update firmware
    //self.prgFwUpdate.hidden=NO;
    
    //update progress bar
    NSNumber *prog = [[NSNumber alloc] initWithFloat:progress];
    [NSThread detachNewThreadSelector:@selector(updateProgress:) toTarget:self withObject:prog];
}

-(void) didBackToSLE97Loader
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Back To SLE97 Loader",nil)
                                                   message: NSLocalizedString(@"Success",nil)
                                                  delegate: self
                                         cancelButtonTitle: nil
                                         otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
    [alert show];
}

-(void) didMcuResetSe
{
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"CW Reset SE",nil)
                                                   message: NSLocalizedString(@"Success",nil)
                                                  delegate: self
                                         cancelButtonTitle: nil
                                         otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
    [alert show];
}

-(void) didUpdateFirmwareDone: (NSInteger)status
{
    /*
     CwFwUpdateStatusSuccess = 0x00,
     CwFwUpdateStatusAuthFail = 0x01,
     CwFwUpdateStatusUpdateFail = 0x02,
     CwFwUpdateStatusCheckFail = 0x03,
     */
    
    //update progress bar
    NSNumber *prog = [[NSNumber alloc] initWithFloat:1.0];
    [NSThread detachNewThreadSelector:@selector(updateProgress:) toTarget:self withObject:prog];
    
    self.lblProgress.hidden=YES;
    
    switch (status) {
        case CwFwUpdateStatusSuccess:
            break;
            
        case CwFwUpdateStatusAuthFail:
            break;
            
        case CwFwUpdateStatusUpdateFail:
            break;
            
        case CwFwUpdateStatusCheckFail:
            break;
    }
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ Disconnected",nil), cardName];
    notify.soundName = UILocalNotificationDefaultSoundName;
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
