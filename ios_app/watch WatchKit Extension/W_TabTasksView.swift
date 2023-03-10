import SwiftUI
import shared

struct W_TabTasksView: View {

    @State private var vm = WatchTabTasksVM()

    var body: some View {
        VMView(vm: vm) { state in
            List {
                ForEach(state.foldersUI, id: \.title) { folderUI in
                    FolderView(title: folderUI.title, tasksUI: folderUI.tasks)
                }
            }
        }
    }

    private struct FolderView: View {

        let title: String
        let tasksUI: [WatchTabTasksVM.TaskUI]

        var body: some View {

            Section(title) {
                ForEach(tasksUI, id: \.task.id) { taskUI in
                    TaskView(taskUI: taskUI)
                }
            }
        }

        private struct TaskView: View {

            var taskUI: WatchTabTasksVM.TaskUI
            @State private var isActivitiesPresented = false

            var body: some View {
                Button(
                        action: {
                            taskUI.start(
                                    onStarted: {
                                        withAnimation {
                                            W_TabsView.lastInstance?.tabSelection = W_TabsView.TAB_ID_TIMER
                                        }
                                    },
                                    needSheet: {
                                        isActivitiesPresented = true
                                    }
                            )
                        },
                        label: {
                            VStack(alignment: .leading, spacing: 0) {

                                if let timeUI = taskUI.textFeatures.timeUI {
                                    Text(timeUI.daytimeText + "  " + timeUI.timeLeftText)
                                            .padding(.top, 1)
                                            .padding(.bottom, 2)
                                            .font(.system(size: 14, weight: .light))
                                            .foregroundColor(timeUI.color.toColor())
                                            .lineLimit(1)
                                }

                                Text(taskUI.listText)
                            }
                        }
                )
                        .sheet(isPresented: $isActivitiesPresented) {
                            TaskSheetDialog(task: taskUI.task, isPresented: $isActivitiesPresented)
                        }
            }

            private struct TaskSheetDialog: View {

                @State private var vm: WatchTaskSheetVM

                let task: TaskModel
                @Binding var isPresented: Bool

                init(task: TaskModel, isPresented: Binding<Bool>) {
                    self.task = task
                    _isPresented = isPresented
                    _vm = State(initialValue: WatchTaskSheetVM(task: task))
                }

                var body: some View {
                    VMView(vm: vm) { state in
                        List {
                            ForEach(state.activitiesUI, id: \.activity.id) { activityUI in
                                ActivityView(
                                        taskSheetDialog: self,
                                        activityUI: activityUI,
                                        task: task
                                )
                            }
                        }
                    }
                }

                private struct ActivityView: View {

                    let taskSheetDialog: TaskSheetDialog
                    let activityUI: WatchTaskSheetVM.ActivityUI
                    var task: TaskModel
                    @State private var isTickerPresented = false

                    var body: some View {
                        Button(
                                action: {
                                    isTickerPresented = true
                                },
                                label: {
                                    VStack(spacing: 0) {

                                        Text(activityUI.listTitle)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .lineLimit(1)
                                                .truncationMode(.middle)

                                        if !activityUI.timerHints.isEmpty {
                                            HStack {
                                                ForEach(activityUI.timerHints, id: \.seconds) { hintUI in
                                                    let isHistory = activityUI.historySeconds.contains(hintUI.seconds.toInt().toKotlinInt())
                                                    Button(
                                                            action: {
                                                                hintUI.startInterval {}
                                                                taskSheetDialog.isPresented = false
                                                                myAsyncAfter(0.05) { // ???????????? 0.2 ???? ???????????? ???? ????????????????
                                                                    W_TabsView.lastInstance?.tabSelection = W_TabsView.TAB_ID_TIMER
                                                                }
                                                            },
                                                            label: {
                                                                Text(hintUI.text)
                                                                        .padding(.horizontal, isHistory ? 3 : 0)
                                                                        .font(.system(size: isHistory ? 12 : 13, weight: .medium))
                                                                        .foregroundColor(.white)
                                                                        .background(isHistory ? .blue : .clear)
                                                                        .clipShape(Capsule(style: .continuous)) // .continuous ????-???? ???????????????????? padding
                                                                        .lineLimit(1)
                                                            }
                                                    )
                                                            .buttonStyle(.borderless)
                                                }
                                                // ?????? ???????? ???????????? ?????? ?????????????? ???? ?????????????? ?????????? ?????????? ?? ??????????????????
                                                // ???????????????????? ?????????????????????? ??????????????????, ???????? ?????????? ???????????????? ????????????.
                                                Button(
                                                        action: {
                                                            isTickerPresented = true
                                                        },
                                                        label: {
                                                            Text(" ")
                                                        }
                                                )
                                                        .buttonStyle(.borderless)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                        )
                                .sheet(isPresented: $isTickerPresented) {
                                    /// The logic of adding a task from the ticker sheet:
                                    /// - As soon as the user pressed "Start", i.e. before the actual addition:
                                    ///    - To make the UI responsive, we immediately start a closing
                                    ///      animation of the timer dialog;
                                    ///    - Without the animation, change the tab to the timer, this is not
                                    ///      noticeable because the activity dialog is still open above it.
                                    /// - After adding an interval, we start closing the dialog of activities,
                                    ///   and immediately get the ticker screen with the selected activity on top.
                                    ///   The time of addition should be enough to avoid simultaneous closing of
                                    ///   the dialogs. But then there is an additional insurance. A small delay
                                    ///   so as not to see twitching of the timer window refresh and an additional
                                    ///   insurance against simultaneous closing of several dialogs.
                                    W_TickerDialog(
                                            activity: activityUI.activity,
                                            task: task,
                                            preAdd: {
                                                W_TabsView.lastInstance?.tabSelection = W_TabsView.TAB_ID_TIMER
                                                isTickerPresented = false
                                                myAsyncAfter(0.05) { /// ?????????? ???? ??????????????????????
                                                    taskSheetDialog.isPresented = false
                                                }
                                            }
                                    )
                                }
                    }
                }
            }
        }
    }
}
