package app.time_to.timeto.ui

import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.dp
import app.time_to.timeto.R
import app.time_to.timeto.rememberVM
import timeto.shared.vm.FoldersSettingsVM

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun FoldersSettingsSheet(
    isPresented: MutableState<Boolean>,
) {
    TimetoSheet(isPresented = isPresented) {

        val (vm, state) = rememberVM { FoldersSettingsVM() }

        Column(
            modifier = Modifier
                .fillMaxHeight()
                .background(c.bgFormSheet)
        ) {

            val scrollState = rememberLazyListState()

            SheetHeaderView(
                onCancel = { isPresented.value = false },
                title = state.headerTitle,
                doneText = state.headerDoneText,
                isDoneEnabled = true,
                scrollToHeader = 0, // todo
            ) {
                isPresented.value = false
            }

            LazyColumn(
                state = scrollState,
                modifier = Modifier
                    .padding(bottom = 20.dp)
                    .navigationBarsPadding()
                    .imePadding(),
                contentPadding = PaddingValues(top = 20.dp, bottom = 20.dp)
            ) {

                val folders = state.folders
                items(
                    items = folders,
                    key = { folder -> folder.id }
                ) { folder ->

                    val isFirst = folders.first() == folder
                    MyListView__ButtonView(
                        text = folder.name,
                        isFirst = isFirst,
                        isLast = folders.last() == folder,
                        modifier = Modifier.animateItemPlacement(),
                        withTopDivider = !isFirst,
                        rightView = {
                            Icon(
                                painterResource(id = R.drawable.ic_round_arrow_upward_24),
                                "Up",
                                tint = c.blue,
                                modifier = Modifier
                                    .padding(end = 10.dp)
                                    .size(26.dp)
                                    .clip(RoundedCornerShape(99.dp))
                                    .clickable(!isFirst) {
                                        vm.sortUp(folder)
                                    }
                                    .padding(2.dp)
                            )
                        }
                    ) {
                        // todo
//                            Text(folderUI.folder.name)
                    }
                }


                ////

                val tmrwButtonUI = state.tmrwButtonUI
                if (tmrwButtonUI != null) {
                    item {
                        MyListView__SectionView(
                            modifier = Modifier.padding(top = MyListView.PADDING_SHEET_FIRST_HEADER)
                        ) {
                            MyListView__SectionView__ButtonView(
                                text = tmrwButtonUI.text,
                            ) {
                                tmrwButtonUI.add()
                            }
                        }
                    }
                }
            }
        }
    }
}