package Weapons

import Arrows.*
import Stack
import Warriors.FireType

abstract class AbstractWeapon {

    abstract val maxAmmo: Int
    abstract val attackType: FireType
    abstract val quiver: Stack<InterfaceArrow>


    open fun noArrowsInQuiver(): Boolean {
        return quiver.isEmptyStack()
    }


    open fun shot(): InterfaceArrow {
        return quiver.pop()!!
    }

    private fun createRandomArrow(): InterfaceArrow {
        return when ((1..4).random()) {
            1 -> Ammo.BONE
            2 -> Ammo.STEEL
            3 -> Ammo.FIRE
            else -> Ammo.FROZEN
        }
    }

    private fun createMagicCharges(): InterfaceArrow {
        return when ((1..2).random()) {
            1 -> Ammo.MAGICFIRE
            else -> Ammo.MAGICFROZEN
        }
    }

    open fun reload() {
        if (attackType == FireType.MultiShot) {
            while (quiver.capacity() < maxAmmo) {
                quiver.push(createMagicCharges())
            }
        } else {
            while (quiver.capacity() < maxAmmo) {
                quiver.push(createRandomArrow())
            }
        }
    }
}
