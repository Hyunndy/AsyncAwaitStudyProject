//
//  MainViewModel.swift
//  AsyncAwaitStudyProject
//
//  Created by hyunndy on 2023/02/16.
//

import Foundation
import Alamofire
import UIKit

enum HyunndyError: Error {
    case badId
    case badNetwork
    case emptyString
}

/**
 Async/await 학습 viewModel 객체
 */
final class MainViewModel {
    
    func getImageURL(width: Int, height: Int) -> URL {
        return URL(string: "https://baconmockup.com/\(width)/\(height)")!
    }

    func getURL(paragraph: Int) -> URL {
        return URL(string: "https://baconipsum.com/api/?type=all-meat&paras=\(paragraph)&start-with-lorem=1")!
    }
    
    // 1. 캐시 생성
    let imageCache = NSCache<NSString, UIImage>()
    
    init() {
        
        // 2. 캐시 정책 설립
        imageCache.countLimit = 20
        imageCache.totalCostLimit = 10 * 1024 * 1024 // byte 기준이므로 10MB
    }
    
    /**
     1번
     Async/await가 없던 시절. CompletionHandler로 알려준다.
     */
    func fetchTitle(completion: @escaping (Result<[String], Error>) -> Void) {
        
        let request = URLRequest(url: getURL(paragraph: 1))
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            
            if let error {
                completion(.failure(error))
            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
                completion(.failure(HyunndyError.badNetwork))
            } else {
                guard let data else {
                    completion(.failure(HyunndyError.badId))
                    return
                }
                
                let paragraph = try? JSONDecoder().decode([String].self, from: data)
                if let paragraph {
                    DispatchQueue.main.async {
                        completion(.success(paragraph))
                    }
                    
                } else {
                    completion(.failure(HyunndyError.emptyString))
                }
            }
        })
        
        task.resume()
    }
    
    /**
     2번
     Async/await 추가
     */
    func fetchTitle2() async throws -> [String] {
        
        let request = URLRequest(url: getURL(paragraph: 2))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HyunndyError.badNetwork
        }
        
        let paragraph = try JSONDecoder().decode([String].self, from: data)
        
        return paragraph
    }
    
    /**
     3번
     async-let
     */
    func fetchTitle3() async throws -> [String] {
        
        let request = URLRequest(url: self.getURL(paragraph: 3))
        async let (data, response) = URLSession.shared.data(for: request)
        guard (try await response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HyunndyError.badNetwork
        }
        
        let paragraph = try JSONDecoder().decode([String].self, from: try await data)
        return paragraph
    }
    
    /**
     6번
     이미지 받아오기 + async-let
     */
    
    
    func fetchImage() async throws -> UIImage? {
        
        // 3. 캐시된 이미지 객체 체크
        if let cacheImage = imageCache.object(forKey: "randomImage") {
            print("캐싱된 이미지 가져왔나요?")
            return cacheImage
        }
        
        // Download Image asynchronously
        let request = URLRequest(url: self.getImageURL(width: 100, height: 100))
        async let (data, response) = URLSession.shared.data(for: request)
        guard (try await response as? HTTPURLResponse)?.statusCode == 200 else {
            throw HyunndyError.badNetwork
        }
        
        guard let image = UIImage(data: try await data) else {
            throw HyunndyError.badNetwork
        }
        
        // 4. 이미지 캐시
        imageCache.setObject(image, forKey: "randomImage")
        
        return image
    }
    
    /**
     4번
     Task Group
     using withThrowingTaskGroup ~
     */
    func fetchTitle4() async throws -> [String] {
        
        var titleArray = [String]()
        
        try await withThrowingTaskGroup(of: [String].self, body: { group in
            
            group.addTask {
                return try await self.fetchTitle3()
            }
            
            for try await taskResult in group {
                titleArray.append(contentsOf: taskResult)
            }
        })
        
        return titleArray
    }
    
    /**
     5번
     Alamofire + Async/await
     */
    func fetchTitle5() async throws -> [String] {
        
        let request = URLRequest(url: self.getURL(paragraph: 1))
//        let value = try await AF.request(request).serializingDecodable([String].self).value
        
        let dataTask = AF.request(request).serializingDecodable([String].self)
        
        let value = try await dataTask.value
        
        return value
    }
}










