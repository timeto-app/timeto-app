package app.time_to.timeto.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Divider
import androidx.compose.material.Icon
import androidx.compose.material.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import app.time_to.timeto.R
import app.time_to.timeto.ui.TriggersView__Utils.removeTriggerIds
import timeto.shared.db.ActivityModel
import timeto.shared.launchEx
import java.util.*

@Composable
fun EditActivitiesSheet(
    isPresented: MutableState<Boolean>,
) {
    val scope = rememberCoroutineScope()

    TimetoSheet(state = isPresented) {

        val allActivities = ActivityModel.getAscSortedFlow().collectAsState(listOf()).value

        Box(
            modifier = Modifier
                .background(c.background)
                .navigationBarsPadding()
        ) {

            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth(),
                contentPadding = PaddingValues(top = 20.dp, bottom = 70.dp)
            ) {

                itemsIndexed(allActivities, key = { _, item -> item.id }) { _, activity ->

                    MyList.SectionItem(
                        isFirst = allActivities.first() == activity,
                        isLast = allActivities.last() == activity,
                    ) {

                        Box(
                            modifier = Modifier
                                .fillMaxSize()
                                .background(c.background2),
                            contentAlignment = Alignment.TopCenter
                        ) {

                            Row(
                                verticalAlignment = Alignment.CenterVertically
                            ) {

                                Text(
                                    activity.nameWithEmoji().removeTriggerIds(),
                                    modifier = Modifier
                                        .padding(
                                            PaddingValues(
                                                horizontal = 16.dp,
                                                vertical = MyList.SECTION_ITEM_BUTTON_V_PADDING
                                            )
                                        )
                                        .weight(1f),
                                    color = c.text,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )

                                Icon(
                                    painterResource(id = R.drawable.ic_round_arrow_downward_24),
                                    "Down",
                                    tint = c.blue,
                                    modifier = Modifier
                                        .padding(start = 5.dp)
                                        .size(24.dp)
                                        .clip(RoundedCornerShape(99.dp))
                                        .clickable {
                                            val tmpActivities = allActivities.map { it }
                                            if (tmpActivities.lastOrNull() == activity)
                                                return@clickable

                                            val oldIndex = tmpActivities.indexOf(activity)
                                            Collections.swap(tmpActivities, oldIndex, oldIndex + 1)
                                            scope.launchEx {
                                                tmpActivities.forEachIndexed { newIndex, activity ->
                                                    activity.upSort(newIndex)
                                                }
                                            }
                                        }
                                        .padding(1.dp)
                                )

                                Icon(
                                    painterResource(id = R.drawable.ic_round_arrow_upward_24),
                                    "Up",
                                    tint = c.blue,
                                    modifier = Modifier
                                        .padding(start = 4.dp, end = 8.dp)
                                        .size(24.dp)
                                        .clip(RoundedCornerShape(99.dp))
                                        .clickable {
                                            val tmpActivities = allActivities.map { it }
                                            if (tmpActivities.firstOrNull() == activity)
                                                return@clickable

                                            val oldIndex = tmpActivities.indexOf(activity)
                                            Collections.swap(tmpActivities, oldIndex, oldIndex - 1)
                                            scope.launchEx {
                                                tmpActivities.forEachIndexed { newIndex, activity ->
                                                    activity.upSort(newIndex)
                                                }
                                            }
                                        }
                                        .padding(1.dp)
                                )
                            }

                            if (allActivities.firstOrNull() != activity)
                                Divider(
                                    color = c.dividerBackground2,
                                    modifier = Modifier.padding(start = 18.dp),
                                    thickness = 0.5.dp
                                )
                        }
                    }
                }
            }

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(end = 21.dp, bottom = 20.dp)
                    .align(Alignment.BottomCenter),
                horizontalArrangement = Arrangement.End,
                verticalAlignment = Alignment.CenterVertically
            ) {

                SpacerW1()

                Text(
                    "Close",
                    modifier = Modifier
                        .padding(end = 14.dp)
                        .clip(MySquircleShape())
                        .clickable {
                            isPresented.value = false
                        }
                        .padding(bottom = 5.dp, top = 5.dp, start = 9.dp, end = 9.dp),
                    color = c.textSecondary,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.W400
                )
            }
        }
    }
}