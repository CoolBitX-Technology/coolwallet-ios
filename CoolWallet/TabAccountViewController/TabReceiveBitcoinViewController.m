//
//  TabReceiveBitcoinViewController.m
//  CwTest
//
//  Created by CP Hsiao on 2014/12/27.
//  Copyright (c) 2014年 CP Hsiao. All rights reserved.
//

#import "TabReceiveBitcoinViewController.h"
#import "CwManager.h"
#import "CwCard.h"
#import "CwAccount.h"
#import "CwAddress.h"
#import "UIColor+CustomColors.h"
#import "OCAppCommon.h"

@interface TabReceiveBitcoinViewController ()  <CwManagerDelegate, CwCardDelegate, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *actBusyIndicator;
@property (weak, nonatomic) IBOutlet UILabel *lblKeyId;
@property (weak, nonatomic) IBOutlet UITextField *txtAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblBip32Path;
@property (weak, nonatomic) IBOutlet UITableView *tableAddressList;
@property (weak, nonatomic) IBOutlet UILabel *lblAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imgQRcode;

@property (strong, nonatomic) NSArray *accountButtons;

- (IBAction)btnNewAddress:(id)sender;

@end

CwCard *cwCard;
CwAccount *account;

NSInteger rowSelected = 0;
NSString *RequestBTC;
NSString *Label;

@implementation TabReceiveBitcoinViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //find CW via BLE
    cwCard = self.cwManager.connectedCwCard;
    //NSLog(@"currentAccountId = %ld",cwCard.currentAccountId);
    
    self.accountButtons = @[self.btnAccount1, self.btnAccount2, self.btnAccount3, self.btnAccount4, self.btnAccount5];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.actBusyIndicator.hidden=YES;
    
    self.txtAddress.delegate = self;
    cwCard.delegate = self;
    
    [self setAccountButton];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma marks - UITextFieldDelegate Delegates

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma marks - Actions

- (IBAction)btnNewAddress:(id)sender {
    if (![cwCard enableGenAddressWithAccountId:account.accId]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Can't create address"
                                                       message: nil
                                                      delegate: nil
                                             cancelButtonTitle: nil
                                             otherButtonTitles:@"OK",nil];
        [alert show];
        
        return;
    }
    
    self.actBusyIndicator.hidden = NO;
    [self.actBusyIndicator startAnimating];
    
    [cwCard genAddress: account.accId KeyChainId: CwAddressKeyChainExternal];
}

#pragma marks - Account Button Actions

- (void)setAccountButton{
    for(int i =0; i< [cwCard.cwAccounts count]; i++) {
        if(i == 0) {
            _btnAccount1.hidden = NO;
        }else if(i == 1) {
            _btnAccount2.hidden = NO;
        }else if(i == 2) {
            _btnAccount3.hidden = NO;
        }else if(i == 3) {
            _btnAccount4.hidden = NO;
        }else if(i == 4) {
            _btnAccount5.hidden = NO;
            _btnAccount5.enabled = YES;
            _btnAddAccount.hidden = YES;
        }
        
    }
    
    RequestBTC = nil;
    if([cwCard.cwAccounts count] == 1) {
        [_btnAccount1 sendActionsForControlEvents:UIControlEventTouchUpInside];
    }else{
        switch (cwCard.currentAccountId) {
            case 0:
                [_btnAccount1 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 1:
                [_btnAccount2 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 2:
                [_btnAccount3 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 3:
                [_btnAccount4 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            case 4:
                [_btnAccount5 sendActionsForControlEvents:UIControlEventTouchUpInside];
                break;
            default:
                break;
        }
    }
    
}

- (IBAction)btnAccount:(id)sender {
    NSInteger currentAccId = cwCard.currentAccountId;
    for (UIButton *btn in self.accountButtons) {
        if (sender == btn) {
            cwCard.currentAccountId = [self.accountButtons indexOfObject:btn];
            [btn setBackgroundColor:[UIColor colorAccountBackground]];
            [btn setSelected:YES];
        } else {
            [btn setBackgroundColor:[UIColor blackColor]];
            [btn setSelected:NO];
        }
    }
    
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", cwCard.currentAccountId]];
    
    if (currentAccId != cwCard.currentAccountId) {
        [self showIndicatorView:@"loading address..."];
        
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    
    if ([account.extKeys count] >0) {
        rowSelected = 0;
        
        [self didGetAccountAddresses:cwCard.currentAccountId];
        [self performSelectorOnMainThread:@selector(getCurrentAccountInfo) withObject:nil waitUntilDone:NO];
    } else {
        rowSelected = -1;
        
        [self getCurrentAccountInfo];
    }
    
    [self setQRcodeDataforkey:rowSelected];
    [_tableAddressList reloadData];
}

-(void) getCurrentAccountInfo
{
    [cwCard getAccountInfo:cwCard.currentAccountId];
}

#pragma marks - CwCard Delegates
-(void) didCwCardCommand
{
    NSLog(@"didCwCardCommand");
    [self.actBusyIndicator stopAnimating];
    self.actBusyIndicator.hidden = YES;
    
    [self.cwManager.connectedCwCard saveCwCardToFile];
}

-(void) didGenAddress: (CwAddress *) addr
{
    NSLog(@"didGenAddress");
    account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)account.accId]];

    /*
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"New Address Created"
                                                   message: nil
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
    */
    rowSelected = account.extKeyPointer-1;
    [self setQRcodeDataforkey:account.extKeyPointer-1];
    
    [_btnEditLabel sendActionsForControlEvents:UIControlEventTouchUpInside];
    //[cwCard getAccountAddresses: account.accId];
    [self.tableAddressList reloadData];
}
/*
-(void) didGetAddressInfo
{
    account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)account.accId]];
    
    [self.tableAddressList reloadData];
    NSLog(@"exkey count = %d, rowselected = %d", [account.extKeys count], rowSelected);
    if([account.extKeys count] > 0)
    {
        
        if(rowSelected == -1) rowSelected = 0;
        [self setQRcodeDataforkey:rowSelected];
        
    }
}*/

-(void) didGetAccountInfo: (NSInteger) accId
{
    NSLog(@"didGetAccountInfo accid = %ld", accId);
    if(accId == cwCard.currentAccountId) {
        account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)account.accId]];
    }
    
    [cwCard getAccountAddresses:accId];
}

-(void) didGetAccountAddresses:(NSInteger)accId
{
    NSLog(@"didGetAccountAddresses: %ld", accId);
    
    if (accId == cwCard.currentAccountId) {
        [self performDismiss];
        
        account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", accId]];
        
        if (account.extKeys.count > 0) {
            [self setQRcodeDataforkey:0];
        } else {
            [self setQRcodeDataforkey:-1];
        }
        
        [self.tableAddressList reloadData];
    }
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    [self dismissAllAlert];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    //if (self.segAddress.selectedSegmentIndex==0)
        return account.extKeyPointer;
    //else
     //   return account.intKeyPointer;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressPrototypeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddressPrototypeCell"];
    }
    
    CwAddress *addr;
    
    addr = (CwAddress *)(account.extKeys[indexPath.row]);
    
    //cell.textLabel.text = addr.address;
    
    if(addr) {
        UILabel *lblAddressLabel = (UILabel *)[cell viewWithTag:100];
        if([addr.note compare:@""] == 0) lblAddressLabel.text = [NSString stringWithFormat: @"%ld", (long)indexPath.row];
        else lblAddressLabel.text = addr.note;
    
        UILabel *lblAddressText = (UILabel *)[cell viewWithTag:101];
        lblAddressText.text = addr.address;
        
        UILabel *lblAddressBalance = (UILabel *)[cell viewWithTag:102];
        lblAddressBalance.text = [NSString stringWithFormat: @"%@ %@", [[OCAppCommon getInstance] convertBTCStringformUnit: (int64_t)addr.balance], [[OCAppCommon getInstance] BitcoinUnit]];
    
    }
    // m/44'/0'/0'/0/0
    //cell.detailTextLabel.text = [NSString stringWithFormat: @"BIP32 Path: m/44'/0'/%ld'/%ld/%ld", (long)addr.accountId, (long)addr.keyChainId, (long)addr.keyId];
    
    return cell;
}

#pragma mark - TableView Delegates

- (void) tableView: (UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (rowSelected != indexPath.row) {
        RequestBTC = nil;
        rowSelected = indexPath.row;
        //NSLog(@"row: %d sec: %d", indexPath.row, indexPath.section);
        [self setQRcodeDataforkey:indexPath.row];
    }
}

#pragma mark - QR code Encode

- (void)setQRcodeDataforkey:(NSInteger)key
{
    if(key >=0) {
        CwAddress *addr = (CwAddress *)(account.extKeys[key]);
        
        _lblLabel.text = addr.note;
        
        _lblAddress.text = addr.address;
    
        NSString *datastr = [NSString stringWithFormat:@"bitcoin:%@",addr.address];
        if(RequestBTC != nil) {
            datastr = [NSString stringWithFormat:@"%@?amount=%@",datastr, RequestBTC];
        }
        UIImage *qrcode = [self quickResponseImageForString:datastr withDimension:170];
    
        [_imgQRcode setImage:qrcode];
    }else{
        _lblLabel.text = @"Label";
        _lblAddress.text = @"Addess";
        [_imgQRcode setImage:[UIImage imageNamed: @"x.png"]];
    }
}


void freeRawData(void *info, const void *data, size_t size) {
    free((unsigned char *)data);
}

- (UIImage *)quickResponseImageForString:(NSString *)dataString withDimension:(int)imageWidth {
    
    QRcode *resultCode = QRcode_encodeString([dataString UTF8String], 0, QR_ECLEVEL_L, QR_MODE_8, 1);
    
    unsigned char *pixels = (*resultCode).data;
    int width = (*resultCode).width;
    int len = width * width;
    
    if (imageWidth < width)
        imageWidth = width;
    
    // Set bit-fiddling variables
    int bytesPerPixel = 4;
    int bitsPerPixel = 8 * bytesPerPixel;
    int bytesPerLine = bytesPerPixel * imageWidth;
    int rawDataSize = bytesPerLine * imageWidth;
    
    int pixelPerDot = imageWidth / width;
    int offset = (int)((imageWidth - pixelPerDot * width) / 2);
    
    // Allocate raw image buffer
    unsigned char *rawData = (unsigned char*)malloc(rawDataSize);
    memset(rawData, 0xFF, rawDataSize);
    
    // Fill raw image buffer with image data from QR code matrix
    int i;
    for (i = 0; i < len; i++) {
        char intensity = (pixels[i] & 1) ? 0 : 0xFF;
        
        int y = i / width;
        int x = i - (y * width);
        
        int startX = pixelPerDot * x * bytesPerPixel + (bytesPerPixel * offset);
        int startY = pixelPerDot * y + offset;
        int endX = startX + pixelPerDot * bytesPerPixel;
        int endY = startY + pixelPerDot;
        
        int my;
        for (my = startY; my < endY; my++) {
            int mx;
            for (mx = startX; mx < endX; mx += bytesPerPixel) {
                rawData[bytesPerLine * my + mx    ] = intensity;    //red
                rawData[bytesPerLine * my + mx + 1] = intensity;    //green
                rawData[bytesPerLine * my + mx + 2] = intensity;    //blue
                rawData[bytesPerLine * my + mx + 3] = 255;          //alpha
            }
        }
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, rawData, rawDataSize, (CGDataProviderReleaseDataCallback)&freeRawData);
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(imageWidth, imageWidth, 8, bitsPerPixel, bytesPerLine, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    
    UIImage *quickResponseImage = [UIImage imageWithCGImage:imageRef];
    
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorSpaceRef);
    CGDataProviderRelease(provider);
    QRcode_free(resultCode);
    
    return quickResponseImage;
}

- (IBAction)btnCopyAddress:(id)sender {
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    //pasteboard.string = @"paste me somewhere";
    pasteboard.string = _lblAddress.text;
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Copy Address"
                                                     message:_lblAddress.text
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

#define TAG_LABEL 1
#define TAG_REQUEST 2

- (IBAction)btnRequestPayment:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Request Payment" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_REQUEST;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeDecimalPad;
    //alertTextField.keyboardType = UIKeyboardTypeNumberPad;
    alertTextField.placeholder = @"Enter request BTC";
    [alert show];
}

- (IBAction)btnEditLabel:(id)sender {
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Edit Label" message:@"" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_LABEL;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Entered: %@",[[alertView textFieldAtIndex:0] text]);
    if(alertView.tag == TAG_LABEL) {
        if(rowSelected >=0) {
            Label = [[alertView textFieldAtIndex:0] text];
            _lblLabel.text = Label;
            [self setAddressLabel:rowSelected];
        }
    }else if(alertView.tag == TAG_REQUEST) {
        NSString *payment = [[[alertView textFieldAtIndex:0] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (payment.length > 0) {
            RequestBTC = payment;
            [self setQRcodeDataforkey:rowSelected];
        }
    }
}

- (void)setAddressLabel: (NSInteger)index
{
    if(index < 0) return;
    CwAddress *addr = (CwAddress *)(account.extKeys[index]);
    addr.note = Label;
    
    [_tableAddressList reloadData];
    [cwCard saveCwCardToFile];
}

- (void)dismissAllAlert
{
    for (UIWindow* w in [UIApplication sharedApplication].windows)
        for (NSObject* o in w.subviews)
            if ([o isKindOfClass:[UIAlertView class]])
                [(UIAlertView*)o dismissWithClickedButtonIndex:[(UIAlertView*)o cancelButtonIndex] animated:YES];
}

@end
