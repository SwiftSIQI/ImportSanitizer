//
//  SanitizerProcess.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/12/23.
//

import Foundation
import Files

protocol SanitizerProcess {
    var mode : FixMode { get set }
    var reference: HeaderMapTable { get set }
    var target : ProjectSourceFiles { get set }
    var needOverwrite: Bool { get set }
    var result: [Description] {get set}
    
    mutating func check(importSyntax: ImportSyntax, in file: File) throws-> Bool
    mutating func fix(importSyntax: ImportSyntax,
             in content: String,
             with file: File ) throws -> String
}

extension SanitizerProcess {
    mutating func shouldIgnore(_ importSyntax: ImportSyntax, in file: File) -> Bool {
        // 1 获取 MapTable 中对应 header 的 pod 名称
        guard let headerName = importSyntax.headerName,
              let podNames = self.reference.mapTable[String(headerName)]  else {
            // 没有找到相应的头文件信息说明, 可能是引用了某些特殊的系统文件
            return true
        }
        guard podNames.count == 1 else {
            // 说明有同名的头文件, 此时不做修复, 应当提醒开发者手动修改
            let syntax = headerName.trimmingCharacters(in: .whitespacesAndNewlines)
            let eType = SyntaxErrorType.duplicatedHeaderFile.rawValue
            let sType = SolutionType.manually.rawValue
            let solution = "\(syntax) 同时属于以下组件 \(podNames), 需要明确使用的组件"
            let description = Description(syntax: syntax, fileName: file.name, filePath: file.path, errorType: eType, soulution: solution)
            self.result.append(description)
            print("错误类型为[\(eType)], 修复方式为[\(sType)], 错误语句为[\(syntax)], 解决方案为 \(solution), 问题发生在 \(file.name) 中".likeValuableSentence(.error))
            return true
        }
        return false
    }
    
    mutating func isValidate(_ importSyntax: ImportSyntax, in file: File) -> Bool {
        // 判断引用的头文件是否为非 .h 类型的文件,例如引入了某个 .m 的文件
        guard let last = importSyntax.headerName?.split(separator: ".").last, String(last) != "m" else {
            // 说明引入了一个 .m 文件, 此时不做修复(没法保证 .h 文件一定存在), 应当提醒开发者手动修改
            let syntax = importSyntax.raw.trimmingCharacters(in: .whitespacesAndNewlines)
            let eType = SyntaxErrorType.implementationFile.rawValue
            let sType = SolutionType.manually.rawValue
            let solution = "删除 \(syntax) 并引入对应的 .h 文件"
            let description = Description(syntax: syntax, fileName: file.name, filePath: file.path, errorType: eType, soulution: solution)
            self.result.append(description)
            print("错误类型为[\(eType)], 修复方式为[\(sType)], 错误语句为[\(syntax)], 解决方案为 \(solution), 问题发生在 \(file.name) 中".likeValuableSentence(.error))
            return false
        }
        return true
    }
}
