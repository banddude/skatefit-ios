import SwiftUI

struct EquipmentOverviewView: View {
    var body: some View {
        VStack(spacing: 30) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "dumbbell")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
                
                Text("Equipment You'll Need")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Most exercises use minimal equipment you can find at home or any gym.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
            }
            .padding(.top, 20)
            
            // Equipment Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 20) {
                EquipmentCard(
                    icon: "circle.dashed",
                    title: "Resistance Bands",
                    description: "Light, medium, and heavy resistance"
                )
                
                EquipmentCard(
                    icon: "dumbbell.fill",
                    title: "Dumbbells",
                    description: "5-20 lbs adjustable weights"
                )
                
                EquipmentCard(
                    icon: "circle.fill",
                    title: "Medicine Ball",
                    description: "6-12 lbs for core work"
                )
                
                EquipmentCard(
                    icon: "rectangle.fill",
                    title: "Exercise Mat",
                    description: "For floor exercises"
                )
                
                EquipmentCard(
                    icon: "square.stack.3d.up",
                    title: "Step/Box",
                    description: "For step-ups and balance"
                )
                
                EquipmentCard(
                    icon: "figure.walk",
                    title: "Body Weight",
                    description: "Many exercises need nothing!"
                )
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Note
            Text("Don't have everything? No problem! Many exercises can be modified or substituted.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

struct EquipmentCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .frame(height: 120)
    }
}

#Preview {
    EquipmentOverviewView()
}