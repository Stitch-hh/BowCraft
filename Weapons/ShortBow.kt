package Weapons

import Arrows.Ammo
import Arrows.InterfaceArrow
import Stack
import Warriors.FireType

class ShortBow : AbstractWeapon() {
    override val maxAmmo = 5
    override val attackType = FireType.SingleShot
    override val quiver = Stack<InterfaceArrow>(Ammo.BONE)



}