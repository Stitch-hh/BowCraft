// gesture_logic.h
//
// Чистая логика решения «помечать ли scroll-событие флагом Cmd» — без Apple
// API, чтобы её можно было юнит-тестить на любой платформе (Linux, CI).
// Значения фаз совпадают с CGScrollPhase / CGMomentumScrollPhase из
// CGEventTypes.h — в ThreeFingerZoomTap.m значения полей события передаются
// сюда как есть.

#ifndef GESTURE_LOGIC_H
#define GESTURE_LOGIC_H

#include <stdbool.h>
#include <stdint.h>

enum {
    GL_SCROLL_PHASE_NONE      = 0,
    GL_SCROLL_PHASE_BEGAN     = 1,
    GL_SCROLL_PHASE_CHANGED   = 2,
    GL_SCROLL_PHASE_ENDED     = 4,
    GL_SCROLL_PHASE_CANCELLED = 8,
    GL_SCROLL_PHASE_MAYBEGIN  = 128,
};

enum {
    GL_MOMENTUM_NONE     = 0,
    GL_MOMENTUM_BEGIN    = 1,
    GL_MOMENTUM_CONTINUE = 2,
    GL_MOMENTUM_END      = 3,
};

typedef struct {
    bool flag_gesture; // текущий жест признан «зумом»
} gl_state;

// Вызывается на каждое continuous scroll-событие. Возвращает: добавлять ли ⌘.
//
// Правила:
// - Решение принимается в активной фазе жеста (momentum == none):
//   на began/mayBegin — по текущему числу пальцев; по ходу жеста третий
//   палец может «доназначить» зум, но потеря пальца решение не отменяет
//   (сенсор мигает при переносе пальцев).
// - Во время инерции пальцев на трекпаде уже нет — решение активной фазы
//   удерживается до конца инерции, чтобы зум на лету не превращался в скролл.
static inline bool gl_should_flag(gl_state *s,
                                  int64_t scroll_phase,
                                  int64_t momentum_phase,
                                  int32_t fingers,
                                  bool app_allowed) {
    if (momentum_phase == GL_MOMENTUM_NONE) {
        if (scroll_phase == GL_SCROLL_PHASE_MAYBEGIN ||
            scroll_phase == GL_SCROLL_PHASE_BEGAN) {
            s->flag_gesture = (fingers == 3) && app_allowed;
        } else if (fingers == 3 && app_allowed) {
            s->flag_gesture = true;
        }
    }
    return s->flag_gesture;
}

#endif // GESTURE_LOGIC_H
