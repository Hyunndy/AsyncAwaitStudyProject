//
//  AppDelegate.swift
//  AsyncAwaitStudyProject
//
//  Created by hyunndy on 2023/02/12.
//

import UIKit
import BackgroundTasks
import CoreData


@main
class AppDelegate: UIResponder, UIApplicationDelegate, URLSessionDownloadDelegate {

    var window: UIWindow?
    var backgroundTask: BGTask?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        registerBackgroundTasks()
        
        // 여기선 launch 시에 했지만, launch가 끝나고 사용자에게 알림 허용 등의 권한 체크를 먼저 하고 수락하면 진행하는게 좀 더 깔끔합니다.
        UIApplication.shared.registerForRemoteNotifications()
        
        return true
    }
    
    /// 앱의 launch sequence가 끝나기 전에 Background Task를 Scheduler에 "등록"해야 합니다.
    /// Info.plist에 등록한 키 값으로 등록해야 합니다.
    private func registerBackgroundTasks() {
        
        print("Background Task 등록!")
        // RefreshTask
        // 1. Refresh Task 등록
        let taskIdentifier = ["com.example.apple-samplecode.ColorFeed.refresh"]
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier[0], using: nil, launchHandler: { task in
        
            // 2. 실제로 수행할 Background 동작 구현
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        })
    }
    
    ///
    /// task.setTaskCompleted(success: 작업 성공 여부) 호출
    /// 실제 Background Task 작동 코드를 작성합니다.
    /// timeOut 되거나, 앱이 종료 될 때를 위해 : task.expirationHandler 구현
    /// 꼭!!! task.setTaskCompleted를 호출해줘야 한다.
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.example.apple-samplecode.ColorFeed.refresh")
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let downloadTask = session.downloadTask(with:URL(string: "https://example.com/my-file.zip")!)
        downloadTask.resume()

        self.backgroundTask = task
        
        Task {
            do {
                let url = URL(string: "https://baconipsum.com/api/?type=all-meat&paras=1&start-with-lorem=1")!
                let request = URLRequest(url: url)
                async let (data, response) = URLSession.shared.data(for: request)
                guard try await (response as? HTTPURLResponse)?.statusCode == 200 else {
                    throw HyunndyError.badNetwork
                }
                
                let paragraph = try JSONDecoder().decode([String].self, from: try await data)
                print("BackgroundTask 성공!! \n\(paragraph[0])")
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }

        }
    }
    
    private func endBackgroundTask() {
        if let backgroundTask = self.backgroundTask {
            backgroundTask.setTaskCompleted(success: true)
            self.backgroundTask = nil
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        // 파일 다운로드 완료
        print("Background Task 완료!")
        
        // BackgroundTask 종료
        endBackgroundTask()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            // 오류 처리..
            print("Background Task 에러!")
            print(error)
        }
        
        // BackgroundTask 종료
        endBackgroundTask()
    }
    
    private func scheduleBackgroundTask() {
        let task = BGAppRefreshTaskRequest(identifier: "com.example.apple-samplecode.ColorFeed.refresh")
        /// (Processing Task 였다면)
        /*
         task.requiresExternalPower = false // 배터리를 사용할 것인지 여부
        task.requiresNetworkConnectivity = false // 네트워크를 사용할 것인지 여부
         */
        
        // 백그라운드 작업을 실행할 때까지의 최소 대기 시간
        task.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            print("Background Task submit!")
            // Background Task 등록!!
            try BGTaskScheduler.shared.submit(task)
        } catch {
            print("Could not schedule app refesh")
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        print(#function)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        scheduleBackgroundTask()
        print(#function)
    }


}

// MARK: APNs
extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs으로 부터 받은 디바이스 토큰:" + deviceToken.description)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("APNs 등록 및 디바이스 토큰 받기 실패:" + error.localizedDescription)
    }
}

