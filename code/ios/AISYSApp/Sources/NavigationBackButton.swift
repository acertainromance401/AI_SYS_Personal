import SwiftUI

struct SmallBackButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.caption.bold())
                .frame(width: 24, height: 24)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로 가기")
    }
}

struct SmallBackButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SmallBackButton()
                }
            }
    }
}

extension View {
    func withSmallBackButton() -> some View {
        modifier(SmallBackButtonModifier())
    }
}