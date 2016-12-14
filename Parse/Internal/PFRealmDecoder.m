// PFRealmDecoder.m
//
// Created by Maxime Epain on 16/08/2016.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import "PFRealmDecoder.h"
#import "PFRealmObject.h"

@implementation PFRealmDecoder

+ (PFRealmDecoder *)decoderWithRealm:(RLMRealm *)realm {
    return [[self alloc] initWithRealm:realm];
}

- (instancetype)init {
    return [self initWithRealm:[RLMRealm defaultRealm]];
}

- (instancetype)initWithRealm:(RLMRealm *)realm {
    self = [super init];
    if (self) {
        _realm = realm;
    }
    return self;
}

- (id)decodeObject:(id)object {
    if ([object isKindOfClass:[NSDictionary class]]) {
        NSString *type = object[@"__type"];
        
        if ([type isEqualToString:@"Pointer"]) {
            NSString *objectId = object[@"objectId"];
            NSString *className = object[@"className"];
            if (className) {
                return [PFObject objectInRealm:self.realm className:className objectId:objectId];
            }
        }
    }
    
    // Embedded objects can't show up here, because we never stored them that way offline.
    return [super decodeObject:object];
}

@end
