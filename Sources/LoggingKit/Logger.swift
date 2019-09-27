//
//  Logger.swift
//  PDFArchiver
//
//  Created by Julian Kahnert on 25.06.19.
//  Copyright © 2019 Julian Kahnert. All rights reserved.
//

import UIKit
import LogModel

public struct Logger {

    // Mark: - Environment
    private static let environment = AppEnvironment.get()
    private static let osVersion = UIDevice().systemVersion
    private static let device = AppEnvironment.getModel()
    private static let version = AppEnvironment.getVersion()
    private static let build = AppEnvironment.getBuildNumber()

    // Mark: - Other variables
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let endpoint: URL
    private let base64Login: String
    private let shouldSend: (() -> Bool)?
    private let filename = "logs.json"
    private let logs: Atomic<[LogModel]>

    public init(endpoint: URL, username: String, password: String, shouldSend: (() -> Bool)? = nil) {
        self.endpoint = endpoint
        self.shouldSend = shouldSend
        self.base64Login = "\(username):\(password)"
            .data(using: .utf8)!
            .base64EncodedString()

        // get saved logs
        let savedLogs = Storage.load(filename, from: .documents, as: [LogModel].self) ?? []
        logs = Atomic(savedLogs)
    }

    public func send(_ level: LoggerLevel, _ message: String, extra data: [String: String] = [:], file: String = #file, line: Int = #line, function: String = #function) {
        guard shouldSend?() ?? true else { return }

        var data = data
        data["debugFile"] = file
        data["debugLine"] = String(line)
        data["debugFunction"] = function

        let newLog = LogModel(timestamp: Date(),
                              level: level,
                              message: message,
                              environment: Logger.environment,
                              os_version: Logger.osVersion,
                              device: Logger.device,
                              version: Logger.version,
                              build: Logger.build,
                              data: data)
        logs.mutate { $0.append(newLog) }
    }

    public func sendOrPersist(with urlSession: URLSession = URLSession.shared) {

        // get logs and check, if there are some
        var logs = [LogModel]()
        self.logs.mutate {
            logs = $0
            $0 = []
        }
        guard !logs.isEmpty else {
            Storage.remove(filename, from: .documents)
            return
        }

        do {
            let jsonData = try Logger.encoder.encode(logs)

            // create post request
            var request = URLRequest(url: endpoint)
            request.httpMethod = "POST"
            request.allHTTPHeaderFields?["Content-Type"] = "application/json"
            request.allHTTPHeaderFields?["Authorization"] = "Basic \(base64Login)"
            request.httpBody = jsonData

            let task = urlSession.dataTask(with: request) { data, response, error in

                // verify that no error occured, e.g. internet was not available or the http status is not 200
                guard error == nil,
                    let reponse = response as? HTTPURLResponse,
                    reponse.statusCode == 200 else {

                        // save logs on device, because something went wrong while sending
                        Storage.save(logs, to: .documents, as: self.filename)
                        self.logs.mutate { $0.append(contentsOf: logs) }
                        return
                }

                // remove file after successful sending
                Storage.remove(self.filename, from: .documents)
            }
            task.resume()

        } catch {

            // save logs on device, because something went wrong while sending
            Storage.save(logs, to: .documents, as: filename)
            self.logs.mutate { $0.append(contentsOf: logs) }
        }
    }
}
