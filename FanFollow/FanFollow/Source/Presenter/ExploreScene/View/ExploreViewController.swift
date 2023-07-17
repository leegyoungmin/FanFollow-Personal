//
//  ExploreViewController.swift
//  FanFollow
//
//  Created by parkhyo on 2023/07/17.
//

import UIKit
import RxSwift

final class ExploreViewController: UIViewController {
    // View Properties
    private let exploreCollectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewLayout()
    ).then {
        $0.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.reuseIdentifier)
        $0.register(CreatorCell.self, forCellWithReuseIdentifier: CreatorCell.reuseIdentifier)
        $0.backgroundColor = .clear
    }
    
    // Properties
    private let viewModel: ExploreViewModel
    private let disposeBag = DisposeBag()
    
    // Initializer
    init(viewModel: ExploreViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

// UICollectionView Layout Method
extension ExploreViewController {
    private func createCategorySection(item: NSCollectionLayoutItem) -> NSCollectionLayoutSection {
        let categoryGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalHeight(0.3),
            heightDimension: .fractionalHeight(0.5)
        )
        
        let categoryGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: categoryGroupSize,
            subitems: [item]
        )
        
        let categorySection = NSCollectionLayoutSection(group: categoryGroup)
        categorySection.interGroupSpacing = 10
        
        return categorySection
    }
    
    private func createCreatorSection(item: NSCollectionLayoutItem) -> NSCollectionLayoutSection {
        let creatorGroupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalHeight(0.3),
            heightDimension: .fractionalHeight(1.0)
        )
        
        let creatorGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: creatorGroupSize,
            subitems: [item]
        )
        
        let creatorSection = NSCollectionLayoutSection(group: creatorGroup)
        creatorSection.orthogonalScrollingBehavior = .continuous
        
        return creatorSection
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let commonItemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        
        let commonItem = NSCollectionLayoutItem(layoutSize: commonItemSize)
        
        let layout = UICollectionViewCompositionalLayout { sectionIndex, _ in
            return sectionIndex == .zero ?
            self.createCategorySection(item: commonItem) : self.createCreatorSection(item: commonItem)
        }
        
        return layout
    }
}
