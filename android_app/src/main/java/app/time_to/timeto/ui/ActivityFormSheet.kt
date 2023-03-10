package app.time_to.timeto.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.Icon
import androidx.compose.material.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.time_to.timeto.R
import app.time_to.timeto.rememberVM
import timeto.shared.db.ActivityModel
import timeto.shared.db.ActivityModel__Data.TimerHints.HINT_TYPE
import timeto.shared.vm.ActivityFormSheetVM

@Composable
fun ActivityFormSheet(
    layer: WrapperView.Layer,
    editedActivity: ActivityModel?,
) {

    val (vm, state) = rememberVM(editedActivity) { ActivityFormSheetVM(editedActivity) }

    Column(
        modifier = Modifier
            .fillMaxHeight()
            .background(c.bgFormSheet)
    ) {

        val scrollState = rememberScrollState()

        Sheet.HeaderView(
            onCancel = { layer.close() },
            title = state.headerTitle,
            doneText = state.headerDoneText,
            isDoneEnabled = state.isHeaderDoneEnabled,
            scrollToHeader = scrollState.value,
        ) {
            vm.save {
                layer.close()
            }
        }

        Column(
            modifier = Modifier
                .verticalScroll(
                    state = scrollState
                )
                .padding(bottom = 20.dp)
                .navigationBarsPadding()
                .imePadding()
        ) {

            ////

            MyListView__Padding__SectionHeader()

            MyListView__HeaderView(
                state.inputNameHeader,
            )

            MyListView__Padding__HeaderSection()

            MyListView__ItemView(
                isFirst = true,
                isLast = true,
            ) {
                MyListView__ItemView__TextInputView(
                    placeholder = state.inputNamePlaceholder,
                    text = state.inputNameValue,
                    onTextChanged = { newText -> vm.setInputNameValue(newText) },
                )
            }

            ////

            TriggersView__FormView(
                triggers = state.textFeatures.triggers,
                onTriggersChanged = { vm.setTriggers(it) },
                modifier = Modifier.padding(top = 18.dp),
                contentPaddingHints = PaddingValues(horizontal = MyListView.PADDING_OUTER_HORIZONTAL),
            )

            MyListView__Padding__SectionSection()

            MyListView__ItemView(
                isFirst = true,
                isLast = false,
            ) {
                MyListView__ItemView__ButtonView(
                    text = state.emojiTitle,
                    withArrow = true,
                    rightView = {
                        val uniqueEmojiValue = state.emoji
                        if (uniqueEmojiValue != null) {
                            Text(
                                uniqueEmojiValue,
                                modifier = Modifier
                                    .padding(end = 4.dp),
                                fontSize = 27.sp
                            )
                        } else {
                            Text(
                                state.emojiNotSelected,
                                modifier = Modifier
                                    .offset(y = -(0.5.dp)),
                                color = c.red,
                                fontSize = 15.sp
                            )
                        }
                    }
                ) {
                    Sheet.show { layer ->
                        SearchEmojiSheet(layer = layer) {
                            vm.setEmoji(it)
                        }
                    }
                }
            }

            MyListView__ItemView(
                isFirst = false,
                isLast = true,
                withTopDivider = true,
            ) {
                MyListView__ItemView__SwitchView(
                    text = state.autoFSTitle,
                    isActive = state.isAutoFS,
                ) {
                    vm.toggleAutoFS()
                }
            }

            MyListView__Padding__SectionSection()

            MyListView__HeaderView(
                title = state.timerHintsHeader,
            )

            MyListView__Padding__HeaderSection()

            Column {

                val hintsTypeName: List<Pair<String, HINT_TYPE>> = listOf(
                    Pair("By History", HINT_TYPE.history),
                    Pair("Custom", HINT_TYPE.custom),
                )

                hintsTypeName.forEach { pair ->

                    val isFirst = hintsTypeName.first() == pair

                    MyListView__ItemView(
                        isFirst = isFirst,
                        isLast = hintsTypeName.last() == pair,
                        withTopDivider = !isFirst
                    ) {

                        val isActive = state.activityData.timer_hints.type == pair.second

                        Column {

                            MyListView__ItemView__RadioView(
                                text = pair.first,
                                isActive = isActive
                            ) {
                                vm.setTimerHintsType(pair.second)
                            }

                            AnimatedVisibility(
                                visible = isActive
                            ) {

                                if (pair.second == HINT_TYPE.custom) {

                                    Column {

                                        /**
                                         * Impossible to use LazyColumn because of nested scroll. todo animation
                                         */
                                        state.timerHintsCustomItems.forEach { customItem ->

                                            Row(
                                                modifier = Modifier
                                                    .padding(
                                                        bottom = 8.dp,
                                                        start = MyListView.PADDING_INNER_HORIZONTAL
                                                    ),
                                                verticalAlignment = Alignment.CenterVertically,
                                            ) {

                                                Icon(
                                                    painterResource(id = R.drawable.sf_xmark_large_light),
                                                    contentDescription = "Close",
                                                    modifier = Modifier
                                                        .padding(end = 4.dp)
                                                        .offset(x = (-2).dp)
                                                        .size(19.dp, 19.dp)
                                                        .clip(RoundedCornerShape(99f))
                                                        .clickable {
                                                            vm.delCustomTimerHint(customItem.seconds)
                                                        }
                                                        .padding(4.dp),
                                                    tint = c.red
                                                )

                                                Text(
                                                    customItem.text,
                                                    modifier = Modifier
                                                        .padding(start = 1.dp)
                                                        .offset(y = -1.dp),
                                                    color = c.text,
                                                    fontSize = 14.sp,
                                                )
                                            }
                                        }

                                        Text(
                                            "Add",
                                            modifier = Modifier
                                                .padding(
                                                    start = MyListView.PADDING_INNER_HORIZONTAL - 8.dp,
                                                    bottom = 8.dp,
                                                )
                                                .clip(RoundedCornerShape(99f))
                                                .clickable {
                                                    Sheet.show { layer ->
                                                        TimerPickerSheet(
                                                            layer = layer,
                                                            title = "Timer Hint",
                                                            doneText = "Add",
                                                            defMinutes = 30,
                                                        ) { seconds ->
                                                            vm.addCustomTimerHint(seconds)
                                                        }
                                                    }
                                                }
                                                .padding(vertical = 4.dp, horizontal = 8.dp),
                                            color = c.blue,
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
