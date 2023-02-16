//
//  MainViewController.swift
//  AsyncAwaitStudyProject
//
//  Created by hyunndy on 2023/02/16.
//

import Foundation
import UIKit

class MainViewController: UIViewController {
    
    
    @IBOutlet weak var containerStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureStackView()
    }
    
    private func configureStackView() {
        for _ in 0..<10 {
             let dummyView = randomColoredView()
            containerStackView.addArrangedSubview(dummyView)
         }
    }
    
    // 랜덤 색상, 100~400 height를 가진 뷰 생성 함수
      private func randomColoredView() -> UIView {
          let view = UIView()
          view.backgroundColor = UIColor(
              displayP3Red: 1.0,
              green: .random(in: 0...1),
              blue: .random(in: 0...1),
              alpha: .random(in: 0...1))
          view.translatesAutoresizingMaskIntoConstraints = false
          view.heightAnchor.constraint(equalToConstant: .random(in: 100...400)).isActive = true
          return view
      }
}
