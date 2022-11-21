package Warriors

import Weapons.LongBow

class LongbowMan : AbstractWarrior() {
    override val maxHitPoints = 500
    override var currentHP = maxHitPoints
    override val warriorAccuracy = 70
    override val warriorWeapon = LongBow()
    override var isKilled = false
    override val evasion = 10
}