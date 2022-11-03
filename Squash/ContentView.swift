//
//  ContentView.swift
//  test
//
//  Created by Joey Shapiro on 11/1/22.
//

import SwiftUI

extension FileManager {
    func isDirectory(atPath: String) -> Bool {
        var check: ObjCBool = false
        if fileExists(atPath: atPath, isDirectory: &check) {
            return check.boolValue
        } else {
            return false
        }
    }
}

struct ContentView: View {
    @State var pathCurrent: String = "/"
    
    var body: some View {
        VStack {
            HStack {
                NavigationView {
                    List {
                        Text("Quick Access").font(.headline)
                        // root
                        NavigationLink( destination: FileView(path: "/", contentView: self)) {
                            Label("Root", systemImage: "externaldrive")
                        }
                        // applications
                        NavigationLink( destination: FileView(path: "/Applications", contentView: self)) {
                            Label("Applications", systemImage: "externaldrive")
                        }
                    }.listStyle(SidebarListStyle())
                    .navigationTitle("Quick Access")
                    VStack {
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .foregroundColor(.accentColor)
                        Text("Hello, world!")
                        Button("test") {
                            print("hello")
                            pathCurrent = "test"
                            print(pathCurrent)
                        }
                    }
                }
            }
            Text(pathCurrent)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FileView : View {
//    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    let columns = [
            GridItem(.adaptive(minimum: 80))
        ]
    var path: String
    var contentView: ContentView
    
    let fm = FileManager.default // need to set directory here

    func getFiles() -> [String] {
        let url = URL(fileURLWithPath: path)
        let cp = try! url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath
        
        contentView.pathCurrent = cp!
        
        // Get the document directory url
        fm.changeCurrentDirectoryPath(cp!)
        var directories: [String] = [fm.currentDirectoryPath]
    
        let dirCur = directories.popLast()!
        
        let files = try! fm.contentsOfDirectory(atPath: dirCur)
//        let urlFiles = files.map({ f in return URL(string: f)! })
        
        return files
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(getFiles(), id: \.self) { f in
                    if fm.isDirectory(atPath: f) {
                        Button {
                        } label: {
                            VStack {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: f))
                                Text(f)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                        }.buttonStyle(.borderless)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .border(.pink)
                        .controlSize(.large)
                    } else {
                        Label(f, systemImage: "doc")
                    }
                }
            }
        }
    }
}
