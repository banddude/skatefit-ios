import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Black background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Custom skater icon
                Image("skater_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                
                Text("SkateFit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
} 