// Copyright 2019-present 650 Industries. All rights reserved.

#import <EXNotifications/EXBareScoper.h>
#import <UMCore/UMDefines.h>

@interface EXBareScoper ()

@end

@implementation EXBareScoper

UM_REGISTER_MODULE()

- (NSString *)getScopedString:(NSString *)string {
  return string;
}

- (NSString *)getUnscopedString:(NSString *)string {
  return string;
}

+ (const NSArray<Protocol *> *)exportedInterfaces {
  return @[@protocol(EXScoper)];
}

@end
