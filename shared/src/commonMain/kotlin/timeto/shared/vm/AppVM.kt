package timeto.shared.vm

import io.ktor.client.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.utils.io.core.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import timeto.shared.*
import timeto.shared.db.*

class AppVM : __VM<AppVM.State>() {

    data class State(
        val isAppReady: Boolean,
    )

    override val state = MutableStateFlow(
        State(
            isAppReady = false
        )
    )

    override fun onAppear() {
        scopeVM().launchEx {

            initKmmDeferred.await()

            if (!DI.isLateInitInitialized())
                fillInitData()

            // todo migration from 143
            val allActivities = ActivityModel.getAscSorted()
            RepeatingModel.getAsc().forEach { repeating ->
                var newText = repeating.text

                val activity = allActivities.firstOrNull { it.emoji in repeating.text }
                if (activity != null)
                    newText = newText.replace(activity.emoji, "") + " #a${activity.id}"

                val timeRes = TimerTimeParser.findTime(newText)
                if (timeRes != null)
                    newText = newText.replace(timeRes.match, "") + " #t${timeRes.seconds}"

                newText = newText.removeDuplicateSpaces()
                if (newText == repeating.text)
                    return@forEach
                // todo remove from sq
                db.repeatingQueries.upTextById(text = newText, id = repeating.id)
                zlog(repeating.text)
                zlog(newText)
                zlog("---")
            }

            state.update { it.copy(isAppReady = true) }

            ///

            IntervalModel
                .getLastOneOrNullFlow()
                .filterNotNull()
                .onEachExIn(this) { lastInterval ->
                    ActivityModel.syncTimeHints()
                    rescheduleNotifications()
                    showTriggersForInterval(lastInterval)
                }

            launchEx {
                while (true) {
                    /**
                     * Not delayToNextMinute(extraMls = 1_000L):
                     * - No need to wait after daytime changes;
                     * - No need to wait after backup restore.
                     */
                    delay(1_000L)
                    try {
                        syncTmrw()
                        syncTodayEvents()
                        syncTodayRepeating()
                    } catch (e: Throwable) {
                        reportApi("AppVM sync today error:$e")
                        delay(300_000L)
                    }
                }
            }

            launchEx {
                // Delay to not load the system at startup. But not too long
                // because some data may be needed soon, like feedback subject.
                delay(500L)
                while (true) {
                    ping()
                    delay(10 * 60 * 1_000L) // 10 min
                }
            }
        }
    }

    fun onNotificationsPermissionReady(delayMls: Long) {
        scopeVM().launchEx {
            delay(delayMls)
            rescheduleNotifications()
        }
    }
}

private suspend fun showTriggersForInterval(
    lastInterval: IntervalModel
) {
    if ((lastInterval.id + 3) < time())
        return

    fun fsOrTriggers(isFS: Boolean, features: TextFeatures) {
        if (isFS) {
            FullScreenUI.open()
            features.triggers.firstOrNull { it !is Trigger.Checklist }?.performUI()
        } else
            features.triggers.firstOrNull()?.performUI()
    }

    val activity = lastInterval.getActivityDI()
    val isActivityAutoFS = activity.isAutoFs

    val note = lastInterval.note
    if (note != null) {
        val noteFeatures = note.parseTextFeatures()

        val fromRepeating = noteFeatures.fromRepeating
        if (fromRepeating != null) {
            val isFS = RepeatingModel.getByIdOrNull(fromRepeating.id)?.isAutoFs ?: false
            fsOrTriggers(isFS, noteFeatures)
            return
        }

        fsOrTriggers(isActivityAutoFS, noteFeatures)
        return
    }

    fsOrTriggers(isActivityAutoFS, activity.name.parseTextFeatures())
}

///
/// Ping

private var pingLastDay: Int? = null
private suspend fun ping() {
    val today = UnixTime().localDay
    if (pingLastDay == today)
        return

    try {
        HttpClient().use { client ->
            val httpResponse = client.get("https://api.timeto.me/ping") {
                url {
                    parameters.append("password", getsertTokenPassword())
                    appendDeviceData()
                }
            }
            val plainJson = httpResponse.bodyAsText()
            val j = Json.parseToJsonElement(plainJson).jsonObject
            if (j.getString("status") != "success")
                throw Exception("status != success\n$plainJson")
            val jData = j.jsonObject["data"]!!.jsonObject
            SecureLocalStorage__Key.token.upsert(jData.getString("token"))
            SecureLocalStorage__Key.feedback_subject.upsert(jData.getString("feedback_subject"))
            pingLastDay = today // After success
        }
    } catch (e: Throwable) {
        reportApi("AppVM ping() exception:\n$e")
    }
}

@Throws(SecureLocalStorage__Exception::class)
private fun getsertTokenPassword(): String {
    val oldPassword = SecureLocalStorage__Key.token_password.getOrNull()
    if (oldPassword != null)
        return oldPassword

    val chars = ('0'..'9') + ('a'..'z') + ('A'..'Z') + ("!@#%^&*()_+".toList())
    val newPassword = (1..15).map { chars.random() }.joinToString("")
    SecureLocalStorage__Key.token_password.upsert(newPassword)
    return newPassword
}

///
/// Sync today

private var syncTodayRepeatingLastDay: Int? = null
private suspend fun syncTodayRepeating() {
    val todayWithOffset = UnixTime(time() - dayStartOffsetSeconds()).localDay
    // To avoid unnecessary checks. It works without that.
    if (syncTodayRepeatingLastDay == todayWithOffset)
        return
    RepeatingModel.syncTodaySafe(todayWithOffset)
    // In case on error while syncTodaySafe()
    syncTodayRepeatingLastDay = todayWithOffset
}

private var syncTodayEventsLastDay: Int? = null
private suspend fun syncTodayEvents() {
    // GD "Day Start Offset" -> "Using for Events"
    val todayNoOffset = UnixTime().localDay
    // To avoid unnecessary checks. It works without that.
    if (syncTodayEventsLastDay == todayNoOffset)
        return
    EventModel.syncTodaySafe(todayNoOffset)
    // In case on error while syncTodaySafe()
    syncTodayEventsLastDay = todayNoOffset
}

private fun syncTmrw() {
    // DI to performance
    // Using .localDayWithDayStart() everywhere
    val utcOffsetDS = localUtcOffsetWithDayStart
    val todayDay = UnixTime(utcOffset = utcOffsetDS).localDay
    val todayFolder = DI.getTodayFolder()
    DI.tasks
        .filter { it.isTmrw && (it.unixTime(utcOffset = utcOffsetDS).localDay < todayDay) }
        .forEach { task ->
            launchExDefault {
                task.upFolder(
                    newFolder = todayFolder,
                    replaceIfTmrw = false // No matter
                )
            }
        }
}

//////

private suspend fun fillInitData() {
    try {
        /**
         * In iOS, the data in the keychain is saved even after uninstalling
         * the app, when initializing it is better to clean it. Otherwise:
         * - Reinstalling will not always "save" in any unclear situation;
         * - If it applies to different devices, there may be more than one
         *   device for one user.
         */
        SecureLocalStorage__Key.values().forEach { it.upsert(null) }
        syncTodayEventsLastDay = null
        syncTodayRepeatingLastDay = null
        pingLastDay = null
    } catch (e: Throwable) {
        reportApi("fillInitData() exception:\n$e")
    }

    // TRICK time() only for SMDAY
    TaskFolderModel.addRaw(TaskFolderModel.ID_TODAY, "Today", 1)
    TaskFolderModel.addTmrw()
    TaskFolderModel.addRaw(time(), "SMDAY", 3)

    val colorsWheel = Wheel(ActivityModel.colors)
    val cGreen = colorsWheel.next()
    val cBlue = colorsWheel.next()
    val cRed = colorsWheel.next()
    val cYellow = colorsWheel.next()
    val cPurple = colorsWheel.next()

    val defData = ActivityModel__Data.buildDefault()
    val aNormal = ActivityModel.TYPE.NORMAL
    ActivityModel.addWithValidation("Meditation", "?????????????", 20 * 60, 1, aNormal, cYellow, defData, false)
    ActivityModel.addWithValidation("Work", "????", 40 * 60, 2, aNormal, cBlue, defData, false)
    ActivityModel.addWithValidation("Hobby", "????", 3600, 3, aNormal, cRed, defData, false)
    val pd = ActivityModel.addWithValidation("Personal development", "????", 30 * 60, 4, aNormal, cPurple, defData, false)
    ActivityModel.addWithValidation("Exercises / Health", "????", 20 * 60, 5, aNormal, colorsWheel.next(), defData, false)
    ActivityModel.addWithValidation("Walk", "????", 30 * 60, 6, aNormal, colorsWheel.next(), defData, false)
    ActivityModel.addWithValidation("Getting ready", "????", 30 * 60, 7, aNormal, colorsWheel.next(), defData, false)
    ActivityModel.addWithValidation("Sleep / Rest", "????", 8 * 3600, 8, aNormal, cGreen, defData, false)
    ActivityModel.addWithValidation("Other", "????", 3600, 9, ActivityModel.TYPE.OTHER, colorsWheel.next(), defData, false)

    val interval = IntervalModel.addWithValidation(30 * 60, pd, null)
    // To 100% ensure
    DI.fillLateInit(interval, interval)

    val todayDay = UnixTime().localDay
    RepeatingModel.addWithValidation("Exercises ???? 30 min", RepeatingModel.Period.EveryNDays(1), todayDay, null, false)
    RepeatingModel.addWithValidation("Meditation ????????????? 20 min", RepeatingModel.Period.EveryNDays(1), todayDay, null, false)
    RepeatingModel.addWithValidation("Small tasks ???? 30 min", RepeatingModel.Period.EveryNDays(1), todayDay, null, false)
    RepeatingModel.addWithValidation("Getting ready ???? 20 min", RepeatingModel.Period.EveryNDays(1), todayDay, null, false)
    RepeatingModel.addWithValidation("Weekly plan ???? 20 min", RepeatingModel.Period.DaysOfWeek(listOf(0)), todayDay, null, false)
}
