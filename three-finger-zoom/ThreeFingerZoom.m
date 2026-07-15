// ThreeFingerZoom.m
//
// Вариант C (PoC): глобальная утилита «три пальца вверх/вниз → zoom»
// через СИНТЕЗ событий. Оставлен для сравнения с вариантом D
// (ThreeFingerZoomTap.m): синтезированный скролл не имеет фаз и инерции
// настоящего трекпадного скролла, поэтому look & feel хуже нативного.
//
// Читает сырые касания трекпада через приватный MultitouchSupport.framework,
// детектит вертикальное движение ровно трёх пальцев и синтезирует scroll-события
// с зажатым ⌘ (Cmd + scroll = zoom в Miro и большинстве канвас-приложений).
//
// Сборка (на macOS):
//   clang -fobjc-arc -O2 ThreeFingerZoom.m -o three-finger-zoom \
//     -framework Foundation -framework ApplicationServices
//
// Приватный фреймворк загружается через dlopen/dlsym: с Big Sur системные
// библиотеки живут в dyld shared cache, бинаря на диске нет, и линковка
// `-framework MultitouchSupport` не работает (нет .tbd для приватных
// фреймворков в SDK).
//
// Запуск:
//   ./three-finger-zoom
//
// Перед использованием:
//   1. System Settings → Trackpad → More Gestures: перевести Mission Control и
//      App Exposé на 4 пальца (или выключить), иначе жест перехватит система.
//   2. Выдать бинарю разрешение Accessibility
//      (System Settings → Privacy & Security → Accessibility) — без него
//      CGEventPost не доставляет события. На свежих macOS чтение мультитача
//      может дополнительно требовать Input Monitoring.
//
// Ограничения PoC: private API (не для App Store, раскладка MTTouch может
// поменяться в новых macOS), только встроенный трекпад (MTDeviceCreateDefault),
// без фильтра по frontmost-приложению.

#import <Foundation/Foundation.h>
#import <ApplicationServices/ApplicationServices.h>
#import <dlfcn.h>

#pragma mark - Приватный MultitouchSupport.framework (via dlopen)

typedef struct { float x, y; } MTPoint;
typedef struct { MTPoint pos, vel; } MTReadout;

// Каноничная раскладка структуры касания (см. заголовки в открытых проектах:
// fingerpinger, hs._asm.undocumented.touchdevice и др.)
typedef struct {
    int32_t frame;
    double timestamp;
    int32_t identifier;
    int32_t state;
    int32_t foo3;
    int32_t foo4;
    MTReadout normalized; // pos.x/pos.y в диапазоне 0..1 по площади трекпада
    float size;
    int32_t zero1;
    float angle;
    float majorAxis;
    float minorAxis;
    MTReadout mm;
    int32_t zero2[2];
    float unk2;
} MTTouch;

typedef void *MTDeviceRef;
typedef int (*MTContactCallback)(MTDeviceRef device, MTTouch *touches,
                                 int32_t numTouches, double timestamp,
                                 int32_t frame);

typedef MTDeviceRef (*MTDeviceCreateDefaultFn)(void);
typedef void (*MTRegisterContactFrameCallbackFn)(MTDeviceRef, MTContactCallback);
typedef void (*MTDeviceStartFn)(MTDeviceRef, int);

#pragma mark - Жест → Cmd+scroll

// Пикселей скролла на всю высоту трекпада; знак и величина = чувствительность.
static const float kSensitivityPixels = 600.0f;

static BOOL gGestureActive = NO;
static float gLastAverageY = 0.0f;

static void PostCommandScroll(int32_t pixels) {
    CGEventRef event = CGEventCreateScrollWheelEvent(
        NULL, kCGScrollEventUnitPixel, 1 /* оси */, pixels);
    CGEventSetFlags(event, kCGEventFlagMaskCommand);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
}

static int ContactFrameCallback(MTDeviceRef device, MTTouch *touches,
                                int32_t numTouches, double timestamp,
                                int32_t frame) {
    if (numTouches != 3) {
        gGestureActive = NO;
        return 0;
    }

    float averageY = (touches[0].normalized.pos.y +
                      touches[1].normalized.pos.y +
                      touches[2].normalized.pos.y) / 3.0f;

    if (gGestureActive) {
        float dy = averageY - gLastAverageY;
        int32_t pixels = (int32_t)lroundf(dy * kSensitivityPixels);
        if (pixels != 0) {
            PostCommandScroll(pixels);
        }
    }

    gGestureActive = YES;
    gLastAverageY = averageY;
    return 0;
}

#pragma mark - main

int main(void) {
    @autoreleasepool {
        if (!AXIsProcessTrusted()) {
            NSLog(@"Нужно разрешение Accessibility "
                  @"(System Settings → Privacy & Security → Accessibility). "
                  @"Показываю системный запрос…");
            NSDictionary *options =
                @{(__bridge id)kAXTrustedCheckOptionPrompt : @YES};
            AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
        }

        void *mtLib = dlopen(
            "/System/Library/PrivateFrameworks/MultitouchSupport.framework/MultitouchSupport",
            RTLD_NOW);
        if (mtLib == NULL) {
            NSLog(@"Не удалось загрузить MultitouchSupport.framework: %s", dlerror());
            return 1;
        }
        MTDeviceCreateDefaultFn createDefault =
            (MTDeviceCreateDefaultFn)dlsym(mtLib, "MTDeviceCreateDefault");
        MTRegisterContactFrameCallbackFn registerCallback =
            (MTRegisterContactFrameCallbackFn)dlsym(mtLib, "MTRegisterContactFrameCallback");
        MTDeviceStartFn deviceStart = (MTDeviceStartFn)dlsym(mtLib, "MTDeviceStart");
        if (!createDefault || !registerCallback || !deviceStart) {
            NSLog(@"Символы MultitouchSupport не найдены (изменился приватный API?)");
            return 1;
        }

        MTDeviceRef device = createDefault();
        if (device == NULL) {
            NSLog(@"Мультитач-устройство не найдено.");
            return 1;
        }

        registerCallback(device, ContactFrameCallback);
        deviceStart(device, 0);

        NSLog(@"Готово: 3 пальца вверх/вниз → Cmd+scroll (zoom). Ctrl+C — выход.");
        CFRunLoopRun();
    }
    return 0;
}
