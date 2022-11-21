package Warriors


interface Warrior {
    val isKilled : Boolean
    val evasion : Int

    fun attack(attackTarget: MutableList<Warrior>)

    fun takeDamage (damage: Int)
}