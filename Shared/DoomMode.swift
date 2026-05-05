import SwiftUI

enum DoomMode: String, CaseIterable, Identifiable {
    case calm
    case suspicious
    case critical
    case armageddon

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calm:
            "CALM"
        case .suspicious:
            "SUSPICIOUS"
        case .critical:
            "CRITICAL"
        case .armageddon:
            "ARMAGEDDON"
        }
    }

    var threatDisplayTitle: String {
        switch self {
        case .calm:
            "TEA IS WARM"
        case .suspicious:
            "TEA IS COOLING"
        case .critical:
            "TEA IS COLD"
        case .armageddon:
            "NO MORE TEAPOT"
        }
    }

    var threatDetailBody: String {
        switch self {
        case .calm:
            """
            Everything is fine.

            The birds are singing,
            the kettle has just boiled,

            and the universe is
            expanding at a perfectly
            acceptable rate.

            Enjoy it.

            These moments are
            statistically rare.
            """
        case .suspicious:
            """
            Something is
            slightly off.

            Hard to say what,
            exactly.

            The tea is still
            drinkable,

            but you’re aware
            of it in a way
            you weren’t before.

            The universe has
            noticed you noticing.
            """
        case .critical:
            """
            This is not great.

            The tea is cold,
            the biscuits have
            gone soft,

            and whatever was
            supposed to go right

            has gone notably,
            specifically wrong.

            You should probably
            do something.

            You won’t,
            but you should.
            """
        case .armageddon:
            """
            Well.

            Here we are.

            In the grand tapestry
            of cosmic events,

            the disappearance
            of the teapot

            ranks surprisingly high.

            Not because it
            changes anything,

            but because it means
            no one thought
            to save it.

            And that says
            everything.
            """
        }
    }

    var statusText: String {
        switch self {
        case .calm:
            "SYSTEM STABLE"
        case .suspicious:
            "ANOMALY WATCH"
        case .critical:
            "BUNKER ALERT"
        case .armageddon:
            "FINAL PROTOCOL"
        }
    }

    var primaryColor: Color {
        switch self {
        case .calm:
            Color(red: 0.47, green: 0.86, blue: 0.55)
        case .suspicious:
            Color(red: 0.78, green: 0.86, blue: 0.28)
        case .critical:
            Color(red: 1.0, green: 0.55, blue: 0.22)
        case .armageddon:
            Color(red: 0.95, green: 0.18, blue: 0.16)
        }
    }

    var accentColor: Color {
        switch self {
        case .calm:
            Color(red: 0.62, green: 0.98, blue: 0.68)
        case .suspicious:
            Color(red: 0.96, green: 0.94, blue: 0.36)
        case .critical:
            Color(red: 1.0, green: 0.72, blue: 0.38)
        case .armageddon:
            Color(red: 1.0, green: 0.42, blue: 0.36)
        }
    }
}
