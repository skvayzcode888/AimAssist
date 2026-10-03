#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

@interface UserSettingsManager : NSObject
@end

static IMP orig_setTraj, orig_setWide, orig_setRuler, orig_setOff;

static BOOL force_YES(id self, SEL _cmd) { return YES; }
static BOOL force_NO(id self, SEL _cmd) { return NO; }

static void new_setTraj(id self, SEL _cmd, BOOL val) {
    ((void(*)(id, SEL, BOOL))orig_setTraj)(self, _cmd, YES);
}
static void new_setWide(id self, SEL _cmd, BOOL val) {
    ((void(*)(id, SEL, BOOL))orig_setWide)(self, _cmd, YES);
}
static void new_setRuler(id self, SEL _cmd, BOOL val) {
    ((void(*)(id, SEL, BOOL))orig_setRuler)(self, _cmd, YES);
}
static void new_setOff(id self, SEL _cmd, BOOL val) {
    ((void(*)(id, SEL, BOOL))orig_setOff)(self, _cmd, NO);
}

static void applyHooks(Class cls) {
    if (!cls) return;
    Method m;
    
    m = class_getInstanceMethod(cls, @selector(showCueBallTrajectory));
    if (m) method_setImplementation(m, (IMP)force_YES);
    
    m = class_getInstanceMethod(cls, @selector(wideGuideline));
    if (m) method_setImplementation(m, (IMP)force_YES);
    
    m = class_getInstanceMethod(cls, @selector(showFineTuningRuler));
    if (m) method_setImplementation(m, (IMP)force_YES);
    
    m = class_getInstanceMethod(cls, @selector(noGuidelinesOffline));
    if (m) method_setImplementation(m, (IMP)force_NO);
    
    m = class_getInstanceMethod(cls, @selector(setShowCueBallTrajectory:));
    if (m) orig_setTraj = method_setImplementation(m, (IMP)new_setTraj);
    
    m = class_getInstanceMethod(cls, @selector(setWideGuideline:));
    if (m) orig_setWide = method_setImplementation(m, (IMP)new_setWide);
    
    m = class_getInstanceMethod(cls, @selector(setShowFineTuningRuler:));
    if (m) orig_setRuler = method_setImplementation(m, (IMP)new_setRuler);
    
    m = class_getInstanceMethod(cls, @selector(setNoGuidelinesOffline:));
    if (m) orig_setOff = method_setImplementation(m, (IMP)new_setOff);
    
    NSLog(@"[AimAssist] Successfully patched UserSettingsManager!");
}

__attribute__((constructor))
static void init_tweak() {
    @autoreleasepool {
        NSLog(@"[AimAssist] dylib loaded, searching for UserSettingsManager...");
        
        Class cls = objc_getClass("UserSettingsManager");
        if (cls) {
            applyHooks(cls);
        } else {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                Class c = objc_getClass("UserSettingsManager");
                if (c) {
                    applyHooks(c);
                } else {
                    NSLog(@"[AimAssist] ERROR: Class UserSettingsManager not found!");
                }
            });
        }
    }
}
