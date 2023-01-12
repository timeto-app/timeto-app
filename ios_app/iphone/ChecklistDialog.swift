import SwiftUI
import shared

struct ChecklistDialog: View {

    @EnvironmentObject private var diApple: DIApple

    @Binding private var isPresented: Bool
    private var checklist: ChecklistModel

    @State private var isAddItemPresented = false

    init(
            isPresented: Binding<Bool>,
            checklist: ChecklistModel
    ) {
        self._isPresented = isPresented
        self.checklist = checklist
    }

    var body: some View {

        ZStack(alignment: .top) {

            let items = diApple.checklistItems.filter { $0.list_id == checklist.id }

            ScrollView(showsIndicators: false) {

                Text(checklist.name)
                        .font(.system(size: 28, weight: .bold))
                        .padding(.top, 70)
                        .padding(.bottom, 15)

                MyListView__SectionView {
                    ForEach(items, id: \.id) { item in
                        ChecklistView__ItemView(item: item, withDivider: items.first != item)
                    }
                }
            }

            HStack {

                Button(
                        action: {
                            isPresented = false
                        },
                        label: { Text("Back") }
                )
                        .foregroundColor(.blue)
                        .padding(.leading, 25)

                Spacer()

                // @formatter:off
                let isCheckedExists = !items.filter { item in item.isChecked() }.isEmpty
                // @formatter:on
                if isCheckedExists {
                    Button(
                            action: {
                                items.forEach { item in
                                    if item.isChecked() {
                                        item.toggle { _ in
                                            // todo
                                        }
                                    }
                                }
                            },
                            label: { Text("Uncheck") }
                    )
                            .foregroundColor(.blue)
                            .padding(.trailing, 15)
                }

                Button(
                        action: {
                            isAddItemPresented = true
                        },
                        label: {
                            Image(systemName: "plus")
                                    .foregroundColor(.blue)
                                    .padding(.trailing, 30)
                        }
                )
            }
                    .padding(.top, 20)
        }
                .background(Color(.mySheetFormBg))
                .sheetEnv(isPresented: $isAddItemPresented) {
                    ChecklistItemFormSheet(isPresented: $isAddItemPresented, checklist: checklist, checklistItem: nil)
                }
    }
}

struct ChecklistView__ItemView: View {

    let item: ChecklistItemModel
    let withDivider: Bool

    @State private var isEditPresented = false

    var body: some View {
        MyListSwipeToActionItem(
                withTopDivider: withDivider,
                deletionHint: item.text,
                deletionConfirmationNote: nil,
                onEdit: {
                    isEditPresented = true
                },
                onDelete: {
                    withAnimation {
                        item.delete { _ in
                            // todo
                        }
                    }
                }
        ) {
            Button(
                    action: {
                        item.toggle { _ in
                            // todo report
                        }
                    },
                    label: {
                        HStack {
                            Text(item.text)
                            Spacer()
                            if item.isChecked() {
                                Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .offset(x: 4)
                            }
                        }
                    }
            )
                    .foregroundColor(.primary)
                    .padding(.horizontal, DEF_LIST_H_PADDING)
                    .padding(.vertical, DEF_LIST_V_PADDING)
        }
                .sheetEnv(isPresented: $isEditPresented) {
                    ChecklistItemFormSheet(
                            isPresented: $isEditPresented,
                            checklist: DI.checklists.filter { $0.id == item.list_id }.first!,
                            checklistItem: item
                    )
                }
    }
}