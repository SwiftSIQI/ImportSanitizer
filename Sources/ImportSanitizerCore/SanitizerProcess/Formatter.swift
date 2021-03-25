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
    
    func check(importSyntax: ImportSyntax, in file: File) throws-> Bool {
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
            //1 获取 file 的 pod 名称
            var currentFilePodName = ""
            switch self.mode {
            case .sdk:
                guard let podspec = try self.target.podspecInfo() else {
                    return false
                }
                currentFilePodName = podspec.moduleName ?? podspec.name
            case .shell:
                let filePathComponent = file.path.split(separator: "/")
                guard let podsIndex = filePathComponent.firstIndex(of: "Pods") else {
                    return false
                }
                currentFilePodName = String(filePathComponent[podsIndex + 1])
            case .app:
                currentFilePodName = "🌝"
            case .convert:
                throw ImportSanitizerError("严重逻辑错误, Formatter Process 不应当出现在 Convert 模式下")
            }
            //2 获取 MapTable 中对应 header 的 pod 名称并判断 pod 名称是否存在包含关系, 只有不存在包含关系才进行修改
            guard let headerName = importSyntax.headerName,
                  let podNames = self.reference.mapTable[String(headerName)] ,
                  podNames.contains(currentFilePodName) == false else {
                return false
            }
            return true
        case .unknown:
            throw ImportSanitizerError("无法识别的头文件引用语句, 语句为 \(importSyntax.raw), 在 \(file) 中")
        }
    }

    // 前置检查已经在 check 方法中进行,所以这里可以直接强制拆包进行处理
    func fix(importSyntax: ImportSyntax,
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
            let final = importSyntax.prefix!
                    + " <" + importSyntax.info! + ">"
            print("错误类型为 [没有使用尖括号], 需要将 \(importSyntax.raw) 改为 \(final), 发生在 \(file.name)".determined(by: needOverwrite))
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
            let final = importSyntax.prefix!
                        + " <" + podNames.first! + "/" + headerName + ">"
            print("错误类型为 [没有使用组件名/头文件的格式], 需要将 \(importSyntax.raw) 改为 \(final), 发生在 \(file.name)".determined(by: needOverwrite))
            result = regex.stringByReplacingMatches(in: result,
                                                    options: .reportProgress,
                                                    range: range,
                                                    withTemplate: final)
        case .guillemetsWithSlash:
            // 对于 <XX/XX.h > 格式直接跳过
            return result
        case .unknown:
            throw ImportSanitizerError("无法识别的头文件引用语句, 语句为 \(importSyntax.raw), 在 \(file) 中")
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
