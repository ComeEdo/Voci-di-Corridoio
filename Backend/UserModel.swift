//
//  UserModel.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 25/03/25.
//

import SwiftData
import SwiftUI
import Combine

protocol UserProtocol: Equatable, Codable, Identifiable, ObservableObject {
    var id: UUID { get }
    var user: User { get }
    var role: Roles { get }
    var profileImage: UIImage? { get }
    var isFetchingImage: Bool { get }
    
    func fetchProfileImage() async throws
}

class AnyUser: ObservableObject {
    @Published private(set) var userViewModel: (any UserProtocol)?
    
    private var cancellable: AnyCancellable?
    
    init<T: UserProtocol>(for userViewModel: T?) {
        self.userViewModel = userViewModel
        cancellable = userViewModel?.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    deinit {
        cancellable?.cancel()
        cancellable = nil
    }
}

@Model
class UserModel: UserProtocol {
    var id: UUID {
        return user.id
    }
    @Attribute(.unique) private(set) var user: User
    private(set) var role: Roles
    @Attribute(.externalStorage) private var profileImageData: Data?
    
    var profileImage: UIImage? {
        get {
            guard let data = profileImageData else { return nil }
            return UIImage(data: data)
        }
        set {
            profileImageData = newValue?.toData()
        }
    }
    
    @Transient private(set) var isFetchingImage: Bool = false
    
    init(user: User, role: Roles) {
        self.user = user
        self.role = role
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        var role: Roles
        if let roleInt = try? container.decode(Int.self, forKey: .role) {
            role = Roles.from(roleInt)
        } else {
            role = try container.decode(Roles.self, forKey: .role)
        }
        self.role = role
        
        switch Roles.isType(role.rawValue) {
        case is Student.Type:
            self.user = try container.decode(Student.self, forKey: .user)
        case is Teacher.Type:
            self.user = try container.decode(Teacher.self, forKey: .user)
        case is Admin.Type:
            self.user = try container.decode(Admin.self, forKey: .user)
        case is Principal.Type:
            self.user = try container.decode(Principal.self, forKey: .user)
        case is Secretariat.Type:
            self.user = try container.decode(Secretariat.self, forKey: .user)
        default:
            self.user = try container.decode(User.self, forKey: .user)
        }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(user, forKey: .user)
    }
    
    static func == (lhs: UserModel, rhs: UserModel) -> Bool {
        return lhs.user == rhs.user && lhs.role == rhs.role
    }
    
    enum CodingKeys: String, CodingKey {
        case role = "roleId"
        case user = "user"
    }
    
    func fetchProfileImage() async throws {
        guard !isFetchingImage else {
            return
        }
        isFetchingImage = true
        defer {
            isFetchingImage = false
        }
        let isUser: Bool = UserManager.shared.isAuthenticated
        guard let url = URL(string: "\(UserManager.shared.URN)\(isUser ? UserManager.APIEndpoints.user : UserManager.APIEndpoints.auth)/\(id)\(UserManager.APIEndpoints.profileImage)") else {
            throw Errors.invalidURL(url: "\(UserManager.shared.URN)\(isUser ? UserManager.APIEndpoints.user : UserManager.APIEndpoints.auth)/\(id)\(UserManager.APIEndpoints.profileImage)")
        }
        guard user.profileImageId != nil else {
            return
        }
        
        if isUser {
            await UserManager.shared.waitUntilAuthLoadingCompletes()
        }
        
        guard let token = (isUser ? UserManager.shared.userToken : UserManager.shared.authToken) else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("image/jpeg", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let image = data.toImage() {
            return self.profileImage = image
        }
        
        func switchStatusCode(in statusCode: Int,for apiResponse: ApiResponse) throws {
            switch statusCode {
            case 400:
                throw Codes.code400(message: apiResponse.message)
            case 401:
                throw AuthError.unauthorized(message: apiResponse.message)
            case 403:
                throw AuthError.forbidden(message: apiResponse.message)
            case 404:
                throw Codes.code404(message: apiResponse.message)
            case 500:
                throw Codes.code500(message: apiResponse.message)
            default:
                throw Errors.unknownError(message: apiResponse.message)
            }
        }
        
        if isUser {
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseUserData<Bool>) = try checkResponse(response: response, data: data)
            let statusCode = httpResponse.statusCode
            
            try switchStatusCode(in: statusCode, for: apiResponse)
        } else {
            let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseAuthData<Bool>) = try checkResponse(response: response, data: data)
            let statusCode = httpResponse.statusCode
            
            try switchStatusCode(in: statusCode, for: apiResponse)
        }
    }
}

class MainUser: UserProtocol, Codable, DefaultPersistenceProtocol {
    static let 🔑: DefaultPersistence.Saves = .mainUser
    var id: UUID {
        return user.id
    }
    let user: User
    let role: Roles
    @Published private(set) var profileImage: UIImage?
    
    var profileImageInfo: (url: URL, exists: Bool) {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let url = directory!.appendingPathComponent("\(id).jpg")
        let exists = FileManager.default.fileExists(atPath: url.path)
        return (url, exists)
    }
    
    @Published private(set) var isFetchingImage: Bool = false
    private(set) var isDelitingImage: Bool = false
    private(set) var isUploadingImage: Bool = false
    var isModifingImage: Bool {
        return  isDelitingImage || isUploadingImage
    }
    
    private var maxImageSize: Int = 10 * 1024 * 1024    // 10 MB
    
    init(user: User, role: Roles) {
        self.user = user
        self.role = role
        loadProfileImage()
    }
    
    static func == (lhs: MainUser, rhs: MainUser) -> Bool {
        return lhs.user == rhs.user && lhs.role == rhs.role
    }
    
    //  MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case role = "roleId"
        case user = "user"
        case profileImageURL = "ProfileImageURL"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let role = try? container.decode(Int.self, forKey: .role) {
            self.role = Roles.from(role)
        } else {
            self.role = try container.decode(Roles.self, forKey: .role)
        }
        
        switch Roles.isType(role.rawValue) {
        case is Student.Type:
            self.user = try container.decode(Student.self, forKey: .user)
        case is Teacher.Type:
            self.user = try container.decode(Teacher.self, forKey: .user)
        case is Admin.Type:
            self.user = try container.decode(Admin.self, forKey: .user)
        case is Principal.Type:
            self.user = try container.decode(Principal.self, forKey: .user)
        case is Secretariat.Type:
            self.user = try container.decode(Secretariat.self, forKey: .user)
        default:
            self.user = try container.decode(User.self, forKey: .user)
        }
        loadProfileImage()
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(role, forKey: .role)
        try container.encode(user, forKey: .user)
    }
    
    //  MARK: - Image Management
    
    func fetchProfileImage() async throws {
        guard !isFetchingImage else {
            return
        }
        await MainActor.run {
            self.isFetchingImage = true
        }
        defer {
            Task { @MainActor in
                self.isFetchingImage = false
            }
        }
        guard let url = URL(string: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.user)/\(id)\(UserManager.APIEndpoints.profileImage)") else {
            throw Errors.invalidURL(url: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.user)/\(id)\(UserManager.APIEndpoints.profileImage)")
        }
        guard user.profileImageId != nil else {
            return await MainActor.run {
                self.profileImage = nil
            }
        }
        
        await UserManager.shared.waitUntilAuthLoadingCompletes()
        
        guard let token = (UserManager.shared.userToken) else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("image/jpeg", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200, let image = data.toImage() {
            await MainActor.run {
                self.profileImage = image
            }
            return writeProfileImage(for: image)
        }
        
        func switchStatusCode(in statusCode: Int,for apiResponse: ApiResponse) throws {
            switch statusCode {
            case 400:
                throw Codes.code400(message: apiResponse.message)
            case 401:
                throw AuthError.unauthorized(message: apiResponse.message)
            case 403:
                throw AuthError.forbidden(message: apiResponse.message)
            case 404:
                throw Codes.code404(message: apiResponse.message)
            case 500:
                throw Codes.code500(message: apiResponse.message)
            default:
                throw Errors.unknownError(message: apiResponse.message)
            }
        }
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseUserData<Bool>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        try switchStatusCode(in: statusCode, for: apiResponse)
    }
    
    private func deleteProfileImage() async throws {
        guard !isDelitingImage else {
            return
        }
        isDelitingImage = true
        defer {
            isDelitingImage = false
        }
        guard let url = URL(string: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.user)\(UserManager.APIEndpoints.profileImage)") else {
            throw Errors.invalidURL(url: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.user)\(UserManager.APIEndpoints.profileImage)")
        }
        guard user.profileImageId != nil else {
            return
        }
        
        await UserManager.shared.waitUntilAuthLoadingCompletes()
        
        guard let token = (UserManager.shared.userToken) else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseUserData<Bool>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            return
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        case 404:
            throw Codes.code404(message: apiResponse.message)
        case 500:
            throw Codes.code500(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
    
    private func uploadProfileImage() async throws {
        guard !isUploadingImage else {
            return
        }
        isUploadingImage = true
        defer {
            isUploadingImage = false
        }
        guard let url = URL(string: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.user)\(UserManager.APIEndpoints.profileImage)") else {
            throw Errors.invalidURL(url: "\(UserManager.shared.URN)\(UserManager.APIEndpoints.user)\(UserManager.APIEndpoints.profileImage)")
        }
        await UserManager.shared.waitUntilAuthLoadingCompletes()
        guard let token = UserManager.shared.userToken else {
            throw AuthError.unauthorized(message: "Token is nil")
        }
        let imageInfo = profileImageInfo
        guard imageInfo.exists else {
            throw TransferError.imageNotFound
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        if let imageJpeg = profileImage?.toData(), imageJpeg.count > maxImageSize, let compressedImageData = compressImageBinarySearch(image: profileImage!) {
            writeProfileImage(from: compressedImageData)
        }
        
        let (data, response) = try await URLSession.shared.upload(for: request, fromFile: imageInfo.url)
        
        let (httpResponse, apiResponse): (HTTPURLResponse, ApiResponseUserData<Bool>) = try checkResponse(response: response, data: data)
        let statusCode = httpResponse.statusCode
        
        switch statusCode {
        case 200:
            print("Response: \(apiResponse.message)")
            return
        case 400:
            throw Codes.code400(message: apiResponse.message)
        case 401:
            throw AuthError.unauthorized(message: apiResponse.message)
        case 403:
            throw AuthError.forbidden(message: apiResponse.message)
        case 413:
            throw Codes.code413(message: apiResponse.message)
        case 500:
            throw Codes.code500(message: apiResponse.message)
        default:
            throw Errors.unknownError(message: apiResponse.message)
        }
    }
    
    func compressImageBinarySearch(image: UIImage) -> Data? {
        guard var compressedData = image.toData() else { return nil }
        
        if compressedData.count <= maxImageSize {
            return compressedData
        }
        
        var lowerBound: CGFloat = 0.0
        var upperBound: CGFloat = 1.0
        var compressionQuality: CGFloat = 1.0
        
        for _ in 0..<6 {
            compressionQuality = (lowerBound + upperBound) / 2
            guard let data = image.jpegData(compressionQuality: compressionQuality) else { return nil }
            compressedData = data
            
            if compressedData.count < maxImageSize {
                lowerBound = compressionQuality
            } else {
                upperBound = compressionQuality
            }
        }
        
        return compressedData
    }
    
    func setImage(for image: UIImage?, onDismiss: () -> Void = {}) {
        guard !isModifingImage else { return }
        defer { onDismiss() }
        switch (image, profileImage) {
        case let (newImage, oldImage) where newImage == oldImage:
            print("⚠️ Image is the same, skipping.")
            break
        case let (newImage?, _):
            profileImage = newImage
            Task {
                writeProfileImage(for: newImage)
                do {
                    try await uploadProfileImage()
                } catch {
                    if let err = mapError(error) {
                        Utility.setupBottom(err)
                    }
                }
            }
        case (nil, _):
            profileImage = nil
            Task {
                deleteFileProfileImage()
                do {
                    try await deleteProfileImage()
                } catch {
                    if let err = mapError(error) {
                        Utility.setupBottom(err)
                    }
                }
            }
        }
    }
    
    private func writeProfileImage(for image: UIImage) {
        do {
            guard let data = image.toData() else {
                throw TransferError.importFailed
            }
            let imageInfo = profileImageInfo
            if imageInfo.exists {
                if imageInfo.url.URLToUIImage()?.pngData() == image.pngData() {
                    return print("⚠️ Image is the same, skipping write.")
                } else {
                    print("⚠️ Image is different, overwriting.")
                    try FileManager.default.removeItem(at: imageInfo.url)
                }
            }
            try data.write(to: imageInfo.url)
            print("Profile image saved.")
        } catch {
            if let err = mapError(error) {
                Utility.setupAlert(err)
            }
        }
    }
    private func writeProfileImage(from data: Data) {
        do {
            let imageInfo = profileImageInfo
            if imageInfo.exists {
                if imageInfo.url.URLToUIImage()?.pngData() == data {
                    return print("⚠️ Image is the same, skipping write.")
                } else {
                    print("⚠️ Image is different, overwriting.")
                    try FileManager.default.removeItem(at: imageInfo.url)
                }
            }
            try data.write(to: imageInfo.url)
            print("Profile image saved.")
        } catch {
            if let err = mapError(error) {
                Utility.setupAlert(err)
            }
        }
    }
    
    private func loadProfileImage() {
        let imageInfo = profileImageInfo
        if imageInfo.exists {
            profileImage = imageInfo.url.URLToUIImage()
        }
    }
    
    func deleteFileProfileImage() {
        let imageInfo = profileImageInfo
        guard imageInfo.exists else {
            return print("⚠️ No file found to delete at: \(imageInfo.url.path)")
        }
        do {
            try FileManager.default.removeItem(at: imageInfo.url)
            print("Profile image deleted.")
        } catch {
            if let err = mapError(error) {
                Utility.setupBottom(err)
            }
        }
    }
}
