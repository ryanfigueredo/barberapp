//
//  UILabel+Extensions.swift
//  BarberApp
//

import UIKit

extension UILabel {
    func letterSpacing(_ spacing: CGFloat) {
        guard let text = text else { return }
        let attrs = NSAttributedString(string: text, attributes: [.kern: spacing])
        attributedText = attrs
    }
}
