//
//  PiecesListViewController.swift
//  RijksMuseum
//
//  Created by Dionne Hallegraeff on 16/10/2025.
//

import UIKit

@MainActor
class PiecesListViewController: UICollectionViewController {
    
    private let viewModel: PiecesListViewModel
    private let imageResizer: IIIFImageResizer
    
    private lazy var dataSource = createDataSource()
    
    init(viewModel: PiecesListViewModel, imageResizer: IIIFImageResizer) {
        self.viewModel = viewModel
        self.imageResizer = imageResizer
        super.init(collectionViewLayout: Self.createLayout())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        startObserving()
        Task { await viewModel.loadData() }
    }
    
    private static func createLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(400)
        )
        
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
        
        let footerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(60)
        )
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: footerSize,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom
        )
        section.boundarySupplementaryItems = [footer]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
    private func setupViews() {
        title = "Rijksmuseum"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        
        collectionView.backgroundColor = .systemBackground
        collectionView.showsVerticalScrollIndicator = false
        
        collectionView.register(
            PieceCollectionViewCell.self,
            forCellWithReuseIdentifier: String(describing: PieceCollectionViewCell.self)
        )
        
        collectionView.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: String(describing: LoadingFooterView.self)
        )
        
        collectionView.dataSource = dataSource
        collectionView.prefetchDataSource = self
    }
    
    private func startObserving() {
        startObservingViewState()
        startObservingFooter()
        updateUI(for: viewModel.viewState)
    }
    
    private func startObservingViewState() {
        withObservationTracking {
            _ = viewModel.viewState
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI(for: self?.viewModel.viewState ?? .idle)
                self?.startObservingViewState()
            }
        }
    }
    
    private func startObservingFooter() {
        withObservationTracking {
            _ = viewModel.isLoadingMore
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateFooter()
                self?.startObservingFooter()
            }
        }
    }
    
    private func updateUI(for viewState: ViewState) {
        switch viewState {
        case .idle:
            contentUnavailableConfiguration = nil
            
        case .loading:
            var config = UIContentUnavailableConfiguration.loading()
            config.text = "Loading pieces..."
            contentUnavailableConfiguration = config
            
        case .loaded(let pieces):
            contentUnavailableConfiguration = nil
            applySnapshot(with: pieces)
            
        case .error(let message):
            var config = UIContentUnavailableConfiguration.empty()
            config.image = UIImage(systemName: "exclamationmark.triangle")
            config.text = message
            config.secondaryText = "Please try again"
            
            var buttonConfig = UIButton.Configuration.filled()
            buttonConfig.title = "Try Again"
            config.button = buttonConfig
            config.buttonProperties.primaryAction = UIAction { [weak self] _ in
                Task { await self?.viewModel.loadData() }
            }
            
            contentUnavailableConfiguration = config
        }
    }
    
    private func updateFooter() {
        let footerIndexPath = IndexPath(item: 0, section: 0)
        if let footerView = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: footerIndexPath) as? LoadingFooterView {
            footerView.configure(isLoading: viewModel.isLoadingMore)
        }
    }
}

// MARK: - UICollectionViewDiffableDataSource
private extension PiecesListViewController {
    typealias DataSource = UICollectionViewDiffableDataSource<Int, Piece>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Int, Piece>
    
    func createDataSource() -> DataSource {
        let dataSource = DataSource(collectionView: collectionView) { [weak self] collectionView, indexPath, piece in
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: String(describing: PieceCollectionViewCell.self),
                for: indexPath
            ) as? PieceCollectionViewCell
            
            guard let cell, let self else { return UICollectionViewCell() }
            
            cell.configure(with: piece, imageResizer: self.imageResizer)
            return cell
        }
        
        dataSource.supplementaryViewProvider = { [weak self] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionFooter else { return nil }
            
            let footerView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: String(describing: LoadingFooterView.self),
                for: indexPath
            ) as? LoadingFooterView
            
            footerView?.configure(isLoading: self?.viewModel.isLoadingMore ?? false)
            return footerView
        }
        
        return dataSource
    }
    
    func applySnapshot(with pieces: [Piece]) {
        var snapshot = Snapshot()
        snapshot.appendSections([0])
        snapshot.appendItems(pieces, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

// MARK: - UICollectionViewDelegate
extension PiecesListViewController {
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.onPieceSelected(at: indexPath.item)
    }
}


// MARK: - UICollectionViewDataSourcePrefetching
extension PiecesListViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard case .loaded(let pieces) = viewModel.viewState else { return }
        
        for indexPath in indexPaths {
            if indexPath.item >= pieces.count - 5 && !viewModel.isLoadingMore {
                Task { await viewModel.loadMore() }
                return
            }
        }
    }
}
