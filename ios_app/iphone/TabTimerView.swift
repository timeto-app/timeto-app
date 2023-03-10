import SwiftUI
import shared

///
/// Related code

private let emojiHPadding = 8.0 // ------↴
private let emojiWidth = 30.0 // ↴       ↓
private let emojiStartPadding = 30.0 + (8.0 * 2)

//////

struct TabTimerView: View {

    @State private var vm = TabTimerVM()

    @State private var isReadmePresented = false

    @State private var isAddActivityPresented = false
    @State private var isEditActivitiesPresented = false
    @State private var isSummaryPresented = false
    @State private var isHistoryPresented = false

    var body: some View {

        // Without NavigationView the NavigationLink does not work,
        // remember the .navigationBarHidden(true)
        NavigationView {

            // If outside of the NavigationView - deletion swipe does not opened in full size.
            VMView(vm: vm) { state in

                ZStack {

                    // For List another setting background
                    Color(.myBackground).edgesIgnoringSafeArea(.all)

                    VStack(spacing: 0) {

                        //
                        // Progress

                        ZStack(alignment: .top) {

                            ///
                            /// Ordering is important, otherwise Edit would not be clicked.

                            TabTimerView_ProgressView(
                                    lastInterval: state.lastInterval
                            )
                                    .padding(.leading, 16)
                                    .padding(.trailing, 16)
                                    .frame(height: 120)

                            HStack {

                                // todo
                                //                            EditButton()
                                //                                    .padding(.leading, 20)

                                //                            if !isShowReadmeOnMain.toBoolean() {
                                Spacer()
                                //                            }

                                /*
                            if isShowReadmeOnMain.toBoolean() {
                                Spacer()
                                Button("Readme") {
                                    isReadmePresented = true
                                }
                                        .padding(.trailing, 20)
                            }
                             */
                            }
                                    .padding(.top, 6)

                            //////
                        }

                        //
                        // List

                        ScrollView(.vertical, showsIndicators: false) {

                            // Might be useful https://stackoverflow.com/questions/63887188
                            VStack(spacing: 0) {

                                ZStack {
                                }
                                        .frame(height: 20)

                                VStack(spacing: 0) {

                                    let activitiesUI = state.activitiesUI

                                    ForEach(activitiesUI, id: \.activity.id) { activityUI in
                                        MyListView__ItemView(
                                                isFirst: activitiesUI.first == activityUI,
                                                isLast: activitiesUI.last == activityUI,
                                                withTopDivider: activityUI.withTopDivider,
                                                dividerPaddingStart: emojiStartPadding,
                                                outerPaddingStart: 0,
                                                outerPaddingEnd: 0
                                        ) {
                                            TabTimerView_ActivityRowView(
                                                    activityUI: activityUI,
                                                    lastInterval: state.lastInterval
                                            )
                                        }
                                    }
                                }
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                /*
                                    .onDelete { set in
                                        // to show the button
                                    }
                                    .onMove { set, toIdx in
                                        if (set.count != 1) {
                                            fatalError("bad count for moving \(set.count)")
                                        }

                                        var tempList = activities.map {
                                            $0
                                        }

                                        let fromIdx = set.first!
                                        if fromIdx < toIdx {
                                            tempList.insert(tempList[fromIdx], at: toIdx)
                                            tempList.remove(at: fromIdx)
                                        } else {
                                            let removedTask = tempList.remove(at: fromIdx)
                                            tempList.insert(removedTask, at: toIdx)
                                        }

                                        for (tempIndex, tempTask) in tempList.enumerated() {
                                            tempTask.updateSort(tempIndex)
                                        }
                                    }
                                     */

                                HStack(spacing: 20) {

                                    Button(
                                            action: {
                                                isSummaryPresented.toggle()
                                            },
                                            label: {
                                                Text("Chart")
                                                        .padding(.vertical, 10)
                                                        .foregroundColor(.primary)
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                        .background(
                                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                        .fill(Color(.mySecondaryBackground))
                                                        )
                                                        // Exactly here, otherwise re-rendering every second because of
                                                        // TabTimerView_ProgressView. This leads to twitch when scrolling.
                                                        .sheetEnv(isPresented: $isSummaryPresented) {
                                                            VStack {

                                                                ChartView()
                                                                        .padding(.top, 15)

                                                                Button(
                                                                        action: { isSummaryPresented.toggle() },
                                                                        label: { Text("close").fontWeight(.light) }
                                                                )
                                                                        .padding(.bottom, 4)
                                                            }
                                                        }
                                            }
                                    )

                                    Button(
                                            action: {
                                                isHistoryPresented.toggle()
                                            },
                                            label: {
                                                Text("History")
                                                        .padding(.vertical, 10)
                                                        .foregroundColor(.primary)
                                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                        .background(
                                                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                        .fill(Color(.mySecondaryBackground))
                                                        )
                                                        // Exactly here, otherwise re-rendering every second because of
                                                        // TabTimerView_ProgressView. This leads to twitch when scrolling.
                                                        .sheetEnv(isPresented: $isHistoryPresented) {
                                                            ZStack {
                                                                Color(.myBackground).edgesIgnoringSafeArea(.all)
                                                                HistoryView(isHistoryPresented: $isHistoryPresented)
                                                            }
                                                                    // todo
                                                                    .interactiveDismissDisabled()
                                                        }
                                            }
                                    )
                                }
                                        .frame(width: .infinity)
                                        .padding(.top, 16)
                                        .listRowBackground(Color(.clear))

                                VStack {

                                    HStack(spacing: 16) {

                                        Button(
                                                action: {
                                                    isAddActivityPresented.toggle()
                                                },
                                                label: {
                                                    Text("New Activity")
                                                }
                                        )
                                                .foregroundColor(.blue)
                                                // Without it on the text click this button triggers
                                                .buttonStyle(PlainButtonStyle())

                                        Button(
                                                action: {
                                                    isEditActivitiesPresented.toggle()
                                                },
                                                label: {
                                                    Text("Edit")
                                                }
                                        )
                                                .foregroundColor(.blue)
                                                // Without it on the text click this button triggers
                                                .buttonStyle(PlainButtonStyle())

                                        Spacer()
                                    }
                                            .padding(.bottom, 20)

                                    Text("Set a timer for each task to stay focused.")
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.bottom, 8)

                                    Text("No \"stop\" option is the main feature of this app. Once you have completed one activity, you have to set a timer for the next one, even if it's a \"sleeping\" activity.")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.bottom, 8)

                                    // todo
                                    //                                Text("This time-tracking approach provides real 24/7 data on how long everything takes. You can see it on the ")
                                    //                                        + Text("Chart").fontWeight(.bold)
                                    //                                        + Text(".")
                                    Text("This time-tracking approach provides real 24/7 data on how long everything takes. You can see it on the Chart.")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                        .frame(width: .infinity)
                                        .listRowBackground(Color(.clear))
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 15))
                                        .lineSpacing(4)
                                        .myMultilineText()
                                        .padding(.top, 26)

                                ZStack {
                                }
                                        .frame(height: 20)
                            }
                        }
                                .padding(.horizontal, 16)
                    }
                }
                        .sheetEnv(
                                isPresented: $isAddActivityPresented
                        ) {
                            ActivityFormSheet(
                                    isPresented: $isAddActivityPresented,
                                    editedActivity: nil
                            ) {
                            }
                        }
                        .sheetEnv(
                                isPresented: $isEditActivitiesPresented
                        ) {
                            EditActivitiesDialog(
                                    isPresented: $isEditActivitiesPresented
                            )
                        }
                        .sheetEnv(isPresented: $isReadmePresented) {
                            TabReadmeView(isPresented: $isReadmePresented)
                        }
                        .navigationBarHidden(true)
            }
        }
    }
}

struct TabTimerView_ActivityRowView: View {

    var activityUI: TabTimerVM.ActivityUI
    var lastInterval: IntervalModel

    @State private var isSetTimerPresented = false
    @State private var isEditSheetPresented = false

    var body: some View {
        MyListSwipeToActionItem(
                deletionHint: activityUI.deletionHint,
                deletionConfirmationNote: activityUI.deletionConfirmation,
                onEdit: {
                    isEditSheetPresented = true
                },
                onDelete: {
                    activityUI.delete()
                }
        ) {
            AnyView(safeView)
        }
    }

    private var safeView: some View {

        Button(
                action: {
                    isSetTimerPresented.toggle()
                },
                label: {

                    let isActive = activityUI.isActive
                    let endPadding = 12.0

                    VStack(alignment: .leading, spacing: 0) {

                        HStack(spacing: 0) {

                            Text(activityUI.activity.emoji)
                                    .frame(width: emojiWidth)
                                    .padding(.horizontal, emojiHPadding)
                                    .font(.system(size: 22))

                            Text(activityUI.listText)
                                    .foregroundColor(isActive ? .white : Color(.label))
                                    .truncationMode(.tail)
                                    .lineLimit(1)

                            Spacer(minLength: 0)

                            ForEach(
                                    activityUI.timerHints,
                                    id: \.self
                            ) { hintUI in
                                Button(
                                        action: {
                                            hintUI.startInterval {}
                                        },
                                        label: {
                                            Text(hintUI.text)
                                                    .font(.system(size: 14, weight: .light))
                                                    .foregroundColor(isActive ? .white : .blue)
                                                    .padding(.leading, 4)
                                                    .padding(.trailing, 4)
                                        }
                                )
                            }
                        }
                                .padding(.trailing, endPadding - 2)

                        TriggersView__List(
                                triggers: activityUI.triggers,
                                paddingTop: 8.0,
                                paddingBottom: 4.0,
                                contentPaddingStart: emojiStartPadding - 1,
                                contentPaddingEnd: endPadding
                        )

                        if let noteUI = activityUI.noteUI {

                            VStack(alignment: .leading, spacing: 0) {

                                HStack(spacing: 0) {

                                    if let leadingEmoji = noteUI.leadingEmoji {
                                        Text(leadingEmoji)
                                                .foregroundColor(Color(.white))
                                                .font(.system(size: 14, weight: .thin))
                                                .frame(width: emojiWidth)
                                                .padding(.horizontal, emojiHPadding)
                                    }

                                    Text(noteUI.text)
                                            .myMultilineText()
                                            .foregroundColor(Color(.white))
                                            .font(.system(size: 14, weight: .thin))
                                            .padding(.leading, noteUI.leadingEmoji != nil ? 0.0 : emojiStartPadding)

                                    Button(
                                            action: {
                                                IntervalModel.companion.cancelCurrentInterval { _ in
                                                    // todo
                                                }
                                            },
                                            label: {
                                                Text("cancel")
                                                        .font(.system(size: 13, weight: .medium))
                                                        .foregroundColor(.blue)
                                                        .padding(.leading, 7)
                                                        .padding(.trailing, 8)
                                                        .padding(.top, 3)
                                                        .padding(.bottom, 3)
                                                        .background(.white)
                                                        .clipShape(Capsule())
                                                        .padding(.leading, 8)
                                            }
                                    )
                                }
                                        .padding(.top, 6)
                                        .padding(.bottom, 2)
                                        .padding(.trailing, endPadding - 2)

                                TriggersView__List(
                                        triggers: noteUI.triggers,
                                        paddingTop: 6.0,
                                        paddingBottom: 4.0,
                                        contentPaddingStart: emojiStartPadding - 1,
                                        contentPaddingEnd: endPadding
                                )
                            }
                        }
                    }
                            .padding(.vertical, 12)
                            /// #TruncationDynamic + README_APP.md
                            .id("\(activityUI.activity.id) \(lastInterval.note)")
                }
        )
                .sheetEnv(isPresented: $isSetTimerPresented) {
                    ActivityTimerSheet(
                            activity: activityUI.activity,
                            isPresented: $isSetTimerPresented,
                            timerContext: nil,
                            onStart: {
                                isSetTimerPresented.toggle()
                                /// With animation twitching emoji
                            }
                    )
                            .background(Color(.mySecondaryBackground))
                            .presentationDetentsHeightIf16(ActivityTimerSheet.RECOMMENDED_HEIGHT, withDragIndicator: true)
                }
                .sheetEnv(isPresented: $isEditSheetPresented) {
                    ActivityFormSheet(
                            isPresented: $isEditSheetPresented,
                            editedActivity: activityUI.activity
                    ) {
                    }
                }
                .buttonStyle(TabTimerView_ActivityRowView_ButtonStyle(isActive: activityUI.isActive))
    }
}

///
/// Custom cell's implementation because the listRowBackground() hide touch effect
///
/// Dirty magic! While using inside halfSheet the buttons
/// don't work, .buttonStyle(.borderless) on halfSheet helps.
///
struct TabTimerView_ActivityRowView_ButtonStyle: ButtonStyle {

    let isActive: Bool

    func makeBody(configuration: Self.Configuration) -> some View {
        let bgColor = isActive ? Color.blue : Color(.mySecondaryBackground)
        return configuration
                .label
                .background(
                        configuration.isPressed ? Color(.systemGray4) : bgColor
                )
    }
}

///
/// Separate class because of picker that triggers on timer changes.
///
struct TabTimerView_ProgressView: View {

    let lastInterval: IntervalModel

    ///

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var timerHackToReload = UUID()
    @State private var isCountDown = true // Обратный отчет или сколько прошло

    private var timerData: TimerData {
        TimerData(interval: lastInterval, defColor: ColorNative.text)
    }

    var body: some View {

        GeometryReader { geometry in

            let timerColor = timerData.color.toColor()

            ZStack {

                EmptyView().id(timerHackToReload)

                VStack {

                    if let title = timerData.title {
                        Text(title)
                                .foregroundColor(timerColor)
                                .font(.system(size: 20, weight: .bold))
                                .tracking(2)
                    }

                    Spacer()
                }
                        .padding(.top, 6)

                VStack(spacing: 0) {

                    Spacer(minLength: 0)

                    HStack {

                        Spacer(minLength: 0)

                        Button(
                                action: {
                                    IntervalModel.companion.restartActualInterval { _ in
                                        // todo
                                    }
                                },
                                label: {
                                    Image(systemName: "arrow.counterclockwise")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20)
                                            .padding(.bottom, 7)
                                            .foregroundColor(timerColor)
                                            .font(Font.title.weight(.thin))
                                }
                        )

                        Spacer(minLength: 0)

                        Text(isCountDown ? timerData.timer : TimerData.companion.secondsToString(seconds: time().toInt32() - lastInterval.id))
                                .font(.system(size: 53, design: .monospaced))
                                //.font(Font.custom("San Francisco", size: 49).monospacedDigit())
                                .fontWeight(.medium)
                                //.padding(.vertical, -10) /// https://stackoverflow.com/q/61431791
                                .foregroundColor(isCountDown ? timerColor : .purple)
                                .padding(.bottom, 8)

                        Spacer(minLength: 0)

                        Button(
                                action: {
                                    FullScreenUI.shared.open()
                                },
                                label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 20)
                                            .foregroundColor(timerColor)
                                            .rotationEffect(.degrees(-90))
                                            .padding(.bottom, 7)
                                            .font(Font.title.weight(.thin))
                                }
                        )

                        Spacer(minLength: 0)
                    }

                    let fullHeight: Double = 15.0

                    ZStack(alignment: .leading) {

                        let fullWidth: Double = geometry.size.width
                        let borderWidth: Double = 0.5

                        let timerSecondsForUi = time() - lastInterval.id.toInt()

                        let blueRatio: Double = CGFloat(timerSecondsForUi) / CGFloat(lastInterval.deadline.toInt())

                        RoundedRectangle(cornerRadius: fullHeight)
                                .fill(Color(.mySecondaryBackground))
                                .frame(width: fullWidth, height: fullHeight)

                        RoundedRectangle(cornerRadius: fullHeight)
                                .stroke(Color(.tertiaryLabel), lineWidth: borderWidth)
                                .frame(width: fullWidth, height: fullHeight)

                        Rectangle()
                                .frame(width: min(blueRatio * fullWidth, fullWidth), height: fullHeight)
                                .foregroundColor(blueRatio < 1 ? .blue : timerData.color.toColor())
                                .animation(.linear(duration: (time() > lastInterval.id.toInt()) ? 0.99 : 0.2))
                    }
                            .cornerRadius(fullHeight)
                }
            }
                    /// onTapGesture() does not work without contentShape() on
                    /// click on empty area, e.g. on the side of the counter.
                    /// But it is difficult to click on "+".
                    // .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isCountDown.toggle()
                        }
                    }
                    ///
                    .onReceive(timer) { _ in
                        // No animation, otherwise it twitch on iOS 16+
                        timerHackToReload = UUID()
                    }
                    .onChange(of: lastInterval.id) { newValue in
                        isCountDown = true
                    }
        }
    }
}
