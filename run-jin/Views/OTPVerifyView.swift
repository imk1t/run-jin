import SwiftUI

struct OTPVerifyView: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            headerSection

            otpInputSection

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            verifyButton

            resendSection

            Spacer()
            Spacer()
        }
        .padding()
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            Text("認証コードを入力")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(viewModel.formattedPhone) に送信しました")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var otpInputSection: some View {
        TextField("000000", text: $viewModel.otpCode)
            .font(.system(size: 32, weight: .bold, design: .monospaced))
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 48)
            .onChange(of: viewModel.otpCode) { _, newValue in
                // 数字のみ、6桁まで
                let filtered = String(newValue.filter(\.isNumber).prefix(6))
                if filtered != newValue {
                    viewModel.otpCode = filtered
                }
            }
    }

    private var verifyButton: some View {
        Button {
            Task {
                await viewModel.verifyOTP()
            }
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                Text("認証する")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isOTPValid || viewModel.isLoading)
        .padding(.horizontal)
    }

    private var resendSection: some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    await viewModel.sendOTP()
                }
            } label: {
                Text("コードを再送信")
                    .font(.subheadline)
            }
            .disabled(viewModel.isLoading)

            Button {
                viewModel.goBackToPhoneInput()
            } label: {
                Text("電話番号を変更")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .disabled(viewModel.isLoading)
        }
    }
}

#Preview {
    let vm = AuthViewModel()
    vm.phase = .otpVerify
    vm.phoneNumber = "09012345678"
    return OTPVerifyView(viewModel: vm)
}
