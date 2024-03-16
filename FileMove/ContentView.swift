//
//  ContentView.swift
//  FileMove
//
//  Created by ssg on 3/15/24.
//

import SwiftUI
import Foundation
import AppKit

struct ContentView: View {
    @State private var sourcePath: URL?
    @State private var destinationPath: URL?
    @State private var finishMessage: String?
    
    var body: some View {
        VStack {
            Button("번역 폴더 선택") {
                self.selectFolder { url in
                    self.sourcePath = url
                }
            }
            if let sourcePath {
                Text(sourcePath.absoluteString)
            }
            
            Button("프로젝트 폴더 선택") {
                self.selectFolder { url in
                    self.destinationPath = url
                }
            }
            if let destinationPath {
                Text(destinationPath.absoluteString)
            }
            
            Button("파일 이동") {
                self.moveFiles()
            }
            if let finishMessage {
                Text(finishMessage)
            }
        }
        .padding()
        .onChange(of: finishMessage) { _, _ in
            print(finishMessage ?? "")
        }
    }
    
    func selectFolder(completion: @escaping (URL) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.begin { response in
            if response == .OK, let url = openPanel.urls.first {
                completion(url)
            }
        }
    }
    func moveFiles() {
        guard let sourcePath,
              let destinationPath = destinationPath?.appendingPathComponent("Namdo") else {
            finishMessage = "Source or destination folder not selected."
            return
        }
        
        let folder = Folder(sourcePath: sourcePath, destinationPath: destinationPath)
        
        finishMessage = ""
        // Perform copy operation for each file
        for route in folder.routes {
            let sourceFileURL = route.makePath(folder.sourcePath)
            let destinationFileURL = route.makePath(folder.destinationPath)
            
            // Check if the file already exists at the destination
            if FileManager.default.fileExists(atPath: destinationFileURL.path) {
                do {
                    // If it exists, delete the file
                    try FileManager.default.removeItem(at: destinationFileURL)
                } catch {
                    finishMessage! += "Error deleting existing file \(destinationFileURL): \(error.localizedDescription)\n"
                    continue
                }
            }
            
            // Copy the file to the destination
            do {
                try FileManager.default.copyItem(at: sourceFileURL, to: destinationFileURL)
                finishMessage! += "File \(route.subDirectory) / \(route.fileName) copied successfully.\n"
            } catch {
                finishMessage! += "Error copying file \(route.subDirectory)\(route.fileName): \(error.localizedDescription)\n"
            }
        }
    }
}

#Preview {
    ContentView()
}

/// 경로 데이터 모델
struct Folder {
    /// 소스 폴더 (번역 폴더)
    let sourcePath: URL
    /// 목적지 폴더 (프로젝트 폴더)
    let destinationPath: URL
    
    /// 경로들
    let routes: [Route] = [
        .init(subDirectory: "", fileName: "LocalizableKeys.swift"),
        .init(subDirectory: "zh-Hant.lproj", fileName: "Localizable.strings"),
        .init(subDirectory: "ja.lproj", fileName: "Localizable.strings"),
        .init(subDirectory: "zh-Hans.lproj", fileName: "Localizable.strings"),
        .init(subDirectory: "en.lproj", fileName: "Localizable.strings"),
        .init(subDirectory: "ko.lproj", fileName: "Localizable.strings")
    ]
}

/// 경로 모델
struct Route {
    /// 하위 경로
    let subDirectory: String
    /// 파일명
    let fileName: String
    
    /// 경로 설정
    func makePath(_ home: URL) -> URL {
        home
            .appendingPathComponent(subDirectory)
            .appendingPathComponent(fileName)
    }
}
