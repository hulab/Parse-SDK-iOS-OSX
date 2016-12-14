// PFRealmDecoder.h
//
// Created by Maxime Epain on 16/08/2016.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import <Foundation/Foundation.h>

#import <Realm/RLMRealm.h>

#import "PFDecoder.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A decoder to decode Parse object stored in Realm.
 */
@interface PFRealmDecoder : PFDecoder

/**
 Realm instance where Parse objects are stored.
 */
@property (nonatomic, weak, readonly) RLMRealm *realm;

/**
 Creates and initializes a Realm decoder.
 
 @param realm Realm instance where Parse objects are stored.
 
 @return The newly-initialized decoder.
 */
+ (PFRealmDecoder *)decoderWithRealm:(RLMRealm *)realm;

/**
 Initializes a Realm decoder.
 
 @param realm Realm instance where Parse objects are stored.
 
 @return The initialized decoder.
 */
- (instancetype)initWithRealm:(RLMRealm *)realm NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
