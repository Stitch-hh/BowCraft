package Warriors

import Arrows.InterfaceArrow
import Weapons.AbstractWeapon

abstract class AbstractWarrior : Warrior {
    abstract val maxHitPoints: Int
    abstract var currentHP: Int
    abstract val warriorAccuracy: Int
    abstract val warriorWeapon: AbstractWeapon
    abstract override var isKilled: Boolean


    override fun attack(attackTarget: MutableList<Warrior>) {
        if (warriorWeapon.noArrowsInQuiver()) {
            warriorWeapon.reload()
        } else {
            when (warriorWeapon.attackType) {
                FireType.SingleShot -> {
                    val endTarget = attackTarget[(0..attackTarget.lastIndex).random()]
                    val endArrow: InterfaceArrow = warriorWeapon.shot()
                    if ((0..100).random() in 0..endTarget.evasion) return
                    else {
                        val endDamage = endArrow.bringDamage(endArrow)
                        endTarget.takeDamage(endDamage)
                        println("$endTarget получил $endDamage урона")
                    }
                }

                is FireType.SplitShot -> {
                    val endTarget = attackTarget[(0..attackTarget.lastIndex).random()]
                    val endArrows = mutableListOf<InterfaceArrow>()
                    while (endArrows.size < 2) {
                        endArrows.add(warriorWeapon.shot())
                    }
                    for (i in endArrows) {
                        if ((0..100).random() in 0..endTarget.evasion) return
                        else {
                            val endDamage = i.bringDamage(i)
                            endTarget.takeDamage(endDamage)
                            println("$endTarget получил $endDamage урона")
                        }
                    }
                }

                FireType.MultiShot -> {
                    attackTarget.forEach {
                        if ((0..100).random() in 0..it.evasion) return
                        else {
                            val endDamage = warriorWeapon.shot().bringDamage((warriorWeapon.shot()))
                            it.takeDamage(endDamage)
                            println("$it получил $endDamage урона")
                            warriorWeapon.reload()
                        }
                    }
                }
            }
        }
    }


    override fun takeDamage(damage: Int) {
        currentHP -= damage
        if (currentHP <= 0) {
            isKilled = true
            println("Юнит погибает")
        }


    }

}