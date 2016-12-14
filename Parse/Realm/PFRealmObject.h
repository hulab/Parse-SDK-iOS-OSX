// PFRealmObject.h
//
// Created by Maxime Epain on 20/05/16.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import <Foundation/Foundation.h>

#import <Realm/RLMObject.h>

#import <Parse/PFObject.h>

NS_ASSUME_NONNULL_BEGIN

@class PFRealmQuery;

/**
 PFRealmObject is a Realm representation of a PFObject.
 */
@interface PFRealmObject<MAPObjectType : PFObject *> : RLMObject

/**
 The Parse object identifier.
 */
@property (readonly) NSString *objectId;

/**
 The Parse object class name.
 */
@property (readonly) NSString *parseClassName;

/**
 When the Parse object was last updated.
 */
@property (readonly) NSDate *updatedAt;

/**
 When the Parse object was created.
 */
@property (readonly) NSDate *createdAt;

/**
 The encoded Parse object.
 */
@property (readonly) NSString *encodedObject;

/**
 Initializes a `PFRealmObject` representing the given Parse object.
 
 @param object The Parse object.
 
 @return An initialized managed object.
 */
- (instancetype)initWithObject:(MAPObjectType)object;

/**
 Gets or creates the Parse object wrapped by the Realm object and saved in the given Realm.
 
 @param realm The Realm which should manage the Parse object.
 
 @return The Parse object.
 */
- (MAPObjectType)objectInRealm:(RLMRealm *)realm;

/**
 Gets or creates the Parse object wrapped by the Realm object and saved in the default Realm.
 
 @return The Parse object.
 */
- (MAPObjectType)objectInDefaultRealm;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

/**
 If a subclass of `PFRealmObject` conforms to `PFRealmObjectSubclass` and calls `PFRealmObject.+registerSubclass`,
 the store will be able to use that class as the native class for a Parse cloud object.
 
 Classes conforming to this protocol should subclass `PFRealmObject`.
 */
@protocol PFRealmObjectSubclass <NSObject>

@required

/**
 The name of the parse class.
 */
+ (NSString *)parseClassName;

@optional

/**
 Create a query which returns objects of this type.
 */
+ (PFRealmQuery *)query;

/**
 Returns a query for objects of this type with a given predicate.
 
 @param predicate The predicate to create conditions from.
 
 @return An instance of `PFRealmQuery`.
 
 @see [PFRealmQuery queryWithClassName:predicate:]
 */
+ (PFRealmQuery *)queryWithPredicate:(NSPredicate *)predicate;

/**
 Lets PFRealmStore know this class should be used to instantiate all objects with class type `parseClassName`.
 
 @warning This method must be called in `+load` of subclasses.
 */
+ (void)registerSubclass;

@end

/**
 PFObject category with realm instantiations.
 */
@interface PFObject (Realm)

/**
 Creates and initializes a Parse object stored in the given Realm.
 
 @param realm     The Realm which should manage the newly-created object.
 @param className The Parse object class name.
 @param objectId  The Parse object ID.
 
 @return The newly-initialized Parse object.
 */
+ (instancetype)objectInRealm:(RLMRealm *)realm className:(NSString *)className objectId:(NSString *)objectId;

/**
 Creates and initializes a Parse object stored in the default Realm.
 
 @param className The Parse object class name.
 @param objectId  The Parse object ID.
 
 @return The newly-initialized Parse object.
 */
+ (instancetype)objectInDefaultRealmWithClassName:(NSString *)className objectId:(NSString *)objectId;

@end

NS_ASSUME_NONNULL_END
