import Warriors.Warrior

class Battle(val team1: MutableList<Warrior>, val team2: MutableList<Warrior>) {

    var battleIsEnded: Boolean = false

    fun battleStatus() {
        if (team1.isEmpty() && team2.isEmpty()) {
            battleIsEnded = true
            println("Draw")
        } else if (team1.isEmpty()) {
            battleIsEnded = true
            println("Team 2 win")
        } else if (team2.isEmpty()) {
            battleIsEnded = true
            println("Team 1 win")
        } else {
            println("team 1 - $team1")
            println("team 2 - $team2")
            println("Battle continue")
        }
    }


    fun battleStep() {
        if (team1.isNotEmpty() && team2.isNotEmpty()) {
            team1[(0..team1.lastIndex).random()].attack(team2)
            val a = team2.filter { it -> it.isKilled }
            team2.removeAll(a)
        } else battleStatus()

        if (team2.isNotEmpty() && team1.isNotEmpty()) {
            team2[(0..team2.lastIndex).random()].attack(team1)
            val a = team1.filter { it -> it.isKilled }
            team1.removeAll(a)
        } else battleStatus()

        battleStatus()
    }
}