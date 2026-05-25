import Foundation

// MARK: - 用户信息
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let nickname: String?
    let phone: String?
    let avatar: String?
    let vipLevel: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, nickname, phone, avatar
        case vipLevel = "vip_level"
    }
}

// MARK: - 登录数据
struct LoginData: Codable {
    let token: String
    let refreshToken: String?
    let userId: Int
    let expiresIn: Int
    let user: User?
    
    enum CodingKeys: String, CodingKey {
        case token
        case refreshToken = "refresh_token"
        case userId = "user_id"
        case expiresIn = "expires_in"
        case user
    }
}

// MARK: - API响应
struct ApiResult<T: Codable>: Codable {
    let code: Int
    let data: T?
    let message: String?
}

struct ApiListResult<T: Codable>: Codable {
    let code: Int
    let data: ListData<T>?
    let message: String?
}

struct ListData<T: Codable>: Codable {
    let list: [T]?
    let total: Int?
    let page: Int?
    let limit: Int?
}

// MARK: - 会话
struct Conversation: Codable, Identifiable {
    let id: Int
    let title: String
    let sessionId: String
    let model: String
    let updatedAt: String?
    let createdAt: String?
    let userId: Int
    var messageCount: Int
    
    enum CodingKeys: String, CodingKey {
        case id, title, model
        case sessionId = "session_id"
        case updatedAt = "updated_at"
        case createdAt = "created_at"
        case userId = "user_id"
        case messageCount
    }
}

// MARK: - 消息
struct Message: Identifiable {
    let id = UUID()
    var role: String
    var content: String
    var text: String?
    var fileCards: [FileCard]?
    var imageUrl: String?
    var videoUrl: String?
    var thumbnailUrl: String?
    var localVideoUri: String?
    var isStreaming: Bool = false
    
    init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

struct FileCard: Codable {
    let url: String
    let filename: String
    let type: String
    let size: String
    let icon: String
}

// MARK: - 技能
struct Skill: Codable, Identifiable {
    var id: String { name }
    let name: String
    let description: String
    let category: String?
    let slug: String?
    let version: String?
    let downloads: Int
    let isInstalled: Bool
    
    enum CodingKeys: String, CodingKey {
        case name, description, category, slug, version, downloads
        case isInstalled = "is_installed"
    }
}

struct SkillDetail: Codable {
    let name: String
    let description: String
    let slug: String?
    let version: String?
    let category: String?
}

// MARK: - 记忆
struct Memory: Codable, Identifiable {
    let id: String
    let content: String
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, content
        case createdAt = "created_at"
    }
}

// MARK: - 任务
struct AgentTask: Codable, Identifiable {
    let id: String
    let name: String
    let prompt: String
    let cronExpression: String
    let status: String
    let notificationEnabled: Bool
    let description: String?
    let runCount: Int
    let nextRun: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, prompt, status, description
        case cronExpression = "cron_expression"
        case notificationEnabled = "notification_enabled"
        case runCount = "run_count"
        case nextRun = "next_run"
    }
}

// MARK: - 积分
struct CreditData: Codable {
    let credits: Int
    let vipLevel: String
    let vipExpire: String?
    
    enum CodingKeys: String, CodingKey {
        case credits
        case vipLevel = "vip_level"
        case vipExpire = "vip_expire"
    }
}

// MARK: - 支付订单结果
struct PaymentOrderResult: Codable {
    let code: Int
    let message: String
    let data: [String: JSONValue]?
    
    var orderNo: String? { data?["order_no"]?.stringValue }
    var codeUrl: String? { data?["code_url"]?.stringValue }
    var amount: Int? { data?["amount"]?.intValue }
    var status: String? { data?["status"]?.stringValue }
    var containerStatus: String? { data?["container_status"]?.stringValue }
}

// MARK: - JSON值包装（替代AnyCodable）
enum JSONValue: Codable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])
    
    var stringValue: String? {
        if case .string(let v) = self { return v }
        return nil
    }
    var intValue: Int? {
        if case .int(let v) = self { return v }
        if case .double(let v) = self { return Int(v) }
        return nil
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            self = .null
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }
}

// MARK: - 容器状态
struct ContainerStatus: Codable {
    let containerStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case containerStatus = "container_status"
    }
}

// MARK: - SSE消息
struct SSEMessage: Codable {
    let content: String?
    let sessionId: String?
    
    enum CodingKeys: String, CodingKey {
        case content
        case sessionId = "session_id"
    }
}
