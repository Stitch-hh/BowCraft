package Warriors

import Weapons.ShortBow

class ShortBowMan : AbstractWarrior() {
    override val maxHitPoints = 200
    override var currentHP = maxHitPoints
    override val warriorAccuracy = 50
    override val warriorWeapon = ShortBow()
    override var isKilled = false
    override val evasion = 25
}