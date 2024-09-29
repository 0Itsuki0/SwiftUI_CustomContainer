//
//  V1.swift
//  ItsukiBoard
//
//  Created by Itsuki on 2024/09/26.
//

// using random collection

import SwiftUI

struct SectionViewV1<Data: RandomAccessCollection, ID : Hashable, Content: View>: View {
    var data: Data
    var id: KeyPath<Data.Element, ID>
    @ViewBuilder var content: (Data.Element) -> Content

    
    var body: some View {
        ForEach(data, id: id) { item in
            CardView(
                padding: CardView.defaultPadding,
                background: {
                CardView.defaultBackground
            }, content: {
                content(item)
            })
        }
    }
}

#Preview {
    let items = [1, 2, 3]
    SectionViewV1(data: items, id: \.self) { item in
        Text("item: \(item)")
    }
}
