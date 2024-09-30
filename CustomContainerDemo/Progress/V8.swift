//
//  V8.swift
//  CustomContainerDemo
//
//  Created by Itsuki on 2024/09/29.
//

// Board view with drag and drop

import SwiftUI
import UniformTypeIdentifiers

struct BoardViewV8<Content: View>: View {

    var title: String? = nil
    
    var padding: (Edge.Set, CGFloat) = (.all, 48)
    var sectionSpacing: CGFloat = 24

    var backgroundColor: Color = .gray
    var backgroundStrokeStyle: StrokeStyle = .init(lineWidth: 1)
    
    @ViewBuilder var content: Content

    private var onDrop: ((Int, Int) -> Void)? = nil

    var body: some View {
        Group(sections: content) { sections in
            HStack(spacing: sectionSpacing) {
                ForEach(sections) { section in
                    let values = section.containerValues
                    SectionViewV8(
                        header: section.header,
                        footer: section.footer,
                        content: section.content,
                        onDrop: onDrop,
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

extension BoardViewV8 {
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


fileprivate struct SectionViewV8<MoreButtonLabel: View, HideButtonLabel: View>: View {
    
    var header: SubviewsCollection
    var footer: SubviewsCollection
    var content: SubviewsCollection
    
    var onDrop: ((Int, Int) -> Void)? = nil
    
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
                
                let card = CardView(
                    padding: padding,
                    background: {background},
                    content: {
                        subview
                            .frame(maxWidth: .infinity)
                    })
                
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

extension SectionViewV8 where MoreButtonLabel == Never, HideButtonLabel == Never {
    
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
    @Entry var sectionPadding: (horizontal: CGFloat, vertical: CGFloat) = SectionViewV8.defaultPadding
    @Entry var itemSpacing: CGFloat = SectionViewV8.defaultItemSpacing
    @Entry var sectionWidth: CGFloat? = SectionViewV8.defaultSectionWidth
    @Entry var sectionBackgroundStyle: (color: Color, strokeStyle: StrokeStyle) = SectionViewV8.defaultBackgroundStyle
    
    @Entry var maxItemCount: Int? = SectionViewV8.defaultMaxItemCount
    @Entry var moreButtonLabel: AnyView = AnyView(SectionViewV8.defaultMoreButtonLabel)
    @Entry var hideButtonLabel: AnyView = AnyView(SectionViewV8.defaultHideButtonLabel)
    @Entry var toggleAnimation: Animation = SectionViewV8.defaultAnimation
    
    // drag and drop
    @Entry var itemMoveDisabled: Bool = false
    @Entry var movable: ((Int, Int) -> Void)? = nil
    
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

}



struct V8ContentView: View {
    @State var items = [0, 1, 2, 3, 4, 5, 6, 7]

    var body: some View {
        
        // drag and drop disabled for specific item
        BoardViewV8($items, id: \.self) { $item in
            Text("Item: \(item)")
                .itemMoveDisabled(item == 2)
        }

        
        // drag and drop for individual section
        BoardViewV8 {
            Section {
                ForEach(items, id: \.self) { item in
                    Text("item: \(item)")
                }
            }
            .movable(perform: { from, to in
                items.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
            })
            
            Section {
                ForEach(items, id: \.self) { item in
                    Text("item: \(item)")
                }
                .movable(perform: { from, to in
                    items.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
                })
            }

            ForEach(items, id: \.self) { item in
                Text("item: \(item)")
            }
            .movable(perform: { from, to in
                items.move(fromOffsets: IndexSet(integer: from), toOffset: Int((to > from ? (to + 1) : to)))
            })
        }
        
        // Custom move action
        HStack {
            BoardViewV8($items, id: \.self) { $item in
                Text("Item: \(item)")
                    .movable(perform: { from, to in
                        items.move(fromOffsets: IndexSet(integer: from), toOffset: 0)
                    })
            }
            
            BoardViewV8 {
                Section {
                    ForEach(items, id: \.self) { item in
                        Text("item: \(item)")
                    }
                }
                .movable(perform: { from, to in
                    items.move(fromOffsets: IndexSet(integer: from), toOffset: 0)
                })
            }
        }
    }
}


#Preview {
    V8ContentView()
}
