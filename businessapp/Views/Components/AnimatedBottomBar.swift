import SwiftUI

struct AnimatedBottomBar<LeadingAction: View, TrailingAction: View, MainAction: View>: View {
    var highlightWhenEmpty: Bool = true
    var hint: String
    var tint: Color = .green
    @Binding var text: String
    @FocusState.Binding var isFocused: Bool
    @ViewBuilder var leadingAction: () -> LeadingAction
    @ViewBuilder var trailingAction: () -> TrailingAction
    @ViewBuilder var mainAction: () -> MainAction
    @State private var isHighlighting: Bool = false
    
    var body: some View {
        let mainLayout = isFocused ? AnyLayout(ZStackLayout(alignment: .bottomTrailing)) :
        AnyLayout(HStackLayout(alignment: .bottom, spacing: 10))
        let shape = RoundedRectangle(cornerRadius: isFocused ? 25 : 30)
        
        ZStack {
            mainLayout {
                let subLayout = isFocused ? AnyLayout(VStackLayout(alignment: .trailing, spacing: 20)) : AnyLayout(ZStackLayout(alignment: .trailing))
                subLayout {
                    TextField(hint, text: $text, axis: .vertical)
                        .lineLimit(5)
                        .focused($isFocused)
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 10) {
                            if #available(iOS 18.0, *) {
                                ForEach(subviews: leadingAction()) { subview in
                                    subview
                                        .frame(width: 35, height: 35)
                                        .contentShape(.rect)
                                }
                            } else {
                                leadingAction()
                            }
                        }
                        .compositingGroup()
                        .allowsHitTesting(isFocused)
                        .blur(radius: isFocused ? 0 : 6)
                        .opacity(isFocused ? 1 : 0)
                        
                        Spacer(minLength: 0)
                        
                        trailingAction()
                            .frame(width: 35, height: 35)
                            .contentShape(.rect)
                    }
                }
                .frame(height: isFocused ? nil : 55)
                .padding(.leading, 15)
                .padding(.trailing, isFocused ? 15 : 10)
                .padding(.bottom, isFocused ? 10 : 0)
                .padding(.top, isFocused ? 20 : 0)
                .background {
                    ZStack {
                        HighlightingBackgroundView()
                        shape
                            .fill(Color.white)
                            .overlay(
                                shape
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .clipShape(shape)
                }
                
                mainAction()
                    .frame(width: 50, height: 50)
                    .background {
                        Circle()
                            .fill(Color.white)
                            .overlay(
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    .clipShape(.circle)
                    .modifier(MainActionOffsetModifier(isFocused: isFocused))
            }
        }
        .modifier(GeometryGroupIfAvailable())
        .animation(.easeInOut(duration: animationDuration), value: isFocused)
    }
    
    @ViewBuilder
    private func HighlightingBackgroundView() -> some View {
        ZStack {
            let shape = RoundedRectangle(cornerRadius: isFocused ? 25 : 30)
            if !isFocused && text.isEmpty && highlightWhenEmpty {
                let clearColors: [Color] = Array(repeating: .clear, count: 1)
                shape
                    .stroke(
                        tint.gradient,
                        style: .init(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .mask {
                        shape
                            .fill(AngularGradient(
                                colors: clearColors + [Color.white] + clearColors,
                                center: .center,
                                angle: .init(degrees: isHighlighting ? 360 : 0)
                            ))
                    }
                    .padding(-2)
                    .blur(radius: 2)
                    .onAppear {
                        withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                            isHighlighting = true
                        }
                    }
                    .onDisappear {
                        isHighlighting = false
                    }
                    .modifier(BlurReplaceTransitionIfAvailable())
            }
        }
    }
    
    var animationDuration: CGFloat {
        if #available(iOS 26, *) {
            return 0.22
        } else {
            return 0.33
        }
    }
}

private struct GeometryGroupIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.geometryGroup()
        } else {
            content
        }
    }
}

private struct BlurReplaceTransitionIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.transition(.blurReplace)
        } else {
            content.transition(.opacity)
        }
    }
}

private struct MainActionOffsetModifier: ViewModifier {
    let isFocused: Bool
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.visualEffect { [isFocused] content, proxy in
                content
                    .offset(x: isFocused ? (proxy.size.width + 30) : 0)
            }
        } else {
            content.offset(x: isFocused ? 80 : 0)
        }
    }
}
