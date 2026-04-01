import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            WindowDragRepresentable()
                .frame(height: 32)
            Spacer()
            Text("No project selected")
                .font(.system(size: 13))
                .foregroundStyle(MuxyTheme.textDim)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
