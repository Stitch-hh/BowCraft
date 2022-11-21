package Warriors

sealed class FireType {
    object SingleShot : FireType()
    data class SplitShot(val burstSize: Int): FireType()
    object MultiShot: FireType()
}
