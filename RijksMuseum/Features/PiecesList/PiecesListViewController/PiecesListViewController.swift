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
    private let imageResizer = IIIFImageResizer()
    
    private lazy var dataSource = createDataSource()
    
    init(viewModel: PiecesListViewModel) {
        self.viewModel = viewModel
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
    
    private func startObserving() {
        withObservationTracking {
            _ = viewModel.viewState
        } onChange: { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI(for: self?.viewModel.viewState ?? .idle)
                self?.startObserving()
            }
        }
        
        updateUI(for: viewModel.viewState)
    }
    
    private static func createLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        layout.footerReferenceSize = CGSize(width: 0, height: 60)
        return layout
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
        dataSource.apply(snapshot, animatingDifferences: true)
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
        
        let maxIndex = indexPaths.compactMap { $0.item }.max() ?? 0
        let threshold = pieces.count - 4
        
        if maxIndex >= threshold && !viewModel.isLoadingMore {
            Task {
                await viewModel.loadMore()
            }
        }
    }
}
