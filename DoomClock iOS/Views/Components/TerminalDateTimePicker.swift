import SwiftUI

enum SelectionStep {
    case date
    case time
}

struct TerminalDateTimePicker: View {
    @Binding var selectedDate: Date
    @Binding var selectedHour: Int
    @Binding var selectedMinute: Int
    let step: SelectionStep
    let mode: DoomMode

    var body: some View {
        VStack(spacing: 12) {
            switch step {
            case .date:
                datePicker
            case .time:
                timePickers
            }
        }
    }

    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text("CHOOSE DATE")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor)

                Text("DAY / MONTH / YEAR")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundStyle(mode.primaryColor.opacity(0.56))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.22))
                    .allowsHitTesting(false)

                DatePicker(
                    "",
                    selection: dateOnlyBinding,
                    in: Calendar.current.startOfDay(for: Date())...,
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .frame(height: 82)
                .clipped()
            }
            .frame(height: 86)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(mode.primaryColor.opacity(0.48), lineWidth: 1)
                    .allowsHitTesting(false)
            )
            .overlay(
                Rectangle()
                    .stroke(mode.primaryColor.opacity(0.18), lineWidth: 1)
                    .frame(height: 24)
                    .allowsHitTesting(false)
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.black.opacity(0.16))
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(mode.primaryColor.opacity(0.34), lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    private var timePickers: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HOUR / MIN")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.primaryColor)

            VStack(spacing: 6) {
                HStack(spacing: 18) {
                    Text("HOUR")
                    Text("MIN")
                }
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.72))

                HStack(spacing: 8) {
                    Picker("Hour", selection: $selectedHour) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text(String(format: "%02d", hour))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)

                    Picker("Minute", selection: $selectedMinute) {
                        ForEach(0..<60, id: \.self) { minute in
                            Text(String(format: "%02d", minute))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .monospacedDigit()
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                }
                .frame(height: 78)
            }
            .frame(height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.22))
                    .allowsHitTesting(false)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(mode.primaryColor.opacity(0.48), lineWidth: 1)
                    .allowsHitTesting(false)
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.black.opacity(0.16))
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(mode.primaryColor.opacity(0.34), lineWidth: 1)
                .allowsHitTesting(false)
        )
    }

    private var dateOnlyBinding: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { selectedDate = Calendar.current.startOfDay(for: $0) }
        )
    }
}
