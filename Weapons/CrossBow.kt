package Weapons


import Arrows.Ammo
import Arrows.InterfaceArrow
import Stack
import Warriors.FireType

class CrossBow : AbstractWeapon() {
    override val maxAmmo = 2
    override val attackType = FireType.SplitShot(2)
    override val quiver = Stack<InterfaceArrow>(Ammo.BONE)

}