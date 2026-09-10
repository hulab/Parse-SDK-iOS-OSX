#!/usr/bin/env python3
"""Compile the production bundle filter: rtk python3 Parse/Tests/test_subclass_bundle_filter.py."""

import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / "Parse/Parse/Internal/Object/Subclassing/PFObjectSubclassingController.m").read_text()
method = source[source.index("- (void)_registerSubclassesInLoadedBundle:"):source.index("- (void)_registerSubclassesInBundle:")]
support = r'''
#import <Foundation/Foundation.h>
#include <assert.h>
#undef TARGET_OS_SIMULATOR
#define TARGET_OS_SIMULATOR CHECK_SIMULATOR

@interface TestBundle : NSObject
@property (nonatomic, copy) NSString *bundlePath;
@property (nonatomic, copy) NSString *executablePath;
@property (nonatomic, getter=isLoaded) BOOL loaded;
@end
@implementation TestBundle
- (BOOL)isKindOfClass:(Class)type { return type == NSBundle.class || [super isKindOfClass:type]; }
@end

@interface PFObjectSubclassingController : NSObject
@property (nonatomic) BOOL scanned;
- (void)_registerSubclassesInLoadedBundle:(NSBundle *)bundle;
- (void)_registerSubclassesInBundle:(NSBundle *)bundle;
@end
@implementation PFObjectSubclassingController
- (void)_registerSubclassesInBundle:(NSBundle *)bundle { self.scanned = YES; }
'''
checks = r'''
@end
static void check(NSString *path, BOOL loaded, NSString *executable, BOOL expected) {
    TestBundle *bundle = [TestBundle new];
    bundle.bundlePath = path;
    bundle.loaded = loaded;
    bundle.executablePath = executable;
    PFObjectSubclassingController *controller = [PFObjectSubclassingController new];
    [controller _registerSubclassesInLoadedBundle:(NSBundle *)bundle];
    if (controller.scanned != expected) {
        NSLog(@"Unexpected scan decision for %@ (loaded=%d, executable=%@)", path, loaded, executable);
        abort();
    }
}
int main(int argc, const char *argv[]) {
    @autoreleasepool {
        assert(argc == 3);
        NSString *runtime = @(argv[1]);
        BOOL skipRuntime = atoi(argv[2]);
        for (NSString *framework in @[@"Frameworks/Foundation.framework", @"PrivateFrameworks/UIKitCore.framework"]) {
            check([runtime stringByAppendingPathComponent:[@"System/Library/" stringByAppendingString:framework]], YES, @"binary", !skipRuntime);
        }
        check([runtime stringByAppendingPathComponent:@"usr/lib"], YES, @"binary", !skipRuntime);
        NSString *runtimeAlias = [runtime stringByReplacingOccurrencesOfString:@"/private/var/" withString:@"/var/"];
        assert([[runtime stringByResolvingSymlinksInPath] isEqualToString:[runtimeAlias stringByResolvingSymlinksInPath]]);
        check([runtimeAlias stringByAppendingPathComponent:@"usr/lib"], YES, @"binary", !skipRuntime);
        check([[runtime stringByAppendingString:@"-other"] stringByAppendingPathComponent:@"My.framework"], YES, @"binary", YES);
        check(@"/Users/runner/Library/Developer/CoreSimulator/Devices/device/data/Containers/Bundle/Application/id/mapstr.app/Frameworks/My.framework", YES, @"binary", YES);
        check(@"/Users/runner/System/Library/My.framework", YES, @"binary", YES);
        check(@"/System/Library/Frameworks/Foundation.framework", YES, @"binary", NO);
        check(@"/Applications/Xcode.app/iPhoneSimulator.sdk/System/Library/Frameworks/Foundation.framework", YES, @"binary", NO);
        check(@"/Library/Frameworks/Parse.framework", YES, @"binary", YES);
        check(@"/Library/Frameworks/Other.framework", YES, @"binary", NO);
        check(@"/Users/runner/My.framework", NO, @"binary", NO);
        check(@"/Users/runner/My.framework", YES, nil, NO);
        PFObjectSubclassingController *controller = [PFObjectSubclassingController new];
        [controller _registerSubclassesInLoadedBundle:nil];
        [controller _registerSubclassesInLoadedBundle:(NSBundle *)[NSObject new]];
        assert(!controller.scanned);
    }
}
'''
with tempfile.TemporaryDirectory(prefix="parse-subclass-bundle-filter-") as directory:
    path = Path(directory)
    runtime_path = path / "mnt/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 27.0.simruntime/Contents/Resources/RuntimeRoot"
    for bundle in ("System/Library/Frameworks/Foundation.framework", "System/Library/PrivateFrameworks/UIKitCore.framework", "usr/lib"):
        (runtime_path / bundle).mkdir(parents=True)
    Path(str(runtime_path) + "-other/My.framework").mkdir(parents=True)
    runtime_root = str(runtime_path.resolve())
    check_source = path / "check.m"
    check_source.write_text(support + method + checks)
    for simulator in (0, 1):
        binary = path / f"check-{simulator}"
        subprocess.run(["clang", "-fobjc-arc", "-Wall", "-Wextra", "-Wno-unused-parameter", "-Werror", f"-DCHECK_SIMULATOR={simulator}", "-framework", "Foundation", str(check_source), "-o", str(binary)], check=True, timeout=60)
        for simulator_root in (None, "", runtime_root):
            environment = os.environ.copy()
            environment.pop("SIMULATOR_ROOT", None)
            if simulator_root is not None:
                environment["SIMULATOR_ROOT"] = simulator_root
            subprocess.run([str(binary), runtime_root, str(int(simulator and bool(simulator_root)))], env=environment, check=True, timeout=30)
print("Subclass bundle filter: simulator/native, missing/empty runtime, symlink aliases, path boundaries, app frameworks and macOS Parse exception passed.")
