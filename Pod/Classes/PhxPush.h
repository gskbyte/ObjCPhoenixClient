//
//  PhxPush.h
//  Pods
//
//  Created by Justin Schneck on 5/1/15.
//
//

#import <Foundation/Foundation.h>
#import "PhxTypes.h"

@class PhxChannel;

NS_ASSUME_NONNULL_BEGIN

@interface PhxPush : NSObject

- (instancetype)initWithChannel:(PhxChannel*)channel
                          event:(NSString*)event
                        payload:(NSDictionary*)payload;

- (void)send;

- (PhxPush *)onReceive:(NSString*)status callback:(OnMessage)callback;
- (PhxPush *)after:(NSTimeInterval)ms callback:(After)callback;

@end

NS_ASSUME_NONNULL_END
