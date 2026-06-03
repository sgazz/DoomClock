import SwiftUI

struct TerminalInputLine<Field: Hashable>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let label: String
    @Binding var text: String
    let field: Field
    var focusedField: FocusState<Field?>.Binding
    let isInteractive: Bool
    let isLastInForm: Bool
    let color: Color
    let onSubmit: () -> Void
    let onNext: () -> Void

    private var isFocused: Bool {
        focusedField.wrappedValue == field
    }

    private var showBlockCursor: Bool {
        isInteractive && isFocused
    }

    private var fieldFont: Font {
        .system(size: 13, weight: .medium, design: .monospaced)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(label)
                .font(fieldFont)
                .foregroundStyle(color.opacity(0.72))

            ZStack(alignment: .leading) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    if isInteractive {
                        Text(text)
                            .font(fieldFont)
                            .foregroundStyle(color.opacity(0.92))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)

                        if showBlockCursor {
                            TerminalBlockCursor(color: color)
                        }
                    } else {
                        Text(text.isEmpty ? "—" : text)
                            .font(fieldFont)
                            .foregroundStyle(color.opacity(0.55))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .allowsHitTesting(false)

                if isInteractive {
                    TextField("", text: $text)
                        .focused(focusedField, equals: field)
                        .font(fieldFont)
                        .foregroundStyle(Color.clear)
                        .tint(.clear)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(isLastInForm ? .continue : .next)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onSubmit {
                            if isLastInForm {
                                onSubmit()
                            } else {
                                onNext()
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isInteractive else { return }
                focusedField.wrappedValue = field
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(color.opacity(isInteractive ? 0.35 : 0.18))
                .frame(height: 1)
        }
    }
}

struct TerminalBlockCursor: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isVisible = true

    let color: Color

    var body: some View {
        Rectangle()
            .fill(color.opacity(isVisible ? 0.95 : 0.2))
            .frame(width: 10, height: 15)
            .shadow(color: color.opacity(0.35), radius: 2)
            .onAppear {
                guard !reduceMotion else {
                    isVisible = true
                    return
                }

                isVisible = true
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                    isVisible = false
                }
            }
    }
}
