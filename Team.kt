import Warriors.*

class Team (private val numberOfWarriors: Int) {
    private val warriorsTeam = mutableListOf<Warrior>()


    private fun createRandomWarrior(): AbstractWarrior {
        return when ((1..100).random()){
            in (10..50) -> ShortBowMan()
            in (60..80) -> LongbowMan()
            in (80..95) -> CrossBowMan()
            else -> Wizard()
        }
    }

    fun fillTheTeam(number: Int = numberOfWarriors): MutableList<Warrior> {
        var warriorsCount = 0
        while (warriorsCount < number) {
            val a: AbstractWarrior = createRandomWarrior()
            a.warriorWeapon.reload()
            warriorsTeam.add(a)
            warriorsCount++
        }
        return warriorsTeam
    }
}