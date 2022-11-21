package Weapons

import Arrows.Ammo
import Arrows.InterfaceArrow
import Stack
import Team
import Warriors.FireType
import Warriors.Warrior

class WizardFireStuff : AbstractWeapon() {
    override val maxAmmo = 99999
    override var attackType = FireType.MultiShot
    override val quiver = Stack<InterfaceArrow>(Ammo.BONE)
}


