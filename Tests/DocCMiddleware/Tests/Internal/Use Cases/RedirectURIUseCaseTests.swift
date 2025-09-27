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

@testable import struct DocCMiddleware.RedirectURIUseCase

@Suite("Redirect URI Use Case", .tags(.useCase))
struct RedirectURIUseCaseTests {

    // MARK: Use case tests
    
#if swift(>=6.2)
    @Test
    func `response when logging event triggered`() async throws {
        try await assertResponse(
            logLevel: try .random(upTo: .debug),
            uriRedirection: .Sample.uriRedirection,
            expects: .movedPermanently
        )
    }
    
    @Test
    func `response when logging event not triggered`() async throws {
        try await assertResponse(
            logLevel: try .random(fromExclusive: .debug),
            uriRedirection: .Sample.uriRedirection,
            expects: .movedPermanently
        )
    }
#else
    @Test("response when logging event triggered")
    func response_whenEventTriggered() async throws {
        try await assertResponse(
            logLevel: try .random(upTo: .debug),
            uriRedirection: .uriRedirection,
            expects: .movedPermanently
        )
    }
    
    @Test("response when logging event not triggered")
    func response_whenEventNotTriggered() async throws {
        try await assertResponse(
            logLevel: try randomLogLevelWithNoEvent,
            uriRedirection: .uriRedirection,
            expects: .movedPermanently
        )
    }
#endif

}

// MARK: - Assertions

private extension RedirectURIUseCaseTests {
    
    // MARK: Functions

    /// Asserts a response returned by the ``RedirectURIUseCase`` use case.
    /// - Parameters:
    ///   - logLevel: A representation of the logging level to set in the `Logger` instance.
    ///   - uriRedirection: A URI path to use in the redirection.
    ///   - statusCode: An expected status code from the response coming out of the use case.
    /// - Throws: An error in case an issue is encountered while asserting the use case.
    func assertResponse(
        logLevel: Logger.Level,
        uriRedirection: String,
        expects statusCode: HTTPResponse.Status
    ) async throws {
        let logHandler = LogHandlerMock()
        let logger = Logger.test(
            level: logLevel,
            handler: logHandler
        )
        
        let context: any RequestContext = RequestContextMock(logger: logger)
        let request: Request = .test(method: .get)
        
        let useCase = RedirectURIUseCase(logger: logger)
        
        // WHEN
        let result = useCase(
            uriRedirection,
            with: (request, context)
        )
        
        // THEN
        #expect(result.status == .movedPermanently)
        #expect(result.body.contentLength == 0)
        #expect(result.headers == [
            .location: uriRedirection,
            .contentLength: "0"
        ])

        let events = logHandler.entries

        if shouldEventBeLogged(logLevel) {
            #expect(!events.isEmpty)
            #expect(events.count == 1)
            
            let loggedEvent = try #require(events.first)

            #expect(loggedEvent == .init(
                level: .debug,
                metadata: [
                    "hb.request.id": "\(context.id)",
                    "hb.request.method": "\(request.method.rawValue)",
                    "hb.request.path": "\(request.uri.path)",
                    "hb.request.status": "\(statusCode.code)",
                    "hb.request.redirect": "\(uriRedirection)"
                ],
                message: "The URI path is redirected to this path: \(uriRedirection)",
                source: .Logging.source
            ))
        } else {
            #expect(events.isEmpty)
        }
    }
    
}

// MARK: - Helpers

private extension RedirectURIUseCaseTests {

    // MARK: Functions
    
    /// Checks whether a logging event should be logged or not.
    /// - Parameter logLevel: A representation of a logging level defined in the logger.
    /// - Returns: A boolean value that indicates whether a logging event should have been logged or not.
    func shouldEventBeLogged(_ logLevel: Logger.Level) -> Bool {
        [Logger.Level.debug, .trace].contains(logLevel)
    }
    
}
