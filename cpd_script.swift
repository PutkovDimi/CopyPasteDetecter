#!/usr/bin/env xcrun --sdk macosx swift

import Foundation

main()

final class CopyPasteDetecter: NSObject {
    private var parser: XMLParser?
    private var numberOfDuplicates: Int = .zero
    private var parsedArguments = ParsedArguments()
    
    init(filepath: String) {
        super.init()
        parser = getXMLParser(byPath: filepath)
        parser?.delegate = self
    }
    
    func parse() -> Bool {
        parser?.parse() ?? false
    }
}

// MARK: - XMLParserDelegate conforming

extension CopyPasteDetecter: XMLParserDelegate {
    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        
        let previousNumberOfDuplicates = numberOfDuplicates
        
        switch elementName {
        case Headers.duplication.rawValue:
            numberOfDuplicates += 1
            parsedArguments.duplicateLinesCount = attributeDict[Headers.lines.rawValue] ?? ""
        case Headers.file.rawValue:
            parsedArguments.lines.append(attributeDict[Headers.line.rawValue] ?? "")
            parsedArguments.pathes.append(attributeDict[Headers.path.rawValue] ?? "")
        default:
            break
        }
        
        if numberOfDuplicates != previousNumberOfDuplicates {
            printAndReset()
        }
    }
}

// MARK: - Private methods

private extension CopyPasteDetecter {
    func getXMLParser(byPath filepath: String) -> XMLParser? {
        
        let absolutePath = "\(FileManager.default.currentDirectoryPath)/\(filepath)"
        let fileURL = URL(fileURLWithPath: absolutePath)
        
        guard
            let xmlParser = XMLParser(contentsOf: fileURL)
        else {
            print("warning: 🆘 There is no file by the given path")
            return nil
        }
        return xmlParser
    }
    
    func printAndReset() {
        guard
            let path = parsedArguments.pathes.first,
            let line = parsedArguments.lines.first
        else {
            parsedArguments = ParsedArguments()
            return
        }
        print("warning: 🖊 Сopy-paste was dectected:\n\(path), line \(line):\n\(parsedArguments.duplicateLinesCount) copy-pasted lines from: \(parsedArguments.duplicatedFiles)\n")
        
        parsedArguments = ParsedArguments()
    }
}

private extension CopyPasteDetecter {
    enum Headers: String {
        case duplication
        case file
        case line
        case lines
        case path
    }
    
    struct ParsedArguments {
        var lines: [String] = []
        var pathes: [String] = []
        var duplicateLinesCount: String = ""
        
        var duplicatedFiles: String {
            var duplicatedFiles = ""
            
            for (position, path) in pathes.enumerated() {
                guard position != .zero
                else { continue }
                
                duplicatedFiles += "\(path), line \(lines[position])"
                if position != pathes.count - 1 {
                    duplicatedFiles += ", "
                }
            }
            
            return duplicatedFiles
        }
    }
}

// MARK: - @Main

func main() {
    guard
        CommandLine.arguments.count
        >= Constants.availableArgumentsCount
    else {
        print("warning: 🆘 There is no path of xml file")
        return
    }

    let xmlFilepath = CommandLine.arguments[Constants.xmlFilePathPosition]
    let detecter = CopyPasteDetecter(filepath: xmlFilepath)
    
    guard detecter.parse() else {
        print("warning: 🆘 Сannot parse file by path \(xmlFilepath)")
        return
    }
}

fileprivate struct Constants {
    static let xmlFilePathPosition = 1
    static let availableArgumentsCount = 2
}


