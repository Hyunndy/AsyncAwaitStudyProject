//
//  MainViewController.swift
//  AsyncAwaitStudyProject
//
//  Created by hyunndy on 2023/02/16.
//

import Foundation
import UIKit

/*
 Async/awit 예시 ViewController
 */
class MainViewController: UIViewController {

    var createLabel: (() -> UILabel) = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 30.0).isActive = true
        
        return label
    }
    
    var taskArray = [Task<(), Never>]()
    
    @IBOutlet weak var containerStackView: UIStackView!
    
    let viewModel = MainViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fetch()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        for array in taskArray {
            array.cancel()
        }
    }
    
    private func fetch() {
        self.viewModel.fetchTitle(completion: { result in
            switch result {
            case .success(let data):
                
                let label = self.createLabel()
                label.text = "competionHandler \n" + (data.last ?? "")
                self.containerStackView.addArrangedSubview(label)
                
            case .failure(let failure):
                print("API FAIL = \(failure.localizedDescription)")
            }
        })
        
        let asyncAwaitTask = Task {
            do {
                let paragraph = try await self.viewModel.fetchTitle2()
                let label = self.createLabel()
                label.text = "async/await \n" + (paragraph.last ?? "")
                self.containerStackView.addArrangedSubview(label)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        self.taskArray.append(asyncAwaitTask)
        
        let asyncletTask = Task {
            do {
                let paragraph = try await self.viewModel.fetchTitle3()
                let label = self.createLabel()
                label.text = "async-let \n" + (paragraph.last ?? "")
                self.containerStackView.addArrangedSubview(label)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        self.taskArray.append(asyncletTask)
    }
}
