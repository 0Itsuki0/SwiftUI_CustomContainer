//
//  V7.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/29.
//

// move: drag and drop v2

import SwiftUI
import UniformTypeIdentifiers

struct SectionViewV7<Content: View>: View {

    @ViewBuilder var content: Content

    @State private var draggedView: Subview.ID?
    @State private var isTarget: Bool = false
    private var onDrop: ((Int, Int) -> Void)? = nil


    var body: some View {
        
        Group(subviews: content) { subviews in
            
            ForEach(subviews) { subview in
                
                let card = CardView(
                    padding: CardView.defaultPadding,
                    background: { CardView.defaultBackground },
                    content: { subview })
                
                if let onDrop {
                    card
                        .onDrag({
                            self.draggedView = subview.id
                            return NSItemProvider(object: String(describing: subview.id) as NSString)
                        })
                        .onDrop(of: [.text], isTargeted: $isTarget, perform: {providers in
                            guard let from = subviews.firstIndex(where: {$0.id == draggedView}), let to = subviews.firstIndex(where: {$0.id == subview.id}) else {
                                return false
                            }
                            onDrop(Int(from), Int(to))
                            return true
                        })
                } else {
                    card
                }
            }
        }
    }
}


extension SectionViewV7{
    
    init(@ViewBuilder _ content: () -> Content) {
        self.init(content: content)
    }
    
    init<D: RandomAccessCollection, C: View>(_ data: D, @ViewBuilder content: @escaping (D.Element) -> C) where D.Element: Identifiable, Content == ForEach<D, D.Element.ID, C> {
        self.init (content: {
            ForEach(data, content: content)
        })
    }
    
    init<D: RandomAccessCollection,  ID : Hashable, C: View>(_ data: D, id: KeyPath<D.Element, ID>, @ViewBuilder content: @escaping (D.Element) -> C) where Content == ForEach<D, ID, C> {
        self.init (content: {
            ForEach(data, id: id,content: content)
        })

    }
    
    init<D, ID, RowContent>(
        _ data: Binding<D>,
        id: KeyPath<D.Element, ID>,
        @ViewBuilder rowContent: @escaping (Binding<D.Element>) -> RowContent
    ) where
    Content == ForEach<LazyMapSequence<D.Indices, (D.Index, ID)>, ID, RowContent>,
    D : MutableCollection,
    D : RandomAccessCollection,
    ID : Hashable,
    RowContent : View,
    D.Index : Hashable {
        
        self.init(content: {
            ForEach(data, id: id) { $item in
                rowContent($item)
            }
        }, onDrop: { from, to in
            data.wrappedValue.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
        })
    }
}




struct V7TestView: View {
    
    @State var items = [0, 1, 2, 3, 4, 5, 6, 7]

    var body: some View {
        SectionViewV7($items, id: \.self) { $item in
            Text("movable: \(item)")
        }
    }

}

#Preview {
    V7TestView()
}
