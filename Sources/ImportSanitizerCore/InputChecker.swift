//
//  InputChecker.swift
//  ImportSanitizer
//
//  Created by SketchK on 2020/12/23.
//

import Foundation
import Files

struct InputChecker {
    var mode: FixMode
    var referencePath: String
    var targetPath: String
    var patchFilePath: String?
    var overwrite: Bool

    func validate() throws -> Void {
        print("""
        对文件路径处理后的信息如下👇
        Reference Path 参数为       \(referencePath)
        Target Path 参数为          \(targetPath)
        Patchfile Path 参数为       \(patchFilePath ?? "nil")
        """)
        
        try isReferencePathValidate()
        try isTargetPathValidate()
        try isPatchFilePathValidate()
    }
    
    func isReferencePathValidate() throws {
        do {
            switch self.mode {
            case .convert:
                let folder = try Folder(path: self.referencePath)
                let validate = (folder.parent?.name == "Pods")
                if !validate {
                    throw ImportSanitizerError("referencePath 参数有误, 在 convert 模式下该参数应该为 Pods 的子目录, 当前参数为 \(referencePath)")
                }
            case .app,.sdk,.shell:
                let validate = (try File(path: self.referencePath).name.caseInsensitiveCompare("Podfile") == .orderedSame )
                if !validate {
                    throw ImportSanitizerError("referencePath 参数有误, 在 sdk, app 或者 shell 模式下, 该路径为 Podfile 的路径, 当前参数为 \(referencePath)")
                }
            }
        } catch {
            throw ImportSanitizerError("referencePath 参数有误, 在 sdk, app 或者 shell 模式下, 该路径为 Podfile 的路径, 在 convert 模式下该参数应该为 Pods 的子目录, 当前参数为: \(referencePath) ")
        }
    }
    
    func isTargetPathValidate() throws {
        do {
            switch self.mode {
            case .sdk, .convert:
                let validate = (try File(path: self.targetPath).extension == "json")
                if !validate {
                    throw ImportSanitizerError("targetPath 参数有误, 在 sdk 或者 convert 模式下该参数的后缀名为 json, 当前参数为 \(targetPath)")
                }
            case .shell:
                let folder = try Folder(path: self.targetPath)
                let validate = (folder.name == "Pods" || folder.parent?.name == "Pods")
                if !validate {
                    throw ImportSanitizerError("targetPath 参数有误, 在 shell 模式下该参数应该为 Pods 目录或者 Pods 的子目录, 当前参数为 \(targetPath)")
                }
            case .app:
                return
            }
        } catch  {
            throw ImportSanitizerError("targetPath 参数有误, 在 sdk 或者 convert 模式下该参数的后缀名为 json, 在 shell 模式下该参数应该为 Pods 目录或者 Pods 的子目录, 当前参数为: \(referencePath)")
        }
    }
    
    func isPatchFilePathValidate() throws {
        do {
            guard let path = self.patchFilePath else {
                return
            }
            let validate = (try File(path: path).extension == "json")
            if !validate {
                throw ImportSanitizerError("patchfilePath 参数有误, 参数的后缀名为 json, 当前参数为 \(path)")
            }
        } catch {
            throw ImportSanitizerError("patchfilePath 参数有误, 参数的后缀名为 json, 当前参数为 \(patchFilePath!)")
        }
    }
}
