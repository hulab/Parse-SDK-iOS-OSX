#!/usr/bin/env python3
"""Run the concurrent equality unit test without the legacy Xcode test project.

Usage: rtk python3 Parse/Tests/test_object_equality.py
Compiles the production state access/equality methods and the actual unit test.
Supplies minimal Foundation objects for construction, copying and notifications,
and maps XCTest assertions to C assertions; this does not build the full SDK.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
objects = (root / "Parse/Parse/Source/PFObject.m").read_text()
states = (root / "Parse/Parse/Internal/Object/State/PFObjectState.m").read_text()
tests = (root / "Parse/Tests/Unit/ObjectUnitTests.m").read_text()


def method(source, signature):
    start = source.index(signature)
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end] + "\n"


support = r'''
#import <Foundation/Foundation.h>
#import <dispatch/dispatch.h>
#include <assert.h>
#define XCTAssertTrue(value, ...) assert(value)
#define XCTAssertFalse(value, ...) assert(!(value))
#define XCTAssertEqual(a, b, ...) assert((a) == (b))
@interface PFObjectState : NSObject <NSCopying>
@property (nonatomic, copy) NSString *parseClassName;
@property (nonatomic, copy) NSString *objectId;
+ (instancetype)stateWithParseClassName:(NSString *)name objectId:(NSString *)objectId isComplete:(BOOL)complete;
- (BOOL)isEqualToState:(PFObjectState *)state;
@end
@implementation PFObjectState
+ (instancetype)stateWithParseClassName:(NSString *)name objectId:(NSString *)objectId isComplete:(BOOL)complete {
    PFObjectState *state = [self new];
    state.parseClassName = name;
    state.objectId = objectId;
    return state;
}
- (id)copyWithZone:(NSZone *)zone { return self; }
'''
object_support = r'''
@interface PFObjectUtilities : NSObject
@end
@implementation PFObjectUtilities
+ (BOOL)isObject:(id)left equalToObject:(id)right { return left == right || [left isEqual:right]; }
@end
@interface PFObject : NSObject {
    NSObject *lock;
    PFObjectState *_pfinternal_state;
}
@property (nonatomic, strong) PFObjectState *_state;
@property (nonatomic, copy) NSString *objectId;
- (instancetype)initWithClassName:(NSString *)name;
- (BOOL)isEqualToObject:(PFObject *)object;
@end
@implementation PFObject
- (instancetype)initWithClassName:(NSString *)name {
    if ((self = [super init])) {
        lock = [NSObject new];
        _pfinternal_state = [PFObjectState stateWithParseClassName:name objectId:nil isComplete:NO];
    }
    return self;
}
- (NSString *)objectId { return self._state.objectId; }
- (void)setObjectId:(NSString *)objectId { self._state = [PFObjectState stateWithParseClassName:self._state.parseClassName objectId:objectId isComplete:YES]; }
- (void)_notifyObjectIdChangedFrom:(NSString *)oldId toObjectId:(NSString *)newId {}
'''
code = support + method(states, "- (BOOL)isEqualToState:") + "@end\n" + object_support
for signature in ("- (PFObjectState *)_state", "- (void)set_state:", "- (BOOL)isEqualToObject:", "- (BOOL)isEqual:(id)other", "- (NSUInteger)hash"):
    code += method(objects, signature)
code += "@end\n" + tests[tests.index("static char PFObjectEqualityQueueKey;"):tests.index("@interface ObjectUnitTests")]
code += "@interface ObjectUnitTests : NSObject\n@end\n@implementation ObjectUnitTests\n"
code += method(tests, "- (void)testEqualityRetainsStatesDuringConcurrentReplacement") + "@end\n"
code += 'int main(void) { @autoreleasepool { [[ObjectUnitTests new] testEqualityRetainsStatesDuringConcurrentReplacement]; puts("Concurrent PFObject equality: both state lifetimes and equality semantics passed."); } }\n'
with tempfile.TemporaryDirectory(prefix="parse-object-equality-") as directory:
    path = Path(directory)
    source = path / "check.m"
    source.write_text(code)
    subprocess.run(["rtk", "clang", "-fobjc-arc", "-fblocks", "-Wall", "-Wextra", "-Wno-unused-parameter", "-Werror", "-framework", "Foundation", str(source), "-o", str(path / "check")], check=True, timeout=60)
    subprocess.run([str(path / "check")], check=True, timeout=30)
