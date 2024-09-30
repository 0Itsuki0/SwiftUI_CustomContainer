//
//  V10.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/30.
//

// Board view: editable (drag, drop, delete)

import SwiftUI
import UniformTypeIdentifiers

struct BoardViewV10<Content: View>: View {

    var title: String? = nil
    
    var padding: (Edge.Set, CGFloat) = (.all, 48)
    var sectionSpacing: CGFloat = 24

    var backgroundColor: Color = .gray
    var backgroundStrokeStyle: StrokeStyle = .init(lineWidth: 1)
    
    @ViewBuilder var content: Content

    private var onDrop: ((Int, Int) -> Void)? = nil
    private var onDelete: ((Int) -> Void)? = nil

    var body: some View {
        Group(sections: content) { sections in
            HStack(spacing: sectionSpacing) {
                ForEach(sections) { section in
                    let values = section.containerValues
                    SectionViewV10(
                        header: section.header,
                        footer: section.footer,
                        content: section.content,
                        onDrop: onDrop,
                        onDelete: onDelete,
                        padding: values.sectionPadding,
                        itemSpacing: values.itemSpacing,
                        sectionWidth: values.sectionWidth,
                        backgroundStyle: values.sectionBackgroundStyle,
                        maxItemCount: values.maxItemCount,
                        moreButtonLabel: {values.moreButtonLabel},
                        hideButtonLabel:  {values.hideButtonLabel},
                        toggleAnimation: values.toggleAnimation

                    )
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(padding.0, padding.1)
            .background(background())

        }

    }
    
    private func background(isTitle: Bool = false) ->  some View {
        let backgroundShape = RoundedRectangle(cornerRadius: 8)
        
        return ZStack {
            backgroundShape
                .inset(by: 2)
                .fill(backgroundColor.opacity(0.3))
            backgroundShape
                .stroke(backgroundColor.opacity(0.8), style: backgroundStrokeStyle)
        }
        .background(
            .white.shadow(.drop(
                color: backgroundColor.opacity(0.3),
                radius: 1, x: 1, y: 2)),
            in: backgroundShape)
    }
}

extension BoardViewV10 {
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
    
    init(@ViewBuilder _ content: () -> Content) {
        self.init(content: content)
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
        
        let onDelete: ((Int) -> Void)? = if editActions.contains(.delete) {{ index in
            withAnimation {
                data.wrappedValue.remove(atOffsets: IndexSet(integer: index))
            }
        }} else { nil }
        
        let onDrop: ((Int, Int) -> Void)? = if editActions.contains(.move) {{ from, to in
            data.wrappedValue.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
        }} else { nil }
        
        self.init(content: {
            ForEach(data, id: id) { $item in
                rowContent($item)
            }
        }, onDrop: onDrop, onDelete: onDelete)
    }
}


fileprivate struct SectionViewV10<MoreButtonLabel: View, HideButtonLabel: View>: View {
    
    var header: SubviewsCollection
    var footer: SubviewsCollection
    var content: SubviewsCollection
    
    var onDrop: ((Int, Int) -> Void)? = nil
    var onDelete: ((Int) -> Void)? = nil

    var padding: (horizontal: CGFloat, vertical: CGFloat)

    var itemSpacing: CGFloat
    var sectionWidth: CGFloat?
    
    var backgroundStyle: (color: Color, strokeStyle: StrokeStyle)
    
    var maxItemCount: Int?
    @ViewBuilder var moreButtonLabel: MoreButtonLabel
    @ViewBuilder var hideButtonLabel: HideButtonLabel
    var toggleAnimation: Animation
    
    @State private var draggedView: Subview.ID?
    @State private var isTarget: Bool = false
    @State private var isExpanded: Bool = false
    
    var body: some View {
        let moreItemsAvailable = if let maxItemCount = maxItemCount, content.count > maxItemCount {
            true
        } else {
            false
        }

        let newSubviews = if let maxItemCount = maxItemCount, moreItemsAvailable, !isExpanded {
            Array(content.prefix(maxItemCount))
        } else {
            Array(content)
        }
        
        VStack(spacing: itemSpacing) {
            if !header.isEmpty {
                headerView()
            } else {
                Spacer().frame(height: padding.vertical)
            }

            ForEach(newSubviews) { subview in
                let values = subview.containerValues
                let background = values.cardBackground
                let padding = values.cardPadding
                let moveDisabled = values.itemMoveDisabled
                let movable = values.movable
                let deleteDisable = values.itemDeleteDisable
                let deletable = values.deletable
                
                let index = content.firstIndex(where: {$0.id == subview.id})

                let onDelete: (() -> Void)? = if (onDelete != nil || deletable != nil) && !deleteDisable {
                    if let index, let deletable {{deletable(index)}}
                    else if let index, let onDelete {{onDelete(index)}}
                    else { nil }
                } else { nil }

                
                
                let card = CardView(
                    padding: padding,
                    background: {background},
                    content: {
                        subview
                            .frame(maxWidth: .infinity)
                    },
                    onDelete: onDelete
                )
                
                if (onDrop != nil || movable != nil) && !moveDisabled {
                    card
                        .onDrag({
                            self.draggedView = subview.id
                            return NSItemProvider(object: String(describing: subview.id) as NSString)
                        })
                        .onDrop(of: [.text], isTargeted: $isTarget, perform: {providers in
                            guard let from = content.firstIndex(where: {$0.id == draggedView}), let to = content.firstIndex(where: {$0.id == subview.id}) else {
                                return false
                            }
                            
                            // prioritize custom action
                            if let movable {
                                movable(Int(from), Int(to))
                            } else if let onDrop {
                                onDrop(Int(from), Int(to))
                            }
                            return true
                        })
                    
                } else {
                    card
                }
                
                
            }
            .padding(.horizontal, padding.horizontal)
            
            if moreItemsAvailable {
                Button(action: {
                    isExpanded.toggle()
                }, label: {
                    if isExpanded {
                        hideButtonLabel
                    } else {
                        moreButtonLabel
                    }
                })
            }
            
            if !footer.isEmpty {
                footerView()
            } else {
                Spacer().frame(height: padding.vertical)
            }

        }
        .animation(toggleAnimation, value: isExpanded)
        .frame(width: sectionWidth)
        .frame(alignment: .top)
        .background(background())
        
    }
    
    private func background(isHeaderFooter: Bool = false) ->  some View {
        let backgroundShape = RoundedRectangle(cornerRadius: 8)
        
        return ZStack {
            backgroundShape
                .inset(by: 2)
                .fill(backgroundStyle.color.opacity(isHeaderFooter ? 0.6 : 0.3))
            backgroundShape
                .stroke(backgroundStyle.color.opacity(0.8), style: backgroundStyle.strokeStyle)
        }
        .background(
            .white.shadow(.drop(
                color: backgroundStyle.color.opacity(0.3),
                radius: 1, x: 1, y: 2)),
            in: backgroundShape)
    }
    
    func headerView() -> some View {
        header
            .padding(.all, 16)
            .frame(maxWidth: .infinity)
            .background(background(isHeaderFooter: true))
    }
    
    func footerView() -> some View {
        footer
            .padding(.all, 16)
            .frame(maxWidth: .infinity)
            .background(background(isHeaderFooter: true))
    }
}

extension SectionViewV10 where MoreButtonLabel == Never, HideButtonLabel == Never {
    
    static var defaultPadding: (horizontal: CGFloat, vertical: CGFloat) = (24, 24)
    static var defaultItemSpacing: CGFloat = 16
    static var defaultSectionWidth: CGFloat? = 240.0
    
    static var defaultBackgroundStyle: (color: Color, strokeStyle: StrokeStyle) = (.brown, .init(lineWidth: 1))
    
    static var defaultMoreButtonLabel: some View {
        Text("More")
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 8).fill(.black))
    }
    
    static var defaultHideButtonLabel: some View {
        Text("Hide")
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 8).fill(.black))
    }
    
    static var defaultMaxItemCount: Int? = nil
    static var defaultAnimation: Animation = .default

}


fileprivate extension ContainerValues {
    
    // section View
    @Entry var sectionPadding: (horizontal: CGFloat, vertical: CGFloat) = SectionViewV10.defaultPadding
    @Entry var itemSpacing: CGFloat = SectionViewV10.defaultItemSpacing
    @Entry var sectionWidth: CGFloat? = SectionViewV10.defaultSectionWidth
    @Entry var sectionBackgroundStyle: (color: Color, strokeStyle: StrokeStyle) = SectionViewV10.defaultBackgroundStyle
    
    @Entry var maxItemCount: Int? = SectionViewV10.defaultMaxItemCount
    @Entry var moreButtonLabel: AnyView = AnyView(SectionViewV10.defaultMoreButtonLabel)
    @Entry var hideButtonLabel: AnyView = AnyView(SectionViewV10.defaultHideButtonLabel)
    @Entry var toggleAnimation: Animation = SectionViewV10.defaultAnimation
    
    // drag and drop
    @Entry var itemMoveDisabled: Bool = false
    @Entry var movable: ((Int, Int) -> Void)? = nil
    
    // delete
    @Entry var itemDeleteDisable: Bool = false
    @Entry var deletable: ((Int) -> Void)? = nil

    
}



fileprivate extension View {
    
    // section view
    func sectionPadding(_ horizontal: CGFloat, _ vertical: CGFloat) -> some View {
        containerValue(\.sectionPadding, (horizontal, vertical))
    }
    
    func itemSpacing(_ spacing: CGFloat) -> some View {
        containerValue(\.itemSpacing, spacing)
    }
    
    func sectionWidth(_ width: CGFloat?) -> some View {
        containerValue(\.sectionWidth, width)
    }
    
    func sectionBackgroundStyle(_ color: Color, _ strokeStyle: StrokeStyle) -> some View {
        containerValue(\.sectionBackgroundStyle, (color, strokeStyle))
    }


    func maxItemCount(_ count: Int?) -> some View {
        containerValue(\.maxItemCount, count)
    }
    
    func moreButtonLabel<V>(@ViewBuilder _ view: () -> V) -> some View where V : View {
        containerValue(\.moreButtonLabel, AnyView(view()))
    }
    
    func hideButtonLabel<V>(@ViewBuilder _ view: () -> V) -> some View where V : View {
        containerValue(\.hideButtonLabel, AnyView(view()))
    }
    
    func toggleAnimation(_ animation: Animation) -> some View {
        containerValue(\.toggleAnimation, animation)
    }
    
    // drag and drop
    func itemMoveDisabled(_ isDisabled: Bool = false) -> some View {
        containerValue(\.itemMoveDisabled, isDisabled)
    }
    
    func movable(perform action: Optional<(Int, Int) -> Void>) -> some View {
        containerValue(\.movable, action)
    }
    
    // delete
    func itemDeleteDisabled(_ isDisabled: Bool = false) -> some View {
        containerValue(\.itemDeleteDisable, isDisabled)
    }
    
    func deletable(perform action: Optional<(Int) -> Void>) -> some View {
        containerValue(\.deletable, action)
    }
}



struct V10ContentView: View {
    @State var items = [0, 1, 2, 3, 4, 5, 6, 7]

    var body: some View {
        
    
        // initializing directly from the initializer.
        // drag and drop, delete disabled for specific item
        HStack {
            
            // all actions
            BoardViewV10($items, id: \.self, editActions: .all, rowContent: { $item in
                Text("Item: \(item)")
                    .itemDeleteDisabled(item == 2)
                    .itemMoveDisabled(item == 5)
            })
            .frame(maxHeight: .infinity, alignment: .top)

            
            // move (drag and drop) only
            BoardViewV10($items, id: \.self, editActions: .move, rowContent: { $item in
                Text("Item: \(item)")
                    .itemDeleteDisabled(item == 2)
                    .itemMoveDisabled(item == 5)
            })
            .frame(maxHeight: .infinity, alignment: .top)

            
            // delete only
            BoardViewV10($items, id: \.self, editActions: .delete, rowContent: { $item in
                Text("Item: \(item)")
                    .itemDeleteDisabled(item == 2)
                    .itemMoveDisabled(item == 5)
            })
            .frame(maxHeight: .infinity, alignment: .top)

        }

        
        // drag and drop, delete for individual section
        BoardViewV10 {
            Section {
                ForEach(items, id: \.self) { item in
                    Text("item: \(item)")
                }
            } header: {
                Text("movable")
            }
            .movable(perform: { from, to in
                items.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
            })
            
            Section {
                ForEach(items, id: \.self) { item in
                    Text("item: \(item)")
                }
                .deletable(perform: { index in
                    withAnimation {
                        items.remove(atOffsets: IndexSet(integer: index))
                    }
                })
            } header: {
                Text("deletable")
            }

            
            ForEach(items, id: \.self) { item in
                Text("item: \(item)")
            }
            .movable(perform: { from, to in
                items.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
            })
            .deletable(perform: { index in
                withAnimation {
                    items.remove(atOffsets: IndexSet(integer: index))
                }
            })
        }
        
        // Custom editable action
        HStack {
            
            // with initializer: always move the item to the top + a bouncy delete animation
            BoardViewV10($items, id: \.self) { $item in
                Text("Item: \(item)")
                    .movable(perform: { from, to in
                        items.move(fromOffsets: IndexSet(integer: from), toOffset: 0)
                    })
                    .deletable(perform: { index in
                        withAnimation(.bouncy(extraBounce: 0.3)) {
                            items.remove(atOffsets: IndexSet(integer: index))
                        }
                    })
            }
            
            // with section: re-sort the list after delete
            BoardViewV10 {
                Section {
                    ForEach(items, id: \.self) { item in
                        Text("item: \(item)")
                    }
                } header: {
                    Text("sort after delete")
                }
                .movable(perform: { from, to in
                    items.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
                })
                .deletable(perform: { index in
                    withAnimation {
                        items.remove(atOffsets: IndexSet(integer: index))
                        items.sort(by: {$0<$1})
                    }
                })
            }
        }
    }
}


#Preview {
    V10ContentView()
}
