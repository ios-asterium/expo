// Copyright 2019-present 650 Industries. All rights reserved.

#import "MessageUnscoper.h"

@implementation MessageUnscoper

+ (NSDictionary *) getUnscopedMessage:(NSDictionary *)message  scoper:(id<EXScoper>)scoper
{
  NSMutableDictionary *mutableMsg = [message mutableCopy];
  for (NSString *key in [message allKeys]) {
    if ([message[key] class] == [NSString class]) {
      mutableMsg[key] = [scoper getUnscopedString:message[key]];
    }
  }
  return mutableMsg;
}

@end
