// ThreeFingerZoomTap.m
//
// Вариант D — «нативный look & feel»: НЕ синтезируем события вообще.
//
// Идея (ТРИЗ-принцип «наоборот» + «посредник»): после переноса системных
// 3-пальцевых жестов на 4 пальца macOS сама генерирует НАСТОЯЩИЙ скролл
// тремя пальцами — тем же пайплайном, что и двумя: те же дельты, фазы,
// ускорение и инерция. Не хватает только зажатого ⌘. Эта утилита ничего не
// генерирует — она лишь добавляет флаг Cmd к пролетающим мимо настоящим
// scroll-событиям, пока на трекпаде три пальца. Поэтому по ощущениям жест
// неотличим от ⌘ + два пальца: это буквально те же самые события.
//
// Сборка (на macOS):
//   clang -fobjc-arc -O2 ThreeFingerZoomTap.m -o three-finger-zoom-tap \
//     -framework Foundation -framework AppKit -framework ApplicationServices
//
// Приватный MultitouchSupport.framework загружается через dlopen/dlsym:
// начиная с Big Sur системные библиотеки живут в dyld shared cache, бинаря
// на диске нет, и обычная линковка `-framework MultitouchSupport` не работает
// (приватным фреймворкам Apple не кладёт .tbd-заглушки в SDK). dlopen при
// этом штатно резолвит путь через shared cache.
//
// Перед запуском:
//   1. System Settings → Trackpad → More Gestures: Mission Control, App Exposé
//      и «Swipe between full-screen applications» → 4 пальца или Off
//      (после этого 3 пальца начинают НАТИВНО скроллить — можно проверить
//      без всякого кода).
//   2. Выключить three-finger drag (Accessibility → Pointer Control →
//      Trackpad Options), если включён.
//   3. Разрешение Accessibility для бинаря (System Settings → Privacy &
//      Security → Accessibility) — нужно для event tap.
//
// Приватный API используется в одном-единственном месте: счётчик пальцев
// на трекпаде. Сами события не трогаем ничем, кроме OR одного бита флагов.
// Логика решения «этот жест — зум» вынесена в gesture_logic.h и покрыта
// юнит-тестами (test_gesture_logic.c), запускаемыми на любой платформе.

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <ApplicationServices/ApplicationServices.h>
#import <dlfcn.h>

#include "gesture_logic.h"

#pragma mark - MultitouchSupport (private, via dlopen): нужен только счётчик пальцев

typedef struct { float x, y; } MTPoint;
typedef struct { MTPoint pos, vel; } MTReadout;

typedef struct {
    int32_t frame;
    double timestamp;
    int32_t identifier, state, foo3, foo4;
    MTReadout normalized;
    float size;
    int32_t zero1;
    float angle, majorAxis, minorAxis;
    MTReadout mm;
    int32_t zero2[2];
    float unk2;
} MTTouch;

typedef void *MTDeviceRef;
typedef int (*MTContactCallback)(MTDeviceRef, MTTouch *, int32_t, double, int32_t);

typedef MTDeviceRef (*MTDeviceCreateDefaultFn)(void);
typedef void (*MTRegisterContactFrameCallbackFn)(MTDeviceRef, MTContactCallback);
typedef void (*MTDeviceStartFn)(MTDeviceRef, int);

static volatile int32_t gFingersOnPad = 0;

static int ContactCallback(MTDeviceRef device, MTTouch *touches,
                           int32_t numTouches, double timestamp, int32_t frame) {
    gFingersOnPad = numTouches;
    return 0;
}

#pragma mark - Белый список приложений (пусто = работать везде)

// Примеры bundle id: Miro desktop — @"com.electron.realtimeboard",
// Figma — @"com.figma.Desktop". Пустой массив = зум тремя пальцами везде.
static NSArray<NSString *> *AllowedBundleIDs(void) {
    return @[];
}

static bool FrontmostAppAllowed(void) {
    NSArray *allowed = AllowedBundleIDs();
    if (allowed.count == 0) return true;
    NSString *bid = NSWorkspace.sharedWorkspace.frontmostApplication.bundleIdentifier;
    return bid != nil && [allowed containsObject:bid];
}

#pragma mark - Event tap: помечаем настоящие скроллы флагом Cmd

static CFMachPortRef gTap = NULL;
static gl_state gGesture = {0};

static CGEventRef TapCallback(CGEventTapProxy proxy, CGEventType type,
                              CGEventRef event, void *refcon) {
    // macOS отключает «медленные» tap'ы — включаем обратно.
    if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
        if (gTap) CGEventTapEnable(gTap, true);
        return event;
    }
    if (type != kCGEventScrollWheel) return event;

    // Трогаем только «непрерывные» (трекпадные) скроллы; колесо мыши — нет.
    if (!CGEventGetIntegerValueField(event, kCGScrollWheelEventIsContinuous))
        return event;

    int64_t scrollPhase   = CGEventGetIntegerValueField(event, kCGScrollWheelEventScrollPhase);
    int64_t momentumPhase = CGEventGetIntegerValueField(event, kCGScrollWheelEventMomentumPhase);

    if (gl_should_flag(&gGesture, scrollPhase, momentumPhase,
                       gFingersOnPad, FrontmostAppAllowed())) {
        CGEventSetFlags(event, CGEventGetFlags(event) | kCGEventFlagMaskCommand);
    }
    return event;
}

#pragma mark - main

int main(void) {
    @autoreleasepool {
        if (!AXIsProcessTrusted()) {
            NSDictionary *opts = @{(__bridge id)kAXTrustedCheckOptionPrompt : @YES};
            AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)opts);
            NSLog(@"Выдайте разрешение Accessibility и перезапустите утилиту.");
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
        registerCallback(device, ContactCallback);
        deviceStart(device, 0);

        gTap = CGEventTapCreate(kCGSessionEventTap, kCGHeadInsertEventTap,
                                kCGEventTapOptionDefault,
                                CGEventMaskBit(kCGEventScrollWheel),
                                TapCallback, NULL);
        if (gTap == NULL) {
            NSLog(@"Не удалось создать event tap — проверьте разрешение Accessibility.");
            return 1;
        }
        CFRunLoopSourceRef source =
            CFMachPortCreateRunLoopSource(kCFAllocatorDefault, gTap, 0);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, kCFRunLoopCommonModes);
        CGEventTapEnable(gTap, true);

        NSLog(@"Готово: 3 пальца вверх/вниз = нативный zoom (⌘ добавляется к настоящему скроллу). Ctrl+C — выход.");
        CFRunLoopRun();
    }
    return 0;
}
