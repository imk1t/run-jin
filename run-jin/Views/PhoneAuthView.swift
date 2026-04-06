import SwiftUI

struct PhoneAuthView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            headerSection

            phoneInputSection

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            sendButton

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "figure.run")
                .font(.system(size: 60))
                .foregroundStyle(.tint)

            Text("ラン陣")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("電話番号でログイン")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var phoneInputSection: some View {
        HStack(spacing: 8) {
            Text("+81")
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 50)

            TextField("090XXXXXXXX", text: $viewModel.phoneNumber)
                .font(.title3)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }

    private var sendButton: some View {
        Button {
            Task {
                await viewModel.sendOTP()
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("認証コードを送信")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isPhoneValid || viewModel.isLoading)
        .padding(.horizontal)
    }
}

#Preview {
    PhoneAuthView(viewModel: AuthViewModel())
}
