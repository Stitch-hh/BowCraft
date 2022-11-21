package Warriors

import Weapons.CrossBow

class CrossBowMan : AbstractWarrior() {
    override val maxHitPoints = 700
    override var currentHP = maxHitPoints
    override val warriorAccuracy = 0
    override val warriorWeapon = CrossBow()
    override var isKilled = false
    override val evasion = 0
}