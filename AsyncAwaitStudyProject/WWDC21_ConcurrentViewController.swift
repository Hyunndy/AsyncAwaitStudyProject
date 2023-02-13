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
    func fetchThumbnail(for ids: [String], completion handler: @escaping ([String: UIImage]?, Error?) -> Void) {
        
        guard let id = ids.first else {
            handler([:], nil)
            return
        }

        let request = URLRequest(url: URL(string: id)!)

        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let error {
                handler(nil, error)
            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                handler(nil, HyunndyError.noImage)
            } else {
                // MARK: 3번
                guard let image = UIImage(data: data!) else {
                    handler(nil, HyunndyError.noImage)
                    return
                }
                
                // MARK: 4번
                image.prepareThumbnail(of: CGSize(width: 40.0, height: 40.0), completionHandler: { thumbnail in
                    guard let thumbnail else {
                        handler(nil, HyunndyError.noImage)
                        return
                    }
                    
                    fetchThumbnail(for: Array(ids.dropFirst()), completion: { thumbnails, error in
                        // .... ad image to thumbnails .....
                    })
                })
            }
        })
        
        task.resume()
    }
    
    /// Asynchronous code with async/await is structured
    /// JUST Async/Await
    func fetchThumbnail2(for ids: [String]) async throws -> [String: UIImage] {
        var thumbnails: [String: UIImage] = [:]
        
        for id in ids {
            let request = URLRequest(url: URL(string: id)!)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            try validateResponse(response)
            guard let image = await UIImage(data: data)?.byPreparingThumbnail(ofSize: CGSize(width: 40.0, height: 40.0)) else {
                throw HyunndyError.noImage
            }
            
            thumbnails[id] = image
        }
        
        return thumbnails
    }
    
    func validateResponse(_ response: URLResponse) throws {
        throw HyunndyError.badId
    }
    
    /// Structured Concurrency with seuquential binding
    func fetchOneThumbnail(withId id: String) async throws -> UIImage {
        let imageReq = URLRequest(url: URL(string: id)!), metaReq = URLRequest(url: URL(string: id)!)
        
        let (data, _) = try await URLSession.shared.data(for: imageReq)
        let (metadata, _) = try await URLSession.shared.data(for: metaReq)
        
        guard
            let size = parseSize(from: metadata),
            let image = await UIImage(data: data)?.byPreparingThumbnail(ofSize: size)
        else {
            throw HyunndyError.noImage
        }
        
        return image
    }
    
    /// Structured Concurrency with async-let concurrent binding
    func fetchOneThumbnail2(withId id: String) async throws -> UIImage {
        let imageReq = URLRequest(url: URL(string: id)!), metaReq = URLRequest(url: URL(string: id)!)
        
        /// async let을 쓰면 이제 다운로드가 Child Task에서 발생하므로 더이상 오른쪽에 try await을 사용하지 않습니다.
        /// 하위 Task, 상위 Task에서 동시에 바인딩된 변수를 """사용할 때"""" Parent Task에서만 Error나 suspend가 Observing 됩니다.
        ///
        async let (data, _) = URLSession.shared.data(for: imageReq)
        async let (metadata, _) = URLSession.shared.data(for: metaReq)
        
        /// 따라서 사용하는 부분에 try await을 붙입니다.
        guard
            let size = parseSize(from: try await metadata),
            let image = try await UIImage(data: data)?.byPreparingThumbnail(ofSize: size)
        else {
            throw HyunndyError.noImage
        }
        
        return image
    }
    
    /// Cancellation checking
    func fetchThumbnails(for ids: [String]) async throws -> [String: UIImage] {
        var thumbnails: [String: UIImage] = [:]
        for id in ids {
            /// Throws an error if the task was canceled.
            /// Task가 취소된 경우 Error을 발생시켜 for 루프를 탈출시킵니다.
            /// Task가 cancel된 경우 쓸모없는 통신을 계속해서 App이 crash 나게 냅두고 싶지 않습니다.
            try Task.checkCancellation()
            if Task.isCancelled { break }
            thumbnails[id] = try await fetchOneThumbnail(withId: id)
        }
        return thumbnails
    }
    
    func parseSize(from: Data) -> CGSize? {
        return CGSize(width: 40.0, height: 40.0)
    }

    /// Async-let is for concurrency with static width
}
