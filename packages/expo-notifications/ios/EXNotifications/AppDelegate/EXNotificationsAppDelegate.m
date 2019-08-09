// Copyright 2019-present 650 Industries. All rights reserved.

#import "EXNotificationsAppDelegate.h"
#import <EXNotifications/EXUserNotificationManager.h>

@implementation EXNotificationsAppDelegate

UM_REGISTER_SINGLETON_MODULE(EXNotificationAppDelegate)

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
  [UNUserNotificationCenter currentNotificationCenter].delegate = [EXUserNotificationManager sharedInstance];
  return false;
}

@end
