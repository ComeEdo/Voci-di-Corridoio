//
//  ProfileView.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 28/02/25.
//

import SwiftUI
import PhotosUI
import Combine

struct CircularProfileImage: View {
    @ObservedObject var userIdentity: AnyUser
    
    private var frame: CGFloat
    
    init(userIdentity: AnyUser, frame: CGFloat = 100) {
        self.userIdentity = userIdentity
        self.frame = frame
    }
    
    var body: some View {
        ZStack {
            if let image = userIdentity.userViewModel?.profileImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(Circle())
                    .frame(height: frame)
            } else {
                DefaultProfileImage(frame: frame)
            }
            if userIdentity.userViewModel?.isFetchingImage ?? false {
                ProgressView()
            }
        }
    }
}

struct DefaultProfileImage: View {
    private let base: CGFloat
    private var lessFrameFirst: CGFloat {
        base * (3 / 4)
    }
    private var lessFrameSecond: CGFloat {
        base * (17 / 20)
    }
    private var offset: CGFloat {
        base * (1 / 10)
    }
    
    init(frame base: CGFloat = 100) {
        self.base = base
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.gray)
                .frame(width: base, height: base)
            Image(systemName: "person.fill")
                .resizable()
                .frame(width: lessFrameFirst, height: lessFrameFirst)
                .frame(width: lessFrameSecond, height: lessFrameSecond)
                .offset(y: offset)
                .clipShape(Circle())
        }
    }
}

struct ProfileView: View {
    @ObservedObject private var viewedUser: AnyUser
    @State private var userEditing: MainUser?
    
    init(for viewedUser: AnyUser) {
        self.viewedUser = viewedUser
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 20) {
                    CircularProfileImage(userIdentity: viewedUser)
                    VStack(alignment: .leading, spacing: 10) {
                        let name = viewedUser.userViewModel?.user.name ?? "Nome"
                        let surname = viewedUser.userViewModel?.user.surname ?? "Cognome"
                        Text(name + " " + surname)
                        Text(viewedUser.userViewModel?.role.description ?? "Ruolo").font(.system(size: 14, weight: .semibold))
                    }.foregroundColor(.white)
                    Spacer()
                }.padding(.horizontal, 20)
                if let student = viewedUser.userViewModel?.user as? Student {
                    VStack(alignment: .leading) {
                        Text("Classe: \(student.classe.name)")
                        Text("Materia: \(student.studyFieldName)")
                    }
                    .padding()
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                }
                if let mainUser = viewedUser.userViewModel as? MainUser {
                    Button {
                        userEditing = mainUser
                    } label: {
                        Label("edit", systemImage: "pencil").textButtonStyle(true)
                    }.padding()
                    Spacer()
                }
            }.navigationTitle(viewedUser.userViewModel?.user.username ?? "username")
        }
        .sheet(item: $userEditing) { mainUser in
            ProfileEditing(for: mainUser)
                .presentationCornerRadius(60)
                .interactiveDismissDisabled(true)
        }
    }
}

@MainActor
class ProfileImagePickerViewModel: ObservableObject {
    @Published var selectedImage: UIImage?
    @Published var selectedItem: PhotosPickerItem? {
        didSet {
            if let selectedItem {
                Task {
                    do {
                        if let image = try await selectedItem.loadTransferable(type: Data.self)?.toImage() {
                            imageToCrop.send(image)
                            print("Image sent to crop")
                        }
                    } catch {
                        if let err = mapError(error) {
                            Utility.setupAlert(err.notification)
                        }
                    }
                }
            }
        }
    }
    
    let imageToCrop = PassthroughSubject<UIImage, Never>()
    
    init(for image: UIImage? = nil) {
        selectedImage = image
    }
}

struct ProfileEditing: View {
    @Environment(\.dismiss) private var dismiss
    
    enum NavigationEditNode: Hashable {
        case image(UIImage)
    }
    
    @State private var profileEditPath: [NavigationEditNode] = []
    
    private var frame: CGFloat = 200
    
    @StateObject private var imagePickerVM: ProfileImagePickerViewModel
    
    @ObservedObject private var mainUser: MainUser
    
    @State private var showPicker = false
    @State private var showCropViewController = false
    
    init(for mainUser: MainUser) {
        self.mainUser = mainUser
        _imagePickerVM = StateObject(wrappedValue: ProfileImagePickerViewModel(for: mainUser.profileImage))
    }
    
    var body: some View {
        NavigationStack(path: $profileEditPath) {
            ScrollView {
                ZStack {
                    if let image = imagePickerVM.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(Circle())
                            .frame(height: frame)
                    } else {
                        DefaultProfileImage(frame: frame)
                    }
                    if mainUser.isFetchingImage {
                        ProgressView()
                    }
                }
                HStack {
                    Menu {
                        Button {
                            print("camera")
                        } label: {
                            Label("Fotocamera", systemImage: "camera")
                        }
                        Button {
                            showPicker = true
                        } label: {
                            Label("Libreria foto", systemImage: "photo")
                        }
                    } label: {
                        Label("Modifica", systemImage: "pencil")
                            .textButtonStyle(true)
                    }
                    .photosPicker(isPresented: $showPicker, selection: $imagePickerVM.selectedItem, matching: .images, preferredItemEncoding: .compatible, photoLibrary: .shared())
                    Button {
                        imagePickerVM.selectedImage = nil
                    } label: {
                        Label("Elimina immagine", systemImage: "delete.left")
                            .textButtonStyle(true)
                    }
                }
            }
            .navigationTitle(mainUser.user.username)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Anulla").foregroundStyle(.red)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if mainUser.profileImage != imagePickerVM.selectedImage {
                            mainUser.setImage(for: imagePickerVM.selectedImage) {
                                dismiss()
                            }
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text("Salva")
                    }
                }
            }
            .onReceive(imagePickerVM.imageToCrop) { image in
                profileEditPath.append(.image(image))
                imagePickerVM.selectedItem = nil
            }
            .navigationDestination(for: NavigationEditNode.self) { node in
                switch node {
                case .image(let image):
                    CircularImageCropper(image: image) { croppedImage in
                        imagePickerVM.selectedImage = croppedImage
                    }
                }
            }
        }
    }
}

struct CircularImageCropper: View {
    @Environment(\.dismiss) private var dismiss
    
    var image: UIImage
    var onCrop: (UIImage) -> Void
    @State private var croppingClosure: (() -> UIImage)?
        
    
    init(image: UIImage, onCrop: @escaping (UIImage) -> Void) {
        self.image = image
        self.onCrop = onCrop
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            ZStack(alignment: .topLeading) {
                ZoomableImageView(image: image, croppingClosure: $croppingClosure).frame(width: size.width, height: size.width)
                
                Canvas { context, _ in
                    var path = Path()
                    
                    path.addRect(CGRect(origin: .zero, size: size))
                    
                    let holeDiameter = size.width
                    let holeRadius = holeDiameter / 2
                    
                    let center = CGPoint(x: holeRadius, y: holeRadius)
                    let holeRect = CGRect(
                        x: center.x - holeRadius,
                        y: center.y - holeRadius,
                        width: holeDiameter,
                        height: holeDiameter
                    )
                    
                    let hole = Path(ellipseIn: holeRect)
                    path.addPath(hole)
                    
                    context.fill(path, with: .color(Color.black.opacity(0.2)), style: .init(eoFill: true))
                }
                .frame(width: size.width, height: size.width)
                .allowsHitTesting(false)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Ritaglia immagine")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if let croppedImage: UIImage = croppingClosure?() {
                        onCrop(croppedImage)
                    }
                    dismiss()
                } label: {
                    Group {
                        Text("Ritaglia")
                        Image(systemName: "crop")
                    }
                }
            }
        }
    }
}

struct ZoomableImageView: UIViewRepresentable {
    var image: UIImage
    @Binding var croppingClosure: (() -> UIImage)?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> ZoomableImageScrollView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        
        let scrollView = ZoomableImageScrollView(imageView: imageView)
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 20
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        DispatchQueue.main.async {
            self.croppingClosure = { scrollView.cropImage() }
        }
        
        return scrollView
    }
    
    func updateUIView(_ uiView: ZoomableImageScrollView, context: Context) {
        // nothing needed here — layout will be triggered automatically
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            (scrollView as? ZoomableImageScrollView)?.imageView
        }
    }
    
    // MARK: - Custom ScrollView to handle layout timing
    class ZoomableImageScrollView: UIScrollView {
        private(set) var imageView: UIImageView
        
        init(imageView: UIImageView) {
            self.imageView = imageView
            super.init(frame: .zero)
            addSubview(imageView)
            
            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
            doubleTap.numberOfTapsRequired = 2
            addGestureRecognizer(doubleTap)
        }
        
        // MARK: - Cropping Function
        func cropImage() -> UIImage {
            guard let originalImage = imageView.image else {
                print("Error: No image found in imageView")
                return UIImage()
            }
            
            let normalizedImage = originalImage.normalizedImage()
            
            guard imageView.frame.size.width > 0, imageView.frame.size.height > 0 else {
                print("Error: Invalid imageView frame")
                return UIImage()
            }
            
            let scaleFactorX = normalizedImage.size.width / imageView.frame.size.width
            let scaleFactorY = normalizedImage.size.height / imageView.frame.size.height
            
            
            let adjustedOffsetX = self.contentOffset.x + self.contentInset.left
            let adjustedOffsetY = self.contentOffset.y + self.contentInset.top
            
            var imageCropRect = CGRect(
                x: adjustedOffsetX * scaleFactorX,
                y: adjustedOffsetY * scaleFactorY,
                width: self.bounds.size.width * scaleFactorX,
                height: self.bounds.size.height * scaleFactorY
            )
            
            let imageBounds = CGRect(origin: .zero, size: normalizedImage.size)
            imageCropRect = imageCropRect.intersection(imageBounds)
            
            guard imageCropRect.width > 0, imageCropRect.height > 0,
                  let cgImage = normalizedImage.cgImage?.cropping(to: imageCropRect) else {
                print("Error: Failed to crop the image")
                return UIImage()
            }
            
            return UIImage(cgImage: cgImage, scale: normalizedImage.scale, orientation: normalizedImage.imageOrientation)
        }

        
        @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            let zoomStep = maximumZoomScale / 5
            var nextZoom = zoomScale + zoomStep
            
            if nextZoom > maximumZoomScale {
                nextZoom = minimumZoomScale
            }
            
            let pointInView = gesture.location(in: imageView)
            let scrollViewSize = bounds.size
            
            let width = scrollViewSize.width / nextZoom
            let height = scrollViewSize.height / nextZoom
            let originX = pointInView.x - (width / 2)
            let originY = pointInView.y - (height / 2)
            
            let zoomRect = CGRect(x: originX, y: originY, width: width, height: height)
            zoom(to: zoomRect, animated: true)
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            if zoomScale == minimumZoomScale, let image = imageView.image {
                let scrollViewSize = bounds.size
                let imageSize = image.size
                let imageRatio = imageSize.width / imageSize.height
                let scrollRatio = scrollViewSize.width / scrollViewSize.height
                
                let newSize: CGSize = if imageRatio < scrollRatio {
                    CGSize(width: scrollViewSize.width, height: scrollViewSize.width / imageRatio)
                } else {
                    CGSize(width: scrollViewSize.height * imageRatio, height: scrollViewSize.height)
                }
                
                imageView.frame = CGRect(origin: .zero, size: newSize)
                contentSize = newSize
            }
            
            centerImage()
        }
        
        private func centerImage() {
            let scrollViewSize = bounds.size
            let imageViewSize = imageView.frame.size
            
            let horizontalInset = max(0, (scrollViewSize.width - imageViewSize.width) / 2)
            let verticalInset = max(0, (scrollViewSize.height - imageViewSize.height) / 2)
            
            contentInset = UIEdgeInsets(
                top: verticalInset,
                left: horizontalInset,
                bottom: verticalInset,
                right: horizontalInset
            )
        }
    }
}

extension UIImage {
    func normalizedImage() -> UIImage {
        if self.imageOrientation == .up {
            return self
        }

        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }

        self.draw(in: CGRect(origin: .zero, size: self.size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
}


#Preview("Profile Preview") {
    @Previewable @StateObject var userManager = UserManager.shared
    @Previewable @StateObject var notificationManager = NotificationManager.shared
    @Previewable @StateObject var keyboardManager = KeyboardManager.shared
    
        ProfileView(for: AnyUser(for: userManager.mainUser))
        .environmentObject(notificationManager)
        .addAlerts(notificationManager)
        .addBottomNotifications(notificationManager)
        .foregroundStyle(Color.accentColor)
        .environmentObject(userManager)
        .environmentObject(keyboardManager)
}

#Preview("Edit Profile Preview") {
    @Previewable @StateObject var userManager = UserManager.shared
    @Previewable @StateObject var notificationManager = NotificationManager.shared
    @Previewable @StateObject var keyboardManager = KeyboardManager.shared
    
    if let user = userManager.mainUser {
        ProfileEditing(for: user)
            .environmentObject(notificationManager)
            .addAlerts(notificationManager)
            .addBottomNotifications(notificationManager)
            .foregroundStyle(Color.accentColor)
            .environmentObject(userManager)
            .environmentObject(keyboardManager)
    }
}

#Preview("Image Cropper Preview") {
    @Previewable @StateObject var userManager = UserManager.shared
    @Previewable @StateObject var notificationManager = NotificationManager.shared
    @Previewable @StateObject var keyboardManager = KeyboardManager.shared
    
    if let image = userManager.mainUser?.profileImage {
        CircularImageCropper(image: image) { croppedImage in }
        .environmentObject(notificationManager)
        .addAlerts(notificationManager)
        .addBottomNotifications(notificationManager)
        .foregroundStyle(Color.accentColor)
        .environmentObject(userManager)
        .environmentObject(keyboardManager)
    }
}
