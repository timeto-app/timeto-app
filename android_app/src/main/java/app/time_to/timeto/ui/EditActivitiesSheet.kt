package app.time_to.timeto.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
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
import app.time_to.timeto.rememberVM
import timeto.shared.vm.SortActivitiesVM

@Composable
fun EditActivitiesSheet(
    layer: WrapperView.Layer
) {

    val (vm, state) = rememberVM { SortActivitiesVM() }

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

            val activitiesUI = state.activitiesUI
            itemsIndexed(
                activitiesUI,
                key = { _, item -> item.activity.id }
            ) { _, activityUI ->

                val isFirst = activitiesUI.first() == activityUI

                MyListView__ItemView(
                    isFirst = isFirst,
                    isLast = activitiesUI.last() == activityUI,
                    withTopDivider = !isFirst,
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
                                activityUI.listText,
                                modifier = Modifier
                                    .padding(
                                        PaddingValues(
                                            horizontal = 16.dp,
                                            vertical = 12.dp,
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
                                        vm.down(activityUI)
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
                                        vm.up(activityUI)
                                    }
                                    .padding(1.dp)
                            )
                        }
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
                        layer.close()
                    }
                    .padding(bottom = 5.dp, top = 5.dp, start = 9.dp, end = 9.dp),
                color = c.textSecondary,
                fontSize = 15.sp,
                fontWeight = FontWeight.W400
            )
        }
    }
}
