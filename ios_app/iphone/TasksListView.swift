import SwiftUI
import shared

struct TasksListView: View {

    @State private var vm: TasksListVM

    private let activeFolder: TaskFolderModel
    let tabTasksView: TabTasksView

    /// hideKeyboard() is more reliable than false
    @FocusState private var isAddFormFocused: Bool

    private let LIST_BOTTOM_ITEM_ID = "bottom_id"

    @StateObject private var keyboardManager = KeyboardManager()

    init(activeFolder: TaskFolderModel, tabTasksView: TabTasksView) {
        self.tabTasksView = tabTasksView
        self.activeFolder = activeFolder
        _vm = State(initialValue: TasksListVM(folder: activeFolder))
    }

    var body: some View {

        VMView(vm: vm) { state in

            GeometryReader { geometry in

                ScrollViewReader { scrollProxy in

                    ScrollView(.vertical, showsIndicators: false) {

                        VStack(spacing: 0) {

                            Spacer()

                            if let tmrwData = state.tmrwData {
                                let tmrwTasksUI = tmrwData.tasksUI
                                ForEach(tmrwTasksUI, id: \.task.id) { taskUI in
                                    let isFirst = tmrwTasksUI.first == taskUI
                                    let isLast = tmrwTasksUI.last == taskUI
                                    MyListView__ItemView(
                                            isFirst: isFirst,
                                            isLast: isLast,
                                            withTopDivider: !isFirst,
                                            outerPaddingStart: 0,
                                            outerPaddingEnd: 0
                                    ) {
                                        TasksListView__TmrwTaskView(taskUI: taskUI)
                                                .id("tmrw \(taskUI.task.id)")
                                    }
                                }

                                MyDivider()
                                        .padding(.horizontal, 80)
                                        .padding(.top, 20)
                                        .padding(.bottom, state.tasksUI.isEmpty ? 0 : 20)
                            }

                            let tasksUIReversed = state.tasksUI.reversed()
                            VStack(spacing: 0) {
                                ForEach(tasksUIReversed, id: \.task.id) { taskUI in
                                    TasksView__TaskRowView(
                                            taskUI: taskUI,
                                            tasksListView: self,
                                            withDivider: tasksUIReversed.last != taskUI
                                    )
                                            .id(taskUI.task.id)
                                }
                            }
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                            if let tmrwData = state.tmrwData {
                                HStack {
                                    Spacer()
                                    Text(tmrwData.curTimeString)
                                            .font(.system(size: 14, weight: .light))

                                    Spacer()
                                }
                                        .padding(.top, 24)
                            }

                            HStack {

                                ZStack {

                                    TextField__VMState(
                                            text: state.addFormInputTextValue,
                                            placeholder: "Task",
                                            isFocused: $isAddFormFocused,
                                            onValueChanged: { newText in
                                                vm.setAddFormInputTextValue(text: newText)
                                            }
                                    )
                                }
                                        .onTapGesture {
                                            isAddFormFocused = true
                                        }

                                Button(
                                        action: {
                                            /// See onTapGesture / onLongPressGesture
                                        },
                                        label: {
                                            Text("SAVE")
                                                    .padding(.horizontal, 12)
                                                    .font(.system(size: 14, weight: .bold))
                                                    .frame(height: 34)
                                                    .foregroundColor(.white)
                                                    .background(
                                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                    .fill(.blue)
                                                    )
                                                    /// https://stackoverflow.com/a/58643879
                                                    .onTapGesture {
                                                        addTask(toHideKeyboard: true, scrollProxy: scrollProxy)
                                                    }
                                                    .onLongPressGesture(minimumDuration: 0.1) {
                                                        addTask(toHideKeyboard: false, scrollProxy: scrollProxy)
                                                    }
                                        }
                                )
                                        .padding(.trailing, 5)
                                        .buttonStyle(PlainButtonStyle())
                            }
                                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color(.mySecondaryBackground)))
                                    .padding(.top, 20)
                                    .padding(.bottom, 20)

                            HStack {
                            }
                                    .id(LIST_BOTTOM_ITEM_ID)
                        }
                                .frame(minHeight: geometry.size.height)
                    }
                            .animation(tabTasksView.withListAnimation ? Animation.easeOut(duration: 0.25) : nil)
                            .offset(y: keyboardManager.height > 0 && isAddFormFocused ? -(keyboardManager.height - TabsView.tabHeight) : 0)
                            ///
                            .onChange(of: isAddFormFocused) { _ in
                                scrollDown(scrollProxy: scrollProxy, toAnimate: true)
                            }
                            .onAppear {
                                scrollDown(scrollProxy: scrollProxy, toAnimate: false)
                            }
                }
            }
                    .padding(.leading, 16)
                    .padding(.trailing, 20)
        }
    }

    private func scrollDown(
            scrollProxy: ScrollViewProxy,
            toAnimate: Bool
    ) {
        if (toAnimate) {
            withAnimation {
                scrollProxy.scrollTo(LIST_BOTTOM_ITEM_ID, anchor: .bottom)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    scrollProxy.scrollTo(LIST_BOTTOM_ITEM_ID, anchor: .bottom)
                }
            }
        } else {
            scrollProxy.scrollTo(LIST_BOTTOM_ITEM_ID, anchor: .bottom)
        }
    }

    private func addTask(
            toHideKeyboard: Bool,
            scrollProxy: ScrollViewProxy
    ) {
        if vm.isAddFormInputEmpty() {
            if toHideKeyboard {
                hideKeyboard()
            }
            return
        }

        vm.addTask {
            DispatchQueue.main.async {
                if toHideKeyboard {
                    hideKeyboard()
                }
            }
        }

        scrollDown(scrollProxy: scrollProxy, toAnimate: true)
    }
}

struct TasksView__TaskRowView: View {

    private let taskUI: TasksListVM.TaskUI

    let tasksListView: TasksListView
    @State private var dragItem: DragItem

    @State private var isSheetPresented = false

    @State private var isAddCalendarSheetPresented = false
    @State private var isEditTaskPresented = false

    @State private var xSwipeOffset: CGFloat = 0
    @State private var width: CGFloat? = nil

    @State private var itemHeight: CGFloat = 0

    private let withDivider: Bool

    init(taskUI: TasksListVM.TaskUI, tasksListView: TasksListView, withDivider: Bool) {
        self.taskUI = taskUI
        self.tasksListView = tasksListView
        self.withDivider = withDivider

        _dragItem = State(initialValue: DragItem(
                isDropAllowed: { drop in
                    if drop is DropItem__Calendar {
                        return true
                    }
                    if let dropFolder = drop as? DropItem__Folder {
                        return dropFolder.folder.id != taskUI.task.folder_id
                    }
                    fatalError("Unknown tasks list drop type")
                }
        ))
    }

    struct MyButtonStyle: ButtonStyle {
        func makeBody(configuration: Self.Configuration) -> some View {
            configuration.label.background(configuration.isPressed ? Color(.systemGray5) : Color(.mySecondaryBackground))
        }
    }

    var body: some View {

        ZStack(alignment: .bottom) {

            GeometryReader { proxy in
                ZStack {
                }
                        .onAppear {
                            width = proxy.size.width
                        }
                        .onChange(of: proxy.frame(in: .global).minY) { _ in
                            xSwipeOffset = 0
                            tasksListView.tabTasksView.onDragStop()
                        }
            }
                    /// height: 1, or full height items if short
                    .frame(height: 1)
            ///

            if (xSwipeOffset > 0) {
                let editOrMoveTitle = tasksListView.tabTasksView.focusedDrop != nil ? "Move to \(tasksListView.tabTasksView.focusedDrop!.name)" : "Edit"
                HStack {
                    Text(editOrMoveTitle)
                            .foregroundColor(.white)
                            .padding(.leading, 16)
                    Spacer()
                }
                        .frame(maxHeight: itemHeight)
                        .background(tasksListView.tabTasksView.focusedDrop == nil ? .blue : .green)
                        .offset(x: xSwipeOffset > 0 ? 0 : xSwipeOffset)
            }

            if (xSwipeOffset < 0) {

                HStack {

                    Text(taskUI.listText)
                            .padding(.leading, 12)
                            .padding(.trailing, 4)
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .font(.system(size: 13, weight: .light))

                    Spacer()

                    Button("Cancel") {
                        xSwipeOffset = 0
                    }
                            .foregroundColor(.white)
                            .padding(.trailing, 12)

                    Button(
                            action: {
                                taskUI.delete()
                            },
                            label: {
                                Text("Delete")
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 5)
                                        .foregroundColor(.red)
                            }
                    )
                            .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(.white)
                            )
                            .padding(.trailing, 12)
                }
                        .frame(maxHeight: itemHeight)
                        .background(.red)
                        .offset(x: xSwipeOffset < 0 ? 0 : xSwipeOffset)
            }

            //////

            let paddingStart = 16.0

            ZStack {

                Button(
                        action: {
                            hideKeyboard()
                            taskUI.start(
                                    onStarted: {
                                        gotoTimer()
                                    },
                                    needSheet: {
                                        isSheetPresented = true
                                    }
                            )
                        },
                        label: {
                            VStack(spacing: 0) {

                                let vPadding = 8.0

                                if let timeUI = taskUI.textFeatures.timeUI {
                                    HStack {
                                        Text(timeUI.daytimeText + "  " + timeUI.timeLeftText)
                                                .padding(.leading, paddingStart)
                                                .padding(.top, 1)
                                                .padding(.bottom, vPadding)
                                                .font(.system(size: 14, weight: .light))
                                                .foregroundColor(timeUI.color.toColor())
                                                .lineLimit(1)
                                        Spacer()
                                    }
                                }

                                HStack {
                                    /// It can be multiline
                                    Text(taskUI.listText)
                                            .padding(.leading, paddingStart)
                                            .padding(.trailing, 16)
                                            .lineSpacing(4)
                                            .multilineTextAlignment(.leading)
                                            .myMultilineText()

                                    Spacer(minLength: 0)
                                }

                                TriggersView__List(triggers: taskUI.textFeatures.triggers)
                                        .padding(.top, taskUI.textFeatures.triggers.isEmpty ? 0 : vPadding)
                            }
                                    .padding(.vertical, 10)
                        }
                )
                        .offset(x: xSwipeOffset)
                        // .background(Color.white.opacity(0.001)) // Without background DnD does not work. WTF?! Work after highPriorityGesture
                        .highPriorityGesture(gesture)
                        .buttonStyle(MyButtonStyle())
                        .foregroundColor(.primary)
                        .background(GeometryReader { geometry -> Color in
                            /// Or "Modifying state during view update, this will cause undefined behavior."
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                itemHeight = geometry.size.height
                            }
                            return Color.clear
                        })
                        .sheetEnv(isPresented: $isSheetPresented) {
                            TaskSheet(
                                    isPresented: $isSheetPresented,
                                    task: taskUI.task
                            ) {
                                isSheetPresented = false
                                gotoTimer()
                            }
                        }
            }

            if (withDivider) {
                MyDivider(xOffset: paddingStart)
            }
        }
                .background(Color(.mySecondaryBackground))
                .id("\(taskUI.task.id) \(taskUI.task.text)") /// #TruncationDynamic
                .sheetEnv(
                        isPresented: $isAddCalendarSheetPresented,
                        content: {
                            EventFormSheet(
                                    isPresented: $isAddCalendarSheetPresented,
                                    editedEvent: nil,
                                    defText: taskUI.listText,
                                    defDate: Date().startOfDay()
                            ) {
                                taskUI.delete()
                            }
                        }
                )
                .sheetEnv(
                        isPresented: $isEditTaskPresented,
                        content: {
                            TaskFormSheet(
                                    task: taskUI.task,
                                    isPresented: $isEditTaskPresented
                            )
                        }
                )
    }

    var gesture: some Gesture {
        DragGesture(minimumDistance: 15, coordinateSpace: .global)
                .onChanged { value in
                    xSwipeOffset = value.translation.width
                    if xSwipeOffset > 1 {
                        tasksListView.tabTasksView.onDragMove(curDragItem: dragItem, value: value)
                    }
                }
                .onEnded { value in
                    let drop = tasksListView.tabTasksView.onDragStop()
                    if let drop = drop {
                        xSwipeOffset = 0
                        if drop is DropItem__Calendar {
                            isAddCalendarSheetPresented = true
                        } else if let dropFolder = drop as? DropItem__Folder {
                            taskUI.upFolder(newFolder: dropFolder.folder)
                        }
                    } else if value.translation.width < -80 {
                        xSwipeOffset = (width ?? 999) * -1
                    } else if value.translation.width > 60 {
                        xSwipeOffset = 0
                        isEditTaskPresented = true
                    } else {
                        xSwipeOffset = 0
                    }
                }
    }

    private func gotoTimer() {
        TabsView.lastInstance?.tabSelection = TabsView.TAB_ID_TIMER
    }
}

struct TasksView__TaskRowView__ActivityRowView: View {

    var activityUI: TaskSheetVM.ActivityUI
    let historySeconds: [Int]
    let onClickOnTimer: () -> Void
    let onStarted: () -> Void

    var body: some View {

        Button(
                action: {
                    onClickOnTimer()
                },
                label: {

                    ZStack(alignment: .bottom) { // .bottom for divider

                        let emojiHPadding = 8.0
                        let emojiWidth = 30.0
                        let startPadding = emojiWidth + (emojiHPadding * 2)

                        HStack(spacing: 0) {

                            Text(activityUI.activity.emoji)
                                    .frame(width: emojiWidth)
                                    .padding(.horizontal, emojiHPadding)
                                    .font(.system(size: 22))

                            Text(activityUI.listText)
                                    .foregroundColor(.primary)
                                    .truncationMode(.tail)
                                    .lineLimit(1)

                            Spacer(minLength: 0)

                            ForEach(activityUI.timerHints, id: \.seconds) { hintUI in
                                let isHistory = activityUI.historySeconds.contains(hintUI.seconds.toInt().toKotlinInt())
                                Button(
                                        action: {
                                            hintUI.startInterval {
                                                onStarted()
                                            }
                                        },
                                        label: {
                                            Text(hintUI.text)
                                                    .font(.system(size: isHistory ? 13 : 14, weight: isHistory ? .medium : .light))
                                                    .foregroundColor(isHistory ? .white : .blue)
                                                    .padding(.leading, 6)
                                                    .padding(.trailing, isHistory ? 6 : 2)
                                                    .padding(.top, 3)
                                                    .padding(.bottom, 3.5)
                                                    .background(isHistory ? .blue : .clear)
                                                    .clipShape(Capsule())
                                                    .padding(.leading, isHistory ? 4 : 0)
                                        }
                                )
                                        .buttonStyle(.borderless)
                            }
                        }
                                .padding(.trailing, 14)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

                        MyDivider(xOffset: startPadding)
                    }
                            .frame(alignment: .bottom)
                            .padding(.leading, 2)
                }
        )
    }
}

///
/// Custom cell's implementation because the listRowBackground() hide touch effect
///
struct TasksView__TaskRowView__ActivityRowView__ButtonStyle: ButtonStyle {

    static let LIST_ITEM_HEIGHT = 44.0 // Based on @Environment(\.defaultMinListRowHeight)

    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
                .frame(height: TasksView__TaskRowView__ActivityRowView__ButtonStyle.LIST_ITEM_HEIGHT)
                .background(configuration.isPressed ? Color(.systemGray4) : Color(.mySecondaryBackground))
    }
}

private struct TasksListView__TmrwTaskView: View {

    let taskUI: TasksListVM.TmrwTaskUI

    var body: some View {

        let paddingStart = 16.0

        VStack(spacing: 0) {

            let vPadding = 8.0

            if let timeUI = taskUI.textFeatures.timeUI {
                HStack {
                    Text(timeUI.daytimeText)
                            .padding(.leading, paddingStart)
                            .padding(.top, 1)
                            .padding(.bottom, vPadding)
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(timeUI.color.toColor())
                            .lineLimit(1)
                    Spacer()
                }
            }

            HStack {
                /// It can be multiline
                Text(taskUI.listText)
                        .padding(.leading, paddingStart)
                        .padding(.trailing, 16)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                        .myMultilineText()

                Spacer(minLength: 0)
            }

            TriggersView__List(triggers: taskUI.textFeatures.triggers)
                    .padding(.top, taskUI.textFeatures.triggers.isEmpty ? 0 : vPadding)
        }
                .padding(.vertical, 10)
    }
}
