//
//  ContentView.swift
//  A
//
//  Created by Pavel Yakimenko on 30/03/2022.
//

import SwiftUI
import RealmSwift
import BackgroundTasks

class AppProperty: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) var app: String
    @Persisted var values: RealmSwift.List<Dog>
}

class Dog: Object {
    @Persisted(primaryKey: true) var id = ObjectId.generate()
    @Persisted var name = UUID().uuidString
}

class Base {
    
    static let shared = Base()
    let timer: Timer
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            Base.shared.addObjects()
        }
    }

    private var notificationTokens = Set<NotificationToken>()
    
    private let queue = DispatchQueue(label: "listenerQueue", qos: .userInitiated)
    
    let config: Realm.Configuration = {
        let fileURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.io.realm.test")!
            .appendingPathComponent("default.realm")
        let config = Realm.Configuration(fileURL: fileURL)
        return config
    }()
    
    func addObjects() {
        let realm = try! Realm(configuration: config)
        
        guard let bundleName = Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String else {
            exit(1)
        }
        let appThings: AppProperty
        if let existing = realm.objects(AppProperty.self).where({ $0.app == bundleName }).first {
            appThings = existing
        } else {
            appThings = try! realm.write { realm.create(AppProperty.self, value: [bundleName])
            }
        }

        try! realm.write {
            appThings.values.append(Dog())
        }
    }
}

struct ContentView: View {
    @ObservedResults(AppProperty.self, configuration: Base.shared.config) var appsData

    func bundleName() -> String {
        Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String ?? "Undef"
    }
    
    var body: some View {
        VStack {
            Text(" This is \(bundleName()).app")
                .padding()
            List {
                ForEach(appsData) { ad in
                    Text("\(ad.app) - \(ad.values.count)")
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
