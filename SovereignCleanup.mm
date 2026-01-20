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
static NSFileManager *_fileManager = nil;
static NSString *_anoTmpPath = nil;
static NSString *_libraryPath = nil;
static NSString *_tmpPath = nil;
static UILabel *_persistentLabel = nil;
static UIWindow *_overlayWindow = nil;
static const void *kSovereignWindowKey = &kSovereignWindowKey; 
static dispatch_source_t _monitorTimer = nil;
static id _orientationObserver = nil; 

// تعريف مسبق للوظائف لضمان استقرار الاستدعاء
void UpdateLabelLayout();
CGFloat GetAppMemoryPercent();
NSString *GetAppleDeviceFullName();
void UpdateLabelText();

#pragma mark - 2. تهيئة موارد النظام (إخفاء الأثر)
void InitGlobalResources() {
    @autoreleasepool {
        if (!_fileManager) {
            _[span_1](start_span)fileManager = [NSFileManager defaultManager];[span_1](end_span)
        }
        [span_2](start_span)NSString *homeDir = NSHomeDirectory();[span_2](end_span)
        [span_3](start_span)[span_4](start_span)// تحديد المسارات الحساسة التي سيتم تنظيفها لمنع الباند[span_3](end_span)[span_4](end_span)
        _[span_5](start_span)anoTmpPath = [homeDir stringByAppendingPathComponent:@"Documents/ano_tmp"];[span_5](end_span)
        _[span_6](start_span)libraryPath = [homeDir stringByAppendingPathComponent:@"Library"];[span_6](end_span)
        _[span_7](start_span)tmpPath = [homeDir stringByAppendingPathComponent:@"tmp"];[span_7](end_span)
    }
}

#pragma mark - 3. نظام التنظيف المستمر (Anti-Log)
void SafeDeletePath(NSString *path) {
    if (_fileManager && [_fileManager fileExistsAtPath:path]) {
        [span_8](start_span)[_fileManager removeItemAtPath:path error:NULL];[span_8](end_span)
    }
}

void DeleteFilesLoop() {
    [span_9](start_span)[span_10](start_span)// مسح السجلات التي قد تكتشفها حماية اللعبة[span_9](end_span)[span_10](end_span)
    [span_11](start_span)SafeDeletePath(_anoTmpPath);[span_11](end_span)
    [span_12](start_span)SafeDeletePath(_libraryPath);[span_12](end_span)
    [span_13](start_span)SafeDeletePath(_tmpPath);[span_13](end_span)
    
    [span_14](start_span)// تكرار العملية كل 5 ثوانٍ لضمان عدم تراكم البلاغات[span_14](end_span)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [span_15](start_span)DeleteFilesLoop();[span_15](end_span)
    });
}

#pragma mark - 4. مراقبة الذاكرة (Memory Monitoring)
static uint64_t GetTotalSystemMemory() {
    int mib[] = {CTL_HW, HW_MEMSIZE};
    uint64_t totalMem = 0;
    [span_16](start_span)size_t len = sizeof(totalMem);[span_16](end_span)
    [span_17](start_span)sysctl(mib, 2, &totalMem, &len, NULL, 0);[span_17](end_span)
    [span_18](start_span)return totalMem;[span_18](end_span)
}

CGFloat GetAppMemoryPercent() {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    [span_19](start_span)kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);[span_19](end_span)
    [span_20](start_span)if (kerr != KERN_SUCCESS) return 0.0;[span_20](end_span)
    
    uint64_t totalMem = GetTotalSystemMemory();
    return totalMem == 0 ? [span_21](start_span)0.0 : roundf((CGFloat)(info.resident_size * 100.0 / totalMem) * 10) / 10;[span_21](end_span)
}

#pragma mark - 5. الواجهة الرسومية (No-Crash Overlay)
UIWindow *CreatePersistentWindow() {
    if (_overlayWindow) return _overlayWindow;
    
    [span_22](start_span)[span_23](start_span)// دعم نظام الـ Scenes في iOS 13+ لمنع الانهيار عند الفتح[span_22](end_span)[span_23](end_span)
    UIWindowScene *activeScene = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
    }

    [span_24](start_span)[span_25](start_span)CGRect screenBounds = activeScene ? activeScene.coordinateSpace.bounds : [UIScreen mainScreen].bounds;[span_24](end_span)[span_25](end_span)
    _overlayWindow = activeScene ? [span_26](start_span)[[UIWindow alloc] initWithWindowScene:activeScene] : [[UIWindow alloc] initWithFrame:screenBounds];[span_26](end_span)
    
    _[span_27](start_span)overlayWindow.windowLevel = UIWindowLevelStatusBar + 100;[span_27](end_span)
    _[span_28](start_span)overlayWindow.userInteractionEnabled = NO;[span_28](end_span)
    _[span_29](start_span)overlayWindow.backgroundColor = [UIColor clearColor];[span_29](end_span)
    _[span_30](start_span)overlayWindow.hidden = NO;[span_30](end_span)
    
    return _overlayWindow;
}

UILabel *CreatePersistentLabel() {
    if (_persistentLabel) return _persistentLabel;
    
    _persistentLabel = [[UILabel alloc] init];
    _[span_31](start_span)persistentLabel.font = [UIFont boldSystemFontOfSize:13];[span_31](end_span)
    _[span_32](start_span)persistentLabel.textColor = [UIColor redColor];[span_32](end_span)
    _[span_33](start_span)persistentLabel.textAlignment = NSTextAlignmentLeft;[span_33](end_span)
    _[span_34](start_span)persistentLabel.numberOfLines = 0;[span_34](end_span)
    _[span_35](start_span)persistentLabel.layer.zPosition = MAXFLOAT;[span_35](end_span)
    
    [span_36](start_span)// مراقبة تدوير الشاشة لتعديل الموقع تلقائياً[span_36](end_span)
    _orientationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
        [span_37](start_span)UpdateLabelLayout();[span_37](end_span)
    }];
    
    return _persistentLabel;
}

void UpdateLabelLayout() {
    if (!_persistentLabel) return;
    [span_38](start_span)CGRect screenBounds = [UIScreen mainScreen].bounds;[span_38](end_span)
    [span_39](start_span)[_persistentLabel sizeToFit];[span_39](end_span)
    CGFloat labelHeight = _persistentLabel.frame.size.height;
    [span_40](start_span)// تحديد الموقع في منتصف يسار الشاشة[span_40](end_span)
    _[span_41](start_span)persistentLabel.frame = CGRectMake(10, (screenBounds.size.height - labelHeight) / 2, 200, labelHeight);[span_41](end_span)
}

void UpdateLabelText() {
    if (!_persistentLabel) return;
    [span_42](start_span)// عرض معلومات الجهاز واستهلاك الذاكرة[span_42](end_span)
    _[span_43](start_span)persistentLabel.text = [NSString stringWithFormat:@"Titanium | Memory: %.1f%%", GetAppMemoryPercent()];[span_43](end_span)
    [span_44](start_span)UpdateLabelLayout();[span_44](end_span)
}

#pragma mark - 6. المدخل الرئيسي (Plugin Entry)
__attribute__((constructor)) static void SovereignInit() {
    [span_45](start_span)// 1. تهيئة الموارد في الخلفية[span_45](end_span)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [span_46](start_span)InitGlobalResources();[span_46](end_span)
    });

    [span_47](start_span)// 2. تشغيل الواجهة بعد ثانية واحدة لضمان استقرار اللعبة[span_47](end_span)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [span_48](start_span)UIWindow *window = CreatePersistentWindow();[span_48](end_span)
        [span_49](start_span)UILabel *label = CreatePersistentLabel();[span_49](end_span)
        [span_50](start_span)if (label.superview != window) [window addSubview:label];[span_50](end_span)
        
        [span_51](start_span)// 3. تحديث البيانات كل ثانيتين[span_51](end_span)
        _[span_52](start_span)monitorTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());[span_52](end_span)
        [span_53](start_span)dispatch_source_set_timer(_monitorTimer, dispatch_time(DISPATCH_TIME_NOW, 0), 2 * NSEC_PER_SEC, 0);[span_53](end_span)
        [span_54](start_span)dispatch_source_set_event_handler(_monitorTimer, ^{ UpdateLabelText(); });[span_54](end_span)
        [span_55](start_span)dispatch_resume(_monitorTimer);[span_55](end_span)
    });

    [span_56](start_span)// 4. تفعيل حلقة التنظيف بعد 30 ثانية لتجنب كشف اللعبة عند الإقلاع[span_56](end_span)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [span_57](start_span)DeleteFilesLoop();[span_57](end_span)
    });
}

#pragma mark - 7. تحرير الموارد (Anti-Leak)
__attribute__((destructor)) static void SovereignDealloc() {
    if (_orientationObserver) {
        [span_58](start_span)[[NSNotificationCenter defaultCenter] removeObserver:_orientationObserver];[span_58](end_span)
        _orientationObserver = nil;
    }
    if (_monitorTimer) {
        [span_59](start_span)dispatch_source_cancel(_monitorTimer);[span_59](end_span)
        _monitorTimer = NULL;
    }
}
