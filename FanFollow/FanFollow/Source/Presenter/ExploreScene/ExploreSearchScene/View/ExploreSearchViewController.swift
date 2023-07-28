//
//  ExploreSearchViewController.swift
//  FanFollow
//
//  Created by parkhyo on 2023/07/23.
//

import UIKit
import RxSwift
import RxRelay

final class ExploreSearchViewController: UIViewController {
    // View Properties
    private let backButton = UIButton().then {
        $0.tintColor = UIColor(named: "AccentColor")
        $0.setImage(UIImage(systemName: Constants.backImage), for: .normal)
    }
    
    private let searchBar = UISearchBar().then {
        $0.layer.borderWidth = 1
        $0.layer.borderColor = UIColor.systemBackground.cgColor
        $0.barTintColor = .systemBackground
        $0.layer.cornerRadius = 10
        $0.clipsToBounds = true
        $0.tintColor = .systemGray
        $0.searchTextField.textColor = .label
        $0.searchTextField.clearButtonMode = .whileEditing
        $0.searchTextField.leftView?.tintColor = .white
        $0.searchTextField.backgroundColor = .systemGray4
        $0.setImage(UIImage(systemName: Constants.clearImage), for: .clear, state: .normal)
        $0.searchTextField.attributedPlaceholder = NSAttributedString(
            string: Constants.searchPlaceHolder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )
    }
    
    private let searchTableView = UITableView(frame: .zero, style: .plain).then {
        $0.separatorColor = .lightGray
        $0.backgroundColor = .clear
        $0.register(CreatorListCell.self, forCellReuseIdentifier: CreatorListCell.reuseIdentifier)
    }
    
    private let searchLabel = UILabel().then {
        $0.textColor = .label
        $0.textAlignment = .center
    }
    
    // Properties
    weak var coordinator: ExploreCoordinator?
    private let viewModel: ExploreSearchViewModel
    private let disposeBag = DisposeBag()
    private var isLoading = BehaviorRelay<Bool>(value: false)
    
    // Initializer
    init(viewModel: ExploreSearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
        binding()
    }
}

// Binding
extension ExploreSearchViewController: UISearchBarDelegate {
    func binding() {
        let output = bindingInput()
        
        bindBackButton()
        bindSearchBar()
        bindTableView(output)
    }
    
    private func bindBackButton() {
        backButton.rx.tap
            .bind {
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindSearchBar() {
        searchBar.rx.text
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: "")
            .map {
                $0.isEmpty ? Constants.noSearch : Constants.noSearchResult
            }
            .drive(searchLabel.rx.text)
            .disposed(by: disposeBag)
        
        searchBar.rx.setDelegate(self)
            .disposed(by: disposeBag)
    }
    
    private func bindTableView(_ output: ExploreSearchViewModel.Output) {
        output.searchCreatorResultModel
            .asDriver(onErrorJustReturn: [])
            .drive(searchTableView.rx.items(
                cellIdentifier: CreatorListCell.reuseIdentifier,
                cellType: CreatorListCell.self)
            ) { indexPath, creator, cell in
                cell.configureCell(creator: creator)
            }
            .disposed(by: disposeBag)
        
        output.searchCreatorResultModel
            .asDriver(onErrorJustReturn: [])
            .map { datas in
                return !(datas.count == .zero)
            }
            .drive(self.searchLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    func bindingInput() -> ExploreSearchViewModel.Output {
        let searchBarEvent = searchBar.rx.text
            .distinctUntilChanged()
            .debounce(.seconds(1), scheduler: MainScheduler.instance)
            .asObservable()
        
        let viewDidScrollEvent = searchTableView.rx.didScroll
            .flatMap { _ in
                if self.isLoading.value { return Observable<Void>.empty() }
                
                let collectionViewContentSizeY = self.searchTableView.contentSize.height
                let contentOffsetY = self.searchTableView.contentOffset.y
                let heightRemainBottomHeight = collectionViewContentSizeY - contentOffsetY
                let frameHeight = self.searchTableView.frame.size.height
                let reachBottom = heightRemainBottomHeight < frameHeight
                
                self.isLoading.accept(reachBottom)
                
                return reachBottom ? Observable<Void>.just(()) : Observable<Void>.empty()
            }
            .asObservable()
        
        let input = ExploreSearchViewModel.Input(
            textDidSearch: searchBarEvent,
            viewDidScroll: viewDidScrollEvent
        )
        
        return viewModel.transform(input: input)
    }
}

// Configure UI
private extension ExploreSearchViewController {
    func configureUI() {
        view.backgroundColor = .systemBackground
        searchTableView.backgroundView = searchLabel
        
        configureHierarchy()
        makeConstraints()
    }
    
    func configureHierarchy() {
        [backButton, searchBar, searchTableView].forEach { view.addSubview($0) }
    }
    
    func makeConstraints() {
        searchBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(10)
            $0.leading.equalTo(backButton.snp.trailing).offset(10)
            $0.trailing.equalToSuperview().inset(10)
        }
        
        backButton.snp.makeConstraints {
            $0.centerY.equalTo(searchBar.snp.centerY)
            $0.leading.equalTo(view.safeAreaLayoutGuide.snp.leading).offset(20)
        }
        
        searchTableView.snp.makeConstraints {
            $0.top.equalTo(searchBar.snp.bottom).offset(10)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        searchLabel.snp.makeConstraints {
            $0.centerX.equalTo(searchTableView.snp.centerX)
            $0.top.equalTo(searchTableView.snp.top).offset(50)
        }
    }
}

// Constants
private extension ExploreSearchViewController {
    enum Constants {
        static let searchPlaceHolder = "닉네임"
        static let clearImage = "xmark.circle"
        static let backImage = "chevron.backward"
        static let noSearch = "크리에이터의 닉네임을 검색해보세요."
        static let noSearchResult = "검색 결과가 없습니다."
    }
}
