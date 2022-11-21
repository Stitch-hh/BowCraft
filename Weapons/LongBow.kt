package Weapons

import Arrows.Ammo
import Arrows.InterfaceArrow
import Stack
import Warriors.FireType

class LongBow : AbstractWeapon(){
    override val maxAmmo = 10
    override val attackType = FireType.SingleShot
    override val quiver = Stack<InterfaceArrow>(Ammo.BONE)

}