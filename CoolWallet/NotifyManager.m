//
//  NotifyManager.m
//  CoolWallet
//
//  Created by 鄭斐文 on 2016/3/8.
//  Copyright © 2016年 MAC-BRYAN. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NotifyManager.h"
#import "SWRevealViewController.h"
#import "CwExchangeManager.h"
#import "CwCard.h"
#import "CwExUnclarifyOrder.h"
#import "CwExSellOrder.h"
#import "CwExchange.h"

#import "UIViewController+Utils.h"
#import "NSUserDefaults+RMSaveCustomObject.h"
#import "NSString+HexToData.h"

#import <ReactiveCocoa/ReactiveCocoa.h>

@implementation NotifyManager

-(void) process:(NSDictionary *)apsInfo
{
    NSDictionary *aps = [apsInfo objectForKey:@"aps"];
    if (aps.count == 0) {
        return;
    }
    
    NSDictionary *data = [apsInfo objectForKey:@"data"];
    NSString *cwid = [data objectForKey:@"cwid"];
    
    NSString *action = [data objectForKey:@"action"];
    NSString *orderID = [data objectForKey:@"order"];
    
    if ([action isEqualToString:@"blockOTP"]) {
        NSNumber *amount = [data objectForKey:@"amount"];
        NSNumber *price = [data objectForKey:@"price"];
        
        CwExUnclarifyOrder *unclarifyOrder = [CwExUnclarifyOrder new];
        unclarifyOrder.orderId = orderID;
        unclarifyOrder.amountBTC = amount;
        unclarifyOrder.price = price;
        
        [self blockOTPFromCwID:cwid withUnclarifyOrder:unclarifyOrder];
    } else if ([action isEqualToString:@"cancelOrder"]) {
        [self cancelOrder:orderID fromCwID:cwid];
    } else if ([action isEqualToString:@"matchOrder"]) {
        [self matchOrder:orderID fromCwID:cwid];
    }
    
    NSString *targetIdentifier;
    
    CwExchangeManager *exchange = [CwExchangeManager sharedInstance];
    if ([exchange isCardLoginEx:cwid]) {
        if ([action isEqualToString:@"blockOTP"]) {
            targetIdentifier = @"ExBlockOrderViewController";
        } else if ([action isEqualToString:@"matchOrder"]) {
            targetIdentifier = @"ExMatchedOrderViewController";
        }
    }
    
    NSString *msg = [aps objectForKey:@"alert"];
    NSNumber *content_available = [aps objectForKey:@"content-available"];
    
    if (content_available.intValue == 1 && [msg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        return;
    }
    
    [self notifyMessage:msg targetIdentifier:targetIdentifier];
}

-(void) notifyMessage:(NSString *)message targetIdentifier:(NSString *)identifier
{
    NSLog(@"notifyMessage:%@, targetIdentifier:%@", message, identifier);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"receive notify" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    UIViewController *currentViewController = [UIViewController currentViewController];
    if (currentViewController && [currentViewController isKindOfClass:[SWRevealViewController class]]) {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:cancelAction];
        
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if (identifier == nil) {
                return;
            }
            UIStoryboard *secondStoryBoard = [UIStoryboard storyboardWithName:@"Accounts" bundle:nil];
            UIViewController *nextViewController = (UIViewController *)[secondStoryBoard instantiateViewControllerWithIdentifier:identifier];
            
            SWRevealViewController *revealController = (SWRevealViewController *)currentViewController;
            if (![[revealController.frontViewController.childViewControllers lastObject] isKindOfClass:[nextViewController class]]) {
                [(UINavigationController *)revealController.frontViewController pushViewController:nextViewController animated:YES];
            }
        }];
        [alertController addAction:okAction];
    } else {
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:okAction];
    }
    
    [currentViewController presentViewController:alertController animated:YES completion:nil];
}

-(void) blockOTPFromCwID:(NSString *)cwid withUnclarifyOrder:(CwExUnclarifyOrder *)unclarifyOrder
{
    NSString *key = [NSString stringWithFormat:@"exchange_%@", cwid];
    
    NSMutableArray *unclarify_orders = [[NSUserDefaults standardUserDefaults] rm_customObjectForKey:key];
    if (unclarify_orders == nil) {
        unclarify_orders = [NSMutableArray new];
    }
    [unclarify_orders addObject:unclarifyOrder];
    
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:unclarify_orders forKey:key];
}

-(void) cancelOrder:(NSString *)orderID fromCwID:(NSString *)cwid
{
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    if (![exManager isCardLoginEx:cwid]) {
        return;
    }
    
    [exManager unblockOrderWithOrderId:orderID];
}

-(void) matchOrder:(NSString *)orderID fromCwID:(NSString *)cwid
{
    CwExchangeManager *exManager = [CwExchangeManager sharedInstance];
    if (![exManager isCardLoginEx:cwid]) {
        return;
    }
    
    [exManager requestMatchedOrder:orderID];
    
    NSString *key = [NSString stringWithFormat:@"exchange_%@", exManager.card.cardId];
    [[NSUserDefaults standardUserDefaults] rm_setCustomObject:exManager.exchange forKey:key];
}

@end
