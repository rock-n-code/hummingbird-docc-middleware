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

import Testing

import protocol Hummingbird.RequestContext

import struct Hummingbird.HTTPResponse
import struct Hummingbird.Request
import struct Logging.Logger

@testable import struct DocCMiddleware.ServeURIUseCase

@Suite("Serve URI Use Case", .tags(.useCase))
struct ServeURIUseCaseTests {
    
    // MARK: Use case tests

#if swift(>=6.2)
    @Test
    func `response when resource served and logging event triggered`() async throws {
        try await assertResponse(
            logLevel: try .random(upTo: .debug),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .ok
        )
    }
    
    @Test
    func `response when resource served and logging event not triggered`() async throws {
        try await assertResponse(
            logLevel: try .random(fromExclusive: .debug),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .ok
        )
    }
    
    @Test
    func `response when resource not found and logging event triggered`() async throws {
        try await assertResponse(
            logLevel: try .random(upTo: .error),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .notFound
        )
    }
    
    @Test
    func `response when resource not found and logging event not triggered`() async throws {
        try await assertResponse(
            logLevel: try .random(fromExclusive: .error),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .notFound
        )
    }
    
    @Test
    func `response throws error when loading resource`() async throws {
        try await assertResponse(
            logLevel: try .random(),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder
        )
    }
#else
    @Test("response when resource served and logging event triggered")
    func response_whenResourceServed_andEventTriggered() async throws {
        try await assertResponse(
            logLevel: try .random(upTo: .debug),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .ok
        )
    }
    
    @Test("response when resource served and logging event not triggered")
    func response_whenResourceServed_andEventNotTriggered() async throws {
        try await assertResponse(
            logLevel: try .random(fromExclusive: .debug),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .ok
        )
    }
    
    @Test("response when resource not found and logging event triggered")
    func resource_whenResourceNotFound_andEventTriggered() async throws {
        try await assertResponse(
            logLevel: try .random(upTo: .error),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .notFound
        )
    }
    
    @Test("response when resource not found and logging event not triggered")
    func resource_whenResourceNotFound_andEventNotTriggered() async throws {
        try await assertResponse(
            logLevel: try .random(fromExclusive: .error),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder,
            expects: .notFound
        )
    }
    
    @Test("response throws error when loading resource")
    func resource_throwsError_whenLoadingResource() async throws {
        try await assertResponse(
            logLevel: try .random(),
            uriPath: .Sample.uriResource,
            folderPath: .Sample.uriFolder
        )
    }
#endif

}

// MARK: - Assertions

private extension ServeURIUseCaseTests {
    
    // MARK: Functions
    
    /// Asserts a response returned by the ``ServeURIUseCase`` use case.
    ///
    /// > important: In case no `statusCode` value is given, the function then assumes that the loading of a file will throw an error.
    ///
    /// - Parameters:
    ///   - logLevel: A representation of the logging level to set in the `Logger` instance.
    ///   - uriPath: A URI path to a resource.
    ///   - folderPath: A URI path to a folder that contains the resource.
    ///   - statusCode: An expected status code from the response coming out of the use case, if any.
    /// - Throws: An error in case an issue is encountered while asserting the use case.
    func assertResponse(
        logLevel: Logger.Level,
        uriPath: String,
        folderPath: String,
        expects statusCode: HTTPResponse.Status? = nil
    ) async throws {
        // GIVEN
        let logHandler = LogHandlerMock()
        let logger = Logger.test(
            level: logLevel,
            handler: logHandler
        )
        
        let fileProvider: FileProviderMock = switch statusCode {
            case .ok: .init(fileIdentifier: .init())
            case .notFound: .init()
            default: .init(fileIdentifier: .init(), shouldLoadFile: false)
        }

        let context: any RequestContext = RequestContextMock(logger: logger)
        let request: Request = .test(method: .get)
        
        let useCase = ServeURIUseCase(
            fileProvider: fileProvider,
            logger: logger
        )

        // WHEN
        // THEN
        if let statusCode {
            let result = try await useCase(
                uriPath,
                at: folderPath,
                with: (request, context)
            )

            #expect(result.headers[.contentLength] == (statusCode == .ok ? "36" : "0"))
            #expect(result.status == statusCode)
            
            let contentLength = try #require(result.body.contentLength)
            
            if statusCode == .ok {
                #expect(contentLength > 0)
            } else {
                #expect(contentLength == 0)
            }
            
            let events = logHandler.entries
            
            if shouldEventBeLogged(
                logLevel: logLevel,
                statusCode: statusCode
            ) {
                #expect(!events.isEmpty)
                #expect(events.count == 1)
                
                let loggedEvent = try #require(events.first)
                let filePath: String = .Sample.uriFile
                
                #expect(loggedEvent == .init(
                    level: statusCode == .ok ? .debug : .error,
                    metadata: [
                        "hb.request.id": "\(context.id)",
                        "hb.request.method": "\(request.method.rawValue)",
                        "hb.request.path": "\(request.uri.path)",
                        "hb.request.status": "\(statusCode.code)"
                    ],
                    message: {
                        if statusCode == .ok {
                            "The body of the resource \(filePath) has \(contentLength) bytes."
                        } else {
                            "The resource \(filePath) has not been found."
                        }
                    }(),
                    source: .Logging.source
                ))
            } else {
                #expect(events.isEmpty)
            }
        } else {
            do {
                _ = try await useCase(
                    uriPath,
                    at: folderPath,
                    with: (request, context)
                )
            } catch is FileProviderMockError {
                #expect(true)
            } catch {
                #expect(true == false)
            }
        }
    }
    
}

// MARK: - Helpers

private extension ServeURIUseCaseTests {
    
    // MARK: Functions
    
    /// Checks whether a logging event should be logged or not, based on a given logging level.
    /// - Parameters:
    ///   - logLevel: A representation of a logging level defined in in the logger.
    ///   - statusCode: A representation of a status code from the response.
    /// - Returns: A boolean value that indicates whether a logging event should have been logged or not.
    func shouldEventBeLogged(
        logLevel: Logger.Level,
        statusCode: HTTPResponse.Status
    ) -> Bool {
        let levels: [Logger.Level] = switch statusCode {
        case .ok: [.debug, .trace]
        case .notFound: [.debug, .error, .info, .notice, .trace, .warning]
        default: []
        }
        
        return levels.contains(logLevel)
    }
    
}
