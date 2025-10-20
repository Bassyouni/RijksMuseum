//
//  PiecesDetailsView.swift
//  RijksMuseum
//
//  Created by Omar Bassyouni on 19/10/2025.
//

import SwiftUI

struct PiecesDetailsView: View {
    
    let piece: Piece
    let imageResizer: IIIFImageResizer
    
    private let headerHeight: CGFloat = 300
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerImageView
                contentView
            }
        }
        .ignoresSafeArea(edges: .top)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    private var headerImageView: some View {
        GeometryReader { geometry in
            AsyncImage(url: imageURL(for: geometry)) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: headerHeight)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: geometry.size.width, height: headerHeight)
                    .shimmer()
            }
            .stretchy()
        }
        .frame(height: headerHeight)
    }
    
    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                if let title = piece.title {
                    Text(title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.leading)
                }
                
                if let creator = piece.creator {
                    Text(creator)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                
                if let date = piece.date {
                    Text(date)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer(minLength: 100)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func imageURL(for geometry: GeometryProxy) -> URL? {
        imageResizer.newImageURL(
            from: piece.imageURL,
            width: Int(geometry.size.width),
            height: Int(headerHeight)
        )
    }
}

#Preview {
    NavigationView {
        PiecesDetailsView(
            piece: Piece(
                id: "1",
                title: "The Night Watch",
                date: "1642",
                creator: "Rembrandt van Rijn",
                imageURL: URL(string: "https://iiif.micr.io/qcYVp/full/max/0/default.jpg")
            ),
            imageResizer: IIIFImageResizer()
        )
    }
}
