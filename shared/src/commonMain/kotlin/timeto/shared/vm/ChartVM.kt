package timeto.shared.vm

import kotlinx.coroutines.flow.*
import timeto.shared.*
import timeto.shared.db.IntervalModel
import kotlin.math.abs

/**
 * todo
 * If you open on one day and then reopen to another,
 * it will not be possible to select the current day.
 */
class ChartVM : __VM<ChartVM.State>() {

    class PeriodHint(
        val title: String,
        val dayStart: Int,
        val dayFinish: Int,
    )

    data class State(
        val dayStart: Int,
        val dayFinish: Int,
        val periodHints: List<PeriodHint>,
        val selectedId: String?,
        val pieItems: List<PieChart.ItemData>,
        val minPickerDay: Int,
        val maxPickerDay: Int,
    ) {
        val activePeriodHintTitle: String = periodHints.firstOrNull { period ->
            period.dayStart == dayStart && period.dayFinish == dayFinish
        }?.title ?: ""
    }

    override val state: MutableStateFlow<State>

    init {
        val today = UnixTime().localDay

        val initDay = DI.firstInterval.unixTime().localDay
        val periods: List<PeriodHint> = listOfNotNull(
            PeriodHint("Today", today, today),
            // Relevant for the first run, otherwise when you click - crash
            if (today > initDay) PeriodHint("Yesterday", today - 1, today - 1) else null,
            PeriodHint("7 days", today - 6, today),
            PeriodHint("30 days", today - 29, today),
        )

        state = MutableStateFlow(
            State(
                dayStart = today - 6,
                dayFinish = today,
                periodHints = periods,
                selectedId = null,
                pieItems = listOf(),
                minPickerDay = initDay,
                maxPickerDay = today,
            )
        )
    }

    override fun onAppear() {
        upPeriod(state.value.dayStart, state.value.dayFinish)
    }

    fun selectId(id: String?) {
        state.update { it.copy(selectedId = id) }
    }

    fun upPeriod(
        dayStart: Int,
        dayFinish: Int,
    ) {
        scopeVM().launchEx {
            val items = prepPieItems(dayStart, dayFinish)
            state.update {
                it.copy(
                    dayStart = dayStart,
                    dayFinish = dayFinish,
                    pieItems = items,
                )
            }
        }
    }

    fun upDayStart(day: Int) = upPeriod(
        dayStart = day,
        dayFinish = state.value.dayFinish,
    )

    fun upDayFinish(day: Int) = upPeriod(
        dayStart = state.value.dayStart,
        dayFinish = day,
    )
}

private suspend fun prepPieItems(
    formDayStart: Int,
    formDayFinish: Int,
): List<PieChart.ItemData> {

    /**
     * The period that is selected can be wider than the history with
     * the data, especially relevant on the first day of the launch,
     * when the data only for the day but the period of 7 days.
     */
    val realTimeStart = UnixTime.byLocalDay(formDayStart).time.max(DI.firstInterval.id)
    val realTimeFinish = (UnixTime.byLocalDay(formDayFinish).inDays(1).time - 1).min(time())

    ///

    val mapActivityIdSeconds = mutableMapOf<Int, Int>()
    val intervalsAsc = IntervalModel.getBetweenIdDesc(realTimeStart, realTimeFinish).reversed()
    intervalsAsc.forEachIndexed { index, interval ->
        val iSeconds = if (intervalsAsc.last() == interval)
            realTimeFinish - interval.id
        else
            intervalsAsc[index + 1].id - interval.id
        mapActivityIdSeconds.plusOrSet(interval.activity_id, iSeconds)
    }
    val prevInterval = IntervalModel.getBetweenIdDesc(0, realTimeStart - 1, 1).firstOrNull()
    if (prevInterval != null) {
        val iSeconds = intervalsAsc.firstOrNull()?.id ?: realTimeFinish
        mapActivityIdSeconds.plusOrSet(prevInterval.activity_id, iSeconds - realTimeStart)
    }

    ///

    val realTotalSeconds = abs(realTimeFinish - realTimeStart)

    val realDayStart = UnixTime(realTimeStart).localDay
    val realDayFinish = UnixTime(realTimeFinish).localDay

    return mapActivityIdSeconds
        .toList()
        .sortedByDescending { it.second }
        .map { (activityId, seconds) ->
            val activity = DI.activitiesSorted.first { it.id == activityId }
            val ratio = seconds.toFloat() / realTotalSeconds
            val tableNote = secondsToString(seconds / (realDayFinish - realDayStart + 1)) + if (realDayStart == realDayFinish) "" else " / day"

            PieChart.ItemData(
                id = "${activity.id}",
                value = seconds.toDouble(),
                color = activity.getColorRgba(),
                title = TextFeatures.parse(activity.nameWithEmoji()).textUi,
                shortTitle = activity.emoji,
                subtitleTop = "${(ratio * 100).toInt()}%",
                subtitleBottom = secondsToString(seconds),
                customData = tableNote,
            )
        }
}

private fun secondsToString(seconds: Int): String {
    val aTime = mutableListOf<String>()
    val hms = seconds.toHms()
    if (hms[0] > 0)
        aTime.add("${hms[0]}h")
    if (hms[1] > 0)
        aTime.add("${hms[1]}m")
    if (aTime.isEmpty())
        aTime.add("${hms[2]}s")
    return aTime.joinToString(" ")
}
