// PFRealmQuery.h
//
// Created by Maxime Epain on 23/05/16.
// Copyright © 2016 Hulab. All rights reserved.
//
// This source code is licensed under the BSD-style license found in the
// LICENSE file in the root directory of this source tree. An additional grant
// of patent rights can be found in the PATENTS file in the same directory.

#import <Foundation/Foundation.h>

#import <Bolts/BFTask.h>

#import <Parse/PFRealmStore.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The `PFRealmQuery` allows to query managed objects from realm and decode them to Parse objects.
 */
@interface PFRealmQuery<MAPObjectType : PFObject *> : NSObject {
    @protected
    dispatch_queue_t query_queue;
}

///--------------------------------------
#pragma mark - Blocks
///--------------------------------------

typedef void (^PFRealmQueryObjectResultBlock)(MAPObjectType _Nullable objects, NSError * _Nullable error);
typedef void (^PFRealmQueryArrayResultBlock)(NSArray<MAPObjectType> *_Nullable objects, NSError * _Nullable error);

///--------------------------------------
#pragma mark - Properties
///--------------------------------------

/**
 The class name to query for.
 */
@property (nonatomic, readonly) NSString *parseClassName;

/**
 The store to query. [PFRealmStore defaultStore] by default.
 */
@property (nonatomic, strong) PFRealmStore *store;

///--------------------------------------
#pragma mark - Creating a Query for a Class
///--------------------------------------

/**
 Initializes the query with a class name.
 
 @param className The class name.
 */
- (instancetype)initWithClassName:(NSString *)className NS_DESIGNATED_INITIALIZER;

/**
 Returns a `PFRealmQuery` for a given class.
 
 @param className The class to query on.
 
 @return A `PFRealmQuery` object.
 */
+ (instancetype)queryWithClassName:(NSString *)className;

/**
 Creates a `PFRealmQuery` with the constraints given by predicate.
 
 The following types of predicates are supported:
 
 - The comparison operands can be property names or constants. At least one of the operands must be a property name.
 - The comparison operators ==, <=, <, >=, >, !=, and BETWEEN are supported for int, long, long long, float, double, and NSDate property types. Such as age == 45
 - Identity comparisons ==, !=, e.g. [Employee objectsWhere:@"company == %@", company]
 - The comparison operators == and != are supported for boolean properties.
 - For NSString and NSData properties, we support the ==, !=, BEGINSWITH, CONTAINS, and ENDSWITH operators, such as name CONTAINS ‘Ja’
 - Case insensitive comparisons for strings, such as name CONTAINS[c] ‘Ja’. Note that only characters “A-Z” and “a-z” will be ignored for case.
 - Realm supports the following compound operators: “AND”, “OR”, and “NOT”. Such as name BEGINSWITH ‘J’ AND age >= 32
 - The containment operand IN such as name IN {‘Lisa’, ‘Spike’, ‘Hachi’}
 - Nil comparisons ==, !=, e.g. [Company objectsWhere:@"ceo == nil"]. Note that Realm treats nil as a special value rather than the absence of a value, so unlike with SQL nil equals itself.
 - ANY comparisons, such as ANY student.age < 21
 - The aggregate expressions @count, @min, @max, @sum and @avg are supported on RLMArray and RLMResults properties, e.g. [Company objectsWhere:@"employees.@count > 5"] to find all companies with more than five employees.
 - Subqueries are supported with the following limitations:
    * @count is the only operator that may be applied to the SUBQUERY expression.
    * The SUBQUERY(…).@count expression must be compared with a constant.
    * Correlated subqueries are not yet supported.
 @see https://realm.io/docs/objc/latest/#filtering
 
 @param className The class to query on.
 @param predicate The predicate to create conditions from.
 */
+ (instancetype)queryWithClassName:(NSString *)className predicate:(nullable NSPredicate *)predicate;

///--------------------------------------
#pragma mark - Adding Basic Constraints
///--------------------------------------

/**
 Add a constraint to the query that requires the given predicate.
 
 @param predicateFormat The predicate format string which can accept variable arguments.
 
 @return The same instance of `PFRealmQuery` as the receiver. This allows method chaining.
 */
- (instancetype)where:(NSString *)predicateFormat, ... ;

/**
 Add a constraint to the query that AND-ing the given predicate.
 
 @param predicateFormat The predicate format string which can accept variable arguments.
 
 @return The same instance of `PFRealmQuery` as the receiver. This allows method chaining.
 */
- (instancetype)and:(NSString *)predicateFormat, ... ;

/**
 Add a constraint to the query that OR-ing the given predicate.
 
 @param predicateFormat The predicate format string which can accept variable arguments.
 
 @return The same instance of `PFRealmQuery` as the receiver. This allows method chaining.
 */
- (instancetype)or:(NSString *)predicateFormat, ... ;

/**
 Add a constraint to the query that NOT-ing the given predicate.
 
 @param predicateFormat The predicate format string which can accept variable arguments.
 
 @return The same instance of `PFRealmQuery` as the receiver. This allows method chaining.
 */
- (instancetype)not:(NSString *)predicateFormat, ... ;

/**
 Add a constraint to the query that requires the given predicate.
 
 @param predicate The predicate.
 @param type      The type of the new predicate.
 */
- (void)addPredicate:(NSPredicate *)predicate type:(NSCompoundPredicateType)type;

///--------------------------------------
#pragma mark - Getting all Matches for a Query
///--------------------------------------

/**
 Finds objects *asynchronously* and sets the `NSArray` of `PFObject` objects as a result of the task.
 
 @return The task, that encapsulates the work being done.
 */
- (BFTask<NSArray<MAPObjectType> *> *)findObjectsInBackground;

/**
 Finds objects *asynchronously* and calls the given block with the results.
 
 @param block The block to execute.
 It should have the following argument signature: `^(NSArray *objects, NSError *error)`
 */
- (void)findObjectsInBackgroundWithBlock:(PFRealmQueryArrayResultBlock)block;

///--------------------------------------
#pragma mark - Getting the First Match in a Query
///--------------------------------------

/**
 Gets an object *asynchronously* and sets it as a result of the task.
 
 @warning This method mutates the query. It will reset the limit to `1`.
 
 @return The task, that encapsulates the work being done.
 */
- (BFTask<MAPObjectType> *)getFirstObjectInBackground;

/**
 Gets an object *asynchronously* and calls the given block with the result.
 
 @warning This method mutates the query. It will reset the limit to `1`.
 
 @param block The block to execute.
 It should have the following argument signature: `^(PFObject *object, NSError *error)`.
 `result` will be `nil` if `error` is set OR no object was found matching the query.
 `error` will be `nil` if `result` is set OR if the query succeeded, but found no results.
 */
- (void)getFirstObjectInBackgroundWithBlock:(PFRealmQueryObjectResultBlock)block;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
