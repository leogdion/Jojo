//
//  File.swift
//  
//
//  Created by Leo Dion on 1/16/23.
//

import Foundation


extension Process  {
  struct TimeoutError : Error {
    let timeout : DispatchTime
  }
  struct UncaughtSignalError : Error {
    private init(reason: Process.TerminationReason, status: Int, data: Data?, output: Data?) {
      self.reason = reason
      self.status = status
      self.data = data
      self.output = output
    }
    
    internal init?(reason: Process.TerminationReason, status: Int32, standardError : Pipe, output: Data?) {
      if reason == .exit, status == 0 {

                return nil
              }
      let reason = reason
      let status = status
      let data = try? standardError.fileHandleForReading.readToEnd()
      
      self.init(reason: reason, status: Int(status), data: data, output: output)
    }
    
    let reason : TerminationReason
    let status : Int
    let data : Data?
    let output : Data?
  }
  
  func run (timeout: DispatchTime)  async throws -> Data? {
        let standardError = Pipe()
        let standardOutput = Pipe()
    
        self.standardError = standardError
        self.standardOutput = standardOutput
	
    let semaphore = DispatchSemaphore(value: 0)

    self.terminationHandler = { _ in
      semaphore.signal()
    }
    try self.run()
    return try await withCheckedThrowingContinuation { continuation in
      
      let result : Result<Data?, Error>
      let outputData = Result{try standardOutput.fileHandleForReading.readToEnd()}
      let semaphoreResult = semaphore.wait(timeout: timeout)
      
      
      switch semaphoreResult {
      case .success:
        if let error = UncaughtSignalError(reason: terminationReason, status: terminationStatus, standardError: standardError, output: try? outputData.get()) {
          result = .failure(error)
        } else {
          result = outputData
        }
      case .timedOut:
        result = .failure(TimeoutError(timeout: timeout))
      }
      continuation.resume(with: result)
    }
  }

}

