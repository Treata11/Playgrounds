//
//  CBass_TestsApp.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/21/24.
//

import SwiftUI

@main
struct CBass_TestsApp: App {
    @Bindable private var model = SimpleModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                //            SimpleModelView()
                MidiChooserView()
            }
            .environment(model)
        }
    }
}
