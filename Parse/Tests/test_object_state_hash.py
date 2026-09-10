#!/usr/bin/env python3
"""Check production state construction/copying/equality/hash with Foundation only.

Usage: rtk python3 Parse/Tests/test_object_state_hash.py
Compiles the actual methods and integer hash helpers without the legacy XCTest
project; unrelated state encoding and persistence methods are not needed here.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
state_source = (root / "Parse/Parse/Internal/Object/State/PFObjectState.m").read_text()
hash_source = (root / "Parse/Parse/Internal/PFHash.m").read_text()


def method(source, signature):
    start = source.index(signature)
    end = source.index("{", start) + 1
    depth = 1
    while depth:
        depth += (source[end] == "{") - (source[end] == "}")
        end += 1
    return source[start:end] + "\n"


code = r'''
#import <Foundation/Foundation.h>
#include <assert.h>
#include <stdio.h>
NSUInteger PFLongHash(unsigned long long value);
NSUInteger PFIntegerPairHash(NSUInteger a, NSUInteger b);
@interface PFObjectState : NSObject <NSCopying>
@property (nonatomic, copy) NSString *parseClassName;
@property (nonatomic, copy) NSString *objectId;
@property (nonatomic, strong) NSDate *createdAt;
@property (nonatomic, strong) NSDate *updatedAt;
@property (nonatomic, copy) NSMutableDictionary *serverData;
@property (nonatomic, getter=isComplete) BOOL complete;
@property (nonatomic, getter=isDeleted) BOOL deleted;
- (instancetype)initWithState:(PFObjectState *)state;
- (instancetype)initWithParseClassName:(NSString *)name objectId:(NSString *)objectId isComplete:(BOOL)complete;
- (BOOL)isEqualToState:(PFObjectState *)state;
@end
@implementation PFObjectState
'''
for signature in (
    "- (instancetype)init {",
    "- (instancetype)initWithState:(PFObjectState *)state {",
    "- (instancetype)initWithParseClassName:(NSString *)parseClassName\n",
    "- (id)copyWithZone:",
    "- (BOOL)isEqual:(id)other",
    "- (BOOL)isEqualToState:",
    "- (NSUInteger)hash",
):
    code += method(state_source, signature)
code += "@end\n" + method(hash_source, "extern NSUInteger PFLongHash(") + method(hash_source, "extern NSUInteger PFIntegerPairHash(")
code += r'''
int main(void) {
    @autoreleasepool {
        PFObjectState *saved = [[PFObjectState alloc] initWithParseClassName:@"MAPPlace" objectId:@"abc123" isComplete:YES];
        PFObjectState *sameIdentity = [[PFObjectState alloc] initWithParseClassName:@"MAPPlace" objectId:[@"abc123" mutableCopy] isComplete:NO];
        PFObjectState *copy = [saved copy];
        assert(copy != saved && [saved isEqual:copy] && copy.hash == saved.hash);
        assert([saved isEqual:sameIdentity] && saved.hash == sameIdentity.hash);
        assert([[NSSet setWithObject:saved] containsObject:sameIdentity]);
        PFObjectState *otherClass = [[PFObjectState alloc] initWithParseClassName:@"OtherClass" objectId:@"abc123" isComplete:YES];
        PFObjectState *otherId = [[PFObjectState alloc] initWithParseClassName:@"MAPPlace" objectId:@"def456" isComplete:YES];
        assert(![saved isEqual:otherClass] && ![saved isEqual:otherId]);
        PFObjectState *unsaved = [[PFObjectState alloc] initWithParseClassName:@"MAPPlace" objectId:nil isComplete:NO];
        PFObjectState *unsavedCopy = [unsaved copy];
        assert([unsaved isEqual:unsaved] && ![unsaved isEqual:unsavedCopy]);
        assert(unsaved.hash == unsavedCopy.hash);
        assert(([NSSet setWithObjects:unsaved, unsavedCopy, nil].count == 2));
        unsavedCopy.objectId = @"abc123";
        assert([unsavedCopy isEqual:saved] && unsavedCopy.hash == saved.hash);
        saved.serverData[@"name"] = @"Changed fields do not alter identity";
        saved.complete = NO;
        assert([saved isEqual:copy] && saved.hash == copy.hash);
        assert(![saved isEqual:nil] && ![saved isEqual:@"abc123"]);
        volatile NSUInteger checksum = 0;
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        for (NSUInteger index = 0; index < 200000; index++) checksum ^= saved.hash;
        double stateTime = CFAbsoluteTimeGetCurrent() - start;
        start = CFAbsoluteTimeGetCurrent();
        for (NSUInteger index = 0; index < 200000; index++) checksum ^= [NSString stringWithFormat:@"%@:%@", saved.parseClassName, saved.objectId].hash;
        double formattedTime = CFAbsoluteTimeGetCurrent() - start;
        printf("PFObjectState hash: saved, unsaved, copies and changed identity passed; 200000 hashes %.2f ms, formatted reference %.2f ms (checksum %lu).\n", stateTime * 1000, formattedTime * 1000, (unsigned long)checksum);
    }
    return 0;
}
'''
with tempfile.TemporaryDirectory(prefix="parse-object-state-hash-") as directory:
    path = Path(directory)
    source = path / "check.m"
    source.write_text(code)
    subprocess.run(["rtk", "clang", "-O2", "-fobjc-arc", "-fblocks", "-Wall", "-Wextra", "-Wno-unused-parameter", "-Werror", "-framework", "Foundation", str(source), "-o", str(path / "check")], check=True, timeout=60)
    subprocess.run(["rtk", "proxy", str(path / "check")], check=True, timeout=30)
