//
//  ShimmerView.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import SwiftUI
import UIKit

private final class UIShimmerView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        startShimmering()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private var shimmerAnimationKey: String {
        return "shimmer"
    }
    
    private func startShimmering() {
        let white = UIColor.white.cgColor
        let alpha = UIColor.white.withAlphaComponent(0.75).cgColor
        let width = bounds.width
        let height = bounds.height
        
        let gradient = CAGradientLayer()
        gradient.colors = [alpha, white, alpha]
        gradient.startPoint = CGPoint(x: 0.0, y: 0.4)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.6)
        gradient.locations = [0.4, 0.5, 0.6]
        gradient.frame = CGRect(x: -width, y: 0, width: width*3, height: height)
        layer.mask = gradient
        
        let animation = CABasicAnimation(keyPath: #keyPath(CAGradientLayer.locations))
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]
        animation.duration = 1.25
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        gradient.add(animation, forKey: shimmerAnimationKey)
    }
    
    private func stopShimmering() {
        layer.mask = nil
    }
}

struct ShimmerView: UIViewRepresentable {
    
    let frame: CGRect
    
    init(frame: CGRect) {
        self.frame = frame
    }
 
    func makeUIView(context: Context) -> UIView {
        return UIShimmerView(frame: frame)
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ShimmerView(frame: CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height))
                }
            )
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}
