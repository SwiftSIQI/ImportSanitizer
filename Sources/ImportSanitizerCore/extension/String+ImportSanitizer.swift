//
//  String+ImportSanitizer.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Rainbow

extension String {    
    func isMatch(pattern: String) throws -> Bool {
        let range = NSRange(location: 0, length: self.count)
        let regexPattern = pattern
        let regex = try NSRegularExpression(pattern: regexPattern,
                                            options: .caseInsensitive)
        let result = regex.matches(in: self,
                                   options: .reportProgress,
                                   range: range)
        // 判断是否存在匹配情况
        return result.count > 0
    }
}

public enum SeperateLine: String {
    case normal     = "-"
}

public enum ValuableSentence: String {
    case note       = "? Note:"         // 在使用 patch file 的地方提示
    case warning    = "! Warning:"      // 在构建映射表时出现重名头文件的地方
    case error      = "* Error:"        // 修改过程中, 出现错误或者出现重名头文件的地方
    case autoFix    = "> AutoFix:"      // 写入模式下, 能够自动修复的地方,
}

public extension String {
    var likeFailed: String { get { return "😭 \(self)".red.bold } }
    var likeSucceeded: String { get { return "🥳 \(self)".green.bold } }
    
    func likeSeperateLine(_ type: SeperateLine) -> String {
        let marginCount = 15
        let margin = String(repeating: type.rawValue, count: marginCount) + ">"
        return "\(margin) \(self)".swap
    }
    
    func likeValuableSentence(_ type: ValuableSentence) -> String {
        switch type {
        case .note:
            return "📘 \(type.rawValue) \(self)".cyan.bold
        case .warning:
            return "⚠️ \(type.rawValue) \(self)".yellow.bold
        case .error:
            return "❌ \(type.rawValue) \(self)".red.bold.underline
        case .autoFix:
            return "✅ \(type.rawValue) \(self)".green.bold
        }
    }
}
