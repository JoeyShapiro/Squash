//
//  ContentView.swift
//  test
//
//  Created by Joey Shapiro on 11/1/22.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            HStack {
                NavigationView {
                    List {
                        Text("Quick Access").font(.headline)
                        // root
                        NavigationLink( destination: FileView(path: "/")) {
                            Label("Root", systemImage: "externaldrive")
                        }
                        // applications
                        NavigationLink( destination: FileView(path: "/Applications")) {
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
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FileView : View {
    var path: String
    
    let fm = FileManager.default // need to set directory here

    func getFiles() -> [String] {
        // Get the document directory url
        fm.changeCurrentDirectoryPath(path)
        var directories: [String] = [fm.currentDirectoryPath]
    
        let dirCur = directories.popLast()!
        
        let files = try! fm.contentsOfDirectory(atPath: dirCur)
//        let urlFiles = files.map({ f in return URL(string: dirCur + "/" + f)! })
        
        return files
    }
    
    var body: some View {
        VStack {
            Text("hello from \(path)")
            List (getFiles(), id: \.self) { f in
                Text(f)
            }
        }
    }
}
