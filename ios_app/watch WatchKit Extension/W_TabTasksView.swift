import SwiftUI
import shared

struct W_TabTasksView: View {

    @EnvironmentObject private var diApple: DIApple

    var body: some View {
        List {
            FolderView(title: "Today", tasks: diApple.tasks.filter { $0.isToday })
            FolderView(title: "Week", tasks: diApple.tasks.filter { $0.isWeek })
            FolderView(title: "Inbox", tasks: diApple.tasks.filter { $0.isInbox })
        }
    }

    private struct FolderView: View {

        let title: String
        let tasks: [TaskModel]

        var body: some View {

            Section(title) {
                ForEach(tasks, id: \.id) { task in
                    TaskView(task: task)
                }
            }
        }

        private struct TaskView: View {

            var task: TaskModel
            @State private var isActivitiesPresented = false

            var body: some View {
                AnyView(safeView)
            }

            private var safeView: some View {
                Button(
                        action: {
                            Task {
                                if let (autostartActivity, autostartSeconds) = await autostartData(task: task) {
                                    WatchToIosSync.shared.startTaskWithLocal(
                                            activity: autostartActivity,
                                            deadline: autostartSeconds.toInt32(),
                                            task: task
                                    )
                                    withAnimation {
                                        W_TabsView.lastInstance?.tabSelection = W_TabsView.TAB_ID_TIMER
                                    }
                                } else {
                                    isActivitiesPresented = true
                                }
                            }
                        },
                        label: {
                            Text(task.text.removeTriggerIdsNoEnsure())
                        }
                )
                        .sheet(isPresented: $isActivitiesPresented) {
                            TaskSheetDialog(task: task, isPresented: $isActivitiesPresented)
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
                                                                myAsyncAfter(0.05) { // Меньше 0.2 на железе не работает
                                                                    W_TabsView.lastInstance?.tabSelection = W_TabsView.TAB_ID_TIMER
                                                                }
                                                            },
                                                            label: {
                                                                Text(hintUI.text)
                                                                        .padding(.horizontal, isHistory ? 3 : 0)
                                                                        .font(.system(size: isHistory ? 12 : 13, weight: .medium))
                                                                        .foregroundColor(.white)
                                                                        .background(isHistory ? .blue : .clear)
                                                                        .clipShape(Capsule(style: .continuous)) // .continuous из-за маленького padding
                                                                        .lineLimit(1)
                                                            }
                                                    )
                                                            .buttonStyle(.borderless)
                                                }
                                                // Без этой кнопки при нажатии по пустому месте рядом с последней
                                                // подсказкой срабатывает подсказка, хотя нужно открыать таймер.
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
                                                myAsyncAfter(0.05) { /// Иначе не закрывается
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