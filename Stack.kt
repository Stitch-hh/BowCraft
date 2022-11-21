class Stack<T>(value: T) {

    private val baseListOfT = mutableListOf<T>()


    fun isEmptyStack() : Boolean{
        return baseListOfT.size == 0
    }

    fun push (item: T){
        baseListOfT.add(item)
    }

    fun pop() : T? {
        return if (baseListOfT.isEmpty()) null
        else {
            val popped = baseListOfT[baseListOfT.lastIndex]
            baseListOfT.removeAt(baseListOfT.lastIndex)
            popped
        }
    }


    fun capacity(): Int {
        return baseListOfT.size
    }
}