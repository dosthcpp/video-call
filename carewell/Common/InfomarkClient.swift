//
//  UploadClient.swift
//  carewell
//
//  Created by DOYEON BAEK on 2022/10/03.
//

import Foundation

class InfomarkClient {
    public func post(param: Dictionary<String, Any>, url: URL, runnable: @escaping Consumer) {
        let paramData = try! JSONSerialization.data(withJSONObject: param, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = paramData

        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(String(paramData.count), forHTTPHeaderField: "Content-Length")

        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in

            if let e = error {
                print("e : \(e.localizedDescription)")
                return
            }

            DispatchQueue.main.async {
                do {
                    let object = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary

                    guard let jsonObject = object else {
                        return
                    }

                    runnable(jsonObject)

                } catch let e as NSError {
                    print("An error has occured while parsing JSONObject: \(e.localizedDescription)")
                }

            }
        }
        task.resume()
    }

    public func postWithErrorHandling(param: Dictionary<String, Any>, url: URL, runnable: @escaping Consumer, errorRunnable: @escaping Consumer) {
        let paramData = try! JSONSerialization.data(withJSONObject: param, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = paramData

        request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(String(paramData.count), forHTTPHeaderField: "Content-Length")

        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in

            if let e = error {
                print("e : \(e.localizedDescription)")
                errorRunnable(e)
                return
            }

            DispatchQueue.main.async {
                do {
                    let object = try JSONSerialization.jsonObject(with: data!, options: []) as? NSDictionary

                    guard let jsonObject = object else {
                        return
                    }

                    runnable(jsonObject)

                } catch let e as NSError {
                    print("An error has occured while parsing JSONObject: \(e.localizedDescription)")
                }

            }
        }
        task.resume()
    }
}
