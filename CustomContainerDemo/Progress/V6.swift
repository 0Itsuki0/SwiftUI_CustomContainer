//
//  V6.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/28.
//

// move: drag and drop v1

import SwiftUI
import UniformTypeIdentifiers

struct SectionViewV6<Content: View, Data: MutableCollection>: View {
    @ViewBuilder var content: Content
      
    @Binding private var data: Data
    @State private var draggedId: Subview.ID?
    @State private var isTarget: Bool = false

    var body: some View {
        

        Group(subviews: content) { subviews in
            
            ForEach(subviews) { subview in

                CardView(
                    padding: CardView.defaultPadding,
                    background: {CardView.defaultBackground},
                    content: {subview}
                )
                .onDrag({
                    print("on Drag: \(subview.id)")
                    self.draggedId = subview.id
                    return NSItemProvider(object: String(describing: subview.id) as NSString)
                })
                .onDrop(of: [.text], isTargeted: $isTarget, perform: {providers in
                    print("on Drop")

                    guard let from = subviews.firstIndex(where: {$0.id == draggedId}), let to = subviews.firstIndex(where: {$0.id == subview.id}) else {
                        return false
                    }
                    data.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
                    return true
                })
                

            }
        }
    }
}


extension SectionViewV6 where Data == EmptyCollection<Any> {
    init<D: RandomAccessCollection, C: View>(_ data: D, @ViewBuilder content: @escaping (D.Element) -> C) where D.Element: Identifiable, Content == ForEach<D, D.Element.ID, C> {
        self.init (content: {
            ForEach(data, content: content)
        }, data: .constant(EmptyCollection<Any>()))
    }
    
    init<D: RandomAccessCollection,  ID : Hashable, C: View>(_ data: D, id: KeyPath<D.Element, ID>, @ViewBuilder content: @escaping (D.Element) -> C) where Content == ForEach<D, ID, C> {
        self.init (content: {
            ForEach(data, id: id,content: content)
        }, data: .constant(EmptyCollection<Any>()))

    }
}



extension SectionViewV6 {
    
    init<ID, RowContent>(
        _ data: Binding<Data>,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder rowContent: @escaping (Binding<Data.Element>) -> RowContent
    ) where
    Content == ForEach<IndexedIdentifierCollection<Data, ID>, ID, EditableCollectionContent<RowContent, Data>>,
    Data : MutableCollection,
    Data : RandomAccessCollection,
    ID : Hashable,
    RowContent : View,
    Data.Index : Hashable {

        self.init(content: {
            ForEach(data, id: id, editActions: .move, content: rowContent)
        }, data: data)

    }
}


struct V6TestView: View {
    
    @State var items = [0, 1, 2, 3, 4, 5, 6, 7]

    var body: some View {

        SectionViewV6($items, id: \.self) { $item in
            Text("Item: \(item)")
        }

        List($items, id: \.self, editActions: .move) { $item in
            Text("item: \(item)")
                .moveDisabled(item == 2)
        }
    }
}

#Preview {
    V6TestView()
}
