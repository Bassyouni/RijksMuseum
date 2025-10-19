//
//  PieceCollectionViewCell.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import UIKit
import Kingfisher

final class PieceCollectionViewCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let creatorLabel = UILabel()
    private let dateLabel = UILabel()
    private let shimmerView = UIView()
    private let imageHeight: CGFloat = 300
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        titleLabel.text = nil
        creatorLabel.text = nil
        dateLabel.text = nil
        showShimmer()
    }
    
    private func setupViews() {
        backgroundColor = .systemBackground
        layer.cornerRadius = 8
        layer.masksToBounds = true
        
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 3
        titleLabel.textAlignment = .left
        
        creatorLabel.font = .systemFont(ofSize: 14, weight: .regular)
        creatorLabel.textColor = .secondaryLabel
        creatorLabel.numberOfLines = 1
        creatorLabel.textAlignment = .left
        
        dateLabel.font = .systemFont(ofSize: 12, weight: .regular)
        dateLabel.textColor = .tertiaryLabel
        dateLabel.numberOfLines = 1
        dateLabel.textAlignment = .left
        
        shimmerView.backgroundColor = .systemGray5
        shimmerView.layer.cornerRadius = 4
        shimmerView.isHidden = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(creatorLabel)
        contentView.addSubview(dateLabel)
        imageView.addSubview(shimmerView)
    }
    
    private func setupConstraints() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        creatorLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        shimmerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            contentView.widthAnchor.constraint(equalToConstant: currentScreenWidth),
            
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: imageHeight),
            
            shimmerView.topAnchor.constraint(equalTo: imageView.topAnchor),
            shimmerView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            shimmerView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            shimmerView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            creatorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            creatorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            creatorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            dateLabel.topAnchor.constraint(equalTo: creatorLabel.bottomAnchor, constant: 4),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with piece: Piece, imageResizer: IIIFImageResizer) {
        titleLabel.text = piece.title ?? "Unknown Title"
        creatorLabel.text = piece.creator ?? "Unknown Artist"
        dateLabel.text = piece.date ?? "Unknown Date"
        
        let imageURL = imageResizer.newImageURL(
            from: piece.imageURL,
            width: Int(currentScreenWidth),
            height: Int(imageHeight)
        )
        
        loadImage(from: imageURL)
    }
    
    private func loadImage(from url: URL?) {
        showShimmer()
        
        guard let url = url else {
            return imageView.image = nil
        }
        
        imageView.kf.setImage(
            with: url,
            placeholder: nil,
            options: [.transition(.fade(0.2)), .cacheOriginalImage]
        ) { [weak self] result in
            self?.hideShimmer()
        }
    }
    
    private func showShimmer() {
        shimmerView.isHidden = false
    }
    
    private func hideShimmer() {
        shimmerView.isHidden = true
    }
    
    private var currentScreenWidth: CGFloat {
        UIWindow.current?.bounds.width ?? 300
    }
}
