//
//  UserManager.swift
//  Voci di Corridoio
//
//  Created by Edoardo Frezzotti on 02/12/24.
//


import SwiftUI

let server = "levoci.local"
let port = 3000
let URN = "https://\(server):\(port)"

import Foundation
import Combine

class UserManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authToken: String? = nil
    @Published var currentUser: User? = nil
    
    // Register a user
    func registerUser(password: String, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(URN)/register")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            print(try JSONEncoder().encode(currentUser))
            request.httpBody = try JSONEncoder().encode(currentUser)
        } catch {
            completion(.failure(error))
            return
        }
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 201 {
                completion(.success("User registered successfully"))
            } else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            }
        }.resume()
    }
    /*
    // Login user and get a token
    func loginUser(user: User, completion: @escaping (Result<String, Error>) -> Void) {
        let url = URL(string: "\(URN)/login")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": user.mail,
            "password": user.password
        ]
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            completion(.failure(error))
            return
        }
        
        let session = URLSession.shared
        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["token"] as? String,
                   let userInfo = json["user"] as? [String: String] {
                    
                    let user = User(
                        name: userInfo["name"] ?? "",
                        surname: userInfo["surname"] ?? "",
                        username: userInfo["username"] ?? "",
                        mail: user.mail,
                        password: user.password // Store securely if needed
                    )
                    DispatchQueue.main.async {
                        self.currentUser = user
                        self.authToken = token
                        self.isAuthenticated = true
                    }
                    completion(.success(token))
                } else {
                    completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to parse token"])))
                }
            } else {
                let errorMessage = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown error"
                completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
            }
        }.resume()
    }*/
    
    // Save token securely
    func saveToken(token: String) {
        UserDefaults.standard.setValue(token, forKey: "authToken")
    }
    
    // Retrieve token from UserDefaults
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: "authToken")
    }
}
