// Copyright 2016-present 650 Industries. All rights reserved.

#import <UserNotifications/UserNotifications.h>

#import <UMCore/UMExportedModule.h>
#import <UMCore/UMModuleRegistryConsumer.h>
#import <UMCore/UMEventEmitter.h>

#import "EXPostOffice.h"
#import "EXThreadSafePostOffice.h"
#import "EXMailbox.h"

NS_ASSUME_NONNULL_BEGIN

@interface EXNotifications : UMExportedModule <EXMailbox, UMModuleRegistryConsumer, UMEventEmitter>

@end

NS_ASSUME_NONNULL_END
