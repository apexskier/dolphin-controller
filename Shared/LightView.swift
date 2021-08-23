import SwiftUI

struct LightView: View {
    let on: Bool
    
    var body: some View {
        if on {
            return Rectangle()
                .fill(Color(red: 103/256, green: 197/256, blue: 209/256))
                .frame(width: 12, height: 12)
        } else {
            return Rectangle()
                .fill(Color(red: 107/256, green: 111/256, blue: 116/256))
                .frame(width: 12, height: 12)
        }
    }
}
