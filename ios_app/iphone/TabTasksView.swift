import SwiftUI
import shared

struct TabTasksView: View {

    @EnvironmentObject private var diApple: DIApple

    static var lastInstance: TabTasksView? = nil

    @State var activeSection: TabTasksView_Section?

    private let tabWidth: CGFloat = 34
    /// No more fits when the keyboard is open on the SE
    private let tabPadding: CGFloat = 15

    /// Docs in use places
    @State var withListAnimation = true

    @State var dropItems: [DropItem] = []
    @State var focusedDrop: DropItem? = nil
    @State var activeDrag: DragItem? = nil

    init() {
        let today = TaskFolderModel.Companion().getToday()
        _activeSection = State(initialValue: TabTasksView_Section_Folder(folder: today))
    }

    func onDragMove(curDragItem: DragItem, value: DragGesture.Value) {
        let x = value.location.x
        let y = value.location.y

        focusedDrop = dropItems.first { drop in
            if !curDragItem.isDropAllowed(drop) {
                return false
            }
            let s = drop.square
            return x > s.x1 && y > s.y1 && x < s.x2 && y < s.y2
        }
        activeDrag = curDragItem
    }

    func onDragStop() -> DropItem? {
        let curFocusedDrop = focusedDrop
        focusedDrop = nil
        activeDrag = nil
        return curFocusedDrop
    }

    var body: some View {

        ZStack {

            Color(.myBackground)
                    .ignoresSafeArea()

            HStack(spacing: 0) {

                /// Because of upActiveSectionWithAnimation() without Spacer can be twitching
                Spacer(minLength: 0)

                if let section = activeSection as? TabTasksView_Section_Folder {
                    /// OMG! Dirty trick!
                    /// Just TabTaskView_TasksListView(...) doesn't call onAppear() to scroll to the bottom.
                    ForEach(diApple.taskFolders, id: \.id) { folder in
                        if section.folder.id == folder.id {
                            TasksListView(activeFolder: section.folder, tabTasksView: self)
                        }
                    }
                } else if activeSection is TabTasksView_Section_Repeating {
                    RepeatingsListView()
                } else if activeSection is TabTasksView_Section_Calendar {
                    EventsListView()
                }

                VStack {

                    //
                    // Calendar

                    let dropCalendar = DropItem(name: "Calendar", type: DropItem.TYPE.CALENDAR, square: DropItem.Square())

                    let isActiveCalendar = activeSection is TabTasksView_Section_Calendar
                    let calendarFgColor: Color = {
                        if focusedDrop?.type == dropCalendar.type {
                            return .green
                        }
                        if activeDrag?.isDropAllowed(dropCalendar) == true {
                            return .purple
                        }
                        if isActiveCalendar {
                            return .blue
                        }
                        return Color(UIColor(argb: 0xFF5F5F5F))
                    }()

                    Button(
                            action: {
                                upActiveSectionWithAnimation(TabTasksView_Section_Calendar())
                            },
                            label: {
                                GeometryReader { geometry in
                                    let _ = dropCalendar.square.upByRect(rect: geometry.frame(in: CoordinateSpace.global))
                                    Image(systemName: "calendar")
                                            .resizable()
                                            .animation(.spring())
                                            ///
                                            .onAppear {
                                                dropItems.append(dropCalendar)
                                            }
                                            .onDisappear {
                                                if let index = dropItems.firstIndex { $0 === dropCalendar } {
                                                    dropItems.remove(at: index)
                                                }
                                            }
                                            ///
                                            .foregroundColor(calendarFgColor)
                                }
                                        .frame(width: tabWidth - 2.4, height: tabWidth - 2.4)
                            }
                    )
                            .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                                                .fill(Color(.myDayNight(.mySecondaryBackground, .myBackground)))
                                    }
                            )

                    Spacer()
                            .frame(height: tabPadding)


                    //
                    // Repeating

                    let isActiveRepeating = activeSection is TabTasksView_Section_Repeating

                    Button(
                            action: {
                                upActiveSectionWithAnimation(TabTasksView_Section_Repeating())
                            },
                            label: {
                                Image(systemName: "repeat")
                                        .padding(.top, 9)
                                        .padding(.bottom, 9)
                                        .foregroundColor(isActiveRepeating ? .white : .primary)
                                        .opacity(isActiveRepeating ? 1 : 0.7)

                            }
                    )
                            .background(

                                    ZStack {

                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(isActiveRepeating ? .blue : Color(.mySecondaryBackground))

                                        if !isActiveRepeating {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                    .stroke(Color(.systemGray6))
                                        }
                                    }
                                            .frame(width: tabWidth)
                            )


                    //
                    // Folders

                    ForEach(diApple.taskFolders.reversed(), id: \.id) { folder in

                        let isActive = folder.id == (activeSection as? TabTasksView_Section_Folder)?.folder.id

                        Spacer()
                                .frame(height: tabPadding)

                        Button(
                                action: {
                                    upActiveSectionWithAnimation(TabTasksView_Section_Folder(folder: folder))
                                },
                                label: {
                                    let nameN = Array(folder.name)
                                            .map {
                                                String($0)
                                            }
                                            .joined(separator: "\n")

                                    let dropType: DropItem.TYPE = try! {
                                        if folder.isInbox {
                                            return DropItem.TYPE.INBOX
                                        }
                                        if folder.isWeek {
                                            return DropItem.TYPE.WEEK
                                        }
                                        if folder.isToday {
                                            return DropItem.TYPE.TODAY
                                        }
                                        throw MyError("Invalid type drop tasks tab")
                                    }()
                                    let drop = DropItem(name: folder.name, type: dropType, square: DropItem.Square())

                                    let isAllowedForDrop = activeDrag?.isDropAllowed(drop) == true
                                    let bgColor: Color = {
                                        if focusedDrop?.type == drop.type {
                                            return .green
                                        }
                                        if isAllowedForDrop {
                                            return .purple
                                        }
                                        return isActive ? .blue : Color(.mySecondaryBackground)
                                    }()

                                    Text(nameN)
                                            .textCase(.uppercase)
                                            .lineSpacing(0)
                                            .font(.system(size: 14, weight: isActive ? .semibold : .regular, design: .monospaced))
                                            .frame(width: tabWidth)
                                            .padding(.top, 10)
                                            .padding(.bottom, 10)
                                            .foregroundColor(isActive || isAllowedForDrop ? .white : .primary)
                                            .background(
                                                    ZStack {
                                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                .fill(bgColor)
                                                        if !isActive {
                                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                    .stroke(Color(.systemGray6))
                                                        }
                                                    }
                                            )
                                            .background(GeometryReader { geometry -> Color in
                                                drop.square.upByRect(rect: geometry.frame(in: CoordinateSpace.global))
                                                return Color.clear
                                            })
                                            ///
                                            .onAppear {
                                                dropItems.append(drop)
                                            }
                                            .onDisappear {
                                                if let index = dropItems.firstIndex { $0 === drop } {
                                                    dropItems.remove(at: index)
                                                }
                                            }
                                            ///
                                            .animation(.spring())
                                }
                        )
                    }
                }
                        .padding(.trailing, 3)
                        .offset(x: -6)
            }
                    .onAppear {
                        UITableView.appearance().sectionFooterHeight = 0
                        UIScrollView.appearance().keyboardDismissMode = .interactive
                    }
                    .onDisappear {
                        /// On onDisappear(), otherwise on onAppear() twitching (hide old and open new).
                        activeSection = TabTasksView_Section_Folder(folder: TaskFolderModel.Companion().getToday())
                    }
        }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                .onAppear {
                    TabTasksView.lastInstance = self
                }
    }

    private func upActiveSectionWithAnimation(
            _ newSection: TabTasksView_Section
    ) {
        /// Fix issue: on tab changes scroll animation.
        withListAnimation = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { /// 0.1 на глаз
            withListAnimation = true
        }
        if activeSection is TabTasksView_Section_Folder && newSection is TabTasksView_Section_Folder {
            /// It's better without animation, faster.
            activeSection = newSection
        } else {
            withAnimation(Animation.linear(duration: 0.04)) {
                activeSection = nil
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                activeSection = newSection
            }
        }
    }
}

///
/// Drag and Drop

struct DragItem {

    let allowedTypes: [DropItem.TYPE]

    func isDropAllowed(_ drop: DropItem) -> Bool {
        allowedTypes.contains(drop.type)
    }
}

class DropItem: ObservableObject {

    let name: String
    let type: TYPE
    let square: Square

    enum TYPE {
        case INBOX
        case WEEK
        case TODAY
        case CALENDAR
    }

    init(name: String, type: TYPE, square: Square) {
        self.name = name
        self.type = type
        self.square = square
    }

    class Square {

        var x1: CGFloat
        var y1: CGFloat
        var x2: CGFloat
        var y2: CGFloat

        init(x1: CGFloat = 0, y1: CGFloat = 0, x2: CGFloat = 0, y2: CGFloat = 0) {
            self.x1 = x1
            self.y1 = y1
            self.x2 = x2
            self.y2 = y2
        }

        func upByRect(rect: CGRect) {
            x1 = rect.origin.x
            y1 = rect.origin.y
            x2 = rect.origin.x + rect.width
            y2 = rect.origin.y + rect.height
        }
    }
}

//////


//
// TabTasksView_Section

protocol TabTasksView_Section {
}

struct TabTasksView_Section_Folder: TabTasksView_Section {
    let folder: TaskFolderModel
}

struct TabTasksView_Section_Repeating: TabTasksView_Section {
}

struct TabTasksView_Section_Calendar: TabTasksView_Section {
}