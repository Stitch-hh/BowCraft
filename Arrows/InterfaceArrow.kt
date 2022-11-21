package Arrows

interface InterfaceArrow {
    val arrowDamage: Int
    val arrowCriticalCoefficient: Int
    val arrowCriticalChance: Int

    fun bringDamage(thisArrow: InterfaceArrow) : Int{
        return if ((0..100).random() in (0..thisArrow.arrowCriticalChance)) thisArrow.arrowDamage * thisArrow.arrowCriticalCoefficient
        else thisArrow.arrowDamage
    }
}
