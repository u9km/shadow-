#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <mach/mach_host.h>

// [1. تعريف المتغيرات العالمية]
static NSFileManager *_fileManager = nil;
static NSString *_anoTmpPath = nil;
static NSString *_libraryPath = nil;
static NSString *_tmpPath = nil;
static UILabel *_persistentLabel = nil;
static UIWindow *_overlayWindow = nil;
static dispatch_source_t _monitorTimer = nil;
static id _orientationObserver = nil;

// تعريف الوظائف
void UpdateLabelLayout();
CGFloat GetAppMemoryPercent();
NSString *GetAppleDeviceFullName();
void UpdateLabelText();

#pragma mark - 2. تهيئة موارد النظام
void InitGlobalResources() {
    @autoreleasepool {
        if (!_fileManager) {
            _fileManager = [NSFileManager defaultManager];
        }
        NSString *homeDir = NSHomeDirectory();
        // تحديد مسارات التنظيف التلقائي لمنع الباند
        _anoTmpPath = [homeDir stringByAppendingPathComponent:@"Documents/ano_tmp"];
        _libraryPath = [homeDir stringByAppendingPathComponent:@"Library"];
        _tmpPath = [homeDir stringByAppendingPathComponent:@"tmp"];
    }
}

#pragma mark - 3. نظام التنظيف المستمر (Anti-Log)
void SafeDeletePath(NSString *path) {
    if (_fileManager && [_fileManager fileExistsAtPath:path]) {
        [_fileManager removeItemAtPath:path error:NULL];
    }
}

void DeleteFilesLoop() {
    SafeDeletePath(_anoTmpPath);
    SafeDeletePath(_libraryPath);
    SafeDeletePath(_tmpPath);
    
    // تكرار الحذف كل 5 ثوانٍ لإخفاء أثر التعديل
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        DeleteFilesLoop();
    });
}

#pragma mark - 4. مراقبة استهلاك الذاكرة (Memory)
CGFloat GetAppMemoryPercent() {
    struct task_basic_info info;
    mach_msg_type_number_t size = TASK_BASIC_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size) != KERN_SUCCESS) return 0.0;
    
    int mib[] = {CTL_HW, HW_MEMSIZE};
    uint64_t totalMem = 0;
    size_t len = sizeof(totalMem);
    sysctl(mib, 2, &totalMem, &len, NULL, 0);
    
    return totalMem == 0 ? 0.0 : roundf((CGFloat)(info.resident_size * 100.0 / totalMem) * 10) / 10;
}

#pragma mark - 5. الواجهة الرسومية (Anti-Crash Overlay)
UIWindow *CreatePersistentWindow() {
    if (_overlayWindow) return _overlayWindow;
    
    // دعم نظام الـ Scenes في iOS 13+ لمنع الانهيار (Crash)
    UIWindowScene *activeScene = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }
    }

    CGRect bounds = activeScene ? activeScene.coordinateSpace.bounds : [UIScreen mainScreen].bounds;
    _overlayWindow = activeScene ? [[UIWindow alloc] initWithWindowScene:activeScene] : [[UIWindow alloc] initWithFrame:bounds];
    
    _overlayWindow.windowLevel = UIWindowLevelStatusBar + 100;
    _overlayWindow.userInteractionEnabled = NO; // لا يمنع اللمس داخل اللعبة
    _overlayWindow.backgroundColor = [UIColor clearColor];
    _overlayWindow.hidden = NO;
    
    return _overlayWindow;
}

void UpdateLabelLayout() {
    if (!_persistentLabel) return;
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    [_persistentLabel sizeToFit];
    CGFloat labelHeight = _persistentLabel.frame.size.height;
    // وضع الملصق في منتصف يسار الشاشة
    _persistentLabel.frame = CGRectMake(10, (screenBounds.size.height - labelHeight) / 2, 220, labelHeight);
}

void UpdateLabelText() {
    if (!_persistentLabel) return;
    _persistentLabel.text = [NSString stringWithFormat:@"Sovereign | Mem: %.1f%%", GetAppMemoryPercent()];
    UpdateLabelLayout();
}

#pragma mark - 6. المدخل الرئيسي (Plugin Constructor)
__attribute__((constructor)) static void SovereignInit() {
    // تهيئة في الخلفية
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        InitGlobalResources();
    });

    // تأخير إنشاء الواجهة لضمان استقرار اللعبة عند الإقلاع
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *window = CreatePersistentWindow();
        if (!_persistentLabel) {
            _persistentLabel = [[UILabel alloc] init];
            _persistentLabel.font = [UIFont boldSystemFontOfSize:12];
            _persistentLabel.textColor = [UIColor redColor];
            _persistentLabel.numberOfLines = 0;
            [window addSubview:_persistentLabel];
            
            // مراقبة تدوير الشاشة لتعديل الموقع
            _orientationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
                                                              object:nil queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) { UpdateLabelLayout(); }];
        }
        
        // تحديث البيانات كل ثانيتين
        _monitorTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_monitorTimer, dispatch_time(DISPATCH_TIME_NOW, 0), 2 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(_monitorTimer, ^{ UpdateLabelText(); });
        dispatch_resume(_monitorTimer);
    });

    // تفعيل حلقة الحذف بعد 30 ثانية
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        DeleteFilesLoop();
    });
}

#pragma mark - 7. تحرير الموارد
__attribute__((destructor)) static void SovereignDealloc() {
    if (_orientationObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:_orientationObserver];
        _orientationObserver = nil;
    }
    if (_monitorTimer) {
        dispatch_source_cancel(_monitorTimer);
        _monitorTimer = NULL;
    }
}

// دالة مساعدة لتعريف الجهاز
NSString *GetAppleDeviceFullName() { return @"iPhone"; }
