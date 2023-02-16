////
////  ViewController.swift
////  AsyncAwaitStudyProject
////
////  Created by hyunndy on 2023/02/12.
////
//
//import UIKit
//
//enum HyunndyError: Error {
//    case badId
//    case noImage
//}
//
//class ViewController: UIViewController {
//
//    let imageView = UIImageView()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        
//        
//        // Do any additional setup after loading the view.
//    }
//    
//    func fetchThumbnail(for id: String, completion: @escaping (Result<UIImage, Error>) -> Void) {
//        
//        // MARK: 1번
//        let request = URLRequest(url: URL(string: id)!)
//        // MARK: 2번
//        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
//            if let error {
//                completion(.failure(error))
//            } else if (response as? HTTPURLResponse)?.statusCode != 200 {
//                    completion(.failure(HyunndyError.badId))
//            } else {
//                // MARK: 3번
//                guard let image = UIImage(data: data!) else {
//                    completion(.failure(HyunndyError.noImage))
//                    return
//                }
//                
//                // MARK: 4번
//                image.prepareThumbnail(of: CGSize(width: 40.0, height: 40.0), completionHandler: { thumbnail in
//                    guard let thumbnail else {
//                        completion(.failure(HyunndyError.noImage))
//                        return
//                    }
//                    
//                    completion(.success(thumbnail))
//                })
//            }
//        })
//        
//        task.resume()
//    }
//    
//    /// 함수에 async 표시를 할 때는 throws 앞에 오거나 함수가 throws하지 않는 경우 화살표 바로 앞에 와야한다.
//    func fetchThumbnail2(for id: String) async throws -> UIImage {
//        
//        // MARK: 1번
//        // 이 함수는 sync이므로 이 때 스레드가 블락된다.
//        let request = URLRequest(url: URL(string: id)!)
//        
//        // MARK: 2번
//        
//        /// 하지만 dataTask와 달리 data 메서드는 awaitable이다.
//        /// data 메서드가 throws로 명시되어있기 때문에 "Try"가 있다.
//        /// 이전 버전에서는 오류를 확인한 다음 CompletionHandler를 명시적으로 호출했어야 했는데, awaitable version에서는 모든 코드가 try 키워드로 압축된다.
//        /// throws로 마크된 함수를 호출할 때 try가 필요한 것 처럼, async로 표시된 함수를 호출하려면 await가 필요합니다.
//        /*
//         /// Convenience method to load data using an URLRequest, creates and resumes an URLSessionDataTask internally.
//         ///
//         /// - Parameter request: The URLRequest for which to load data.
//         /// - Parameter delegate: Task-specific delegate.
//         /// - Returns: Data and response.
//         public func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse)
//         */
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
//            throw HyunndyError.badId
//        }
//        // MARK: 3번
//        let maybeImage = UIImage(data: data)
//        
//        // MARK: 4번
//        /*
//         @available(iOS 15.0, *)
//         open func byPreparingThumbnail(ofSize size: CGSize) async -> UIImage?
//         */
//        guard let thumbnail = await maybeImage?.byPreparingThumbnail(ofSize: CGSize(width: 40.0, height: 40.0)) else {
//            throw HyunndyError.noImage
//        }
//        
//        return thumbnail
//    }
//    
//    func fetchThumbnail(for id: String) async throws -> UIImage {
//        let request = URLRequest(url: URL(string: id)!)
//        let (data, response) = try await URLSession.shared.data(for: request)
//        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw HyunndyError.badId }
//        let maybeImage = UIImage(data: data)
//        guard let thumbnail = await maybeImage?.thumbnail else { throw HyunndyError.noImage }
//        return thumbnail
//    }
//}
//
//extension UIImage {
//    var thumbnail: UIImage? {
//        get async {
//            let size = CGSize(width: 40.0, height: 40.0)
//            return await self.byPreparingThumbnail(ofSize: size)
//        }
//    }
//}
//
//
//
//
//
