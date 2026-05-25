import Foundation
import SwiftUI

/// 认证管理器 - 处理用户登录状态和Token管理
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?
    @Published var isVip: Bool = false
    @Published var credits: Int = 0
    
    private let api = APIService.shared
    
    private init() {
        checkLoginStatus()
    }
    
    /// 检查登录状态
    func checkLoginStatus() {
        if let token = UserDefaults.standard.string(forKey: Constants.tokenKey), !token.isEmpty {
            isLoggedIn = true
            loadUserInfo()
        } else {
            isLoggedIn = false
        }
        
        isVip = UserDefaults.standard.bool(forKey: Constants.isVipKey)
    }
    
    /// 加载用户信息
    func loadUserInfo() {
        Task {
            do {
                let result = try await api.getMe()
                if result.code == 0, let user = result.data {
                    await MainActor.run {
                        self.currentUser = user
                        self.isVip = user.vipLevel != "free" && user.vipLevel != nil
                        UserDefaults.standard.set(self.isVip, forKey: Constants.isVipKey)
                    }
                }
                
                let creditResult = try await api.getCreditBalance()
                if creditResult.code == 0, let creditData = creditResult.data {
                    await MainActor.run {
                        self.credits = creditData.credits
                    }
                }
            } catch {
                print("加载用户信息失败: \(error)")
            }
        }
    }
    
    /// 登录
    func login(phone: String, code: String? = nil, password: String? = nil, loginType: String = "sms") async throws -> Bool {
        let result = try await api.login(phone: phone, code: code, password: password, loginType: loginType)
        
        if result.code == 0, let data = result.data {
            UserDefaults.standard.set(data.token, forKey: Constants.tokenKey)
            UserDefaults.standard.set(data.userId, forKey: Constants.userIdKey)
            
            if let user = data.user {
                UserDefaults.standard.set(user.id, forKey: Constants.userIdKey)
                UserDefaults.standard.set(user.name, forKey: Constants.userNameKey)
                UserDefaults.standard.set(user.nickname, forKey: Constants.userNicknameKey)
                self.currentUser = user
                self.isVip = user.vipLevel != "free" && user.vipLevel != nil
            } else {
                self.isVip = false
            }
            
            UserDefaults.standard.set(self.isVip, forKey: Constants.isVipKey)
            
            await MainActor.run {
                self.isLoggedIn = true
            }
            
            return true
        } else {
            throw NSError(domain: "", code: result.code, userInfo: [NSLocalizedDescriptionKey: result.message ?? "登录失败"])
        }
    }
    
    /// 注册
    func register(phone: String, password: String, code: String) async throws -> Bool {
        let result = try await api.register(phone: phone, password: password, code: code)
        
        if result.code == 0, let data = result.data {
            UserDefaults.standard.set(data.token, forKey: Constants.tokenKey)
            UserDefaults.standard.set(data.userId, forKey: Constants.userIdKey)
            
            if let user = data.user {
                UserDefaults.standard.set(user.id, forKey: Constants.userIdKey)
                UserDefaults.standard.set(user.name, forKey: Constants.userNameKey)
                UserDefaults.standard.set(user.nickname, forKey: Constants.userNicknameKey)
                self.currentUser = user
            }
            
            await MainActor.run {
                self.isLoggedIn = true
            }
            
            return true
        } else {
            throw NSError(domain: "", code: result.code, userInfo: [NSLocalizedDescriptionKey: result.message ?? "注册失败"])
        }
    }
    
    /// 退出登录
    func logout() {
        UserDefaults.standard.removeObject(forKey: Constants.tokenKey)
        UserDefaults.standard.removeObject(forKey: Constants.userIdKey)
        UserDefaults.standard.removeObject(forKey: Constants.userNameKey)
        UserDefaults.standard.removeObject(forKey: Constants.userNicknameKey)
        UserDefaults.standard.set(false, forKey: Constants.isVipKey)
        
        currentUser = nil
        isVip = false
        credits = 0
        isLoggedIn = false
    }
    
    /// 获取当前模型
    func getCurrentModel() -> String {
        return UserDefaults.standard.string(forKey: Constants.currentModelKey) ?? "deepseek-v3"
    }
    
    /// 设置当前模型
    func setCurrentModel(_ model: String) {
        UserDefaults.standard.set(model, forKey: Constants.currentModelKey)
    }
    
    /// 获取用户ID
    var userId: Int {
        return UserDefaults.standard.integer(forKey: Constants.userIdKey)
    }
    
    /// 获取用户昵称
    var nickname: String {
        return UserDefaults.standard.string(forKey: Constants.userNicknameKey) ?? "用户\(userId)"
    }
    
    /// 激活测试VIP
    func activateTestVip() async throws {
        let result = try await api.activateTestVip()
        if result.code == 0 {
            await MainActor.run {
                self.isVip = true
                UserDefaults.standard.set(true, forKey: Constants.isVipKey)
            }
        } else {
            throw NSError(domain: "", code: result.code, userInfo: [NSLocalizedDescriptionKey: result.message])
        }
    }
}
