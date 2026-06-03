import SwiftUI

struct TerminalLineView: View {
    let text: String
    let color: Color

    var body: some View {
        Group {
            if let status = StatusLine.parse(text) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(status.prefix)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(status.marker)
                        .foregroundStyle(status.marker == "[ FAIL ]" ? color.opacity(0.62) : color.opacity(0.88))
                        .layoutPriority(1)
                }
            } else {
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.system(size: 13, weight: .medium, design: .monospaced))
        .foregroundStyle(color.opacity(text == ">" ? 0.35 : 0.88))
        .shadow(color: color.opacity(0.28), radius: 1.5)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private struct StatusLine {
        let prefix: String
        let marker: String

        static func parse(_ text: String) -> StatusLine? {
            let markers = ["[ OK ]", "[ FAIL ]"]
            guard let marker = markers.first(where: { text.contains($0) }),
                  let range = text.range(of: marker) else { return nil }
            let prefix = String(text[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            return StatusLine(prefix: prefix.isEmpty ? text : prefix + " ", marker: marker)
        }
    }
}
