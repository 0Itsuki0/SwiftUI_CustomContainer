//
//  V2.swift
//  ItsukiBoard
//
//  Created by Itsuki on 2024/09/26.
//

// using ForEach subview

import SwiftUI

struct SectionViewV2<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ForEach(subviews: content) { subview in
            CardView(padding: CardView.defaultPadding,
                     background: {
                CardView.defaultBackground
            }, content: {
                subview
            })
        }
    }
}

extension SectionViewV2 {
    init<Data: RandomAccessCollection, C: View>(_ data: Data, @ViewBuilder content: @escaping (Data.Element) -> C) where Data.Element: Identifiable, Content == ForEach<Data, Data.Element.ID, C> {
        self.init {
            ForEach(data, content: content)
        }
    }
    
    init<Data: RandomAccessCollection,  ID : Hashable, C: View>(_ data: Data, id: KeyPath<Data.Element, ID>, @ViewBuilder content: @escaping (Data.Element) -> C) where Content == ForEach<Data, ID, C> {
        self.init {
            ForEach(data, id: id, content: content)
        }
    }
}

#Preview {
    let items = [1, 2, 3]
    SectionViewV2 {
        ForEach(items, id:\.self) { item in
            Text("item: \(item)")
        }
        
        Text("some other stuff")
    }
    
    SectionViewV2(items, id: \.self) { item in
        Text("item: \(item)")
    }
}

