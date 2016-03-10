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

#import "UIViewController+Utils.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
        [application registerForRemoteNotifications];
        
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    }
    
    [Fabric with:@[[Crashlytics class]]];
    
    /*
    // Change the background color of navigation bar
    [[UINavigationBar appearance] setBarTintColor:[UIColor whiteColor]];
    
    // Change the font style of the navigation bar
    NSShadow *shadow = [[NSShadow alloc] init];
    shadow.shadowColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
    shadow.shadowOffset = CGSizeMake(0, 0);
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:10.0/255.0 green:10.0/255.0 blue:10.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           shadow, NSShadowAttributeName,
                                                           [UIFont fontWithName:@"Helvetica-Light" size:21.0], NSFontAttributeName, nil]];
    /*
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
    /*
    [[OCAppCommon getInstance]initDefult];
    
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window = window;
    
    FrontViewController *frontViewController = [[FrontViewController alloc] init];
    //FrontViewController *frontViewController = [[FrontViewController alloc] init];
    RearViewController *rearViewController = [[RearViewController alloc] init];
    
    //ViewController *viewController = [[UIStoryboard storyboardWithName:@"Main" bundle:NULL] instantiateViewControllerWithIdentifier:@"ViewController"];
    
    UINavigationController *frontNavigationController = [[UINavigationController alloc] initWithRootViewController:frontViewController];
    UINavigationController *rearNavigationController = [[UINavigationController alloc] initWithRootViewController:rearViewController];
    
    SWRevealViewController *revealController = [[SWRevealViewController alloc] initWithRearViewController:nil frontViewController:frontNavigationController];
    revealController.delegate = self;
    
    [revealController setRightViewController:rearNavigationController];
    
    self.viewController = revealController;
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
   // UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    //[revealController pushFrontViewController:navigationController animated:YES];
    
    NSString *myStoryboardName=@"Main";
    //if(UI_USER_INTERFACE_IDIOM()== UIUserInterfaceIdiomPad)
     //   myStoryboardName = [myStoryboardName stringByAppendingString:@"_iPad"];
    UIStoryboard *myTargetStoryboard=[UIStoryboard storyboardWithName:myStoryboardName bundle:nil];
    [revealController presentModalViewController:[myTargetStoryboard instantiateInitialViewController] animated:YES];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.window.frame.size.width, 20)];
    label.backgroundColor = [UIColor blackColor];
    [self.window.rootViewController.view addSubview:label];
    self.window.backgroundColor = [UIColor blackColor];
    //[[UINavigationBar appearance] setBackgroundImage:@"reveal-icon" forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setBarTintColor:UIColorFromRGB(0x0000FF)];
    //UIBarButtonItem *rightRevealButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"menu-icon.png"];
    //[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"nav_bg.png"] forBarMetrics:UIBarMetricsDefault];
     */
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
        alertTitle = @"Notification";
    }
    
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle: alertTitle
                                                   message: notification.alertBody
                                                  delegate: nil
                                         cancelButtonTitle: nil
                                         otherButtonTitles:@"OK",nil];
    [alert show];
}


@end
