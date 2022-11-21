package Arrows

enum class Ammo : InterfaceArrow {
    BONE {
        override val arrowDamage = 5
        override val arrowCriticalCoefficient = 2
        override val arrowCriticalChance = 5
    },
    STEEL {
        override val arrowDamage = 10
        override val arrowCriticalCoefficient = 2
        override val arrowCriticalChance = 0
    },
    FIRE {
        override val arrowDamage = 5
        override val arrowCriticalCoefficient = 4
        override val arrowCriticalChance = 20
    },
    FROZEN {
        override val arrowDamage = 15
        override val arrowCriticalCoefficient = 1
        override val arrowCriticalChance = 0
    },
    MAGICFIRE {
        override val arrowDamage = 2
        override val arrowCriticalCoefficient = 4
        override val arrowCriticalChance = 40
    },
    MAGICFROZEN {
        override val arrowDamage = 4
        override val arrowCriticalCoefficient = 1
        override val arrowCriticalChance = 0
    }
}




