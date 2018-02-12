//
//  NetworkService.swift
//  PhotoTestApp
//
//  Created by Evgeniy on 05/02/2018.
//  Copyright © 2018 Evgeniy. All rights reserved.
//

import UIKit

typealias RequestCompletionBlock = (Data?, Error?) -> Void
let kRequestTime = 5.0
let kConnectionLiveTime = 10.0

class NetworkService: NSObject {

    private let config = URLSessionConfiguration.ephemeral

    func requestFromURL(requestUrl: URL, completionBlock: (RequestCompletionBlock)? = nil) {
        let urlRequest = URLRequest(url: requestUrl)
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest  = kRequestTime
        config.timeoutIntervalForResource = kConnectionLiveTime

        let downloadSession = URLSession(configuration: config)

        let sessionTask = downloadSession.dataTask(with: urlRequest) { (data, response, error) in

            if let error = error as NSError? {

                // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                // then your Info.plist has not been properly configured to match the target server.
                //

                if error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                    print("ERROR: App Transport Security Requires Secure Connection")
                } else {
                    completionBlock?(nil, error)
                }

                return
            }

            // here we check for any returned Error from the server,
            // "and" we also check for any http response errors check for any response errors
            if let httpResponse = response as? HTTPURLResponse? {

                if let statusCode = httpResponse?.statusCode, statusCode / 100 != 2 {

                    let errorString = String.localizedStringWithFormat(NSLocalizedString("HTTP Error",
                            comment: "Error message displayed when receiving an error from the server."))

                    let userInfo: Dictionary = [NSLocalizedDescriptionKey: errorString]
                    let error = NSError(domain: "HTTP", code: statusCode, userInfo: userInfo)

                    // error - use completion block
                    completionBlock?(nil, error)
                    return
                }

                if  let data = data {
                    // return received data
                    completionBlock?(data, nil)
                }
            }

        }

        sessionTask.resume()
    }
}
