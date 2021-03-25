//
//  ImportSyntax.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Files

enum ImportSyntaxType {
    case quotationWithSlash         // "A/A.h"
    case noSlash                    // "A.h" or  <A.h>
    case guillemetsWithSlash        // <A/A.h>
    case unknown                    // 未定义类型头文件
}

struct ImportSyntax: CustomStringConvertible {
    var description: String { raw }

    // #import "A/A.h" 为例 ( 注意,同时支持 include 语法 )
    let raw: String                         // #import "A/A.h"
    let prefix: String?                     // #import
    let info: String?                       // A/A.h
    let headerName: String?                 // A.h
    let podName: String?                    // A
    var type: ImportSyntaxType              // quotationWithSlash
    
    init?(_ raw: String) throws {
        self.raw = raw
        self.type = try ImportSyntax.getImportSyntaxType(self.raw)

        guard let aPrefix = raw.split(separator: " ").first else {
            return nil
        }
        self.prefix = String(aPrefix)
        
        guard let aInfo = raw.split(separator: " ").last?.dropLast().dropFirst() else {
            return nil
        }
        self.info = String(aInfo)
        
        switch type {
        case .quotationWithSlash, .guillemetsWithSlash:
            guard let aPodName = self.info?.split(separator: "/").first,
                  let aheaderName = self.info?.split(separator: "/").last else {
                self.podName = nil
                self.headerName = nil
                return
            }
            self.podName = String(aPodName)
            self.headerName = String(aheaderName)
        case .noSlash:
            self.podName = nil
            self.headerName = self.info
        case .unknown:
            throw ImportSanitizerError("无法识别的头文件引用语句, 内容为 \(self.raw)")
        }
    }}


public enum ImportRegexPattern: String {
    // #(import|include)
    case defaultPattern             = "\\n\\s*#import\\s*[<\"](.*?)[\">]"
    case quotationWithSlashPattern  = "\\n\\s*#import\\s*(\")(.*?)/(.*?)(\")"
    case guillemetsWithSlashPattern = "\\n\\s*#import\\s*(<)(.*?)/(.*?)(>)"
    case noSlashPattern             = "\\n\\s*#import\\s*[<\"]([^/]*?)[\">]"
}

extension ImportSyntax {
    static func getImportSyntaxType(_ raw: String) throws -> ImportSyntaxType {
        // 匹配 "A/A.h"
        let quotationWithSlashPattern = ImportRegexPattern.quotationWithSlashPattern.rawValue
        // 匹配 "A.h" or  <A.h>
        let noSlashPattern = ImportRegexPattern.noSlashPattern.rawValue
        // 匹配 <A/A.h>
        let guillemetsWithSlashPattern = ImportRegexPattern.guillemetsWithSlashPattern.rawValue
        
        if try raw.isMatch(pattern: quotationWithSlashPattern) {
            return .quotationWithSlash
        } else if try raw.isMatch(pattern: noSlashPattern)  {
            return .noSlash
        } else if try raw.isMatch(pattern: guillemetsWithSlashPattern) {
            return .guillemetsWithSlash
        } else {
            throw ImportSanitizerError("无法识别的头文件引用语句, 内容为 \(raw)")
        }
    }
    
    static func searchImportSyntax(in content: String) throws -> [ImportSyntax] {
        var sentence = [ImportSyntax]()
        // 以 #import或者#include 开头, 中间包含多个空格, 最后包含 < > 或者 " " 的写法
        let pattern = ImportRegexPattern.defaultPattern.rawValue
        let regex = try NSRegularExpression(pattern: pattern,
                                            options: .caseInsensitive)
        let matches = regex.matches(in: content,
                                    options: .reportProgress,
                                    range: NSRange(location: 0, length: content.count))
        // 根据匹配结果获取符合要求的字符串内容
        for match in matches {
            guard let range = Range(match.range, in: content),
                  let syntax = try ImportSyntax(String(content[range])) else {
                continue
            }
            sentence.append(syntax)
        }
        return sentence
    }
}
