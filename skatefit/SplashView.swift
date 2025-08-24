import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // You can customize the background color here
            Color.blue.ignoresSafeArea()
            
            VStack {
                // Replace with your app logo or image if available
                Image(systemName: "figure.skating")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.white)
                
                Text("SkateFit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
} 