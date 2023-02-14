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
    func fetchThumbnails3(for ids: [String]) async throws -> [String: UIImage] {
        var thumbnails: [String: UIImage] = [:]
        for id in ids {
            /// 여기서 fetchOneThumbnail2() 에는
            /// async let (data, _) = URLSession.shared.data(for: imageReq)
            /// async let (metadata, _) = URLSession.shared.data(for: metaReq)
            /// 요렇게 2개의 Child Task가 생성된다.
            /// 이 말은? 다음 루프가 시작되기 전에 두 개의 Child Task가 완료되야된다는 뜻
            thumbnails[id] = try await fetchOneThumbnail2(withId: id)
        }
        
        return thumbnails
    }
    
    /// 위 루프에서 모든 썸네일을 동시에 가져오려면 어케 해야할까..? 루프가 몇 개가 돌지는 모른다!!
    /// 요 상황에서 나오는게 Task Group 이다.
    
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
    
    func taskgroup2(for ids: [String]) async throws -> [String: UIImage] {
        var thumbnail: [String: UIImage] = [:]
        
        try await withThrowingTaskGroup(of: Void.self, body: { group in
            for id in ids {
                group.addTask {
                    thumbnail[id] = try await self.fetchOneThumbnail2(withId: id)
                }
            }
        })
    }
    
    // A task group is for concurrency with dynamic width
    func taskgroupFetchThumbnail(for ids: [String]) async throws -> [String: UIImage] {
        
        var thumbnails: [String: UIImage] = [:]
        
        /*
         withThrowingTaskGroup을 통해 Task Group을 만들 수 있다.
         요 함수는 Error를 throw 할 수 있는 child task를 만들기 위해 범위가 지정된 group object를 만들어줍니다.
         그룹 나가면 Task들은 바로 죽는다.
         블록 내부 안에 for-in loop를 배치했기 때문에 여기서 많은 양의 Task를 동시 생성할 수 있습니다.
         
         그룹 안에 들어가면 순서와 상관없이 Task가 생깁니다.
         
         */
        try await withThrowingTaskGroup(of: (String, UIImage).self, body: { group in
            for id in ids {
                group.addTask {
                    // 딕셔너리는 한 번에 두 개 이상의 액세스를 처리할 수 없는데 이 Task Group에서는 동시에 Task가 많이 생기므로 data race 컴파일 에러가 발생한다.
//                    thumbnails[id] = try await self.fetchOneThumbnail2(withId: id)
                    // 근데 이 data race 컴파일에러를 과거에는 직접 찾아야했는데... 이제는 개발자가 찾을 수 있다. 어떻게?
                    /*
                     data-race safety
                     Task creation은 @sendable 클로저에서 생성된다.
                     @sendable 클로저 본문은 변경 가능한 변수를 캡쳐하는것이 제한됩니다. 왜? Task가 시작된 후 수정될 수 있으니까는.
                     이 말은.. Task안에서의 캡처한 값이 공유하기에 안전해야 함을 의미한다. -> value Types, actos, 자체 동기화를 구현하는 class 객체
                     
                     */
                    return (id, try await self.fetchOneThumbnail2(withId: id))
                }
            }
            
            // 이 for-await 루프는 완료된 순서대로 자식 작업에서 결과를 가져옵니다.
            for try await (id, thumbnail) in group {
                thumbnails[id] = thumbnail
            }
        })
        return thumbnails
    }
}
