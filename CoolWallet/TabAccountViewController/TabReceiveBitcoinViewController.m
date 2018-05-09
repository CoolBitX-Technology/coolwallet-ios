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

#define TAG_LABEL 1
#define TAG_REQUEST 2

@interface TabReceiveBitcoinViewController ()  <CwBtcNetworkDelegate, UITextFieldDelegate>

@property (strong, nonatomic) CwBtcNetWork *btcNet;

@property (weak, nonatomic) IBOutlet UITableView *tableAddressList;
@property (weak, nonatomic) IBOutlet UILabel *lblAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblLabel;
@property (weak, nonatomic) IBOutlet UIImageView *imgQRcode;
@property (weak, nonatomic) IBOutlet UIView *detailView;

@property (strong, nonatomic) NSArray *accountButtons;
@property (strong, nonatomic) NSMutableArray *extAddressArray;

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
    self.extAddressArray = [[NSMutableArray alloc] init];
    
    self.detailView.layer.borderWidth = 1.0;
    self.detailView.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.view sendSubviewToBack:self.detailView];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    UIViewController *parantViewController = self.parentViewController;
    [parantViewController.navigationItem setTitle:NSLocalizedString(@"Receive",nil)];
    self.addButton = ((TabbarAccountViewController *)parantViewController).addButton;
    [self.addButton setTarget:self];
    [self.addButton setAction:@selector(btnNewAddress:)];
    
    cwCard.delegate = self;
    
    if (!self.btcNet) {
        self.btcNet = [CwBtcNetWork sharedManager];
    }
    self.btcNet.delegate = self;
    self.extAddressArray = account.extKeys;
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

- (void) getCurrentAccountInfo
{
    [cwCard getAccountInfo:cwCard.currentAccountId];
}

- (void) getAccountTransactions:(CwAccount *)account
{
    [self.btcNet getBalanceAndTransactionByAccount:account.accId];
}

- (void)genNewAddress
{
    [self showIndicatorView:NSLocalizedString(@"create address",nil)];
    [cwCard genAddress: account.accId KeyChainId: CwAddressKeyChainExternal];
}

- (BOOL)needGenNewAddress
{
    BOOL needGen = YES;
    NSMutableArray* extKeys = [self.extAddressArray copy];
    for (CwAddress* cwAddress in extKeys) {
        if (cwAddress.historyTrx.count == 0) {
            needGen = NO;
            break;
        }
    }
    return needGen;
}

- (NSMutableArray*)sortExternalAddresses:(NSMutableArray*)extKeys
{
    NSMutableArray* extAddress = [extKeys copy];
    NSMutableArray* addressHasTx = [[NSMutableArray alloc] init];
    NSMutableArray* addressNoTx = [[NSMutableArray alloc] init];
    NSMutableArray* newArray = [[NSMutableArray alloc] init];
    for (CwAddress* cwAddress in extAddress) {
        if (cwAddress.historyTrx.count > 0) {
            [addressHasTx addObject:cwAddress];
        } else {
            [addressNoTx addObject:cwAddress];
        }
    }
    
    NSArray *sortedAddressHasTx;
    sortedAddressHasTx = [addressHasTx sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *first = [NSNumber numberWithInteger:[(CwAddress*)a keyId]];
        NSNumber *second = [NSNumber numberWithInteger:[(CwAddress*)b keyId]];
        return [second compare:first];
    }];
    NSArray *sortedAddressNoTx;
    sortedAddressNoTx = [addressNoTx sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSNumber *first = [NSNumber numberWithInteger:[(CwAddress*)a keyId]];
        NSNumber *second = [NSNumber numberWithInteger:[(CwAddress*)b keyId]];
        return [second compare:first];
    }];
    if(sortedAddressNoTx) [newArray addObjectsFromArray:sortedAddressNoTx];
    if(sortedAddressHasTx) [newArray addObjectsFromArray:sortedAddressHasTx];
    
    return newArray;
}

#pragma mark - UITextFieldDelegate Delegates
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - Button Actions
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
        [self showIndicatorView:NSLocalizedString(@"loading address...",nil)];
        
        [cwCard setDisplayAccount:cwCard.currentAccountId];
    }
    
    if ([self.extAddressArray count] > 0 && [account isAllAddressSynced]) {
        
        [self performSelectorOnMainThread:@selector(getCurrentAccountInfo) withObject:nil waitUntilDone:NO];
    } else {
        [self getCurrentAccountInfo];
    }
}

- (IBAction)btnNewAddress:(id)sender {
    if (![cwCard enableGenAddressWithAccountId:account.accId]) {
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle: NSLocalizedString(@"Unable to create new address",nil)
                                                       message: NSLocalizedString(@"Maximum number of 5 unused addresses reached in this account",nil)
                                                      delegate: nil
                                             cancelButtonTitle: nil
                                             otherButtonTitles: NSLocalizedString(@"OK",nil),nil];
        [alert show];
        
        return;
    }
    
    [self genNewAddress];
}

- (IBAction)btnCopyAddress:(id)sender {
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    //pasteboard.string = @"paste me somewhere";
    pasteboard.string = _lblAddress.text;
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"Copied",nil)
                                                     message:_lblAddress.text
                                                    delegate:self
                                           cancelButtonTitle: NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
    [alert show];
}

- (IBAction)btnRequestPayment:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Request Payment",nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_REQUEST;
    UITextField * alertTextField = [alert textFieldAtIndex:0];
    alertTextField.keyboardType = UIKeyboardTypeDecimalPad;
    //alertTextField.keyboardType = UIKeyboardTypeNumberPad;
    alertTextField.placeholder = NSLocalizedString(@"Enter request BTC",nil);
    [alert show];
}

- (IBAction)btnEditLabel:(id)sender {
    
    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Edit Label",nil) message:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"OK",nil) otherButtonTitles:nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_LABEL;
    [alert show];
}

#pragma mark - CwCard Delegates
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
    
    self.extAddressArray = account.extKeys;
    self.extAddressArray = [self sortExternalAddresses:self.extAddressArray];
    
    rowSelected = 0;
    [self setQRcodeDataforkey:0];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_btnEditLabel sendActionsForControlEvents:UIControlEventTouchUpInside];
        [self.tableAddressList reloadData];
        
        if (![cwCard enableGenAddressWithAccountId:account.accId]) {
            [self.addButton setEnabled:NO];
            [self.addButton setTintColor:[UIColor clearColor]];
        }
    });
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
    
    account = [cwCard.cwAccounts objectForKey:[NSString stringWithFormat: @"%ld", (long)accId]];
    self.extAddressArray = account.extKeys;
    
    if (self.extAddressArray.count > 0) {
        if (account.lastUpdate == nil) {
            [self showIndicatorView:NSLocalizedString(@"loading address...",nil)];
            [self getAccountTransactions:account];
        } else {
            if ([self needGenNewAddress]) {
                [self genNewAddress];
            } else {
                self.extAddressArray = [self sortExternalAddresses:self.extAddressArray];
                rowSelected = 0;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self setQRcodeDataforkey:rowSelected];
                    [self.tableAddressList reloadData];
                });
            }
        }
    } else {
        return;
    }
}

#pragma mark - CwBtcNetwork Delegate
-(void) didGetTransactionByAccount:(NSInteger)accId
{
    NSLog(@"didGetTransactionByAccount: %ld", (long)accId);
    [self performDismiss];
    if (accId != cwCard.currentAccountId) {
        return;
    }
    if ([self needGenNewAddress]) {
        [self genNewAddress];
        return;
    }
    self.extAddressArray = account.extKeys;
    self.extAddressArray = [self sortExternalAddresses:self.extAddressArray];
    
    if (rowSelected >= 0) {
        [self setQRcodeDataforkey:rowSelected];
        [self.tableAddressList performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    }
}

#pragma mark - CwManager Delegate
-(void) didDisconnectCwCard: (NSString *)cardName
{
    [self dismissAllAlert];
    //Add a notification to the system
    UILocalNotification *notify = [[UILocalNotification alloc] init];
    notify.alertBody = [NSString stringWithFormat:NSLocalizedString(@"%@ Disconnected",nil), cardName];
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
    return self.extAddressArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddressPrototypeCell" forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"AddressPrototypeCell"];
    }
    
    CwAddress *addr;
    
    addr = (CwAddress *)(self.extAddressArray[indexPath.row]);
    
    //cell.textLabel.text = addr.address;
    
    if(addr) {
        UILabel *lblAddressLabel = (UILabel *)[cell viewWithTag:100];
        if([addr.note compare:@""] == 0) {
//            lblAddressLabel.text = [NSString stringWithFormat: @"%d", (int)indexPath.row + 1];
            lblAddressLabel.text = [NSString stringWithFormat: @"%ld", (long)addr.keyId];
        } else {
            lblAddressLabel.text = addr.note;
        }
        
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if(key >=0 && self.extAddressArray.count > 0) {
            CwAddress *addr = (CwAddress *)(self.extAddressArray[key]);
            
            _lblLabel.text = addr.note;
            
            _lblAddress.text = addr.address;
            
            NSString *datastr = [NSString stringWithFormat:@"bitcoin:%@",addr.address];
            if(RequestBTC != nil) {
                datastr = [NSString stringWithFormat:@"%@?amount=%@",datastr, RequestBTC];
            }
            UIImage *qrcode = [self quickResponseImageForString:datastr withDimension:170];
            
            [_imgQRcode setImage:qrcode];
        } else {
            _lblLabel.text = NSLocalizedString(@"",nil);
            _lblAddress.text = NSLocalizedString(@"Addess",nil);
            [_imgQRcode setImage:[UIImage imageNamed: @"x.png"]];
        }
    });
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
    CwAddress *addr = (CwAddress *)(self.extAddressArray[index]);
    addr.note = Label;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [_tableAddressList reloadData];
    });

    for (CwAddress* cwAddress in account.extKeys) {
        if ([cwAddress.address isEqualToString:addr.address]) {
            cwAddress.note = Label;
        }
    }
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
