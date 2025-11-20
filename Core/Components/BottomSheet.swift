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
            ZStack {
                // Dimmed background overlay
                Color.black.opacity(isExpanded ? 0.3 : 0.1)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    VStack(spacing: 0) {
                        // Enhanced Drag Handle with glass effect
                        ZStack {
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .frame(width: 48, height: 6)
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 48, height: 6)
                            
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.5), lineWidth: 0.5)
                                .frame(width: 48, height: 6)
                        }
                        .padding(.top, Spacing.m)
                        .padding(.bottom, Spacing.m)
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                        
                        content
                            .frame(height: currentHeight + dragOffset)
                            .frame(maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity)
                    .background(
                        ZStack {
                            // Base material layer
                            RoundedRectangle(cornerRadius: Radius.xlarge)
                                .fill(.thinMaterial)
                            
                            // Gradient overlay for depth
                            RoundedRectangle(cornerRadius: Radius.xlarge)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.cgGlassLight,
                                            Color.clear,
                                            Color.cgGlassDark.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Glass border highlight
                            RoundedRectangle(cornerRadius: Radius.xlarge)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.6),
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        }
                    )
                    .shadow(color: .black.opacity(0.2), radius: 30, x: 0, y: -10)
                    .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: -5)
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
                                        if value.translation.height > 150 {
                                            isPresented = false
                                        } else {
                                            isExpanded = false
                                        }
                                    } else {
                                        isExpanded = true
                                    }
                                }
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                    )
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
        }
    }
}

