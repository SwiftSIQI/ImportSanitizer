//
//  Utility.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Files

public struct ImportSanitizerError: LocalizedError {
    public let message: String
    public init(_ message: String) {
        self.message = message
    }
    public var errorDescription: String? { message }
}

public class Utility {
    static func fetchSDKNames(with podsPath: String) throws -> [String] {
        var sdkNames = [String]()
        // 获取所有组件的名称,通过排除 pods 目录下的个别文件夹
        let excludedFolderNames = ["Pods.xcodeproj",
                                   "Target Support Files",
                                   "Local Podspecs",
                                   "Headers"]
        sdkNames = try Folder(path: podsPath)
            .subfolders
            .filter { excludedFolderNames.contains($0.name) == false }
            .map{$0.name}
        return sdkNames
    }
    
    static func fetchPodspecInfo(with podspecPath: String) throws -> PodSpec {
        // 处理 podspec 的逻辑
        let url = URL(fileURLWithPath: podspecPath)
        let jsonData = try Data(contentsOf: url, options: .alwaysMapped )
        let podspec = try JSONDecoder().decode(PodSpec.self, from: jsonData)
        return podspec
    }
    
    static func fetchCustomMapTable(with patchFilePath: String) throws -> [CustomMapTableInfo] {
        // 处理 podspec 的逻辑
        let url = URL(fileURLWithPath: patchFilePath)
        let jsonData = try Data(contentsOf: url, options: .alwaysMapped )
        let mapTableInfo = try JSONDecoder().decode([CustomMapTableInfo].self, from: jsonData)
        return mapTableInfo
    }
}
