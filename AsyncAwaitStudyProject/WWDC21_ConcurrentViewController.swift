//
//  WWDC21_ConcurrentViewController.swift
//  AsyncAwaitStudyProject
//
//  Created by hyunndy on 2023/02/13.
//

import Foundation
import UIKit

class ViewController2: UIViewController {
    
    /*
     Asynchronous code with completion Handlers is unstructured
     */
    func fetchThumbnail(for ids: [String], completion: @escaping (Result<UIImage, Error>) -> Void) {
        
        guard let id = ids.first else {
            completion(.failure(HyunndyError.badId))
            return
        }
        
        // MARK: 1번
        let request = URLRequest(url: URL(string: id)!)
        // MARK: 2번
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let error {
                completion(.failure(error))
            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                    completion(.failure(HyunndyError.badId))
            } else {
                // MARK: 3번
                guard let image = UIImage(data: data!) else {
                    completion(.failure(HyunndyError.noImage))
                    return
                }
                
                // MARK: 4번
                image.prepareThumbnail(of: CGSize(width: 40.0, height: 40.0), completionHandler: { thumbnail in
                    guard let thumbnail else {
                        completion(.failure(HyunndyError.noImage))
                        return
                    }
                    
                    completion(.success(thumbnail))
                })
            }
        })
        
        task.resume()
    }
    
    func setUI() {
        var array = ["1", "2", "3"]
        self.fetchThumbnail(for: Array(array.dropFirst()), completion: { result in
            
            // thumbnail to UIImage...
        })
    }
}
