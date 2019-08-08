// Copyright 2016-present 650 Industries. All rights reserved.

#import "EXNotifications.h"
#import "EXUserNotificationCenter.h"
#import "UMEventEmitterService.h"

@interface EXNotifications ()

@property (strong, atomic) id<EXUserNotificationCenterProxy> userNotificationCenter;
@property (strong) NSString *appId;
@property (nonatomic, weak) UMModuleRegistry *moduleRegistry;
@property (nonatomic, weak) id<UMEventEmitterService> eventEmitter;

@end

@implementation EXNotifications

UM_REGISTER_MODULE();

+ (const NSString *)exportedModuleName
{
    return @"ExponentNotifications";
}

- (instancetype)init
{
  if (self = [super init]) {
      self.userNotificationCenter = [EXUserNotificationCenter sharedInstance];
  }
  return self;
}

- (void)setModuleRegistry:(UMModuleRegistry *)moduleRegistry
{
    _moduleRegistry = moduleRegistry;
    _eventEmitter = [_moduleRegistry getModuleImplementingProtocol:@protocol(UMEventEmitterService)];
    [[EXThreadSafePostOffice sharedInstance]
     registerModuleAndGetPendingDeliveriesWithAppId:self.appId mailbox:self];
}

UM_EXPORT_METHOD_AS(getPushTokenAsync,
                 getDevicePushTokenWithConfig: (__unused NSDictionary *)config
                 resolver:(UMPromiseResolveBlock)resolve
                 rejecter:(UMPromiseRejectBlock)reject)
{
  // TODO
}

UM_EXPORT_METHOD_AS(presentLocalNotification,
                    presentLocalNotification:(NSDictionary *)payload
                    resolver:(UMPromiseResolveBlock)resolve
                    rejecter:(__unused UMPromiseRejectBlock)reject)
{
  if (!payload[@"data"]) {
    reject(@"E_NOTIF_NO_DATA", @"Attempted to send a local notification with no `data` property.", nil);
    return;
  }
  UNMutableNotificationContent *content = [self _localNotificationFromPayload:payload];
  UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:content.userInfo[@"id"]
                                                                        content:content
                                                                        trigger:nil];

  [self.userNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"E_NOTIF", [NSString stringWithFormat:@"Could not add a notification request: %@", error.localizedDescription], error);
    } else {
      resolve(content.userInfo[@"id"]);
    }
  }];
}

UM_EXPORT_METHOD_AS(scheduleNotificationWithTimer,
                    scheduleNotificationWithTimer:(NSDictionary *)payload
                    withOptions:(NSDictionary *)options
                    resolver:(UMPromiseResolveBlock)resolve
                    rejecter:(UMPromiseRejectBlock)reject)
{
 if (!payload[@"data"]) {
   reject(@"E_NOTIF_NO_DATA", @"Attempted to send a local notification with no `data` property.", nil);
   return;
 }
 BOOL repeats = [options[@"repeat"] boolValue];
 int seconds = [options[@"interval"] intValue] / 1000;
 UNTimeIntervalNotificationTrigger *notificationTrigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:seconds repeats:repeats];
 UNMutableNotificationContent *content = [self _localNotificationFromPayload:payload];
 UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:content.userInfo[@"id"]
                                                                       content:content
                                                                       trigger:notificationTrigger];
 [_userNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
   if (error) {
     reject(@"E_NOTIF_REQ", error.localizedDescription, error);
   } else {
     resolve(content.userInfo[@"id"]);
   }
 }];
}

UM_EXPORT_METHOD_AS(scheduleNotificationWithCalendar,
                    scheduleNotificationWithCalendar:(NSDictionary *)payload
                    withOptions:(NSDictionary *)options
                    resolver:(UMPromiseResolveBlock)resolve
                    rejecter:(UMPromiseRejectBlock)reject)
{
 if (!payload[@"data"]) {
   reject(@"E_NOTIF_NO_DATA", @"Attempted to send a local notification with no `data` property.", nil);
   return;
 }
 UNCalendarNotificationTrigger *notificationTrigger = [self calendarTriggerFrom:options];
 UNMutableNotificationContent *content = [self _localNotificationFromPayload:payload];
 UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:content.userInfo[@"id"]
                                                                       content:content
                                                                       trigger:notificationTrigger];
 [_userNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
   if (error) {
     reject(@"E_NOTIF_REQ", error.localizedDescription, error);
   } else {
     resolve(content.userInfo[@"id"]);
   }
 }];
}

UM_EXPORT_METHOD_AS(scheduleLocalNotification,
                    scheduleLocalNotification:(NSDictionary *)payload
                    withOptions:(NSDictionary *)options
                    resolver:(UMPromiseResolveBlock)resolve
                    rejecter:(UMPromiseRejectBlock)reject)
{
  if (!payload[@"data"]) {
    reject(@"E_NOTIF_NO_DATA", @"Attempted to send a local notification with no `data` property.", nil);
    return;
  }
  UNCalendarNotificationTrigger *notificationTrigger = [self notificationTriggerFor:options[@"time"]];
  UNMutableNotificationContent *content = [self _localNotificationFromPayload:payload];
  UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:content.userInfo[@"id"]
                                                                        content:content
                                                                        trigger:notificationTrigger];
  [_userNotificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
    if (error) {
      reject(@"E_NOTIF_REQ", error.localizedDescription, error);
    } else {
      resolve(content.userInfo[@"id"]);
    }
  }];
}

UM_EXPORT_METHOD_AS(cancelScheduledNotificationAsync,
                 cancelScheduledNotificationAsync:(NSString *)uniqueId
                 withResolver:(UMPromiseResolveBlock)resolve
                 rejecter:(UMPromiseRejectBlock)reject)
{
  __weak id<EXUserNotificationCenterProxy> userNotificationCenter = _userNotificationCenter;
  [_userNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
    for (UNNotificationRequest *request in requests) {
      if ([request.content.userInfo[@"id"] isEqualToString:uniqueId]) {
        [userNotificationCenter removePendingNotificationRequestsWithIdentifiers:@[request.identifier]];
        return resolve(nil);
      }
    }
    reject(@"E_NO_NOTIF", [NSString stringWithFormat:@"Could not find pending notification request to cancel with id = %@", uniqueId], nil);
  }];
}

UM_EXPORT_METHOD_AS(cancelAllScheduledNotificationsAsync,
                 cancelAllScheduledNotificationsAsyncWithResolver:(UMPromiseResolveBlock)resolve
                 rejecter:(__unused UMPromiseRejectBlock)reject)
{
  __weak id<EXUserNotificationCenterService> userNotificationCenter = _userNotificationCenter;
  [_userNotificationCenter getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * _Nonnull requests) {
    NSMutableArray<NSString *> *requestsToCancelIdentifiers = [NSMutableArray new];
    for (UNNotificationRequest *request in requests) {
      if ([request.content.userInfo[@"experienceId"] isEqualToString:self.experienceId]) {
        [requestsToCancelIdentifiers addObject:request.identifier];
      }
    }
    [userNotificationCenter removePendingNotificationRequestsWithIdentifiers:requestsToCancelIdentifiers];
    resolve(nil);
  }];
}

#pragma mark - Badges

// TODO: Make this read from the kernel instead of UIApplication for the main Exponent app

UM_EXPORT_METHOD_AS(getBadgeNumberAsync,
                 getBadgeNumberAsyncWithResolver:(UMPromiseResolveBlock)resolve
                 rejecter:(UMPromiseRejectBlock)reject)
{
  __block NSInteger badgeNumber;
  [EXUtil performSynchronouslyOnMainThread:^{
    badgeNumber = RCTSharedApplication().applicationIconBadgeNumber;
  }];
  resolve(@(badgeNumber));
}

UM_EXPORT_METHOD_AS(setBadgeNumberAsync,
                    setBadgeNumberAsync:(nonnull NSNumber *)number
                    resolver:(UMPromiseResolveBlock)resolve
                    rejecter:(__unused UMPromiseRejectBlock)reject)
{
  [EXUtil performSynchronouslyOnMainThread:^{
    RCTSharedApplication().applicationIconBadgeNumber = number.integerValue;
  }];
  resolve(nil);
}

# pragma mark - Categories

UM_EXPORT_METHOD_AS(createCategoryAsync,
                 createCategoryWithCategoryId:(NSString *)categoryId
                 actions:(NSArray *)actions
                 resolver:(UMPromiseResolveBlock)resolve
                 rejecter:(__unused UMPromiseRejectBlock)reject)
{
  NSMutableArray<UNNotificationAction *> *actionsArray = [[NSMutableArray alloc] init];
  for (NSDictionary<NSString *, id> *actionParams in actions) {
    [actionsArray addObject:[self parseNotificationActionFromParams:actionParams]];
  }

  UNNotificationCategory *newCategory = [UNNotificationCategory categoryWithIdentifier:[self internalIdForIdentifier:categoryId]
                                                                               actions:actionsArray
                                                                     intentIdentifiers:@[]
                                                                               options:UNNotificationCategoryOptionNone];

  __weak id<EXUserNotificationCenterService> userNotificationCenter = _userNotificationCenter;
  [_userNotificationCenter getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *categories) {
    NSMutableSet<UNNotificationCategory *> *newCategories = [categories mutableCopy];
    for (UNNotificationCategory *category in newCategories) {
      if ([category.identifier isEqualToString:newCategory.identifier]) {
        [newCategories removeObject:category];
        break;
      }
    }
    [newCategories addObject:newCategory];
    [userNotificationCenter setNotificationCategories:newCategories];
    resolve(nil);
  }];
}

UM_EXPORT_METHOD_AS(deleteCategoryAsync,
                 deleteCategoryWithCategoryId:(NSString *)categoryId
                 resolver:(UMPromiseResolveBlock)resolve
                 rejecter:(__unused UMPromiseRejectBlock)reject)
{
  NSString *internalCategoryId = [self internalIdForIdentifier:categoryId];
  __weak id<EXUserNotificationCenterService> userNotificationCenter = _userNotificationCenter;
  [_userNotificationCenter getNotificationCategoriesWithCompletionHandler:^(NSSet<UNNotificationCategory *> *categories) {
    NSMutableSet<UNNotificationCategory *> *newCategories = [categories mutableCopy];
    for (UNNotificationCategory *category in newCategories) {
      if ([category.identifier isEqualToString:internalCategoryId]) {
        [newCategories removeObject:category];
        break;
      }
    }
    [userNotificationCenter setNotificationCategories:newCategories];
    resolve(nil);
  }];
}

#pragma mark - internal

- (UNMutableNotificationContent *)_localNotificationFromPayload:(NSDictionary *)payload
{
  UNMutableNotificationContent *content = [UNMutableNotificationContent new];

  NSString *uniqueId = [[NSUUID new] UUIDString];

  content.title = payload[@"title"];
  content.body = payload[@"body"];

  if ([payload[@"sound"] boolValue]) {
    content.sound = [UNNotificationSound defaultSound];
  }

  if ([payload[@"count"] isKindOfClass:[NSNumber class]]) {
    content.badge = (NSNumber *)payload[@"count"];
  }

  if ([payload[@"categoryId"] isKindOfClass:[NSString class]]) {
    content.categoryIdentifier = [self internalIdForIdentifier:payload[@"categoryId"]];
  }
  
  content.userInfo = @{
                       @"body": payload[@"data"],
                       @"experienceId": self.experienceId,
                       @"id": uniqueId,
                       };

  return content;
}

- (NSString *)internalIdForIdentifier:(NSString *)identifier {
  return [_notificationsIdentifiersManager internalIdForIdentifier:identifier experienceId:self.experienceId];
}

- (UNCalendarNotificationTrigger *)notificationTriggerFor:(NSNumber * _Nullable)unixTime
{
  NSDateComponents *dateComponents = [self dateComponentsFrom:unixTime];
  return [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:dateComponents repeats:NO];
}

- (NSDateComponents *)dateComponentsFrom:(NSNumber * _Nullable)unixTime {
  static unsigned unitFlags = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour | NSCalendarUnitDay | NSCalendarUnitMonth |  NSCalendarUnitYear;
  NSDate *triggerDate = [RCTConvert NSDate:unixTime] ?: [NSDate new];
  NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
  return [calendar components:unitFlags fromDate:triggerDate];
}

- (UNCalendarNotificationTrigger *)calendarTriggerFrom:(NSDictionary *)options
{
 BOOL repeats = [options[@"repeat"] boolValue];

  NSDateComponents *date = [[NSDateComponents alloc] init];

  NSArray *timeUnits = @[@"year", @"day", @"weekDay", @"month", @"hour", @"second", @"minute"];

  for (NSString *timeUnit in timeUnits) {
   if (options[timeUnit]) {
     [date setValue:options[timeUnit] forKey:timeUnit];
   }
 }

  return [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:date repeats:repeats];
}


- (UNNotificationAction *)parseNotificationActionFromParams:(NSDictionary *)params
{
  NSString *actionId = [self internalIdForIdentifier:params[@"actionId"]];
  NSString *buttonTitle = params[@"buttonTitle"];

  UNNotificationActionOptions options = UNNotificationActionOptionNone;
  if (![params[@"doNotOpenInForeground"] boolValue]) {
    options += UNNotificationActionOptionForeground;
  }
  if ([params[@"isDestructive"] boolValue]) {
    options += UNNotificationActionOptionDestructive;
  }
  if ([params[@"isAuthenticationRequired"] boolValue]) {
    options += UNNotificationActionOptionAuthenticationRequired;
  }

  if ([params[@"textInput"] isKindOfClass:[NSDictionary class]]) {
    return [UNTextInputNotificationAction actionWithIdentifier:actionId
                                                         title:buttonTitle
                                                       options:options
                                          textInputButtonTitle:params[@"textInput"][@"submitButtonTitle"]
                                          textInputPlaceholder:params[@"textInput"][@"placeholder"]];
  }

  return [UNNotificationAction actionWithIdentifier:actionId title:buttonTitle options:options];
}

- (void)setModuleRegistry:(UMModuleRegistry *)moduleRegistry
{
  [[EXThreadSafePostOffice sharedInstance] registerModuleAndGetPendingDeliveriesWithExperienceId:self.experienceId mailbox:self];
}

- (void)dealloc
{
  [[EXThreadSafePostOffice sharedInstance] unregisterModuleWithExperienceId:self.experienceId];
}

- (void)onForegroundNotification:(NSDictionary *)notification
{
  //TODO send to "Exponent.onUserInteraction"
}

- (void)onUserInteraction:(NSDictionary *)userInteraction
{
  //TODO send to "Exponent.onForegroundNotification"
}

@end
