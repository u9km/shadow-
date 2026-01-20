#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/mach_host.h>

// ============================================================================
// [1. الموارد والمتغيرات العالمية]
// ============================================================================
[span_0](start_span)static NSFileManager *_fileManager = nil;[span_0](end_span)
[span_1](start_span)static NSString *_anoTmpPath = nil;[span_1](end_span)
[span_2](start_span)static NSString *_libraryPath = nil;[span_2](end_span)
[span_3](start_span)static NSString *_tmpPath = nil;[span_3](end_span)
[span_4](start_span)static UILabel *_persistentLabel = nil;[span_4](end_span)
[span_5](start_span)static UIWindow *_overlayWindow = nil;[span_5](end_span)
[span_6](start_span)static dispatch_source_t _monitorTimer = nil;[span_6](end_span)
[span_7](start_span)static id _orientationObserver = nil;[span_7](end_span)

void UpdateLabelLayout();
CGFloat GetAppMemoryPercent();
NSString *GetAppleDeviceFullName();
void UpdateLabelText();

#pragma mark - 2. تهيئة موارد النظام
void InitGlobalResources() {
    @autoreleasepool {
        if (!_fileManager) {
            _[span_8](start_span)fileManager = [NSFileManager defaultManager];[span_8](end_span)
        }
        [span_9](start_span)NSString *homeDir = NSHomeDirectory();[span_9](end_span)
        _[span_10](start_span)anoTmpPath = [homeDir stringByAppendingPathComponent:@"Documents/ano_tmp"];[span_10](end_span)
        _[span_11](start_span)libraryPath = [homeDir stringByAppendingPathComponent:@"Library"];[span_11](end_span)
        _[span_12](start_span)tmpPath = [homeDir stringByAppendingPathComponent:@"tmp"];[span_12](end_span)
    }
}

#pragma mark - 3. حلقة التنظيف (Anti-Ban)
void SafeDeletePath(NSString *path) {
    [span_13](start_span)if (_fileManager && [_fileManager fileExistsAtPath:path]) {[span_13](end_span)
        [span_14](start_span)[_fileManager removeItemAtPath:path error:NULL];[span_14](end_span)
    }
}

void DeleteFilesLoop() {
    [span_15](start_span)SafeDeletePath(_anoTmpPath);[span_15](end_span)
    [span_16](start_span)SafeDeletePath(_libraryPath);[span_16](end_span)
    [span_17](start_span)SafeDeletePath(_tmpPath);[span_17](end_span)
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [span_18](start_span)DeleteFilesLoop();[span_18](end_span)
    });
}

#pragma mark - 4. مراقبة الذاكرة (Performance)
CGFloat GetAppMemoryPercent() {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    [span_19](start_span)kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);[span_19](end_span)
    [span_20](start_span)if (kerr != KERN_SUCCESS) return 0.0;[span_20](end_span)
    
    [span_21](start_span)int mib[] = {CTL_HW, HW_MEMSIZE};[span_21](end_span)
    [span_22](start_span)uint64_t totalMem = 0;[span_22](end_span)
    [span_23](start_span)size_t len = sizeof(totalMem);[span_23](end_span)
    [span_24](start_span)sysctl(mib, 2, &totalMem, &len, NULL, 0);[span_24](end_span)
    
    return totalMem == 0 ? [span_25](start_span)0.0 : roundf((CGFloat)(info.resident_size * 100.0 / totalMem) * 10) / 10;[span_25](end_span)
}

#pragma mark - 5. الواجهة الرسومية (Anti-Crash Overlay)
UIWindow *CreatePersistentWindow() {
    [span_26](start_span)if (_overlayWindow) return _overlayWindow;[span_26](end_span)
    
    UIWindowScene *activeScene = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
    }

    [span_27](start_span)CGRect bounds = activeScene ? activeScene.coordinateSpace.bounds : [UIScreen mainScreen].bounds;[span_27](end_span)
    _overlayWindow = activeScene ? [span_28](start_span)[[UIWindow alloc] initWithWindowScene:activeScene] : [[UIWindow alloc] initWithFrame:bounds];[span_28](end_span)
    
    _[span_29](start_span)overlayWindow.windowLevel = UIWindowLevelStatusBar + 100;[span_29](end_span)
    _[span_30](start_span)overlayWindow.userInteractionEnabled = NO;[span_30](end_span)
    _[span_31](start_span)overlayWindow.backgroundColor = [UIColor clearColor];[span_31](end_span)
    _[span_32](start_span)overlayWindow.hidden = NO;[span_32](end_span)
    
    [span_33](start_span)return _overlayWindow;[span_33](end_span)
}

void UpdateLabelLayout() {
    [span_34](start_span)if (!_persistentLabel) return;[span_34](end_span)
    [span_35](start_span)CGRect screenBounds = [UIScreen mainScreen].bounds;[span_35](end_span)
    [span_36](start_span)[_persistentLabel sizeToFit];[span_36](end_span)
    [span_37](start_span)CGFloat labelHeight = _persistentLabel.frame.size.height;[span_37](end_span)
    _[span_38](start_span)persistentLabel.frame = CGRectMake(10, (screenBounds.size.height - labelHeight) / 2, 220, labelHeight);[span_38](end_span)
}

void UpdateLabelText() {
    [span_39](start_span)if (!_persistentLabel) return;[span_39](end_span)
    _[span_40](start_span)persistentLabel.text = [NSString stringWithFormat:@"Sovereign | Mem: %.1f%%", GetAppMemoryPercent()];[span_40](end_span)
    [span_41](start_span)[_persistentLabel sizeToFit];[span_41](end_span)
    [span_42](start_span)UpdateLabelLayout();[span_42](end_span)
}

#pragma mark - 6. المدخل الرئيسي (Constructor)
__attribute__((constructor)) static void SovereignInit() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [span_43](start_span)InitGlobalResources();[span_43](end_span)
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [span_44](start_span)UIWindow *window = CreatePersistentWindow();[span_44](end_span)
        if (!_persistentLabel) {
            _[span_45](start_span)persistentLabel = [[UILabel alloc] init];[span_45](end_span)
            _[span_46](start_span)persistentLabel.font = [UIFont boldSystemFontOfSize:12];[span_46](end_span)
            _[span_47](start_span)persistentLabel.textColor = [UIColor redColor];[span_47](end_span)
            _[span_48](start_span)persistentLabel.numberOfLines = 0;[span_48](end_span)
            [span_49](start_span)[window addSubview:_persistentLabel];[span_49](end_span)
            
            _orientationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                              object:nil queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) { UpdateLabelLayout(); [span_50](start_span)}];[span_50](end_span)
        }
        
        _[span_51](start_span)monitorTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());[span_51](end_span)
        [span_52](start_span)dispatch_source_set_timer(_monitorTimer, dispatch_time(DISPATCH_TIME_NOW, 0), 2 * NSEC_PER_SEC, 0);[span_52](end_span)
        [span_53](start_span)dispatch_source_set_event_handler(_monitorTimer, ^{ UpdateLabelText(); });[span_53](end_span)
        [span_54](start_span)dispatch_resume(_monitorTimer);[span_54](end_span)
    });

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [span_55](start_span)DeleteFilesLoop();[span_55](end_span)
    });
}

#pragma mark - 7. تحرير الموارد (Destructor)
__attribute__((destructor)) static void SovereignDealloc() {
    if (_orientationObserver) {
        [span_56](start_span)[[NSNotificationCenter defaultCenter] removeObserver:_orientationObserver];[span_56](end_span)
        _[span_57](start_span)orientationObserver = nil;[span_57](end_span)
    }
    if (_monitorTimer) {
        [span_58](start_span)dispatch_source_cancel(_monitorTimer);[span_58](end_span)
        _[span_59](start_span)monitorTimer = NULL;[span_59](end_span)
    }
}

NSString *GetAppleDeviceFullName() { return @"iPhone"; }
