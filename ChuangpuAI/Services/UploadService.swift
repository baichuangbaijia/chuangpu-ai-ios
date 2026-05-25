import Foundation
import PhotosUI
import SwiftUI

/// 上传服务 - 处理图片和文件上传
class UploadService {
    static let shared = UploadService()
    private init() {}
    
    private let uploadBaseURL = "https://ai.xianbaba188.cn/upload-api/"
    
    /// 上传图片
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - progress: 进度回调
    /// - Returns: 上传后的URL
    func uploadImage(imageData: Data, progress: ((Double) -> Void)? = nil) async throws -> String {
        return try await upload(fileData: imageData, endpoint: "image", mimeType: "image/jpeg", progress: progress)
    }
    
    /// 上传文件
    /// - Parameters:
    ///   - fileData: 文件数据
    ///   - filename: 文件名
    ///   - mimeType: MIME类型
    ///   - progress: 进度回调
    /// - Returns: 上传后的URL
    func uploadFile(fileData: Data, filename: String, mimeType: String, progress: ((Double) -> Void)? = nil) async throws -> String {
        return try await upload(fileData: fileData, endpoint: "file", mimeType: mimeType, filename: filename, progress: progress)
    }
    
    /// 上传视频
    /// - Parameters:
    ///   - fileData: 视频数据
    ///   - progress: 进度回调
    /// - Returns: 上传后的URL
    func uploadVideo(fileData: Data, progress: ((Double) -> Void)? = nil) async throws -> String {
        return try await upload(fileData: fileData, endpoint: "video", mimeType: "video/mp4", progress: progress)
    }
    
    private func upload(
        fileData: Data,
        endpoint: String,
        mimeType: String,
        filename: String? = nil,
        progress: ((Double) -> Void)? = nil
    ) async throws -> String {
        guard let url = URL(string: uploadBaseURL + endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        if let token = UserDefaults.standard.string(forKey: Constants.tokenKey) {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        var body = Data()
        let name = endpoint
        let displayFilename = filename ?? "\(name).\(mimeType.components(separatedBy: "/").last ?? "bin")"
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(displayFilename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        progress?(0.3)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        progress?(0.9)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError((response as? HTTPURLResponse)?.statusCode ?? 500)
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let code = json["code"] as? Int, code == 0,
              let dataObj = json["data"] as? [String: Any],
              let url = dataObj["url"] as? String else {
            throw APIError.decodingError
        }
        
        progress?(1.0)
        return url
    }
    
    /// 从PHAsset获取图片数据
    func getImageData(from asset: PHAsset) async throws -> (Data, CGSize) {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.version = .original
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, uti, orientation, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let imageData = data else {
                    continuation.resume(throwing: NSError(domain: "UploadService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取图片数据"]))
                    return
                }
                
                let size = CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
                continuation.resume(returning: (imageData, size))
            }
        }
    }
    
    /// 从URL获取文件数据
    func getFileData(from url: URL) async throws -> (Data, String) {
        let (data, _) = try await URLSession.shared.data(from: url)
        let filename = url.lastPathComponent
        return (data, filename)
    }
}
