//
//  HeaderMapTable.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation
import Files

enum HeaderFileType : String {
    case Public  = "/Pods/Headers/Public"
    case Private = "/Pods/Headers/Private"
}

struct HeaderMapTable {
    let path: String
    let mode: FixMode
    var mapTable = [String: [String]]()
    var pubMapTable = [String: [String]]()
    var priMapTable = [String: [String]]()
    var convertFolderName:String? = nil
    var podsPath:String? = nil
    
    var count: Int { mapTable.count }

    init(referencePath: String, mode: FixMode) throws {
        self.path = referencePath
        self.mode = mode
        self.mapTable = [String: [String]]()
        self.pubMapTable = [String: [String]]()
        self.priMapTable = [String: [String]]()

        switch self.mode {
        case .app, .sdk, .shell:
            let podsPathString = referencePath.replacingOccurrences(of: "/Podfile",
                                                                with: "/Pods")
            let sdkCount = try Utility.fetchSDKNames(with: podsPathString).count
            self.podsPath = podsPathString
            print("当前工程引入的 SDK 数量: \(sdkCount)")
        case .convert:
            var element = referencePath.split(separator: "/")
            self.convertFolderName = String(element.removeLast())
            self.podsPath =  "/" + element.joined(separator: "/")
            print("当前工程引入的 SDK 数量: 1")
        }
        if let pathString = self.podsPath {
            self.pubMapTable = try searchHeaderFilesIn(pathString,
                                                       type: HeaderFileType.Public)
            self.priMapTable = try searchHeaderFilesIn(pathString,
                                                       type: HeaderFileType.Private)
            self.mapTable = self.priMapTable.merging(self.priMapTable) { (current, new) -> [String] in
                return (current + new).removeDuplicate()
            }
            print("映射表的键值对数量有: \(mapTable.count)")
        }
    }
}

extension HeaderMapTable {
    mutating func searchHeaderFilesIn(_ podsPath:String, type: HeaderFileType) throws -> [String: [String]]{
        var mapTable = [String: [String]]()
        // 根据传入值,构建 Public 或者 Private 的文件夹目录
        let folderPath = podsPath.replacingOccurrences(of: "/Pods",with: type.rawValue)
        // 创建对应 Public/Private 里的子目录数组
        let headerFolder = try Folder(path: folderPath)
        var subfolders = Array.init(headerFolder.subfolders)
        // 如果 convert folder name 存在就代表是转换模式
        // 此时只需要保留 convert folder name 里的头文件目录
        if let target = self.convertFolderName {
            subfolders = subfolders.filter { $0.name == target }
        }
        // 构建 map 表, 获取 public/private 的相对路径
        // map 表的 key 为 头文件名称, value 为 相对路径,即 #import 的引入方式
        for folder in subfolders {
            let headerFiles = folder.files.recursive.filter{ $0.extension == "h" }
            for file in headerFiles {
                let relativePath = file.path(relativeTo: headerFolder)
                guard mapTable[file.name] != nil else {
                    mapTable[file.name] = [relativePath]
                    continue
                }
                guard mapTable[file.name]?.contains(relativePath) == false else { continue }
                mapTable[file.name]?.append(relativePath)
            }
        }
        return mapTable
    }
    
    mutating func updateWith(patchFile: String) throws {
        let customMapTableInfo = try Utility.fetchCustomMapTable(with: patchFile)
        print("根据 patch file 修改了以下头文件的映射关系:".bold)
        for info in customMapTableInfo {
            guard let syntaxFromPods = self.mapTable[info.name] else { continue }
            let syntaxFromPatch = info.pod + "/" + info.name
            self.mapTable[info.name] = [syntaxFromPatch]
            print("将 \(info.name) 的映射关系从 \(syntaxFromPods) 变成了 \(syntaxFromPatch)".likeValuableSentence(.note))
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
            "头文件 \(header) 重复，对应仓库路径为 \(pods.joined(separator: ","))"
        }
        print("""
        注意! 该项目依赖的组件存在重名头文件的情况 !!!"
        涉及的仓库个数为 \(relatedPods.count) 个
        涉及的仓库和文件是:
        \(relatedPods.joined(separator: "\r"))
        重名头文件个数为 \(duplicatedHeadersInfo.count) 个
        重名头文件的有:
        """)
        for message in duplicatedHeadersMessage {
            print("\(message)".likeValuableSentence(.note))
        }
    }
}
