//
//  BottomSheet.swift
//  CardGenius
//
//  Interactive Bottom Sheet Component
//

import SwiftUI

struct BottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var isExpanded: Bool = false
    
    let collapsedHeight: CGFloat
    let expandedHeight: CGFloat
    let content: Content
    
    init(
        isPresented: Binding<Bool>,
        collapsedHeight: CGFloat = 120,
        expandedHeight: CGFloat = 500,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.collapsedHeight = collapsedHeight
        self.expandedHeight = expandedHeight
        self.content = content()
    }
    
    private var currentHeight: CGFloat {
        isExpanded ? expandedHeight : collapsedHeight
    }
    
    var body: some View {
        if isPresented {
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    // Drag Handle
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.cgSecondaryText.opacity(0.3))
                        .frame(width: 40, height: 5)
                        .padding(.top, Spacing.m)
                        .padding(.bottom, Spacing.s)
                    
                    content
                        .frame(height: currentHeight + dragOffset)
                        .frame(maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: Radius.xlarge)
                        .fill(.ultraThinMaterial)
                        .cgCardShadow()
                )
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newOffset = value.translation.height
                            if newOffset > 0 || isExpanded {
                                dragOffset = newOffset
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            if abs(value.translation.height) > threshold {
                                if value.translation.height > 0 {
                                    isExpanded = false
                                } else {
                                    isExpanded = true
                                }
                            }
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                dragOffset = 0
                            }
                        }
                )
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        }
    }
}

