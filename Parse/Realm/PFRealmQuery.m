// PFRealmQuery.m
//
// Created by Maxime Epain on 23/05/16.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import <Bolts/BFExecutor.h>
#import <Realm/RLMResults.h>

#import "PFRealmQuery.h"
#import "PFRealmObject.h"

@interface PFRealmQuery ()
@property (nonatomic, strong) NSPredicate *predicate;
@end

@implementation PFRealmQuery

///--------------------------------------
#pragma mark - Creating a Query for a Class
///--------------------------------------

- (instancetype)initWithClassName:(NSString *)className {
    self = [super init];
    if (self) {
        self.store = [PFRealmStore defaultStore];
        query_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        _parseClassName = className;
        [self where:@"parseClassName == %@", self.parseClassName];
    }
    return self;
}

+ (instancetype)queryWithClassName:(NSString *)className {
    return [[self alloc] initWithClassName:className];
}

+ (instancetype)queryWithClassName:(NSString *)className predicate:(nullable NSPredicate *)predicate {
    PFRealmQuery *query = [self queryWithClassName:className];
    query.predicate = predicate;
    return query;
}

///--------------------------------------
#pragma mark - Adding Basic Constraints
///--------------------------------------

- (instancetype)where:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self addPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args] type:NSAndPredicateType];
    va_end(args);
    return self;
}

- (instancetype)and:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self addPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args] type:NSAndPredicateType];
    va_end(args);
    return self;
}

- (instancetype)or:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self addPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args] type:NSOrPredicateType];
    va_end(args);
    return self;
}

- (instancetype)not:(NSString *)predicateFormat, ... {
    va_list args;
    va_start(args, predicateFormat);
    [self addPredicate:[NSPredicate predicateWithFormat:predicateFormat arguments:args] type:NSNotPredicateType];
    va_end(args);
    return self;
}

- (void)addPredicate:(NSPredicate *)predicate type:(NSCompoundPredicateType)type {
    if (!predicate) return;
    
    if (!self.predicate) {
        self.predicate = predicate;
        return;
    }
    
    self.predicate = [[NSCompoundPredicate alloc] initWithType:type subpredicates:@[self.predicate, predicate]];
}

///--------------------------------------
#pragma mark - Getting all Matches for a Query
///--------------------------------------

- (BFTask<NSArray<PFObject *> *> *)findObjectsInBackground {
    
    return [BFTask taskFromExecutor:[BFExecutor executorWithDispatchQueue:query_queue] withBlock:^id _Nonnull{
        RLMRealm *realm = [RLMRealm realmWithConfiguration:self.store.configuration error:nil];
        
        Class class = [PFRealmStore subclassForParseClassName:self.parseClassName];
        RLMResults<PFRealmObject *> *results = [class objectsInRealm:realm withPredicate:self.predicate];
        
        NSMutableArray *objects = [NSMutableArray array];
        for (PFRealmObject *result in results) {
            
            PFObject *object = [result objectInRealm:realm];
            [objects addObject:object];
        }
        return [BFTask taskWithResult:objects];
    }];
}

- (void)findObjectsInBackgroundWithBlock:(PFRealmQueryArrayResultBlock)block {
    
    [[self findObjectsInBackground] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                               withBlock:^id _Nullable(BFTask<NSArray<PFObject *> *> * _Nonnull task) {
                                                   block(task.result, task.error);
                                                   return task;
                                               }];
}

///--------------------------------------
#pragma mark - Getting the First Match in a Query
///--------------------------------------

- (BFTask<PFObject *> *)getFirstObjectInBackground {
    
    return [BFTask taskFromExecutor:[BFExecutor executorWithDispatchQueue:query_queue] withBlock:^id _Nonnull{
        RLMRealm *realm = [RLMRealm realmWithConfiguration:self.store.configuration error:nil];
        
        Class class = [PFRealmStore subclassForParseClassName:self.parseClassName];
        RLMResults<PFRealmObject *> *results = [class objectsInRealm:realm withPredicate:self.predicate];
        
        PFObject *object = [results.firstObject objectInRealm:realm];
        return [BFTask taskWithResult:object];
        
    }];
}

- (void)getFirstObjectInBackgroundWithBlock:(PFRealmQueryObjectResultBlock)block {
    
    [[self getFirstObjectInBackground] continueWithExecutor:[BFExecutor mainThreadExecutor]
                                                  withBlock:^id _Nullable(BFTask<PFObject *> * _Nonnull task) {
                                                      block(task.result, task.error);
                                                      return task;
                                                  }];
}

@end
