// test_gesture_logic.c
//
// Юнит-тесты state machine из gesture_logic.h. Собираются и работают на любой
// платформе:
//   cc -std=c11 -Wall -Wextra -Werror -o test_gesture_logic test_gesture_logic.c
//   ./test_gesture_logic

#include <assert.h>
#include <stdio.h>

#include "gesture_logic.h"

int main(void) {
    // 1. Обычный 2-пальцевый скролл никогда не помечается, включая инерцию.
    {
        gl_state s = {0};
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_BEGAN,   GL_MOMENTUM_NONE,     2, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE,     2, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_ENDED,   GL_MOMENTUM_NONE,     0, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_NONE,    GL_MOMENTUM_BEGIN,    0, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_NONE,    GL_MOMENTUM_CONTINUE, 0, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_NONE,    GL_MOMENTUM_END,      0, true));
    }

    // 2. 3-пальцевый жест помечается сразу и держит флаг всю инерцию
    //    (пальцы уже подняты, fingers == 0).
    {
        gl_state s = {0};
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_BEGAN,   GL_MOMENTUM_NONE,     3, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE,     3, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_ENDED,   GL_MOMENTUM_NONE,     0, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_NONE,    GL_MOMENTUM_BEGIN,    0, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_NONE,    GL_MOMENTUM_CONTINUE, 0, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_NONE,    GL_MOMENTUM_END,      0, true));
    }

    // 3. Третий палец добавили по ходу 2-пальцевого жеста — зум включается
    //    с этого момента.
    {
        gl_state s = {0};
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_BEGAN,   GL_MOMENTUM_NONE, 2, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE, 2, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE, 3, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE, 3, true));
    }

    // 4. Следующий жест после 3-пальцевого начинается «с чистого листа»:
    //    2-пальцевый скролл снова не помечается.
    {
        gl_state s = {0};
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_BEGAN, GL_MOMENTUM_NONE,  3, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_NONE,  GL_MOMENTUM_END,   0, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_BEGAN, GL_MOMENTUM_NONE,  2, true));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_NONE,  GL_MOMENTUM_BEGIN, 0, true));
    }

    // 5. Белый список приложений: если frontmost app не разрешён — никогда.
    {
        gl_state s = {0};
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_BEGAN,   GL_MOMENTUM_NONE, 3, false));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE, 3, false));
        assert(!gl_should_flag(&s, GL_SCROLL_PHASE_NONE,    GL_MOMENTUM_BEGIN, 0, false));
    }

    // 6. Дрожание сенсора: жест начался с 3 пальцев, счётчик мигнул на 2 —
    //    решение активной фазы не отменяется (иначе зум дёргался бы).
    {
        gl_state s = {0};
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_BEGAN,   GL_MOMENTUM_NONE, 3, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE, 2, true));
        assert( gl_should_flag(&s, GL_SCROLL_PHASE_CHANGED, GL_MOMENTUM_NONE, 3, true));
    }

    printf("OK: все сценарии gesture_logic пройдены\n");
    return 0;
}
