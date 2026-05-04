import SwiftUI

struct TerminalDateTimePicker: View {
    @Binding var selectedDate: Date
    let mode: DoomMode

    var body: some View {
        VStack(spacing: 10) {
            header
            previewCard
            dateSection
        }
    }

    private var header: some View {
        VStack(spacing: 3) {
            Text("SET DOOMSDAY")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.primaryColor)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text("Choose fictional target date & time")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.68))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.76)
        }
    }

    private var previewCard: some View {
        VStack(spacing: 4) {
            Text("TARGET LOCKED ON")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.62))
                .lineLimit(1)

            VStack(spacing: 0) {
                Text(formattedTargetDayMonth(selectedDate))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Text(formattedTargetYear(selectedDate))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(mode.accentColor.opacity(0.9))
                    .lineLimit(1)
            }

            Text(formattedTargetTime(selectedDate))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(mode.accentColor.opacity(0.92))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.black.opacity(0.24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(mode.primaryColor.opacity(0.35), lineWidth: 1)
        )
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("DATE & TIME")
                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                .foregroundStyle(mode.primaryColor.opacity(0.72))
                .padding(.leading, 3)

            DatePicker(
                "Doomsday",
                selection: $selectedDate,
                in: Date()...,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .tint(mode.primaryColor)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.vertical, 5)
            .padding(.horizontal, 6)
            .background(pickerBackground)
            .opacity(0.94)

            helperText
        }
    }

    private var helperText: some View {
        Text("Fictional countdown only.")
            .font(.system(size: 8, weight: .medium, design: .monospaced))
            .foregroundStyle(mode.primaryColor.opacity(0.5))
            .multilineTextAlignment(.center)
            .lineLimit(2)
    }

    private var pickerBackground: some View {
        RoundedRectangle(cornerRadius: 7, style: .continuous)
            .fill(mode.primaryColor.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(mode.primaryColor.opacity(0.5), lineWidth: 1)
            )
    }

    private func formattedTargetDayMonth(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.day, .month, .year], from: date)
        let day = components.day ?? 1
        let month = monthSymbols[max(min((components.month ?? 1) - 1, 11), 0)]
        return String(format: "%02d %@", day, month)
    }

    private func formattedTargetYear(_ date: Date) -> String {
        let year = Calendar.current.component(.year, from: date)
        return String(format: "%04d", year)
    }

    private func formattedTargetTime(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", components.hour ?? 0, components.minute ?? 0)
    }

    private var monthSymbols: [String] {
        ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    }
}
