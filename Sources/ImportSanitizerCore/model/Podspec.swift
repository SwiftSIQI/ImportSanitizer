//
//  Podspec.swift
//  ImportSanitizerCore
//
//  Created by SketchK on 2020/11/3.
//

import Foundation

public struct SubSpec: Codable {
    var name: String
    var sourceFiles: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case sourceFiles = "source_files"
    }
    
    public init(from decoder: Decoder) throws {
        let vals = try decoder.container(keyedBy: CodingKeys.self)
        name = try vals.decode(String.self, forKey: CodingKeys.name)
        // 判断 sourceFiles 类型的归属
        if let stringProperty = try? vals.decode(String.self, forKey: CodingKeys.sourceFiles) {
            sourceFiles = [stringProperty]
        } else if let arrayProperty = try? vals.decode(Array<String>.self, forKey: CodingKeys.sourceFiles) {
            sourceFiles = arrayProperty
        }
    }
}

public struct PodSpec: Codable {
    var name: String
    var moduleName: String?
    var sourceFiles: [String]?
    var subSpecs: [SubSpec]?
    
    enum CodingKeys: String, CodingKey {
        case name
        case moduleName = "module_name"
        case sourceFiles = "source_files"
        case subSpecs = "subspecs"
    }
    
    public init(from decoder: Decoder) throws {
        let vals = try decoder.container(keyedBy: CodingKeys.self)
        name = try vals.decode(String.self, forKey: CodingKeys.name)
        // 判断 moduleName 是否为空
        if let moduleNameProperty = try? vals.decode(String.self, forKey: CodingKeys.moduleName) {
            moduleName = moduleNameProperty
        }
        // 判断 sourceFiles 类型的归属
        if let stringProperty = try? vals.decode(String.self, forKey: CodingKeys.sourceFiles) {
            sourceFiles = [stringProperty]
        } else if let arrayProperty = try? vals.decode(Array<String>.self, forKey: CodingKeys.sourceFiles) {
            sourceFiles = arrayProperty
        }
        // 判断 subSpecs 类型的归属
        if let arrayProperty = try? vals.decode([SubSpec].self, forKey: .subSpecs) {
            subSpecs = arrayProperty
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        if let moduleNameProperty = moduleName {
            try container.encode(moduleNameProperty, forKey: .moduleName)
        }
        try container.encode(sourceFiles, forKey: .sourceFiles)
        try container.encode(subSpecs, forKey: .subSpecs)
    }
}

extension PodSpec {
    func sourceFilesAll() -> [String] {
        var result = [String]()
        if let value = self.sourceFiles {
            result.append(contentsOf: value)
        }
        if let info = self.subSpecs {
            for subspec in info {
                if let value = subspec.sourceFiles {
                    result.append(contentsOf: value)
                }
            }
        }
        return result
    }
}
