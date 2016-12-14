// PFRealmStore.m
//
// Created by Maxime Epain on 24/05/16.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import <Bolts/BFExecutor.h>

#import "PFRealmStore.h"
#import "PFObject.h"
#import "PFInternalUtils.h"
#import "PFRealmObject.h"

@implementation PFRealmStore

///--------------------------------------
#pragma mark - Init
///--------------------------------------

+ (instancetype)defaultStore {
    return [[self alloc] initWithConfiguration:[RLMRealmConfiguration defaultConfiguration]];
}

- (instancetype)initWithConfiguration:(RLMRealmConfiguration *)configuration {
    self = [super init];
    if (self) {
        self.configuration = configuration;
        store_queue = dispatch_queue_create("com.hulab.RealmStore", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

///--------------------------------------
#pragma mark - Saving Objects to Realm
///--------------------------------------

- (BFTask<NSNumber *> *)saveObject:(PFObject *)object {
    return [self saveObjects:@[object]];
}

- (BFTask<NSNumber *> *)saveObjects:(NSArray<PFObject *> *)objects {
    return [BFTask taskFromExecutor:[BFExecutor executorWithDispatchQueue:store_queue] withBlock:^id _Nonnull{
        // Add to Realm with transaction
        NSError *error = nil;
        RLMRealm *realm = [RLMRealm realmWithConfiguration:self.configuration error:&error];
        
        if (!error) {
            [realm beginWriteTransaction];
            
            [PFInternalUtils traverseObject:objects usingBlock:^id(id object) {
                
                if ([object isKindOfClass:[PFObject class]]) {
                    Class class = [PFRealmStore subclassForParseClassName:[object parseClassName]];
                    PFRealmObject *managedObject = [[class alloc] initWithObject:object];
                    [realm addOrUpdateObject:managedObject];
                }
                return object;
            }];
            
            [realm commitWriteTransaction:&error];
        }
        
        if (error) {
            return [BFTask taskWithError:error];
        }
        return [BFTask taskWithResult:@(YES)];
    }];
}

///--------------------------------------
#pragma mark - Removing Objects from Realm
///--------------------------------------

- (BFTask<NSNumber *> *)removeObject:(PFObject *)object {
    return [self removeObjects:@[object] cascade:nil];
}

- (BFTask<NSNumber *> *)removeObject:(__kindof PFObject *)object cascade:(MAPCascadeBlock)cascade {
    return [self removeObjects:@[object] cascade:cascade];
}

- (BFTask<NSNumber *> *)removeObjects:(NSArray<PFObject *> *)objects {
    return [self removeObjects:objects cascade:nil];
}

- (BFTask<NSNumber *> *)removeObjects:(NSArray<__kindof PFObject *> *)objects cascade:(MAPCascadeBlock)cascade {
    return [BFTask taskFromExecutor:[BFExecutor executorWithDispatchQueue:store_queue] withBlock:^id _Nonnull{
        // Add to Realm with transaction
        NSError *error = nil;
        RLMRealm *realm = [RLMRealm realmWithConfiguration:self.configuration error:&error];
        
        if (!error) {
            [realm beginWriteTransaction];
            
            [PFInternalUtils traverseObject:objects usingBlock:^id(id object) {
                
                if ([object isKindOfClass:[PFObject class]]) {
                    
                    BOOL delete = [objects containsObject:object];
                    if (!delete && cascade) {
                        delete = cascade(object);
                    }
                    
                    if (delete) {
                        Class class = [PFRealmStore subclassForParseClassName:[object parseClassName]];
                        PFRealmObject *managedObject = [class objectInRealm:realm forPrimaryKey:[object objectId]];
                        [realm deleteObject:managedObject];
                    }
                }
                
                return object;
            }];
            
            [realm commitWriteTransaction:&error];
        }
        
        if (error) {
            return [BFTask taskWithError:error];
        }
        return [BFTask taskWithResult:@(YES)];
    }];
}

@end

@implementation PFRealmStore (Polymorphism)

///--------------------------------------
#pragma mark - PFRealmStore factory methods for Subclassing
///--------------------------------------

static NSMutableDictionary *subclassRegistration;

// Picked up in Parse
+ (void)registerSubclass:(Class)subclass {
    NSAssert([subclass conformsToProtocol:@protocol(PFRealmObjectSubclass)],
             @"Can only call +registerSubclass on subclasses conforming to PFRealmObjectSubclass.");
    
    NSString *parseClassName = [subclass parseClassName];
    Class registeredClass    = NSClassFromString(subclassRegistration[parseClassName]);
    
    if (registeredClass && registeredClass != subclass) {
        // We've already registered a more specific subclass
        if ([registeredClass isSubclassOfClass:subclass]) {
            return;
        }
        
        NSAssert([subclass isSubclassOfClass:registeredClass],
                 @"Tried to register both %@ and %@ as the native PFRealmObject subclass "
                 "of %@. Cannot determine the right class to use because neither "
                 "inherits from the other.", registeredClass, subclass, parseClassName);
    }
    
    if (!subclassRegistration) {
        subclassRegistration = [NSMutableDictionary dictionary];
    }
    
    // Register the subclass
    subclassRegistration[parseClassName] = NSStringFromClass(subclass);
}

// Picked up in Parse
- (void)unregisterSubclass:(Class)subclass {
    NSAssert([subclass conformsToProtocol:@protocol(PFRealmObjectSubclass)],
             @"Can only call +registerSubclass on subclasses conforming to PFRealmObjectSubclass.");
    
    NSString *parseClassName = [subclass parseClassName];
    Class registeredClass    = NSClassFromString(subclassRegistration[parseClassName]);
    
    // Make it a no-op if the class itself is not registered or
    // if there is another class registered under the same name.
    if (registeredClass == nil || ![registeredClass isEqual:subclass]) {
        return;
    }
    
    [subclassRegistration removeObjectForKey:parseClassName];
}

// Picked up in Parse
+ (Class)subclassForParseClassName:(NSString *)parseClassName {
    NSString *class = subclassRegistration[parseClassName];
    
    if (!class) {
        return PFRealmObject.class;
    }
    return NSClassFromString(class);
}

@end

@implementation PFRealmStore (SharingApplication)

///--------------------------------------
#pragma mark - Extensions Data Sharing
///--------------------------------------

+ (void)enableDataSharingWithApplicationGroupIdentifier:(NSString *)groupIdentifier {
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSURL *container = [fm containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    NSAssert(container, @"There is no '%@' App group, check your app capabilities", groupIdentifier);
    
    container = [container URLByAppendingPathComponent:@"Mapstr"];
    
    if (![fm fileExistsAtPath:container.path]) {
        NSError *error = nil;
        // TODO (maxep) : Handle error
        [fm createDirectoryAtPath:container.path withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    RLMRealmConfiguration *configuration = [RLMRealmConfiguration defaultConfiguration];
    configuration.fileURL = [container URLByAppendingPathComponent:@"default.realm"];
    [RLMRealmConfiguration setDefaultConfiguration:configuration];
}

@end
