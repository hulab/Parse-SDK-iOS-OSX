// PFRealmStore.h
//
// Created by Maxime Epain on 24/05/16.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import <Foundation/Foundation.h>

#import <Bolts/BFTask.h>
#import <Realm/RLMRealmConfiguration.h>

#import <Parse/PFObject.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The PFRealmStore represents a Realm store for Parse objects.
 */
@interface PFRealmStore : NSObject {
    @protected
    dispatch_queue_t store_queue;
}

typedef BOOL(^MAPCascadeBlock)(__kindof PFObject *object);

/**
 The store's configuration.
 */
@property (nonatomic, strong) RLMRealmConfiguration *configuration;

/**
 Creates and initializes store for the current Parse user.
 
 @return The newly-initialized user store.
 */
+ (instancetype)defaultStore;

/**
 Instantiates an object store for the given Realm configuration.
 
 @param configuration The Realm configuration
 
 @return An initialized user store.
 */
- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

///--------------------------------------
#pragma mark - Saving Objects to Realm
///--------------------------------------

/**
 Stores an object, and every object it points to recursively, to the user's realm database.
 
 @param object   The root of the objects to save.
 
 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)saveObject:(__kindof PFObject *)object;

/**
 Stores objects, and every object it points to recursively, to the user's realm database.
 
 @param objects The root objects to save.
 
 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)saveObjects:(NSArray<__kindof PFObject *> *)objects;

///--------------------------------------
#pragma mark - Removing Objects from Realm
///--------------------------------------

/**
 Stores an object to the realm database.
 
 @param object   The object to remove.
 
 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)removeObject:(__kindof PFObject *)object;

/**
 Removes an object in cascade from the realm database.
 
 @param object The object to remove.
 @param cascade A block object to be executed when a nested object has been found, this block returns whether or not the nested object must be deleted.
 
 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)removeObject:(__kindof PFObject *)object cascade:(nullable MAPCascadeBlock)cascade;

/**
 Removes objects from the realm database.
 
 @param objects The objects to remove.
 
 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)removeObjects:(NSArray<__kindof PFObject *> *)objects;

/**
 Removes objects in cascade from the realm database.

 @param objects The objects to remove.
 @param cascade A block object to be executed when a nested object has been found, this block returns whether or not the nested object must be deleted.

 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSNumber *> *)removeObjects:(NSArray<__kindof PFObject *> *)objects cascade:(nullable MAPCascadeBlock)cascade;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

@protocol PFRealmObjectSubclass;

/**
 `PFRealmStore` category to register Realm object subclass related to Parse class name.
 */
@interface PFRealmStore (Polymorphism)

///--------------------------------------
#pragma mark - PFRealmStore factory methods for Subclassing
///--------------------------------------

/**
Lets the store know this class should be used to instantiate all objects with class type `parseClassName`.

@param subclass       The subclass to register.
*/
+ (void)registerSubclass:(Class<PFRealmObjectSubclass>)subclass;

/**
 Unregisters this class from the subclass factory.
 
 @param subclass The subclass to unregister.
 */
- (void)unregisterSubclass:(Class<PFRealmObjectSubclass>)subclass;

/**
 Gets the subclass registered for the specified Parse class name.
 
 @param parseClassName The Parse class name.
 
 @return The `PFRealmObject` subclass registered for the specified class name. If none has been registered, `PFRealmObject` is retruned.
 */
+ (Class)subclassForParseClassName:(NSString *)parseClassName;

@end

/**
 `PFRealmStore` category to set the default Realm database path to a shared coontainer.
 */
@interface PFRealmStore (SharingApplication)

///--------------------------------------
#pragma mark - Enabling Extensions Data Sharing
///--------------------------------------

/**
 Enables data sharing with an application group identifier.
 
 After enabling - Managed Store is going to be available to every application/extension in a group that have the same group identifier.
 
 @param groupIdentifier Application Group Identifier to share data with.
 */
+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier;

@end

NS_ASSUME_NONNULL_END
