package app.time_to.timeto.ui

import android.view.MotionEvent
import androidx.activity.compose.BackHandler
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.input.pointer.*
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.layout.positionInWindow
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.time_to.timeto.*
import app.time_to.timeto.R
import kotlinx.coroutines.delay
import timeto.shared.DI
import timeto.shared.db.TaskFolderModel
import timeto.shared.vm.TabTasksVM
import java.util.*
import kotlin.random.Random

var setTodayFolder: (() -> Unit)? = null

val TAB_TASKS_PADDING_START = 24.dp
val TAB_TASKS_PADDING_END = 68.dp

val taskListSectionPadding = 20.dp

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun TabTasksView() {
    val (_, state) = rememberVM { TabTasksVM() }

    var activeSection by remember {
        mutableStateOf<Section?>(Section_Folder(DI.getTodayFolder()))
    }

    ///
    /// Navigation

    setTodayFolder = {
        activeSection = Section_Folder(DI.getTodayFolder())
    }
    BackHandler((activeSection as? Section_Folder)?.folder?.isToday != true) {
        setTodayFolder!!()
    }

    //////

    val dragItem = remember { mutableStateOf<DragItem?>(null) }
    val dropItems = remember { mutableListOf<DropItem>() }
    fun setFocusedDrop(drop: DropItem?) {
        dragItem.value?.focusedDrop?.value = drop
    }

    Box(
        Modifier
            .motionEventSpy { event ->
                val dragItemValue = dragItem.value ?: return@motionEventSpy

                val x = event.x
                val y = event.y
                val focusedDrop = dropItems
                    .filter { dragItemValue.isDropAllowed(it) }
                    .firstOrNull { drop ->
                        val s = drop.square
                        x > s.x1 && y > s.y1 && x < s.x2 && y < s.y2
                    }

                if (focusedDrop == null) {
                    setFocusedDrop(null)
                    return@motionEventSpy
                }

                when (event.action) {
                    MotionEvent.ACTION_UP -> {
                        dragItemValue.onDrop(focusedDrop)
                        setFocusedDrop(null)
                    }
                    MotionEvent.ACTION_MOVE -> {
                        if (dragItemValue.focusedDrop.value == null)
                            vibrateShort()
                        setFocusedDrop(focusedDrop)
                    }
                    else -> {
                        setFocusedDrop(null)
                    }
                }
            }
            .background(c.background),
        contentAlignment = Alignment.CenterEnd
    ) {

        when (val curSection = activeSection) {
            is Section_Folder -> TasksListView(curSection.folder, dragItem)
            is Section_Calendar -> EventsListView()
            is Section_Repeating -> RepeatingsListView()
        }

        val buttonWidth = 35.dp
        val tabSpace = 11.dp

        Column(
            modifier = Modifier
                .padding(end = 12.dp)
                .width(buttonWidth)
                .fillMaxHeight(),
            verticalArrangement = Arrangement.Center
        ) {

            val activeTextColor = c.white
            val inactiveTextColor = c.textSecondary

            LazyColumn(
                contentPadding = PaddingValues(bottom = tabSpace)
            ) {

                val tabShape = MySquircleShape(50f)

                item {
                    val isActive = activeSection is Section_Calendar

                    val dropItem = remember { DropItem.Type__Calendar(DropItem.Square(0, 0, 0, 0)) }
                    DisposableEffect(Unit) {
                        dropItems.add(dropItem)
                        onDispose { dropItems.remove(dropItem) }
                    }
                    val isAllowedToDrop = dragItem.value?.isDropAllowed?.invoke(dropItem) ?: false
                    val isFocusedToDrop = dragItem.value?.focusedDrop?.value == dropItem

                    val textColor = animateColorAsState(
                        when {
                            isFocusedToDrop -> c.tasksTabDropFocused
                            isAllowedToDrop -> c.purple
                            isActive -> c.blue
                            else -> c.calendarIconColor
                        },
                        spring(stiffness = Spring.StiffnessMedium)
                    )

                    val rotationMaxAngle = 5f
                    var rotationAngle by remember { mutableStateOf(0f) }
                    val rotationAngleAnimate by animateFloatAsState(
                        targetValue = rotationAngle,
                        animationSpec = tween(durationMillis = Random.nextInt(80, 130), easing = LinearEasing),
                        finishedListener = {
                            if (isAllowedToDrop)
                                rotationAngle = if (rotationAngle < 0) rotationMaxAngle else -rotationMaxAngle
                        }
                    )
                    LaunchedEffect(isAllowedToDrop) {
                        if (isAllowedToDrop)
                            delay(Random.nextInt(0, 100).toLong())
                        rotationAngle = if (isAllowedToDrop) (if (Random.nextBoolean()) rotationMaxAngle else -rotationMaxAngle) else 0f
                    }

                    Box(
                        modifier = Modifier
                            .padding(horizontal = 1.dp)
                            .fillMaxWidth()
                            .rotate(rotationAngleAnimate)
                            .onGloballyPositioned { c ->
                                dropItem.upSquareByCoordinates(c)
                            }
                            .clip(MySquircleShape(40f, -4f))
                            .background(c.calendarIconBg)
                            .clickable {
                                activeSection = Section_Calendar()
                            },
                    ) {
                        Icon(
                            painterResource(id = R.drawable.sf_calendar_medium_light),
                            contentDescription = "Calendar",
                            tint = textColor.value,
                            modifier = Modifier
                                .fillMaxWidth()
                        )
                    }
                }

                item {
                    val isActive = activeSection is Section_Repeating
                    val backgroundColor = animateColorAsState(if (isActive) c.blue else c.background2, spring(stiffness = Spring.StiffnessMedium))
                    val textColor = animateColorAsState(if (isActive) activeTextColor else inactiveTextColor, spring(stiffness = Spring.StiffnessMedium))

                    Box(
                        modifier = Modifier
                            .padding(top = 10.dp)
                            .width(buttonWidth)
                            .height(buttonWidth)
                            .clip(tabShape)
                            .background(backgroundColor.value)
                            .clickable {
                                activeSection = Section_Repeating()
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            painterResource(id = R.drawable.sf_repeat_medium_semibold),
                            contentDescription = "Repeating",
                            tint = textColor.value,
                            modifier = Modifier.size(17.5.dp)
                        )
                    }
                }

                items(state.folders.reversed()) { folder ->
                    val dropItem = remember {
                        DropItem.Type__Folder(folder, DropItem.Square(0, 0, 0, 0))
                    }
                    DisposableEffect(Unit) {
                        dropItems.add(dropItem)
                        onDispose {
                            dropItems.remove(dropItem)
                        }
                    }
                    val isAllowedToDrop = dragItem.value?.isDropAllowed?.invoke(dropItem) ?: false
                    val isFocusedToDrop = dragItem.value?.focusedDrop?.value == dropItem

                    val isActive = (activeSection as? Section_Folder)?.folder?.id == folder.id
                    val backgroundColor = animateColorAsState(
                        when {
                            isFocusedToDrop -> c.tasksTabDropFocused
                            isAllowedToDrop -> c.purple
                            isActive -> c.blue
                            else -> c.background2
                        },
                        spring(stiffness = Spring.StiffnessMedium)
                    )
                    val textColor = animateColorAsState(
                        when {
                            isFocusedToDrop -> c.white
                            isAllowedToDrop -> c.white
                            isActive -> activeTextColor
                            else -> inactiveTextColor
                        },
                        spring(stiffness = Spring.StiffnessMedium)
                    )

                    val rotationMaxAngle = 3f
                    var rotationAngle by remember { mutableStateOf(0f) }
                    val rotationAngleAnimate by animateFloatAsState(
                        targetValue = rotationAngle,
                        animationSpec = tween(durationMillis = Random.nextInt(80, 130), easing = LinearEasing),
                        finishedListener = {
                            if (isAllowedToDrop)
                                rotationAngle = if (rotationAngle < 0) rotationMaxAngle else -rotationMaxAngle
                        }
                    )
                    LaunchedEffect(isAllowedToDrop) {
                        if (isAllowedToDrop)
                            delay(Random.nextInt(0, 50).toLong())
                        rotationAngle = if (isAllowedToDrop) (if (Random.nextBoolean()) rotationMaxAngle else -rotationMaxAngle) else 0f
                    }

                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(top = tabSpace)
                            .rotate(rotationAngleAnimate)
                            .onGloballyPositioned { c ->
                                dropItem.upSquareByCoordinates(c)
                            }
                            .clip(tabShape)
                            .background(backgroundColor.value)
                    ) {

                        Text(
                            folder.name.uppercase().split("").joinToString("\n").trim(),
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    activeSection = Section_Folder(folder)
                                }
                                .padding(vertical = 8.dp),
                            textAlign = TextAlign.Center,
                            color = textColor.value,
                            fontSize = 15.sp,
                            lineHeight = 16.5.sp,
                            fontWeight = FontWeight.W600,
                            fontFamily = FontFamily.Monospace
                        )
                    }
                }
            }
        }
    }
}

private interface Section
private class Section_Folder(val folder: TaskFolderModel) : Section
private class Section_Calendar : Section
private class Section_Repeating : Section


//
// Drag and Drop

class DragItem(
    val focusedDrop: MutableState<DropItem?>,
    val isDropAllowed: (drop: DropItem) -> Boolean,
    val onDrop: (drop: DropItem) -> Unit,
)

sealed class DropItem(
    val name: String,
    val square: Square,
) {

    fun upSquareByCoordinates(c: LayoutCoordinates) {
        val p = c.positionInWindow()
        square.x1 = p.x.toInt()
        square.y1 = p.y.toInt()
        square.x2 = p.x.toInt() + c.size.width
        square.y2 = p.y.toInt() + c.size.height
    }

    class Square(var x1: Int, var y1: Int, var x2: Int, var y2: Int)

    ///
    /// Types

    class Type__Folder(
        val folder: TaskFolderModel,
        square: Square,
    ) : DropItem(folder.name, square)

    class Type__Calendar(
        square: Square,
    ) : DropItem("Calendar", square)
}

////

fun gotoTimer() {
    globalNav!!.navigate(TabItem.Timer.route) {
        popUpTo(0)
    }
}
