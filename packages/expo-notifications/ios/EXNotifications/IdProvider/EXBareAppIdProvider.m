// Copyright 2019-present 650 Industries. All rights reserved.

#import "EXBareAppIdProvider.h"

@implementation EXBareAppIdProvider

UM_REGISTER_MODULE()

- (NSString *)getAppId {
  return @"defaultId";
}

+ (const NSArray<Protocol *> *)exportedInterfaces {
  return @[@protocol(EXAppIdProvider)];
}

@end
