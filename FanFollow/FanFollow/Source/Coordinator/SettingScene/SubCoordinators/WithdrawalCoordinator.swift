//
//  WithdrawalCoordinator.swift
//  FanFollow
//
//  Created by parkhyo on 2023/08/14.
//

import UIKit

final class WithdrawalCoordinator: Coordinator {
    weak var parentCoordinator: Coordinator?
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
//        let childViewController = RegisterOutViewController()
//        let controller = BottomSheetViewController(controller: childViewController)
//        controller.modalPresentationStyle = .overFullScreen
//        controller.modalTransitionStyle = .crossDissolve
//        self.navigationController.present(controller, animated: false)
        
        let repository = DefaultAuthRepository(
            networkService: DefaultNetworkService.shared,
            userDefaultsService: UserDefaults.standard
        )
        let useCase = DefaultWithdrawalUseCase(authRepository: repository)
        let viewModel = WithdrawlViewModel(withdrawlUseCase: useCase)

        let controller = WithdrawalViewController(viewModel: viewModel)
        controller.modalPresentationStyle = .overFullScreen
        controller.coordinator = self

        navigationController.present(controller, animated: false)
    }
    
    func reconnect(current viewController: UIViewController) {
        let application = UIApplication.shared
        guard let scene = application.connectedScenes.first?.delegate as? SceneDelegate else {
            return
        }
        
        viewController.dismiss(animated: false) {
            scene.mainCoordinator?.start()
        }
    }
}
