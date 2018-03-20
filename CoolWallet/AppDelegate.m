//
//  AppDelegate.m
//  CoolWallet
//
//  Created by MAC-BRYAN on 2014/10/15.
//  Copyright (c) 2014年 MAC-BRYAN. All rights reserved.
//

#import "AppDelegate.h"
#import "FrontViewController.h"
#import "RearViewController.h"
#import "ViewController.h"
#import "OCAppCommon.h"
#import "NSString+HexToData.h"
#import "APPData.h"
#import "NotifyManager.h"
#import "CwTransactionFee.h"

#import "UIViewController+Utils.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSURL* resourceURL = [[NSBundle mainBundle] URLForResource:@"fabric.apikey" withExtension:nil];
    NSStringEncoding usedEncoding;
    NSString* fabricAPIKey = [NSString stringWithContentsOfURL:resourceURL usedEncoding:&usedEncoding error:NULL];
    // The string that results from reading the bundle resource contains a trailing
    // newline character, which we must remove now because Fabric/Crashlytics
    // can't handle extraneous whitespace.
    NSCharacterSet* whitespaceToTrim = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString* fabricAPIKeyTrimmed = [fabricAPIKey stringByTrimmingCharactersInSet:whitespaceToTrim];
    
    [Crashlytics startWithAPIKey:fabricAPIKeyTrimmed];
    
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        [application registerForRemoteNotifications];
        
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    
    [Fabric with:@[[Crashlytics class]]];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [CwTransactionFee saveData];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [CwTransactionFee saveData];
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSLog(@"get APNS token: %@", [NSString dataToHexstring:deviceToken]);
    [APPData sharedInstance].deviceToken = [NSString dataToHexstring:deviceToken];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"register APNS fail: %@", error);
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"app state: %ld, fetchCompletionHandler receive notify: %@", [[UIApplication sharedApplication] applicationState], userInfo);
    
    if ([[UIApplication sharedApplication] applicationState]!=UIApplicationStateBackground) {
        NotifyManager *notifyManager = [NotifyManager new];
        [notifyManager process:userInfo];
    }
    
    completionHandler(UIBackgroundFetchResultNoData);
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    notification.applicationIconBadgeNumber = 0;
    
    NSString *alertTitle = [notification.userInfo objectForKey:@"title"];
    if (alertTitle == nil) {
        alertTitle = NSLocalizedString(@"Notification", nil);
    }
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: alertTitle
                                                   message: notification.alertBody
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:NSLocalizedString(@"OK",nil),nil];
    [alert show];
}


@end
