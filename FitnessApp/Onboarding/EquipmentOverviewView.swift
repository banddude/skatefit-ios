import SwiftUI

struct EquipmentOverviewView: View {
    let equipmentData: InfoSection

    var body: some View {
        OnboardingTemplateView(
            icon: equipmentData.icon,
            title: equipmentData.title,
            description: equipmentData.description,
            cardData: equipmentData.cards,
            proTip: equipmentData.proTip
        )
    }
}
