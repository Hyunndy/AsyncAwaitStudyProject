//
//  MainViewController.swift
//  AsyncAwaitStudyProject
//
//  Created by hyunndy on 2023/02/16.
//

import Foundation
import UIKit

protocol asyncPropertyProtocol {
    var thumbnailWithAsync: [String] { get async throws } //아아
}

/*
 Async/awit 예시 ViewController
 */
class MainViewController: UIViewController, asyncPropertyProtocol {
   
    /// 프로퍼티 + async/await
    var thumbnailWithAsync: [String] {
        get async throws {
            return try await self.viewModel.fetchTitle3()
        }
    }

    var createLabel: (() -> UILabel) = {
        let label = UILabel()
        label.backgroundColor = .white
        label.textColor = .black
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 30.0).isActive = true
        
        return label
    }
    
    /// Task관리를 위한 Array
    var taskArray = [Task<(), Never>]()
    
    @IBOutlet weak var containerStackView: UIStackView!
    
    let viewModel = MainViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        fetch()
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

        let taskGroupTask = Task {
            do {
                let paragraph = try await self.viewModel.fetchTitle4()
                let label = self.createLabel()
                label.text = "Task-Group \n" + (paragraph.last ?? "")
                self.containerStackView.addArrangedSubview(label)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        self.taskArray.append(taskGroupTask)

        let unStructuredTask = Task {
            do {
                let request = URLRequest(url: self.viewModel.getURL(paragraph: 5))
                let (data, response) = try await URLSession.shared.data(for: request)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw HyunndyError.badNetwork
                }

                let paragraph = try JSONDecoder().decode([String].self, from: data)
                let label = self.createLabel()
                label.text = "UnStructrued Task \n" + (paragraph.last ?? "")
                self.containerStackView.addArrangedSubview(label)
            } catch let error {
                print(error.localizedDescription)
            }
        }

        self.taskArray.append(unStructuredTask)

        let propertyTask = Task {
            do {
                let paragraph = try await self.thumbnailWithAsync
                let label = self.createLabel()
                label.text = "ProperyWithAsync \n" + (paragraph.last ?? "")
                self.containerStackView.addArrangedSubview(label)
            } catch let error {
                print(error.localizedDescription)
            }
        }

        self.taskArray.append(propertyTask)
        
        let alamofireTask = Task {
            do {
                let paragraph = try await self.viewModel.fetchTitle5()
                let label = self.createLabel()
                label.text = "AlamofireAsync \n" + (paragraph.last ?? "")
                self.containerStackView.addArrangedSubview(label)
            } catch let error {
                print(error.localizedDescription)
            }
        }
        self.taskArray.append(alamofireTask)
    }
}
