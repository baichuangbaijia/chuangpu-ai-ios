import Foundation
import SwiftUI

/// Markdown渲染辅助类
struct MarkdownHelper {
    
    /// 解析Markdown为AttributedString
    static func parse(_ text: String) -> AttributedString {
        do {
            var result = try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
            
            // 自定义代码块样式
            if let range = result.range(of: "```") {
                result[range].foregroundColor = Constants.accentOrange
            }
            
            return result
        } catch {
            return AttributedString(text)
        }
    }
    
    /// 将Markdown转换为NSAttributedString用于TextKit
    static func parseToNSAttributedString(_ text: String) -> NSAttributedString {
        let mutableString = NSMutableAttributedString(string: text)
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16)
        ]
        
        mutableString.addAttributes(baseAttributes, range: NSRange(location: 0, length: mutableString.length))
        
        // 代码块
        let codePattern = "`([^`]+)`"
        if let regex = try? NSRegularExpression(pattern: codePattern) {
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
            for match in matches.reversed() {
                let codeRange = match.range(at: 1)
                if let range = Range(codeRange, in: text) {
                    let code = String(text[range])
                    let codeAttr = NSAttributedString(
                        string: code,
                        attributes: [
                            .foregroundColor: UIColor(Color(hex: "F97316")),
                            .backgroundColor: UIColor(Color(hex: "252540")),
                            .font: UIFont.monospacedSystemFont(ofSize: 15, weight: .regular)
                        ]
                    )
                    mutableString.replaceCharacters(in: match.range, with: codeAttr)
                }
            }
        }
        
        // 加粗
        let boldPattern = "\\*\\*([^*]+)\\*\\*"
        if let regex = try? NSRegularExpression(pattern: boldPattern) {
            let matches = regex.matches(in: mutableString.string, range: NSRange(location: 0, length: mutableString.length))
            for match in matches.reversed() {
                let boldRange = match.range(at: 1)
                if let range = Range(boldRange, in: mutableString.string) {
                    let boldText = String(mutableString.string[range])
                    let boldAttr = NSAttributedString(
                        string: boldText,
                        attributes: [
                            .foregroundColor: UIColor.white,
                            .font: UIFont.boldSystemFont(ofSize: 16)
                        ]
                    )
                    mutableString.replaceCharacters(in: match.range, with: boldAttr)
                }
            }
        }
        
        return mutableString
    }
    
    /// 简单的文本清理
    static func cleanText(_ text: String) -> String {
        var result = text
        result = result.replacingOccurrences(of: "**", with: "")
        result = result.replacingOccurrences(of: "`", with: "")
        result = result.replacingOccurrences(of: "# ", with: "")
        result = result.replacingOccurrences(of: "## ", with: "")
        result = result.replacingOccurrences(of: "### ", with: "")
        return result
    }
    
    /// 提取文本摘要
    static func extractSummary(from text: String, maxLength: Int = 50) -> String {
        let cleaned = cleanText(text)
        if cleaned.count <= maxLength {
            return cleaned
        }
        let index = cleaned.index(cleaned.startIndex, offsetBy: maxLength)
        return String(cleaned[..<index]) + "..."
    }
}

/// Markdown文本视图组件
struct MarkdownText: View {
    let text: String
    let textColor: Color
    let fontSize: CGFloat
    
    init(_ text: String, textColor: Color = .white, fontSize: CGFloat = 16) {
        self.text = text
        self.textColor = textColor
        self.fontSize = fontSize
    }
    
    var body: some View {
        Text(parseMarkdown(text))
            .font(.system(size: fontSize))
            .foregroundColor(textColor)
    }
    
    private func parseMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text, options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            ))
        } catch {
            return AttributedString(text)
        }
    }
}
