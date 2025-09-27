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

import protocol Hummingbird.FileProvider
import protocol Hummingbird.RequestContext

import struct Hummingbird.HTTPResponse
import struct Hummingbird.LocalFileSystem
import struct Hummingbird.Request
import struct Logging.Logger

@testable import struct DocCMiddleware.DocCMiddleware

@Suite("DocC Middleware", .tags(.middleware))
struct DocCMiddlewareTests {
    
    // MARK: Initializers tests

#if swift(>=6.2)
    @Test
    func `initialize with URI and folder paths`() {
        assertInit(configuration: .init(
            uriRoot: .Sample.uriResource,
            folderRoot: .Sample.uriFolder
        ))
    }
    
    @Test
    func `initialize with URI path and type that conforms to the FileProvider protocol`() {
        assertInit(
            configuration: .init(
                uriRoot: .Sample.uriResource,
                folderRoot: .empty
            ),
            fileProvider: FileProviderStub()
        )
    }
#else
    @Test("initialize with URI and folder paths")
    func init_withURI_andFolderPaths() {
        assertInit(configuration: .init(
            uriRoot: .Sample.uriResource,
            folderRoot: .Sample.uriFolder
        ))
    }
    
    @Test("initialize with type that conforms to the FileProvider protocol")
    func init_withURI_path_andFileProviderType() {
        assertInit(
            configuration: .init(
                uriRoot: .Sample.uriResource,
                folderRoot: .empty
            ),
            fileProvider: FileProviderStub()
        )
    }
#endif
    
    // MARK: RouterMiddleware tests
    
#if swift(>=6.2)
    @Test(arguments: zip(
        Input.redirectURIPaths,
        Output.redirectURIPaths
    ))
    func `redirect a URI path while triggering logging event`(
        uriPath: String,
        expects uriRedirect: String
    ) async throws {
        try await assertRedirect(
            logLevel: try .random(upTo: .debug),
            uriPath: .Sample.uriDocument + uriPath,
            to: .Sample.uriDocument + uriRedirect
        )
    }
    
    @Test(arguments: zip(
        Input.redirectURIPaths,
        Output.redirectURIPaths
    ))
    func `redirect a URI path without triggering logging event`(
        uriPath: String,
        expects uriRedirect: String
    ) async throws {
        try await assertRedirect(
            logLevel: try .random(fromExclusive: .debug),
            uriPath: .Sample.uriDocument + uriPath,
            to: .Sample.uriDocument + uriRedirect
        )
    }
    
    @Test(arguments: Input.redirectURIPaths)
    func `redirect a URI path not prefixed with root URI path`(uriPath: String) async throws {
        try await assertRedirect(
            logLevel: try .random(),
            uriPath: uriPath,
            expects: .ok
        )
    }
    
    @Test(arguments: zip(
        Input.serveURIPaths,
        Output.serveURIFilePaths
    ))
    func `serve an existing URI resource while triggering logging event`(
        uriPath: String,
        uriFile: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(upTo: .debug),
            uriPath: .Sample.uriDocument + uriPath,
            uriFile: uriFile,
            statusCode: .ok
        )
    }
    
    @Test(arguments: Input.serveURIPaths)
    func `serve an existing URI resource without triggering logging event`(
        uriPath: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(fromExclusive: .debug),
            uriPath: .Sample.uriDocument + uriPath,
            statusCode: .ok
        )
    }
    
    @Test(arguments: zip(
        Input.serveURIPaths,
        Output.serveURIFilePaths
    ))
    func `serve a non existing URI resource while triggering logging event`(
        uriPath: String,
        uriFile: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(upTo: .error),
            uriPath: .Sample.uriDocument + uriPath,
            uriFile: uriFile,
            statusCode: .notFound
        )
    }
    
    @Test(arguments: Input.serveURIPaths)
    func `serve a non existing URI resource without triggering logging event`(
        uriPath: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(fromExclusive: .error),
            uriPath: .Sample.uriDocument + uriPath,
            statusCode: .notFound
        )
    }
    
    @Test(arguments: Input.serveURIPaths)
    func `serve a URI resource not prefixed with root URI path`(
        uriPath: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(),
            uriPath: uriPath
        )
    }
#else
    @Test("redirect a URI path while triggering logging event", arguments: zip(
        Input.redirectURIPaths,
        Output.redirectURIPaths
    ))
    func redirect_aURIPath_triggeringLoggingEvent(
        uriPath: String,
        expects uriRedirect: String
    ) async throws {
        try await assertRedirect(
            logLevel: try .random(upTo: .debug),
            uriPath: .Sample.uriRoot + uriPath,
            to: .Sample.uriRoot + uriRedirect
        )
    }
    
    @Test("redirect a URI path without triggering logging event", arguments: zip(
        Input.redirectURIPaths,
        Output.redirectURIPaths
    ))
    func redirect_aURIPath_notTriggeringLoggingEvent(
        uriPath: String,
        expects uriRedirect: String
    ) async throws {
        try await assertRedirect(
            logLevel: try .random(fromExclusive: .debug),
            uriPath: .Sample.uriRoot + uriPath,
            to: .Sample.uriRoot + uriRedirect
        )
    }
    
    @Test("redirect a URI path not prefixed with root URI path", arguments: Input.redirectURIPaths)
    func redirect_aURIPath_notPrefixedURIRoot(uriPath: String) async throws {
        try await assertRedirect(
            logLevel: try .random(),
            uriPath: .Sample.uriResource + uriPath,
            expects: .ok
        )
    }
    
    @Test("serve an existing URI resource while triggering logging event", arguments: zip(
        Input.serveURIPaths,
        Output.serveURIFilePaths
    ))
    func serve_exitingURIResource_triggeringLoggingEvent(
        uriPath: String,
        uriFile: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(upTo: .debug),
            uriPath: .Sample.uriDocument + uriPath,
            uriFile: uriFile,
            statusCode: .ok
        )
    }
    
    @Test("serve an existing URI resource without triggering logging event", arguments: Input.serveURIPaths)
    func server_existingURIResource_notTriggeringLoggingEvent(
        uriPath: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(fromExclusive: .debug),
            uriPath: .Sample.uriDocument + uriPath,
            statusCode: .ok
        )
    }
    
    @Test("serve a non existing URI resource while triggering logging event", arguments: zip(
        Input.serveURIPaths,
        Output.serveURIFilePaths
    ))
    func serve_notExistingURIResource_triggeringLoggingEvent(
        uriPath: String,
        uriFile: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(upTo: .error),
            uriPath: .Sample.uriDocument + uriPath,
            uriFile: uriFile,
            statusCode: .notFound
        )
    }
    
    @Test("serve a non existing URI resource without triggering logging event", arguments: Input.serveURIPaths)
    func serve_notExistingURIResource_triggeringLoggingEvent(
        uriPath: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(fromExclusive: .error),
            uriPath: .Sample.uriDocument + uriPath,
            statusCode: .notFound
        )
    }
    
    @Test("serve a URI resource not prefixed with root URI path", arguments: Input.serveURIPaths)
    func server_aURIResource_notPrefixed_withURIRoot(
        uriPath: String
    ) async throws {
        try await assertServe(
            logLevel: try .random(),
            uriPath: uriPath
        )
    }
#endif

}

// MARK: - Assertions

private extension DocCMiddlewareTests {
    
    // MARK: Functions
    
    /// Asserts the public initializer.
    /// - Parameters:
    ///   - configuration: A type that contains the parameters to configure the middleware.
    ///   - logger: A type that interacts with the logging system.
    func assertInit(
        configuration: DocCMiddleware<LocalFileSystem>.Configuration,
        logger: Logger = .test()
    ) {
        // GIVEN
        // WHEN
        let middleware = DocCMiddleware(
            configuration: configuration,
            logger: logger
        )
        
        // THEN
        #expect(middleware.configuration.folderRoot == configuration.folderRoot)
        #expect(middleware.configuration.uriRoot == configuration.uriRoot)
        #expect(middleware.configuration.threadPool === configuration.threadPool)
        
        #expect(middleware.logger.label == logger.label)
        #expect(middleware.logger.logLevel == logger.logLevel)
        #expect(middleware.logger.metadataProvider == nil)
        
        #expect(type(of:middleware.fileProvider) == LocalFileSystem.self)
    }
    
    /// Asserts the internal initializer with a concrete file provider type.
    /// - Parameters:
    ///   - configuration: A type that contains the parameters to configure the middleware.
    ///   - logger: A type that interacts with the logging system.
    ///   - fileProvider: A type that conforms to the protocol that defines file system interactions, if any.
    func assertInit<FileSystemProvider: FileProvider>(
        configuration: DocCMiddleware<FileSystemProvider>.Configuration,
        logger: Logger = .test(),
        fileProvider: FileSystemProvider
    ) {
        // GIVEN
        // WHEN
        let middleware = DocCMiddleware(
            configuration: configuration,
            fileProvider: fileProvider,
            logger: logger
        )
        
        // THEN
        #expect(middleware.configuration.folderRoot == configuration.folderRoot)
        #expect(middleware.configuration.uriRoot == configuration.uriRoot)
        #expect(middleware.configuration.threadPool === configuration.threadPool)

        #expect(middleware.logger.label == logger.label)
        #expect(middleware.logger.logLevel == logger.logLevel)
        #expect(middleware.logger.metadataProvider == nil)
        
        #expect(type(of:middleware.fileProvider) == FileSystemProvider.self)
    }
    
    /// Asserts a URI path redirection done by the middleware.
    /// - Parameters:
    ///   - logLevel: A representation of the logging level to set in the `Logger` instance.
    ///   - uriPath: A URI path to a resource.
    ///   - uriRedirect: A redirected URI path, if any.
    ///   - statusCode: An expected status code from the response coming out of the use case.
    /// - Throws: An error in case an issue is encountered while asserting URI path redirections by the middleware.
    func assertRedirect(
        logLevel: Logger.Level,
        uriPath: String,
        to uriRedirect: String? = nil,
        expects statusCode: HTTPResponse.Status = .movedPermanently
    ) async throws {
        // GIVEN
        let logHandler: LogHandlerMock = .init()
        let logger: Logger = .test(
            level: logLevel,
            handler: logHandler
        )
        
        let context: any RequestContext = RequestContextMock(logger: logger)
        let request: Request = .test(
            method: .get,
            path: uriPath
        )
        
        let middleware = DocCMiddleware(
            configuration: .init(
                uriRoot: .Sample.uriRoot,
                folderRoot: .Sample.uriFolder
            ),
            fileProvider: FileProviderMock(),
            logger: logger
        )

        // WHEN
        let result = try await middleware.handle(request, context: context) { _, _ in
            .init(status: .ok)
        }

        // THEN
        #expect(result.status == statusCode)
        
        let events = logHandler.entries
        
        if statusCode == .movedPermanently, let uriRedirect {
            #expect(result.body.contentLength == 0)
            #expect(result.headers == [
                .location: uriRedirect,
                .contentLength: "0"
            ])
            
            if shouldEventBeLogged(
                logLevel: logLevel,
                statusCode: statusCode
            ) {
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
                        "hb.request.redirect": "\(uriRedirect)"
                    ],
                    message: "The URI path is redirected to this path: \(uriRedirect)",
                    source: .Logging.source
                ))
            } else {
                #expect(events.isEmpty)
            }
        } else {
            #expect(events.isEmpty)
        }
    }
    
    /// Asserts a URI resource serving done by the middleware.
    /// - Parameters:
    ///   - logLevel: A representation of the logging level to set in the `Logger` instance.
    ///   - uriPath: A URI path for a resource.
    ///   - uriFile: A URI path for a file in the local file system.
    ///   - statusCode: An expected status code from the response coming out of the use case, if any.
    /// - Throws: An error in case an issue is encountered while asserting URI path servings by the middleware.
    func assertServe(
        logLevel: Logger.Level,
        uriPath: String,
        uriFile: String? = nil,
        statusCode: HTTPResponse.Status? = nil
    ) async throws {
        // GIVEN
        let logHandler: LogHandlerMock = .init()
        let logger: Logger = .test(
            level: logLevel,
            handler: logHandler
        )
        let fileProvider: FileProviderMock = switch statusCode {
        case .ok: .init(fileIdentifier: .init())
        case .notFound: .init()
        default: .init(fileIdentifier: .init(), shouldLoadFile: false)
        }
        
        let context: any RequestContext = RequestContextMock(logger: logger)
        let request: Request = .test(
            method: .get,
            path: uriPath
        )

        let middleware = DocCMiddleware(
            configuration: .init(
                uriRoot: .Sample.uriRoot,
                folderRoot: .Sample.uriFolder
            ),
            fileProvider: fileProvider,
            logger: logger
        )
        
        // WHEN
        let result = try await middleware.handle(request, context: context) { _, _ in
            .init(status: .ok)
        }

        // THEN
        if let statusCode {
            #expect(result.status == statusCode)
            #expect(result.headers == [ 
                .contentLength: (statusCode == .ok ? "36" : "0")
            ])

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
                let uriFile = try #require(uriFile)

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
                            "The body of the resource \(uriFile) has \(contentLength) bytes."
                        } else {
                            "The resource \(uriFile) has not been found."
                        }
                    }(),
                    source: .Logging.source
                ))
            } else {
                #expect(events.isEmpty)
            }
        } else {
            #expect(result.status == .ok)
        }
    }
    
}

// MARK: - Helpers

private extension DocCMiddlewareTests {

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
        case .movedPermanently, .ok: [.debug, .trace]
        case .notFound: [.debug, .error, .info, .notice, .trace, .warning]
        default: []
        }
        
        return levels.contains(logLevel)
    }
    
}

// MARK: - Constants

private extension Input {
    /// A list of relative URI paths to match against the URI path redirections done by the middleware.
    static let redirectURIPaths: [String] = [.empty, .Path.forwardSlash, "/documentation", "/tutorials"]
    /// A list of relative URI paths to match against the URI path servings done by the middleware.
    static let serveURIPaths: [String] = [
        "/documentation/",
        "/tutorials/",
        "/data/documentation.json",
        "/favicon.ico",
        "/favicon.svg",
        "/theme-settings.json",
        "/css/file.css",
        "/data/data.bin",
        "/downloads/file.txt",
        "/images/image.png",
        "/img/image.jpg",
        "/index/file",
        "/js/file.js", 
        "/videos/video.mp4"
    ]
}

private extension Output {
    /// A list of expected relative URI path redirections outputs coming out of the URI path redirections done by the middleware.
    static let redirectURIPaths: [String] = [.Path.forwardSlash, "/documentation", "/documentation/", "/tutorials/"]
    /// A list of expected relative file URI paths of the logged messages coming out of the URI path servings done by the middleware.
    static let serveURIFilePaths: [String] = [
        "/SomeDocument.doccarchive/documentation/somedocument/index.html",
        "/SomeDocument.doccarchive/tutorials/somedocument/index.html",
        "/SomeDocument.doccarchive/data/documentation/somedocument.json",
        "/SomeDocument.doccarchive/SomeDocument/favicon.ico",
        "/SomeDocument.doccarchive/SomeDocument/favicon.svg",
        "/SomeDocument.doccarchive/SomeDocument/theme-settings.json",
        "/SomeDocument.doccarchive/SomeDocument/css/file.css",
        "/SomeDocument.doccarchive/SomeDocument/data/data.bin",
        "/SomeDocument.doccarchive/SomeDocument/downloads/file.txt",
        "/SomeDocument.doccarchive/SomeDocument/images/image.png",
        "/SomeDocument.doccarchive/SomeDocument/img/image.jpg",
        "/SomeDocument.doccarchive/SomeDocument/index/file",
        "/SomeDocument.doccarchive/SomeDocument/js/file.js",
        "/SomeDocument.doccarchive/SomeDocument/videos/video.mp4"
    ]
}
