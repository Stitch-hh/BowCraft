package Warriors

import Weapons.AbstractWeapon
import Weapons.WizardFireStuff

class Wizard : AbstractWarrior() {
    override val maxHitPoints = 300
    override var currentHP = maxHitPoints
    override val warriorAccuracy = 150
    override val warriorWeapon = WizardFireStuff()
    override var isKilled = false
    override val evasion = 0
}