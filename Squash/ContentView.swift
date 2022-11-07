//
//  ContentView.swift
//  test
//
//  Created by Joey Shapiro on 11/1/22.
//

import SwiftUI

class Test : ObservableObject {
    @Published var pressure = 0.0
}

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

struct KeyEventHandling: NSViewRepresentable {
    @EnvironmentObject var test: Test
    
    class KeyView: NSView {
        var test: Test
        override var acceptsFirstResponder: Bool { true }
        
        init(test: Test) {
            self.test = test
            super.init(frame: .zero)
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func pressureChange(with event: NSEvent) {
            if event.pressure == 1 { // i think this is force click
                print("\(event.pressure)")
                test.pressure = Double(event.pressure)
            } else {
                test.pressure = Double(event.pressure)
            }
        } // x-=-1
    }

    func makeNSView(context: Context) -> NSView {
        let view = KeyView(test: test)
        DispatchQueue.main.async { // wait till next event cycle
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}

struct ContentView: View {
    @StateObject var test = Test()
    @State var pathCurrent: String = "/"
    
    var body: some View {
        VStack {
            HStack {
                NavigationView {
                    List {
                        Text("Quick Access").font(.headline)
                        // root
                        NavigationLink( destination: FilesView(path: "/", contentView: self)) {
                            Label("Root", systemImage: "externaldrive")
                        }
                        // applications
                        NavigationLink( destination: FilesView(path: "/Applications", contentView: self)) {
                            Label("Applications", systemImage: "externaldrive")
                        }
                        // This
                        NavigationLink( destination: FilesView(path: ".", contentView: self)) {
                            Label("Home", systemImage: "externaldrive")
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
        }.environmentObject(test)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct FilesView : View {
//    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    let columns = [
            GridItem(.adaptive(minimum: 80))
        ]
    @State var path: String
    var contentView: ContentView
    @EnvironmentObject var test: Test
    @State private var overWhat = ""
    @State private var whatChosen = ""
    @State private var filesToList: [String] = []
    @State private var maxDepth: Int = 1
    
    let fm = FileManager.default // need to set directory here

    func getFiles() {
        let url = URL(fileURLWithPath: path)
        let cp = try! url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath
        var depth = 0
        
        contentView.pathCurrent = cp!
        
        // Get the document directory url
        fm.changeCurrentDirectoryPath(cp!)
        var directories: [String] = [cp!]
        
        while !directories.isEmpty && depth <= maxDepth {
            let dirCur = directories.popLast()!
            print(dirCur)
            
            do {
                let files = try fm.contentsOfDirectory(atPath: dirCur)
                //        let urlFiles = files.map({ f in return URL(string: f)! })
                let filepaths = files.map({ f in return dirCur + f})
                
                directories.append(contentsOf: filepaths.filter { fm.isDirectory(atPath: $0) })
                
                print(filesToList.count)
                filesToList.append(contentsOf: filepaths)
                depth -= -1
            } catch {
                print(error)
            }
        }
        
        print(filesToList.count)
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(filesToList, id: \.self) { f in
                    let fpaths = f.split(separator: "/")
                    VStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: f))
                        Text(fpaths.last!)//.foregroundColor(overWhat == fpaths.last! ? .green : .red)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .overlay(overWhat == fpaths.last! ?
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.green.opacity(0.5), lineWidth: 5)
                                 :
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(.green.opacity(0.0), lineWidth: 5)
                        )
                        .gesture(TapGesture(count:1).onEnded({
                            print("Tap Displayed")
                            
                        }))
                        .highPriorityGesture(TapGesture(count:2).onEnded({
                            print("Double Tap Displayed")
                            whatChosen = f
                            if fm.isDirectory(atPath: f) {
                                path = f
                                filesToList.removeAll()
                                getFiles()
                            } else {
                                print(f)
                            }
                        }))
                        .background(KeyEventHandling().environmentObject(test))
                        .onHover { isOver in
                            if isOver {
                                overWhat = String(fpaths.last!)
                            } else {
                                overWhat = ""
                            }
                        }
                }
            }
            Text(String(test.pressure))
        }.onAppear(perform: {getFiles()}).environmentObject(test)
    }
}
