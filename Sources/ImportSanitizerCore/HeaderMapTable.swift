//
//  HeaderMapTable.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Files

struct HeaderMapTable {
    let path: String
    let mode: FixMode
    var mapTable = [String: [String]]()
    var count: Int { mapTable.count }

    init(referencePath path: String, mode: FixMode) throws {
        self.path = path
        self.mode = mode
        self.mapTable = [String: [String]]()
        switch self.mode {
        case .app, .sdk, .shell:
            let podsFolder = path.replacingOccurrences(of: "/Podfile",
                                                     with: "/Pods")
            let sdkCount = try Utility.fetchSDKNames(with: podsFolder).count
            print("当前工程引入的 SDK 数量: \(sdkCount)")
            try updateWith(folder: podsFolder)
        case .convert:
            print("当前工程引入的 SDK 数量: 1")
            try updateWith(path: path)
        }
        print("映射表的键值对数量有: \(mapTable.count)")
    }
}

extension HeaderMapTable {
    mutating func updateWith(folder: String) throws {
        // 核心逻辑: 通过 Pods 目录获取所有 SDK 的名称
        // 处理 Pods 的逻辑, 因为 Pods 目录永远与 Podfile 保持同级
        let sdkNames = try Utility.fetchSDKNames(with: folder)
        // 通过组件名称构建一个 sdk 路径, 在这个路径下把所有文件名遍历并塞到映射表中
        for sdk in sdkNames {
            let sdkPath = folder + "/" + sdk
            try updateWith(path: sdkPath)
        }
    }
    
    mutating func updateWith(path: String) throws{
        // 核心逻辑: 将目录名作为组件名, 目录里的 .h 文件作为内容
        var mapTable = self.mapTable
        let sdkPath = path
        let sdk = try Folder(path: sdkPath).name
        let headerFiles = try Folder(path: sdkPath).files.recursive.filter{
            $0.extension == "h" }
        for file in headerFiles {
            guard mapTable[file.name] != nil else {
                mapTable[file.name] = [sdk]
                continue
            }
            guard mapTable[file.name]?.contains(sdk) == false else { continue }
            mapTable[file.name]?.append(sdk)
        }
        self.mapTable = mapTable
    }
    
    mutating func updateWith(patchFile: String) throws {
        let customMapTableInfo = try Utility.fetchCustomMapTable(with: patchFile)
        print("根据 patch file 修改了以下头文件的映射关系:".bold)
        for info in customMapTableInfo {
            guard let podsNames = self.mapTable[info.name] else { continue }
            self.mapTable[info.name] = [info.pod]
            print("将 \(info.name) 的映射关系从 \(podsNames) 变成了 \(info.pod)".likeValuableSentence(.note))
        }
    }
}

extension HeaderMapTable {
    func duplicatedHeadersInfo() -> [String: [String]] {
        return mapTable.filter { $0.value.count > 1 }
    }
    
    func doctor() {
        let duplicatedHeadersInfo = self.duplicatedHeadersInfo()
        guard  !duplicatedHeadersInfo.isEmpty else {
            return
        }
        
        let relatedPods = duplicatedHeadersInfo.reduce(
            Set<String>()) { (relatedPods, info) in
            let (_, pods) = info
            return relatedPods.union(pods)
        }
        
        let duplicatedHeadersMessage = duplicatedHeadersInfo.map {
            (header, pods) -> String in
            "头文件 \(header) 重复，对应仓库有 \(pods.joined(separator: ","))"
        }
        print("""
        注意! 该项目依赖的组件存在重名头文件的情况 !!!"
        涉及的仓库个数为 \(relatedPods.count) 个
        涉及的仓库有:
        \(relatedPods.joined(separator: "\r"))
        重名头文件个数为 \(duplicatedHeadersInfo.count) 个
        重名头文件的有:
        """)
        for message in duplicatedHeadersMessage {
            print("\(message)".likeValuableSentence(.note))
        }
    }
}
