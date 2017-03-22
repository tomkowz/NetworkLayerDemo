//
//  NetworkQueryGeneretor.swift
//  NetworkLayerExample
//
//  Created by Alessio Roberto on 03/03/2017.
//  Copyright © 2017 Tomasz Szulc. All rights reserved.
//

import Foundation

struct NetworkQueryGeneretor {
    func makeQuery(for url: URL, params: Parameters?, type: Query) -> URLRequest {
        switch type {
        case .json:
            var mutableRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                            timeoutInterval: 10.0)
            if let params = params {
                mutableRequest.httpBody = try! JSONSerialization.data(withJSONObject: params, options: [])
            }
            
            return mutableRequest
        case .path:
            var components = url.absoluteString
            
            components.append(convert(params: params))
            
            let newUrl = URL(string: components)!
            
            return URLRequest(url: newUrl, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        case .jsonImage:
            return createRequest(for: url, params: params)
        }
        
    }
    
    /// Convert a `Parameters` list in an URL query
    ///
    /// - Parameter params: The list of `Parameters`
    /// - Returns: The string that rapresent an URL query
    private func convert(params: Parameters?) -> String {
        guard let params = params else {
            return ""
        }
        
        var query = ""
        
        params.forEach { key, value in
            let valueString = "\(value)"
            query = query + "\(key)=\(valueString.encode())&"
        }
        
        return "?" + query
    }
    
    /// Create request
    ///
    /// - parameter userid:   The userid to be passed to web service
    /// - parameter password: The password to be passed to web service
    /// - parameter email:    The email address to be passed to web service
    ///
    /// - returns:            The NSURLRequest that was created
    private func createRequest(for url: URL, params: Parameters?) -> URLRequest {
        let boundary = generateBoundaryString()
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        guard let params = params else {
            return request
        }
        
        request.httpBody = createBody(with: params, boundary: boundary)
        
        return request
    }
    
    /// Create body of the multipart/form-data request with an image as Data
    ///
    /// - Parameters:
    ///   - parameters: The dictionary containing keys and values to be passed to web service
    ///   - boundary: The multipart/form-data boundary
    /// - Returns: The NSData of the body of the request
    private func createBody(with parameters: Parameters, boundary: String) -> Data {
        var body = Data()
        
        var tmp = parameters
        
        body = append(parameters: parameters, to: body, boundary: boundary)
        
        //TODO: - change key
        // fileKey is the key in the JSON for the image
        if let file = tmp.removeValue(forKey: "fileKey") as? Data {
            body = append(image: file, to: body, boundary: boundary)
        }
        
        body.append(string: "--\(boundary)--\r\n")
        
        return body
    }
    
    
    /// Append in the boy parameters that are not image
    ///
    /// - Parameters:
    ///   - parameters: The dictionary containing keys and values to be passed to web service
    ///   - body: Instance off the body
    ///   - boundary: The multipart/form-data boundary
    /// - Returns: The body Data
    private func append(parameters: Parameters, to body: Data, boundary: String) -> Data {
        var tmpBody = body
        for (key, value) in parameters {
            tmpBody.append(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            tmpBody.append(string: "\(value)\r\n")
        }
        
        return tmpBody
    }
    
    
    /// Append to the body the image
    ///
    /// - Parameters:
    ///   - file: Data instance that rappresent the image
    ///   - body: Instance off the body
    ///   - boundary: The multipart/form-data boundary
    /// - Returns: The body Data
    private func append(image file: Data, to body: Data, boundary: String) -> Data {
        var tmpBody = body
        
        tmpBody.append(string: "--\(boundary)\r\n")
        //TODO: - change keys fileKey and fileName
        tmpBody.append(string: "Content-Disposition: form-data; name=\"\("fileKey")\"; filename=\"\("fileName")\"\r\n")
        tmpBody.append(string: "Content-Type: image/jpeg\r\n\r\n")
        tmpBody.append(file)
        tmpBody.append(string: "\r\n")
        
        return tmpBody
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    private func generateBoundaryString() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
}
