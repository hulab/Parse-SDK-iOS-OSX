// PFRealmObject.m
//
// Created by Maxime Epain on 20/05/16.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import <Realm/RLMResults.h>

#import "PFRealmObject.h"
#import "PFRealmStore.h"
#import "PFRealmQuery.h"
#import "PFEncoder.h"
#import "PFRealmDecoder.h"
#import "PFObjectPrivate.h"
#import "PFInternalUtils.h"
#import "PFJSONSerialization.h"

@interface PFRealmObject ()
@property (atomic) NSString *objectId;
@property (atomic) NSString *parseClassName;
@property (atomic) NSDate   *updatedAt;
@property (atomic) NSDate   *createdAt;
@property (atomic) NSString *encodedObject;
@property (atomic) NSString *localId;
@end

@implementation PFRealmObject

+ (NSString *)primaryKey {
    return @"objectId";
}

+ (NSArray<NSString *> *)requiredProperties {
    return @[@"parseClassName", @"encodedObject"];
}

- (instancetype)initWithObject:(PFObject *)object {
    self = [super init];
    if (self) {
        self.objectId       = object.objectId;
        self.parseClassName = object.parseClassName;
        self.updatedAt      = object.updatedAt;
        self.createdAt      = object.createdAt;
        
        PFEncoder *encoder = [PFPointerObjectEncoder objectEncoder];
        // We don't care about operationSetUUIDs here
        NSArray *operationSetUUIDs = nil;
        NSDictionary *encoded = [object RESTDictionaryWithObjectEncoder:encoder operationSetUUIDs:&operationSetUUIDs];
        self.encodedObject = [PFJSONSerialization stringFromJSONObject:encoded];
        
        [PFRealmObject cacheObject:object];
    }
    return self;
}

- (PFObject *)objectInRealm:(RLMRealm *)realm {
    PFObject *object = [PFRealmObject cachedObjectWithClassName:self.parseClassName objectId:self.objectId];
    
    if (!object) {
        object = [PFObject objectWithoutDataWithClassName:self.parseClassName objectId:self.objectId];
        [PFRealmObject cacheObject:object];
        
        NSDictionary *json = [PFJSONSerialization JSONObjectFromString:self.encodedObject];
        PFRealmDecoder *decoder = [PFRealmDecoder decoderWithRealm:realm];
        [object mergeFromRESTDictionary:json withDecoder:decoder];
    }
    return object;
}

- (PFObject *)objectInDefaultRealm {
    return [self objectInRealm:[RLMRealm defaultRealm]];
}

///--------------------------------------
#pragma mark - PFRealmObject factory methods for Subclassing
///--------------------------------------

+ (NSString *)parseClassName {
    return @"_Generic";
}

+ (void)registerSubclass {
    [PFRealmStore registerSubclass:self];
}

+ (PFRealmQuery *)query {
    NSAssert([self conformsToProtocol:@protocol(PFRealmObjectSubclass)],
                        @"+[PFRealmObject query] can only be called on subclasses conforming to PFRealmObjectSubclass.");
    return [PFRealmQuery queryWithClassName:self.parseClassName];
}

+ (PFRealmQuery *)queryWithPredicate:(NSPredicate *)predicate {
    NSAssert([self conformsToProtocol:@protocol(PFRealmObjectSubclass)],
                        @"+[PFRealmObject queryWithClassName:] can only be called on subclasses conforming to PFRealmObjectSubclass.");
    return [PFRealmQuery queryWithClassName:self.parseClassName predicate:predicate];
}

///--------------------------------------
#pragma mark - PFObject unicity
///--------------------------------------

static NSMapTable<NSString *, PFObject *> *objectMap;

+ (void)cacheObject:(PFObject *)object {
    if (!objectMap) {
        objectMap = [NSMapTable strongToWeakObjectsMapTable];
    }
    
    if (object.objectId) {
        NSString *key = [NSString stringWithFormat:@"%@:%@", object.parseClassName, object.objectId];
        [objectMap setObject:object forKey:key];
    }
}

+ (PFObject *)cachedObjectWithClassName:(NSString *)className objectId:(NSString *)objectId {
    NSString *key = [NSString stringWithFormat:@"%@:%@", className, objectId];
    return [objectMap objectForKey:key];
}

+ (void)removeObjectFromCache:(PFObject *)object {
    NSString *key = [NSString stringWithFormat:@"%@:%@", object.parseClassName, object.objectId];
    [objectMap removeObjectForKey:key];
}

@end

@implementation PFObject (Realm)

+ (instancetype)objectInRealm:(RLMRealm *)realm className:(NSString *)className objectId:(NSString *)objectId {
    PFObject *object = [PFRealmObject cachedObjectWithClassName:className objectId:objectId];
    
    if (!object) {
        object = [PFObject objectWithoutDataWithClassName:className objectId:objectId];
        [PFRealmObject cacheObject:object];
        
        Class class = [PFRealmStore subclassForParseClassName:className];
        PFRealmObject *managedObject = [class objectInRealm:realm forPrimaryKey:objectId];
        
        if (managedObject) {
            NSDictionary *json = [PFJSONSerialization JSONObjectFromString:managedObject.encodedObject];
            PFRealmDecoder *decoder = [PFRealmDecoder decoderWithRealm:realm];
            [object mergeFromRESTDictionary:json withDecoder:decoder];
        }
    }
    return object;
}

+ (instancetype)objectInDefaultRealmWithClassName:(NSString *)className objectId:(NSString *)objectId {
    return [self objectInRealm:[RLMRealm defaultRealm] className:className objectId:objectId];
}

@end
