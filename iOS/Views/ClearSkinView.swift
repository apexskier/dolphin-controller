import SwiftUI

struct ClearSkinView: View {
    @State var orientation: UIInterfaceOrientation = .unknown

    var image: UIImage {
        let image = UIImage(named: "iPhoneTeardown")!
        let newOrientation: UIImage.Orientation
        switch orientation {
        case .landscapeRight: newOrientation = .left
        case .landscapeLeft: newOrientation = .right
        case .portraitUpsideDown: newOrientation = .down
        default:
            return image
        }
//        let image = UIImage(named: "ControllerBoard")!
//        let newOrientation: UIImage.Orientation
//        switch orientation {
//        case .landscapeLeft: newOrientation = .down
//        case .portrait: newOrientation = .right
//        case .portraitUpsideDown: newOrientation = .left
//        default:
//            return image
//        }
        return UIImage(
            cgImage: image.cgImage!,
            scale: image.scale,
            orientation: newOrientation
        )
    }

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didChangeStatusBarFrameNotification)) { _ in
                orientation = UIApplication.shared.statusBarOrientation
            }
            .onAppear {
                orientation = UIApplication.shared.statusBarOrientation
            }
            .opacity(0.6)
            .blur(radius: 4)
    }
}

#Preview {
    ClearSkinView()
}
