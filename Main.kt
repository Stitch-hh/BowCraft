import Warriors.Warrior

fun main() {



    println("Введите число воинов в команде")
    var a = 0
    fun takeTheNumber() {
        val b = readLine()?.toIntOrNull()
        if (b == null || b < 1) {
            println("Введите корректное число")
            takeTheNumber()
        } else {
            a = b
        }
    }

    fun commandFiller(numb: Int): MutableList<Warrior> {
        return Team(numb).fillTheTeam()
    }

    takeTheNumber()
    val t1: MutableList<Warrior> = commandFiller(a)
    val t2: MutableList<Warrior> = commandFiller(a)


    val battle = Battle(t1, t2)
    var step = 1

    while (!battle.battleIsEnded) {
        println("Ход номер $step")
        battle.battleStep()
        step++
    }
}
