//
//  Converter.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/12/23.
//

import Foundation
import Files

struct Converter: SanitizerProcess {
    var mode : FixMode
    var reference: HeaderMapTable
    var target : ProjectSourceFiles
    var needOverwrite: Bool
    
    func check(importSyntax: ImportSyntax, in file: File) throws-> Bool {
        switch importSyntax.type {
        case .guillemetsWithSlash, .quotationWithSlash, .noSlash:
            switch mode {
            case .convert:
                //0 检查 import syntax 是否有必要进行检查
                if shouldIgnore(importSyntax, in: file) {
                    return false
                }
                //1 对于 convert ,如果前置的检查已经确认头文件名存在,
                //  且 reference 里有这个头文件, 那就意味这个头文件语句需要修改
                //  因为 reference 里面只会有需要修改的头文件索引表
                return true
            case .app, .sdk, .shell:
                throw ImportSanitizerError("严重逻辑错误, Converter Process 不应当出现在 app, sdk, shell 模式下")
            }
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
        // 将 <A.h> "A.h" <Old/A.h> "Old/A.h" 换成 <New/A.h> 的写法
        let pattern = importSyntax.raw
            .replacingOccurrences(of: "+", with: "\\+")
            .replacingOccurrences(of: "/", with: "\\/")
        
        let regex = try NSRegularExpression(pattern: pattern,
                                            options: .caseInsensitive)
        let headerName = importSyntax.headerName!
        let podNames = self.reference.mapTable[String(headerName)]!
        let final = importSyntax.prefix!
                    + " <" + podNames.first! + "/" + headerName + ">"
        print("头文件引用关系转换成功, 从 \(importSyntax.raw) 变成 \(final), 发生在 \(file.name)".likeValuableSentence(.autoFix))
        result = regex.stringByReplacingMatches(in: result,
                                                options: .reportProgress,
                                                range: range,
                                                withTemplate: final)
        return result
    }
}
