// Copyright 2015-present 650 Industries. All rights reserved.

#import "EXUserNotificationManager.h"
#import "EXRemoteNotificationManager.h"
#import "EXPostOffice.h"

@implementation EXUserNotificationManager

+ (EXUserNotificationManager*)sharedInstance
{
  static EXUserNotificationManager *sharedInstance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    sharedInstance = [[EXUserNotificationManager alloc] init];
  });
  return sharedInstance;
}

# pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
  EXPendingNotification *pendingNotification = [[EXPendingNotification alloc] initWithNotificationResponse:response];
  
  NSString *appId = response.notification.request.content.userInfo[@"appId"];
  [[EXThreadSafePostOffice sharedInstance] notifyAboutUserInteractionForAppId:appId userInteraction:[pendingNotification propertiesUserInteractionFormat]];
  completionHandler();
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{

  NSDictionary *userInfo = notification.request.content.userInfo;
  
  BOOL shouldDisplayInForeground = NO || userInfo[@"canInForeground"];

  if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive || shouldDisplayInForeground) {
    completionHandler(
                      UNNotificationPresentationOptionAlert +
                      UNNotificationPresentationOptionSound +
                      UNNotificationPresentationOptionBadge // TODO: let user decide
                      );
    return;
  }

  EXPendingNotification *pendingNotification = [[EXPendingNotification alloc] initWithNotification:notification];
  
  NSString *appId = userInfo[@"appId"];
  [[EXThreadSafePostOffice sharedInstance] notifyAboutForegroundNotificationForAppId:appId notification:[pendingNotification propertiesForegroundNotificationFormat]];

  completionHandler(UNNotificationPresentationOptionNone);
}

@end
