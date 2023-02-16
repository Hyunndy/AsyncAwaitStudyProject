////
////  WWDC21_ConcurrentViewController.swift
////  AsyncAwaitStudyProject
////
////  Created by hyunndy on 2023/02/13.
////
//
//import Foundation
//import UIKit
//
//class ViewController2: UIViewController {
//    
//    /*
//     Asynchronous code with completion Handlers is unstructured
//     */
//    func fetchThumbnail(for ids: [String], completion handler: @escaping ([String: UIImage]?, Error?) -> Void) {
//        
//        guard let id = ids.first else {
//            handler([:], nil)
//            return
//        }
//
//        let request = URLRequest(url: URL(string: id)!)
//
//        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
//            if let error {
//                handler(nil, error)
//            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
//                handler(nil, HyunndyError.noImage)
//            } else {
//                // MARK: 3번
//                guard let image = UIImage(data: data!) else {
//                    handler(nil, HyunndyError.noImage)
//                    return
//                }
//                
//                // MARK: 4번
//                image.prepareThumbnail(of: CGSize(width: 40.0, height: 40.0), completionHandler: { thumbnail in
//                    guard let thumbnail else {
//                        handler(nil, HyunndyError.noImage)
//                        return
//                    }
//                    
//                    fetchThumbnail(for: Array(ids.dropFirst()), completion: { thumbnails, error in
//                        // .... ad image to thumbnails .....
//                    })
//                })
//            }
//        })
//        
//        task.resume()
//    }
//    
//    /// Asynchronous code with async/await is structured
//    /// JUST Async/Await
//    func fetchThumbnail2(for ids: [String]) async throws -> [String: UIImage] {
//        var thumbnails: [String: UIImage] = [:]
//        
//        for id in ids {
//            let request = URLRequest(url: URL(string: id)!)
//            let (data, response) = try await URLSession.shared.data(for: request)
//            
//            try validateResponse(response)
//            guard let image = await UIImage(data: data)?.byPreparingThumbnail(ofSize: CGSize(width: 40.0, height: 40.0)) else {
//                throw HyunndyError.noImage
//            }
//            
//            thumbnails[id] = image
//        }
//        
//        return thumbnails
//    }
//    
//    func validateResponse(_ response: URLResponse) throws {
//        throw HyunndyError.badId
//    }
//    
//    /// Structured Concurrency with seuquential binding
//    func fetchOneThumbnail(withId id: String) async throws -> UIImage {
//        let imageReq = URLRequest(url: URL(string: id)!), metaReq = URLRequest(url: URL(string: id)!)
//        
//        let (data, _) = try await URLSession.shared.data(for: imageReq)
//        let (metadata, _) = try await URLSession.shared.data(for: metaReq)
//        
//        guard
//            let size = parseSize(from: metadata),
//            let image = await UIImage(data: data)?.byPreparingThumbnail(ofSize: size)
//        else {
//            throw HyunndyError.noImage
//        }
//        
//        return image
//    }
//    
//    /// Cancellation checking
//    func fetchThumbnails(for ids: [String]) async throws -> [String: UIImage] {
//        var thumbnails: [String: UIImage] = [:]
//        for id in ids {
//            /// Throws an error if the task was canceled.
//            /// Task가 취소된 경우 Error을 발생시켜 for 루프를 탈출시킵니다.
//            /// Task가 cancel된 경우 쓸모없는 통신을 계속해서 App이 crash 나게 냅두고 싶지 않습니다.
//            try Task.checkCancellation()
//            if Task.isCancelled { break }
//            thumbnails[id] = try await fetchOneThumbnail(withId: id)
//        }
//        return thumbnails
//    }
//    
//    func parseSize(from: Data) -> CGSize? {
//        return CGSize(width: 40.0, height: 40.0)
//    }
//
//    /// Async-let is for concurrency with static width
//    func fetchThumbnails3(for ids: [String]) async throws -> [String: UIImage] {
//        var thumbnails: [String: UIImage] = [:]
//        for id in ids {
//            /// 여기서 fetchOneThumbnail2() 에는
//            /// async let (data, _) = URLSession.shared.data(for: imageReq)
//            /// async let (metadata, _) = URLSession.shared.data(for: metaReq)
//            /// 요렇게 2개의 Child Task가 생성된다.
//            /// 이 말은? 다음 루프가 시작되기 전에 두 개의 Child Task가 완료되야된다는 뜻
//            thumbnails[id] = try await fetchOneThumbnail2(withId: id)
//        }
//        
//        return thumbnails
//    }
//    
//    /// 위 루프에서 모든 썸네일을 동시에 가져오려면 어케 해야할까..? 루프가 몇 개가 돌지는 모른다!!
//    /// 요 상황에서 나오는게 Task Group 이다.
//    
//    /// Structured Concurrency with async-let concurrent binding
//    func fetchOneThumbnail2(withId id: String) async throws -> UIImage {
//        let imageReq = URLRequest(url: URL(string: id)!), metaReq = URLRequest(url: URL(string: id)!)
//        
//        /// async let을 쓰면 이제 다운로드가 Child Task에서 발생하므로 더이상 오른쪽에 try await을 사용하지 않습니다.
//        /// 하위 Task, 상위 Task에서 동시에 바인딩된 변수를 """사용할 때"""" Parent Task에서만 Error나 suspend가 Observing 됩니다.
//        ///
//        async let (data, _) = URLSession.shared.data(for: imageReq)
//        async let (metadata, _) = URLSession.shared.data(for: metaReq)
//        
//        /// 따라서 사용하는 부분에 try await을 붙입니다.
//        guard
//            let size = parseSize(from: try await metadata),
//            let image = try await UIImage(data: data)?.byPreparingThumbnail(ofSize: size)
//        else {
//            throw HyunndyError.noImage
//        }
//        
//        return image
//    }
//    
//    func taskgroup2(for ids: [String]) async throws -> [String: UIImage] {
//        var thumbnail: [String: UIImage] = [:]
//        
//        try await withThrowingTaskGroup(of: Void.self, body: { group in
//            for id in ids {
//                group.addTask {
//                    thumbnail[id] = try await self.fetchOneThumbnail2(withId: id)
//                }
//            }
//        })
//    }
//    
//    // A task group is for concurrency with dynamic width
//    func taskgroupFetchThumbnail(for ids: [String]) async throws -> [String: UIImage] {
//        
//        var thumbnails: [String: UIImage] = [:]
//        
//        /*
//         withThrowingTaskGroup을 통해 Task Group을 만들 수 있다.
//         요 함수는 Error를 throw 할 수 있는 child task를 만들기 위해 범위가 지정된 group object를 만들어줍니다.
//         그룹 나가면 Task들은 바로 죽는다.
//         블록 내부 안에 for-in loop를 배치했기 때문에 여기서 많은 양의 Task를 동시 생성할 수 있습니다.
//         
//         그룹 안에 들어가면 순서와 상관없이 Task가 생깁니다.
//         
//         */
//        try await withThrowingTaskGroup(of: (String, UIImage).self, body: { group in
//            for id in ids {
//                group.addTask {
//                    // 딕셔너리는 한 번에 두 개 이상의 액세스를 처리할 수 없는데 이 Task Group에서는 동시에 Task가 많이 생기므로 data race 컴파일 에러가 발생한다.
////                    thumbnails[id] = try await self.fetchOneThumbnail2(withId: id)
//                    // 근데 이 data race 컴파일에러를 과거에는 직접 찾아야했는데... 이제는 개발자가 찾을 수 있다. 어떻게?
//                    /*
//                     data-race safety
//                     Task creation은 @sendable 클로저에서 생성된다.
//                     @sendable 클로저 본문은 변경 가능한 변수를 캡쳐하는것이 제한됩니다. 왜? Task가 시작된 후 수정될 수 있으니까는.
//                     이 말은.. Task안에서의 캡처한 값이 공유하기에 안전해야 함을 의미한다. -> value Types, actos, 자체 동기화를 구현하는 class 객체
//                     
//                     */
//                    return (id, try await self.fetchOneThumbnail2(withId: id))
//                }
//            }
//            
//            // 이 for-await 루프는 완료된 순서대로 자식 작업에서 결과를 가져옵니다.
//            for try await (id, thumbnail) in group {
//                thumbnails[id] = thumbnail
//            }
//        })
//        return thumbnails
//    }
//}
//
//@MainActor
//class MyDelegate: UICollectionViewDelegate {
//    func isEqual(_ object: Any?) -> Bool {
//        <#code#>
//    }
//    
//    var hash: Int
//    
//    var superclass: AnyClass?
//    
//    func `self`() -> Self {
//        <#code#>
//    }
//    
//    func perform(_ aSelector: Selector!) -> Unmanaged<AnyObject>! {
//        <#code#>
//    }
//    
//    func perform(_ aSelector: Selector!, with object: Any!) -> Unmanaged<AnyObject>! {
//        <#code#>
//    }
//    
//    func perform(_ aSelector: Selector!, with object1: Any!, with object2: Any!) -> Unmanaged<AnyObject>! {
//        <#code#>
//    }
//    
//    func isProxy() -> Bool {
//        <#code#>
//    }
//    
//    func isKind(of aClass: AnyClass) -> Bool {
//        <#code#>
//    }
//    
//    func isMember(of aClass: AnyClass) -> Bool {
//        <#code#>
//    }
//    
//    func conforms(to aProtocol: Protocol) -> Bool {
//        <#code#>
//    }
//    
//    func responds(to aSelector: Selector!) -> Bool {
//        <#code#>
//    }
//    
//    var description: String
//    
//    
//    /*
//     UI 작업은 메인스레드에서 발생해야 하며
//     Swift Actor 세션에도 있는것처럼
//     Swift는 @MainActor라고 표기함으로써 이걸 보장합니다.
//     
//     컬렉션뷰가 있고,
//     우리는 Cell에 네트워크에서 썸네일을 가져와 표기하려고합니다.
//     하지만! Delegate는 async하지 않으므로 async 함수를 호출할 수 없씁니다. await할 수 없기 떄문이죠 ㅠㅠㅠㅠ
//     
//     당장 Task를 시작해야지만,
//     Task는 delegate action에 대한 응답으로 시작한 work의 확장입니다(??)
//     우리는 이 new Task가 UI 우선순위로 MainActor에서 계속 실행되기를 원합니다.
//     
//     우리는 이 Task의 수명을 이 싱글 delegate 함수에 바인딩하고싶지 않습니다!
//     
//     이러한 상황에서..!!
//     우리는 Unstrucutured task를 만들 수 있습니다.
//     */
////    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt item: IndexPath) {
////        let ids = getThumbnailIds(for: item)
////        let thumbnails = await fetchThumbnail2(for: ids)
////    }
//
//    /*
//     코드의 비동기 부분을 클로저로 이동하고,
//     해당 클로저를 전달하며 비동기 작업을 구성해보겠습니다.
//     
//     이렇게 하면 무슨일이 일어나냐면
//     Task를 생성하는 시점에 도달하면 Swift는 original scope와 동일한 Actor에서 실행되도록 스케줄링 합니다. (Task는 자동 스케줄링됨)
//     이 경우에는 Main Actor 입니다!
//     그사이에 control은 호출자에게 즉시 반환됩니다. 함수 말하는거겠죠?
//     
//     썸네일 받아오는 Task는 delegate 함수에서 Main Thread를 차단하지 않고 기회가 있을 때 Main Thread에서 실행됩니다.
//     이런 식으로 Task를 생성하면 구조화된 코드와 구조화되지 않은 코드 사이의 중간지점을 제공합니다.
//    
//     */
////    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt item: IndexPath) {
////        let ids = getThumbnailIds(for: item)
////        Task {
////            let thumbnails = try await fetchThumbnail2(for: ids)
////            display(thumbnails, in: cell)
////        }
////    }
//    /*
//     위 코드는 unscope Task로 만약에 썸네일이 로드되기전에 스크롤되서 다시 로드해야하면 이 Task는 명시적으로 취소해줘야한다.
//     */
//    
//    var thumbnailTasks: [IndexPath: Task<Void, Error>] = [:]
////
////    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt item: IndexPath) {
////        let ids = getThumbnailIds(for: item)
////        thumbnailTasks[item] = Task {
////            defer { thumbnailTasks[item] = nil } // defer가 뭐징
////            let thumbnails = try await fetchThumbnail2(for: ids)
////            display(thumbnails, in: cell)
////        }
////    }
////
////    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
////        thumbnailTasks[indexPath]?.cancel()
////    }
////
//  
//    /*
//     서버에서 썸네일을 가져온 후 나중에 가져오려고 할 때 네트워크에 다시 연결되지 않도록 로컬 디스크 캐시에 기록하려고 한다고 가정해보자.
//     캐싱은 메인 액터에서 발생할 필요가 없으며 모든 썸네일 가져오기를 취소하더라도 가져온 썸네일을 캐시하는것이 여전히 유용합니다.
//     */
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt item: IndexPath) {
//        let ids = getThumbnailIds(for: item)
//        thumbnailTasks[item] = Task {
//            defer { thumbnailTasks[item] = nil } // defer가 뭐징
//            let thumbnails = try await fetchThumbnail2(for: ids)
//            display(thumbnails, in: cell)
//            
//            /*
//             Datached Task
//             로컬 디스크에 캐싱하는거니까 낮은 우선순위의 백그라운드에 지정합니다.
//             */
//            Task.detached(.background, operation: {
//                writeToLocalcache(thumbnails)
//            })
//        }
//    }
//    
//    
//    
//    func display(_ dic: [String: UIImage], in: UICollectionViewCell) {
//        
//    }
//    
//    /// Asynchronous code with async/await is structured
//    /// JUST Async/Await
//    func fetchThumbnail2(for ids: [String]) async throws -> [String: UIImage] {
//        var thumbnails: [String: UIImage] = [:]
//        
//        for id in ids {
//            let request = URLRequest(url: URL(string: id)!)
//            let (data, response) = try await URLSession.shared.data(for: request)
//            
//            try validateResponse(response)
//            guard let image = await UIImage(data: data)?.byPreparingThumbnail(ofSize: CGSize(width: 40.0, height: 40.0)) else {
//                throw HyunndyError.noImage
//            }
//            
//            thumbnails[id] = image
//        }
//        
//        return thumbnails
//    }
//    
//    func getThumbnailIds(for: IndexPath) -> [String] {
//        return ["아"]
//    }
//}
//
//
//class testViewController2: UIViewController {
//    
//    
//}
