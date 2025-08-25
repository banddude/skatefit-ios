import SwiftUI

// Data structure for the cards
struct OnboardingCardData: Identifiable {
    let id = UUID()
    let icon: String?
    let title: String
    let description: String
    let color: Color
    let gesture: String?
}

// Reusable Card View
struct OnboardingCardView: View {
    let data: OnboardingCardData

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                if let icon = data.icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(data.color)
                }
                Text(data.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(data.color)
            }

            Text(data.description)
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(data.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// The main template view
struct OnboardingTemplateView: View {
    let icon: String
    let title: String
    let description: String
    let cardData: [OnboardingCardData]
    let proTip: String?

    var body: some View {
        VStack(spacing: 20) {
            // Header from DifficultyExplanationView
            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 20)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 10)

            // Body from EquipmentOverviewView
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(cardData) { data in
                        OnboardingCardView(data: data)
                    }
                    
                    if let proTip = proTip {
                        HStack {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text(proTip)
                                .font(.callout)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 10)
                    }
                    
                    Spacer(minLength: 80)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}