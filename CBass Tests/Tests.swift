//
//  Tests.swift
//  CBass Tests
//
//  Created by Treata Norouzi on 5/26/24.
//

import BassHLS
import SwiftUI

struct TestView: View {
    var body: some View {
        /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Hello, world!@*/Text("Hello, world!")/*@END_MENU_TOKEN@*/
            .onAppear {
                BASS_3DVECTOR()
            }
    }
}

#Preview {
    TestView()
}               
