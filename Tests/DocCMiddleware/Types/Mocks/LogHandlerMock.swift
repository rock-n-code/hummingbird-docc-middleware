// ===----------------------------------------------------------------------===
//
// This source file is part of the Hummingbird DocC Middleware open source project
//
// Copyright (c) 2025 Röck+Cöde VoF. and the Hummingbird DocC Middleware project authors
// Licensed under the EUPL 1.2 or later.
//
// See LICENSE for license information
// See CONTRIBUTORS for the list of Hummingbird DocC Middleware project authors
//
// ===----------------------------------------------------------------------===

import Foundation

import protocol Logging.LogHandler

import struct Logging.Logger

/// A mock that conforms to the `LogHandler` protocol.
struct LogHandlerMock {
    
    // MARK: Properties

    /// A representation of the logging level assigned to this mock.
    private var _logLevel: Logger.Level = .debug

    /// A dictionary that contains all the metadata assigned to this mock.
    private var _metadata: Logger.Metadata = [:]
    
    /// A logging event recorder attached to this mock.
    private let recorder: LogRecorder = .init()

    // MARK: Computed
    
    /// A list of all the logged events that are being persisted in the recorder.
    var entries: [LogEntry] { recorder.entries }
    
}

// MARK: - LogEntry

/// A type that contains the information logged in a logging event.
struct LogEntry: Equatable {
    
    // MARK: Properties
    
    /// A representation of the level attached to a logged event.
    let level: Logger.Level
    
    /// A metadata dictionary that contains additional information attached to a logged event.
    let metadata: Logger.Metadata?
    
    /// A message attached to a logged event.
    let message: Logger.Message

    /// A source from where a logged event was triggered.
    let source: String
    
}

// MARK: - LogRecorder

extension LogHandlerMock {
    /// A class that records all the events logged by the ``LogHandlerMock`` mock handler.
    ///
    /// This class conforms to the `Sendable` protocol by using the `@unchecked` modifier because a `NSLock`type is used to handle the access to the logged events in a thread-safe way.
    final class LogRecorder: @unchecked Sendable {
        
        // MARK: Properties
        
        /// A list of all the logged events persisted in a thread-safe way.
        private(set) var _entries: [LogEntry] = []
        
        /// A type that coordinates the access to the persisted logged events in a thread-safe way.
        private let lock: NSLock = .init()
        
        // MARK: Computed
        
        /// A list of all the logged events.
        var entries: [LogEntry] {
            lock.withLock { _entries }
        }
        
        // MARK: Functions
        
        /// Records data related to a logged event.
        /// - Parameters:
        ///   - level: A representation of the level attached to a logged event.
        ///   - metadata: A metadata dictionary that contains additional information attached to a logged event.
        ///   - message: A message attached to a logged event.
        ///   - source: A source from where a logged event was triggered.
        func record(
            level: Logger.Level,
            metadata: Logger.Metadata?,
            message: Logger.Message,
            source: String
        ) {
            lock.withLock {
                _entries += [.init(
                    level: level,
                    metadata: metadata,
                    message: message,
                    source: source
                )]
            }
        }

    }
}

// MARK: - LogHandler

extension LogHandlerMock: LogHandler {

    // MARK: Properties
    
    var metadata: Logger.Metadata {
        get { _metadata }
        set(newValue) { _metadata = newValue }
    }
    
    var logLevel: Logger.Level {
        get { _logLevel }
        set(newValue) { _logLevel = newValue }
    }
    
    // MARK: Subscripts
    
    subscript(metadataKey metadataKey: String) -> Logger.Metadata.Value? {
        get { _metadata[metadataKey] }
        set(newValue) { _metadata[metadataKey] = newValue }
    }

    // MARK: Functions
    
    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        recorder.record(
            level: level,
            metadata: metadata,
            message: message,
            source: source
        )
    }
    
}
