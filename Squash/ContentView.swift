//
//  ContentView.swift
//  test
//
//  Created by Joey Shapiro on 11/1/22.
//

import SwiftUI

class Test : ObservableObject {
    @Published var pressure = 0.0
    @Published var maxDepth = 1
}

struct FileDepthd : Hashable {
    var name: String
    var path: String
    var depth: Int
    var isDirectory: Bool
    
//    var hashValue: Int {
//        return path.hashValue
//    }
    
    static func == (lhs: FileDepthd, rhs: FileDepthd) -> Bool {
        return lhs.name == rhs.name && lhs.path == rhs.path && lhs.depth == rhs.depth && lhs.isDirectory == rhs.isDirectory
    }
}

func getPathComponents(at: String) -> [String] {
    // break up the path into its components
    var ancestors = at.split(separator: "/")
    // prepend the root folder
    ancestors.insert("/", at: 0)
    
    return ancestors.map { String($0) } // return a string version (why is substring a thing)
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow    // << important !!
        view.isEmphasized = true
//        view.material = .sidebar
        view.state = .active
        view.window?.titlebarAppearsTransparent = true
        
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    }
}

extension View {
    func backgroundBlur(with color: Color) -> some View {
        background(
            RoundedRectangle(cornerRadius: 5)
                .fill(color.opacity(0.3))
                .ignoresSafeArea() // also does the title bar
        ).background(VisualEffectView())
    }
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
                            Label("Applications", systemImage: "compass.drawing")
                        }
                        // This
                        NavigationLink( destination: FilesView(path: ".", contentView: self)) {
                            Label("Home", systemImage: "house")
                        }
                        // documents
                        NavigationLink( destination: FilesView(path: "/Users/\(NSUserName())/documents", contentView: self)) {
                            Label {
                                Text("Documents")
                            } icon: {
                                Image(systemName: "doc.richtext").foregroundColor(.accentColor)
                            }
                        }
                    }.backgroundBlur(with: .red)//.listStyle(SidebarListStyle())
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
            Divider()
            HStack {
                Label {
                    HStack {
                        ForEach(getPathComponents(at: pathCurrent), id: \.self) { d in
                            Button(d, action: {
                                print(d)
                            })
                        }
                    }
                } icon: {
                    Image(systemName: "list.bullet.indent").foregroundColor(.accentColor)
                }.help("Path of the current directory")
                Spacer()
                Stepper(value: $test.maxDepth, in: -1...5, step: 1) {
                    Label {
                        Text("\(Int(test.maxDepth))")
                    } icon: {
                        Image(systemName: "water.waves").foregroundColor(.accentColor)
                    }
                }.help("Max Depth to search down the directory")
            }.padding(5)
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
    @State private var filesToList: [FileDepthd] = []
    
    let fm = FileManager.default // need to set directory here

    func getFiles() {
        let url = URL(fileURLWithPath: path)
        let cp = try! url.resourceValues(forKeys: [.canonicalPathKey]).canonicalPath
        
        contentView.pathCurrent = cp!
        
        // Get the document directory url
        fm.changeCurrentDirectoryPath(cp!)
        var directories: [FileDepthd] = [FileDepthd(name: "", path: cp!, depth: 0, isDirectory: true)] // we should first add the children, but that is a lot of extra work. cant find good way then to have children be depth 0
        
        while !directories.isEmpty {
            let dirCur = directories.removeFirst() // queue
            
            do {
                let files = try fm.contentsOfDirectory(atPath: dirCur.path)
                //        let urlFiles = files.map({ f in return URL(string: f)! })
                
                let filepaths = files.map({ f in
                    return FileDepthd(name: f,
                                      path: dirCur.path == "/" ? dirCur.path + f : dirCur.path + "/" + f,
                                      depth: dirCur.depth - -1,
                                      isDirectory: fm.isDirectory(atPath: dirCur.path + "/" + f))
                    
                })
                
                directories.append(contentsOf: filepaths.filter { $0.isDirectory &&
                    ($0.depth <= test.maxDepth || test.maxDepth == -1) }) //? only add values less than the depth or -1 is infinite, then keep going
                
                print(filesToList.count)
                filesToList.append(contentsOf: filepaths)
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
                    VStack {
                        Image(nsImage: NSWorkspace.shared.icon(forFile: f.path))
                            .colorMultiply(.white.opacity(1.0 / Double(f.depth)))
                            .opacity(f.name.starts(with: ".") ? 0.2 : 1.0)
                        Text(f.name)//.foregroundColor(overWhat == fpaths.last! ? .green : .red)
                    }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding()
                        .overlay(overWhat == f.path ?
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
                            whatChosen = f.path
                            if f.isDirectory {
                                path = f.path
                                filesToList.removeAll()
                                getFiles()
                            } else {
                                print(f)
                                let task = Process()
                                task.executableURL = URL(fileURLWithPath: "/Applications/Visual Studio Code - Insiders.app")
                                task.arguments = [f.path]
                                do {
                                    try task.run()
                                } catch {
                                    print(error)
                                }
                                
                                let outputPipe = Pipe()
                                let errorPipe = Pipe()

                                task.standardOutput = outputPipe
                                task.standardError = errorPipe
                                
                                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                                
                                let output = String(decoding: outputData, as: UTF8.self)
                                let error = String(decoding: errorData, as: UTF8.self)
                                
                                print(output)
                                print(error)
                            }
                        }))
                        .background(KeyEventHandling().environmentObject(test))
                        .onHover { isOver in overWhat = isOver ? f.path : "" }
                        .help("Path: \(f.path)\nDepth: \(f.depth)")
                }
            }
            Text(String(test.pressure))
        }.onAppear(perform: {getFiles()}).environmentObject(test)
    }
}
