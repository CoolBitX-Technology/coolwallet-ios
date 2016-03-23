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
#import "CwBtcNetWork.h"
#import "TabbarAccountViewController.h"

@interface TabReceiveBitcoinViewController ()  <CwBtcNetworkDelegate, UITextFieldDelegate>

@property (strong, nonatomic) CwBtcNetWork *btcNet;

@property (weak, nonatomic) IBOutlet UITableView *tableAddressList;
@property (weak, nonatomic) IBOutlet UILabel *lblAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imgQRcode;
@property (weak, nonatomic) IBOutlet UIView *detailView;

@property (strong, nonatomic) NSArray *accountButtons;

- (IBAction)btnNewAddress:(id)sender;

@property (strong, nonatomic) UIBarButtonItem *addButton;

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
    
    self.detailView.layer.borderWidth = 1.0;
    self.detailView.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.view sendSubviewToBack:self.detailView];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIViewController *parantViewController = self.parentViewController;
    [parantViewController.navigationItem setTitle:@"Receive"];
    self.addButton = ((TabbarAccountViewController *)parantViewController).addButton;
    [self.addButton setTarget:self];
    [self.addButton setAction:@selector(btnNewAddress:)];
    
    cwCard.delegate = self;
    
    if (!self.btcNet) {
        self.btcNet = [CwBtcNetWork sharedManager];
    }
    self.btcNet.delegate = self;
    
    [self setAccountButton];
}

-(void) viewDidDisappear:(BOOL)animated
{
    if (self.btcNet && self.btcNet.delegate == self) {
        self.btcNet.delegate = nil;
    }
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
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: @"Unable to create new address"
                                                       message: @"Maximum number of 5 unused addresses reached in this account"
                                                      delegate: nil
                                             cancelButtonTitle: nil
                                             otherButtonTitles:@"OK",nil];
        [alert show];
        
        return;
    }
    
    [self showIndicatorView:@"create address"];
    
    [cwCard genAddress: account.accId KeyChainId: CwAddressKeyChainExternal];
}

#pragma marks - Account Button Actions

- (void)setAccountButton{
    UIButton *selectedAccount;
    
    for(int i =0; i< [cwCard.cwAccounts count]; i++) {
        UIButton *accountBtn = [self.accountButtons objectAtIndex:i];
        accountBtn.hidden = NO;
        
        if (i == self.cwManager.connectedCwCard.currentAccountId) {
            selectedAccount = accountBtn;
        }
    }
    
    RequestBTC = nil;
    [selectedAccount sendActionsForControlEvents:UIControlEventTouchUpInside];
}

- (IBAction)btnAccount:(id)sender {
    NSInteger currentAccId = cwCard.currentAccountId;
    for (UIButton *btn in self.accountButtons) {
        if (sender == btn) {
            cwCard.currentAccountId = [self.accountButtons indexOfObject:btn];
            [btn setSelected:YES];
        } else {
            [btn setSelected:NO];
        }
    }
    
    account = (CwAccount *) [cwCard.cwAccounts objectForKey:[NSString stringWithFormat:@"%ld", (long)cwCard.currentAccountId]];
    
    if ([cwCard enableGenAddressWithAccountId:account.accId]) {
        [self.addButton setEnabled:YES];
        [self.addButton setTintColor:[UIColor whiteColor]];
    } else {
        [self.addButton setEnabled:NO];
        [self.addButton setTintColor:[UIColor clearColor]];
    }
    
    if (currentAccId != cwCard.currentAccountId) {
        [self showIndicatorView:@"loading address..."];
        
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    
    if ([account.extKeys count] > 0 && [account isAllAddressSynced]) {
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

-(void) getAccountTransactions:(CwAccount *)account
{
    [self.btcNet getBalanceAndTransactionByAccount:account.accId];
}

#pragma marks - CwCard Delegates
-(void) didCwCardCommand
{
    NSLog(@"didCwCardCommand");
    [self.cwManager.connectedCwCard saveCwCardToFile];
}

-(void) didGenAddress: (CwAddress *) addr
{
    NSLog(@"didGenAddress");
    [self performDismiss];
    account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)account.accId]];

    rowSelected = account.extKeyPointer-1;
    [self setQRcodeDataforkey:account.extKeyPointer-1];
    
    [_btnEditLabel sendActionsForControlEvents:UIControlEventTouchUpInside];
    //[cwCard getAccountAddresses: account.accId];
    [self.tableAddressList reloadData];
    
    if (![cwCard enableGenAddressWithAccountId:account.accId]) {
        [self.addButton setEnabled:NO];
        [self.addButton setTintColor:[UIColor clearColor]];
    }
}

-(void) didGetAccountInfo: (NSInteger) accId
{
    NSLog(@"didGetAccountInfo accid = %ld", (long)accId);
    if(accId == cwCard.currentAccountId) {
        account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)account.accId]];
    }
    
    [cwCard getAccountAddresses:accId];
}

-(void) didGetAccountAddresses:(NSInteger)accId
{
    NSLog(@"didGetAccountAddresses: %ld", (long)accId);
    
    if (accId != cwCard.currentAccountId) {
        return;
    }
    
    [self performDismiss];
    
    NSString *selectedAddress = _lblAddress.text;
    
    account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)accId]];
    
    if (account.extKeys.count > 0) {
        if (account.lastUpdate == nil) {
            [self performSelectorInBackground:@selector(getAccountTransactions:) withObject:account];
        }
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.address = %@", selectedAddress];
        NSArray *result = [account.extKeys filteredArrayUsingPredicate:predicate];
        if (result.count > 0) {
            rowSelected = [account.extKeys indexOfObject:result[0]];
        } else {
            rowSelected = 0;
        }
    } else {
        rowSelected = -1;
    }
    
    [self setQRcodeDataforkey:rowSelected];
    [self.tableAddressList reloadData];
}

#pragma mark - CwBtcNetwork Delegate
-(void) didGetTransactionByAccount:(NSInteger)accId
{
    NSLog(@"didGetTransactionByAccount: %ld", (long)accId);
    
    if (accId != cwCard.currentAccountId) {
        return;
    }
    
    if (rowSelected >= 0) {
        [self.tableAddressList performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
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
        
        if (addr.historyTrx.count > 0) {
            [lblAddressText setTextColor:[UIColor grayColor]];
        } else {
            [lblAddressText setTextColor:[UIColor whiteColor]];
        }
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
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Copied"
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
