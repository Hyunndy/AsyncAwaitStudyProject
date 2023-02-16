//
//  MainViewModel.swift
//  AsyncAwaitStudyProject
//
//  Created by hyunndy on 2023/02/16.
//

import Foundation

enum HyunndyError: Error {
    case badId
    case badNetwork
    case emptyString
}

/**
 Async/await 학습 viewModel 객체
 */
final class MainViewModel {

    func getURL(paragraph: Int) -> URL {
        return URL(string: "https://baconipsum.com/api/?type=all-meat&paras=\(paragraph)&start-with-lorem=1")!
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
}










