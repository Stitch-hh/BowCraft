# Zoom in/out жестом «три пальца вверх/вниз» на macOS

Задача: в приложениях типа Miro zoom делается пинчем двумя пальцами или `⌘ + скролл двумя пальцами`.
Хотим, чтобы то же самое делал свайп **тремя пальцами вверх/вниз**.

## 1. Почему это не делается одной галочкой в настройках

Трёхпальцевые свайпы в macOS **зарезервированы системой** и перехватываются
WindowServer'ом *до* того, как жест дойдёт до приложения:

| Жест | Системное действие по умолчанию |
|---|---|
| 3 пальца вверх | Mission Control |
| 3 пальца вниз | App Exposé |
| 3 пальца вбок | Переключение Spaces / полноэкранных приложений |
| 3 пальца (drag) | «Перетаскивание тремя пальцами» (опция Accessibility) |

В System Settings нет способа назначить на этот жест zoom. Поэтому **любое**
решение (и «настроечное», и кодовое) начинается с одного и того же шага —
освободить жест:

1. **System Settings → Trackpad → More Gestures**:
   - *Mission Control* → «Swipe Up with Four Fingers» (или Off);
   - *App Exposé* → «Swipe Down with Four Fingers» (или Off);
   - *Swipe between full-screen applications* → «Four Fingers» (или Off).
2. **System Settings → Accessibility → Pointer Control → Trackpad Options**:
   выключить «Use trackpad for dragging» в режиме three-finger drag (если включён).

Второй важный факт: в публичных API macOS **нет события «свайп тремя пальцами
с непрерывной дельтой»**:

- scroll-события (`NSEventTypeScrollWheel`) генерируются только двумя пальцами и
  не содержат числа пальцев;
- `NSEventTypeSwipe` — дискретное событие (только направление, без дельты) и
  приходит лишь когда системные жесты отключены;
- «сырые» касания доступны приложению через **NSTouch** (только внутри своих окон),
  а глобально — только через **приватный** `MultitouchSupport.framework`.

Отсюда три рабочих варианта решения.

## 2. Вариант A — без кода: BetterTouchTool (рекомендуется пользователю Miro)

[BetterTouchTool](https://folivora.ai) (BTT) — стандартный инструмент для таких
задач: он сам читает трекпад через приватный multitouch-API и имеет готовые
триггеры «3 Finger Swipe Up / Down», в том числе **per-application**.

Рецепт:

1. Освободить жест в системных настройках (см. раздел 1).
2. В BTT: **Trackpad → выбрать приложение Miro** (или «All Apps») → добавить триггер
   **«3 Finger Swipe Up»** → действие: шорткат **⌘ и `+`** (zoom in в Miro).
3. Аналогично **«3 Finger Swipe Down»** → **⌘ и `-`** (zoom out).
4. Для более «плавного» зума: в расширенных настройках триггера включить повторение
   действия, пока пальцы на трекпаде, либо назначить действием эмуляцию скролла
   с зажатым ⌘ — Miro интерпретирует `⌘ + scroll` как непрерывный zoom.

Альтернативы того же класса: [Multitouch](https://multitouch.app),
[Swish](https://highlyopinionated.co/swish/).

Что **не** подходит: Karabiner-Elements — это клавиатурный ремаппер; его
MultitouchExtension умеет лишь использовать число пальцев на трекпаде как
*условие* для клавиатурных ремапов, но не превращать свайп в непрерывный жест.

## 3. Вариант B — код в своём приложении (если мы разработчики «своего Miro»)

Нативное AppKit-приложение может получать сырые касания трекпада внутри своих
view через `NSTouch`: `view.allowedTouchTypes = [.indirect]` +
`touchesBegan/Moved/Ended(with:)`. Считаем пальцы, берём среднюю `normalizedPosition.y`
трёх касаний, дельту превращаем в масштаб.

Рабочий пример: [`CanvasZoomView.swift`](CanvasZoomView.swift).

Свойства решения:
- публичный API, можно в App Store;
- работает только внутри своего приложения (чужое Miro так не улучшить);
- системные жесты всё равно надо перевесить на 4 пальца — приложение не может
  «отобрать» жест у Mission Control.

Примечание для Electron/веба: браузер не отдаёт странице число пальцев на
трекпаде (страница видит только `wheel`, где пинч приходит как `wheel + ctrlKey`),
поэтому чисто в JS задача не решается. В Electron есть событие
`BrowserWindow: 'swipe'` (up/down/left/right), но оно дискретное и зависит от
системных настроек трекпада. Практичный путь для Electron-приложения — нативный
хелпер по схеме варианта C, шлющий команды в renderer.

## 4. Вариант C — код глобально: свой мини-BTT

Глобальная фоновая утилита:

1. читает сырые касания через приватный `MultitouchSupport.framework`
   (`MTDeviceCreateDefault` → `MTRegisterContactFrameCallback` → `MTDeviceStart`);
2. детектит «ровно 3 пальца, движутся по вертикали»;
3. синтезирует через `CGEventPost` scroll-события с флагом ⌘
   (`CGEventSetFlags(ev, kCGEventFlagMaskCommand)`) — ровно то, что Miro и
   большинство канвас-приложений понимают как zoom.

PoC: [`ThreeFingerZoom.m`](ThreeFingerZoom.m). Сборка и запуск (на Mac):

```sh
clang -fobjc-arc -O2 ThreeFingerZoom.m -o three-finger-zoom \
  -F/System/Library/PrivateFrameworks -framework MultitouchSupport \
  -framework Foundation -framework ApplicationServices
./three-finger-zoom
```

Требования и риски:
- разрешение **Accessibility** (System Settings → Privacy & Security →
  Accessibility) — без него `CGEventPost` не доставляет события; на свежих
  версиях macOS чтение мультитача может дополнительно требовать **Input Monitoring**;
- жест должен быть освобождён от Mission Control / App Exposé (раздел 1);
- `MultitouchSupport.framework` — **приватный API**: в App Store нельзя,
  раскладка структуры `MTTouch` не документирована и может поменяться в новой
  major-версии macOS (тем не менее BTT/Multitouch/Middle живут на нём годами);
- PoC глобальный; в проде стоит добавить фильтр по frontmost-приложению
  (`NSWorkspace.shared.frontmostApplication`), порог срабатывания, обработку
  подключения/отключения внешних трекпадов (`MTDeviceCreateList`).

## 5. Сравнение и рекомендация

| Вариант | Усилия | Область действия | App Store | Надёжность |
|---|---|---|---|---|
| A: BetterTouchTool | ~15 минут | любое приложение | n/a | высокая (поддерживается автором) |
| B: NSTouch в своём приложении | небольшие | только своё приложение | да | высокая (публичный API) |
| C: своя глобальная утилита | средние | любое приложение | нет | средняя (приватный API) |

**Рекомендация:** как пользователю Miro — вариант A (BTT). Как разработчику
своего канвас-приложения — вариант B. Вариант C — если нужен именно свой
глобальный инструмент без сторонних программ; PoC в этой папке показывает, что
это ~100 строк кода.
