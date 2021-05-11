//
//  Formatter.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/12/23.
//

import Foundation
import Files

struct Formatter: SanitizerProcess {
    var mode : FixMode
    var reference: HeaderMapTable
    var target : ProjectSourceFiles
    var needOverwrite: Bool
    var result = [Description]()
    
    mutating func check(importSyntax: ImportSyntax, in file: File) throws-> Bool {
        switch importSyntax.type {
        case .guillemetsWithSlash:
            return false
        case .quotationWithSlash:
            return true
        case .noSlash:
            //0 检查 import syntax 是否有必要进行检查
            if shouldIgnore(importSyntax, in: file) {
                return false
            }
            //1 不管是引用自己的头文件,还是引用其他的头文件,都需要包含前缀
            return true
        case .unknown:
            throw ImportSanitizerError("无法识别的头文件引用语句, 语句为 \(importSyntax.raw.trimmingCharacters(in: .whitespacesAndNewlines)), 在 \(file.name) 中")
        }
    }

    // 前置检查已经在 check 方法中进行,所以这里可以直接强制拆包进行处理
    mutating func fix(importSyntax: ImportSyntax,
             in content: String,
             with file: File ) throws -> String {
        var result = content
        let range = NSRange(location: 0, length:result.count)
        switch importSyntax.type {
        case .quotationWithSlash:
            // 将 "XX/XX.h" 的写法变为 <XX/XX.h> 的写法
            let pattern = importSyntax.raw
                .replacingOccurrences(of: "+", with: "\\+")
                .replacingOccurrences(of: "/", with: "\\/")
            let regex = try NSRegularExpression(pattern: pattern,
                                                options: .caseInsensitive)
            let final = importSyntax.prefix! + " <" + importSyntax.info! + ">"
            
            
            let syntax = importSyntax.raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let eType = SyntaxErrorType.quotationWithSlash.rawValue
            let sType = SolutionType.automatically.rawValue
            let solution = "将 \(syntax) 改为 \(final.trimmingCharacters(in: .whitespacesAndNewlines))"
            let description = Description(syntax: syntax, fileName: file.name, filePath: file.path, errorType: eType, soulution: solution)
            self.result.append(description)
            print("错误类型为[\(eType)], 修复方式为[\(sType)], 错误语句为[\(syntax)], 解决方案为 \(solution), 问题发生在 \(file.name) 中".determined(by: needOverwrite))
            result = regex.stringByReplacingMatches(in: result,
                                                    options: .reportProgress,
                                                    range: range,
                                                    withTemplate: final)
        case .noSlash:
            // 将 "XX.h" or <XX.h> 的写法变为 <XX/XX.h > 的写法
            let pattern = importSyntax.raw
                .replacingOccurrences(of: "+", with: "\\+")
            let regex = try NSRegularExpression(pattern: pattern,
                                                options: .caseInsensitive)
            let headerName = importSyntax.headerName!
            let podNames = self.reference.mapTable[String(headerName)]!
            let final = importSyntax.prefix! + " <" + podNames.first! + ">"
            
            let syntax = importSyntax.raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let eType = SyntaxErrorType.noSlash.rawValue
            let sType = SolutionType.automatically.rawValue
            let solution = "将 \(syntax) 改为 \(final.trimmingCharacters(in: .whitespacesAndNewlines))"
            let description = Description(syntax: syntax, fileName: file.name, filePath: file.path, errorType: eType, soulution: solution)
            self.result.append(description)
            print("错误类型为[\(eType)], 修复方式为[\(sType)], 错误语句为[\(syntax)] , 解决方案为 \(solution), 问题发生在 \(file.name) 中".determined(by: needOverwrite))
            result = regex.stringByReplacingMatches(in: result,
                                                    options: .reportProgress,
                                                    range: range,
                                                    withTemplate: final)
        case .guillemetsWithSlash:
            // 对于 <XX/XX.h > 格式直接跳过
            return result
        case .unknown:
            throw ImportSanitizerError("无法识别的头文件引用语句, 语句为 \(importSyntax.raw.trimmingCharacters(in: .whitespacesAndNewlines)), 在 \(file) 中")
        }
        return result
    }
    
}

extension String {
    func determined(by needOverwrite: Bool) -> String{
        if needOverwrite {
            return self.likeValuableSentence(.autoFix)
        } else {
            return self.likeValuableSentence(.error)
        }
    }
}
