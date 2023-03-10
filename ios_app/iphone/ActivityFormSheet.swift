import SwiftUI
import shared

struct ActivityFormSheet: View {

    @State private var vm: ActivityFormSheetVM

    @Binding private var isPresented: Bool
    private let onSave: () -> ()

    @State private var isAddCustomHintPresented = false
    @State private var isEmojiSheetPresented = false

    @State private var sheetHeaderScroll = 0

    init(
            isPresented: Binding<Bool>,
            editedActivity: ActivityModel?,
            onSave: @escaping () -> Void
    ) {
        self.onSave = onSave
        _isPresented = isPresented
        vm = ActivityFormSheetVM(activity: editedActivity)
    }

    var body: some View {

        VMView(vm: vm, stack: .VStack(spacing: 0)) { state in

            SheetHeaderView(
                    onCancel: { isPresented.toggle() },
                    title: state.headerTitle,
                    doneText: state.headerDoneText,
                    isDoneEnabled: state.isHeaderDoneEnabled,
                    scrollToHeader: sheetHeaderScroll
            ) {
                vm.save {
                    isPresented = false
                    onSave()
                }
            }

            ScrollViewWithVListener(showsIndicators: false, vScroll: $sheetHeaderScroll) {

                VStack(spacing: 0) {

                    VStack(spacing: 0) {

                        MyListView__Padding__SectionHeader()

                        MyListView__HeaderView(title: state.inputNameHeader)

                        MyListView__Padding__HeaderSection()

                        MyListView__ItemView(
                                isFirst: true,
                                isLast: true
                        ) {

                            MyListView__ItemView__TextInputView(
                                    text: state.inputNameValue,
                                    placeholder: state.inputNamePlaceholder,
                                    isAutofocus: false,
                                    onValueChanged: { newValue in
                                        vm.setInputNameValue(text: newValue)
                                    }
                            )
                        }

                        TriggersView__Form(
                                triggers: state.textFeatures.triggers,
                                onTriggersChanged: { newTriggers in
                                    vm.setTriggers(newTriggers: newTriggers)
                                },
                                spaceAround: 21,
                                bgColor: .myDayNight(.white, .mySheetFormBg),
                                paddingTop: 18
                        )

                        MyListView__Padding__SectionSection()
                    }

                    MyListView__ItemView(
                            isFirst: true,
                            isLast: false
                    ) {

                        MyListView__ItemView__ButtonView(
                                text: state.emojiTitle,
                                withArrow: true,
                                rightView: AnyView(

                                        HStack(spacing: 0) {

                                            if let selectedEmoji = state.emoji {
                                                Text(selectedEmoji)
                                                        .font(.system(size: 30))
                                                        .padding(.trailing, 8)
                                            } else {
                                                Text(state.emojiNotSelected)
                                                        .foregroundColor(.red)
                                                        .font(.system(size: 15))
                                                        .padding(.trailing, 8)
                                            }
                                        }
                                )
                        ) {
                            isEmojiSheetPresented = true
                        }
                                .sheetEnv(isPresented: $isEmojiSheetPresented) {
                                    SearchEmojiSheet(isPresented: $isEmojiSheetPresented) { emoji in
                                        vm.setEmoji(newEmoji: emoji)
                                    }
                                }
                    }

                    MyListView__ItemView(
                            isFirst: false,
                            isLast: true,
                            withTopDivider: true
                    ) {
                        MyListView__ItemView__SwitchView(
                                text: state.autoFSTitle,
                                isActive: state.isAutoFS
                        ) {
                            vm.toggleAutoFS()
                        }
                    }

                    //////

                    MyListView__Padding__SectionSection()

                    MyListView__HeaderView(title: state.timerHintsHeader)

                    MyListView__Padding__HeaderSection()

                    VStack(spacing: 0) {

                        let hintsTypeName: [(title: String, type: ActivityModel__Data.TimerHintsHINT_TYPE)] = [
                            ("By History", .history),
                            ("Custom", .custom),
                        ]

                        ForEach(hintsTypeName, id: \.type) { pair in

                            let isActive = state.activityData.timer_hints.type == pair.type

                            let isFirst = hintsTypeName.first! == pair

                            MyListView__ItemView(
                                    isFirst: isFirst,
                                    isLast: hintsTypeName.last! == pair,
                                    withTopDivider: !isFirst
                            ) {

                                VStack(spacing: 0) {

                                    MyListView__ItemView__RadioView(
                                            text: pair.title,
                                            isActive: isActive
                                    ) {
                                        withAnimation {
                                            vm.setTimerHintsType(type: pair.type)
                                        }
                                    }

                                    if isActive {

                                        if (pair.type == .custom) {

                                            VStack(alignment: .leading, spacing: 0) {

                                                // Because it can be by mistake not unique I do through count
                                                ForEach(0..<state.timerHintsCustomItems.count, id: \.self) { idx in

                                                    let customItem = state.timerHintsCustomItems[idx]

                                                    HStack {

                                                        Button(
                                                                action: {
                                                                    vm.delCustomTimerHint(seconds: customItem.seconds)
                                                                },
                                                                label: {
                                                                    Image(systemName: "minus.circle.fill")
                                                                            .foregroundColor(.red)
                                                                }
                                                        )

                                                        Text(customItem.text)
                                                    }
                                                            .padding(.bottom, 10)
                                                }

                                                Button(
                                                        action: {
                                                            isAddCustomHintPresented = true
                                                        },
                                                        label: {
                                                            Text("Add")
                                                        }
                                                )
                                            }
                                                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                                    .padding(.leading, MyListView.PADDING_INNER_HORIZONTAL)
                                                    .padding(.bottom, 14)
                                                    .sheetEnv(isPresented: $isAddCustomHintPresented) {
                                                        TimerPickerSheet(
                                                                isPresented: $isAddCustomHintPresented,
                                                                title: "Timer Hint",
                                                                doneText: "Add",
                                                                defMinutes: 30
                                                        ) { seconds in
                                                            vm.addCustomTimerHint(seconds: seconds.toInt32())
                                                        }
                                                                .presentationDetentsMediumIf16()
                                                    }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Spacer()
                            .frame(minHeight: 20)
                }
            }
        }
                .background(Color(.mySheetFormBg))
    }
}
