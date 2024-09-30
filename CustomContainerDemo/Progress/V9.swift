//
//  V9.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/29.
//


// section view: editable (delete & move)

import SwiftUI
import UniformTypeIdentifiers

struct SectionViewV9<Content: View>: View {

    @ViewBuilder var content: Content

    @State private var draggedView: Subview.ID?
    @State private var isTarget: Bool = false
    private var onDrop: ((Int, Int) -> Void)? = nil
    private var onDelete: ((Int) -> Void)? = nil

    var body: some View {
        
        Group(subviews: content) { subviews in
            let subviewArray: [Subview] = Array(subviews)

            ForEach(subviewArray) { subview in
                
                let index = subviews.firstIndex(where: {$0.id == subview.id})

                let onDelete: (() -> Void)? = if let index, let onDelete {
                    {onDelete(index)}
                } else { nil }
                
                let card = CardView(
                    padding: CardView.defaultPadding,
                    background: { CardView.defaultBackground },
                    content: { subview },
                    onDelete: onDelete
                )
                
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


extension SectionViewV9{
    
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
        editActions: EditActions<D> = .all,
        @ViewBuilder rowContent: @escaping (Binding<D.Element>) -> RowContent
    ) where
    Content == ForEach<LazyMapSequence<D.Indices, (D.Index, ID)>, ID, RowContent>,
    D : MutableCollection,
    D : RandomAccessCollection,
    D : RangeReplaceableCollection,
    ID : Hashable,
    RowContent : View,
    D.Index : Hashable {
        
        let onDelete: ((Int) -> Void)? = if editActions.contains(.delete) {
            { index in
                withAnimation {
                    data.wrappedValue.remove(atOffsets: IndexSet(integer: index))
                }
            }
        } else {
            nil
        }
        
        self.init(content: {
            ForEach(data, id: id) { $item in
                rowContent($item)
            }
        }, onDrop: { from, to in
            data.wrappedValue.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
        }, onDelete: onDelete)
    }
}




struct V9TestView: View {
    
    @State var items = [0, 1, 2, 3, 4, 5, 6, 7]

    var body: some View {
        SectionViewV9($items, id: \.self, editActions: .delete) { $item in
            Text("movable: \(item)")
        }
    }

}

#Preview {
    V9TestView()
}
