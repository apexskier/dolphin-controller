import SwiftUI

struct LightView: View {
    let assigned: Bool
    let available: Bool?
    
    var body: some View {
        var color = GameCubeColors.lightGray.opacity(0.5)
        var icon = "circle.dashed"
        if assigned {
            icon = "circle.fill" // iOS 15 "circle.inset.filled"
            color = Color(red: 163/255, green: 252/255, blue: 255/255)
        } else if available == true {
            icon = "circle"
            color = GameCubeColors.lightGray
        } else if available == false {
            icon = "slash.circle" // iOS 15 "circle.slash"
            color = GameCubeColors.lightGray
        }
        let light = Image(systemName: icon)
            .resizable()
            .foregroundColor(color)
            .frame(width: 18, height: 18)
        return light
    }
}
