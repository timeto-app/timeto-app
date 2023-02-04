import SwiftUI

struct TextField__VMState: View {

    /// It's not VMState-like, but it's useful for UI logic.
    @FocusState.Binding private var isFocused: Bool

    /// TRICK
    /// Otherwise on init() with new text @State text would not updated.
    /// It is needed for view model if input hints exists.
    @State private var text: String
    private let stateText: String

    private let placeholder: String
    private let onValueChanged: (String) -> Void

    init(
            text: String,
            placeholder: String,
            isFocused: FocusState<Bool>.Binding,
            onValueChanged: @escaping (String) -> Void
    ) {
        _isFocused = isFocused
        _text = State(initialValue: text)
        stateText = text
        self.placeholder = placeholder
        self.onValueChanged = onValueChanged
    }

    var body: some View {

        ZStack(alignment: .trailing) {

            ZStack {
                if #available(iOS 16.0, *) {
                    TextField(
                            text: $text,
                            prompt: Text(placeholder),
                            axis: .vertical
                    ) {
                        // todo what is it?
                    }
                            .padding(.vertical, 8)
                } else {
                    // One line ;(
                    TextField(text: $text, prompt: Text(placeholder)) {}
                }
            }
                    ///
                    .onChange(of: text) { newValue in
                        onValueChanged(newValue)
                    }
                    .onChange(of: stateText) { newValue in
                        text = newValue
                    }
                    ///
                    .focused($isFocused)
                    .textFieldStyle(.plain)
                    .frame(minHeight: MyListView.ITEM_MIN_HEIGHT)
                    .padding(.leading, MyListView.PADDING_SECTION_ITEM_INNER_HORIZONTAL)
                    .padding(.trailing, MyListView.PADDING_SECTION_ITEM_INNER_HORIZONTAL + 16) // for clear button

            TextFieldClearButtonView(
                    text: $text,
                    trailingPadding: 8
            ) {
                isFocused = true
            }
        }
                .onTapGesture {
                    isFocused = true
                }
    }
}