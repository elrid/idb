/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import CompanionLib
import Foundation
import GRPC
import IDBCompanionUtilities
import IDBGRPCSwift
import IOSurface
import NIOHPACK
import SwiftProtobuf
import XCTestBootstrap

// XPC imports
import Darwin

final class CompanionServiceProvider: Idb_CompanionServiceAsyncProvider {

  private let target: FBiOSTarget
  private let commandExecutor: FBIDBCommandExecutor
  private let reporter: FBEventReporter
  private let logger: FBIDBLogger
  private let interceptorFactory: Idb_CompanionServiceServerInterceptorFactoryProtocol

  init(
    target: FBiOSTarget,
    commandExecutor: FBIDBCommandExecutor,
    reporter: FBEventReporter,
    logger: FBIDBLogger,
    interceptors: Idb_CompanionServiceServerInterceptorFactoryProtocol
  ) {
    self.target = target
    self.commandExecutor = commandExecutor
    self.reporter = reporter
    self.logger = logger
    self.interceptorFactory = interceptors
  }

  var interceptors: Idb_CompanionServiceServerInterceptorFactoryProtocol? { interceptorFactory }

  private var targetLogger: FBControlCoreLogger {
    get throws {
      guard let logger = target.logger else {
        throw GRPCStatus(code: .internalError, message: "Target logger not configured")
      }
      return logger
    }
  }

  func connect(request: Idb_ConnectRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_ConnectResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await ConnectMethodHandler(reporter: reporter, logger: logger, target: target)
        .handle(request: request, context: context)
    }
  }

  func debugserver(requestStream: GRPCAsyncRequestStream<Idb_DebugServerRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_DebugServerResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await DebugserverMethodHandler(commandExecutor: commandExecutor)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func dap(requestStream: GRPCAsyncRequestStream<Idb_DapRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_DapResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await DapMethodHandler(commandExecutor: commandExecutor, targetLogger: targetLogger)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func describe(request: Idb_TargetDescriptionRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_TargetDescriptionResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await DescribeMethodHandler(reporter: reporter, logger: logger, target: target, commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func install(requestStream: GRPCAsyncRequestStream<Idb_InstallRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_InstallResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await InstallMethodHandler(commandExecutor: commandExecutor, targetLogger: targetLogger)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func instruments_run(requestStream: GRPCAsyncRequestStream<Idb_InstrumentsRunRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_InstrumentsRunResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await InstrumentsRunMethodHandler(target: target, targetLogger: targetLogger, commandExecutor: commandExecutor, logger: logger)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func log(request: Idb_LogRequest, responseStream: GRPCAsyncResponseStreamWriter<Idb_LogResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await LogMethodHandler(target: target, commandExecutor: commandExecutor)
        .handle(request: request, responseStream: responseStream, context: context)
    }
  }

  func xctrace_record(requestStream: GRPCAsyncRequestStream<Idb_XctraceRecordRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_XctraceRecordResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await XctraceRecordMethodHandler(logger: logger, targetLogger: targetLogger, target: target)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func accessibility_info(request: Idb_AccessibilityInfoRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_AccessibilityInfoResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await AccessibilityInfoMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func focus(request: Idb_FocusRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_FocusResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await FocusMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func hid(requestStream: GRPCAsyncRequestStream<Idb_HIDEvent>, context: GRPCAsyncServerCallContext) async throws -> Idb_HIDResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await HidMethodHandler(commandExecutor: commandExecutor)
        .handle(requestStream: requestStream, context: context)
    }
  }

  func open_url(request: Idb_OpenUrlRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_OpenUrlRequest {
    return try await FBTeardownContext.withAutocleanup {
      try await OpenUrlMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func set_location(request: Idb_SetLocationRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_SetLocationResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await SetLocationMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func send_notification(request: Idb_SendNotificationRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_SendNotificationResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await SendNotificationMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func simulate_memory_warning(request: Idb_SimulateMemoryWarningRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_SimulateMemoryWarningResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await SimulateMemoryWarningMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func approve(request: Idb_ApproveRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_ApproveResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await ApproveMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func revoke(request: Idb_RevokeRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_RevokeResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await RevokeMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func clear_keychain(request: Idb_ClearKeychainRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_ClearKeychainResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await ClearKeychainMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func contacts_update(request: Idb_ContactsUpdateRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_ContactsUpdateResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await ContactsUpdateMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func setting(request: Idb_SettingRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_SettingResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await SettingMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func get_setting(request: Idb_GetSettingRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_GetSettingResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await GetSettingMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func list_settings(request: Idb_ListSettingRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_ListSettingResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await ListSettingsMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func launch(requestStream: GRPCAsyncRequestStream<Idb_LaunchRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_LaunchResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await LaunchMethodHandler(commandExecutor: commandExecutor)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func list_apps(request: Idb_ListAppsRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_ListAppsResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await ListAppsMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func terminate(request: Idb_TerminateRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_TerminateResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await TerminateMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func uninstall(request: Idb_UninstallRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_UninstallResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await UninstallMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func add_media(requestStream: GRPCAsyncRequestStream<Idb_AddMediaRequest>, context: GRPCAsyncServerCallContext) async throws -> Idb_AddMediaResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await AddMediaMethodHandler(commandExecutor: commandExecutor)
        .handle(requestStream: requestStream, context: context)
    }
  }

  func record(requestStream: GRPCAsyncRequestStream<Idb_RecordRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_RecordResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await RecordMethodHandler(target: target, targetLogger: targetLogger)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func screenshot(request: Idb_ScreenshotRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_ScreenshotResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await ScreenshotMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func get_main_screen_iosurface(request: Idb_GetMainScreenIOSurfaceRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_GetMainScreenIOSurfaceResponse {
    return try await FBTeardownContext.withAutocleanup {
      do {
        // Get the IOSurface object from the command executor
        let surface = try await BridgeFuture.value(commandExecutor.get_main_screen_iosurface())
        
        // Validate the XPC service parameter
        guard !request.xpcService.isEmpty else {
          throw GRPCStatus(code: .invalidArgument, message: "XPC service name is required")
        }
        
        // Send the IOSurface via XPC
        let result = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
          let serviceNameCString = request.xpcService.cString(using: .utf8)!
          
          // Create XPC connection
          let connection = xpc_connection_create_mach_service(serviceNameCString, nil, 0)
          
          // Use a flag to ensure continuation is only resumed once
          var continuationResumed = false
          
          xpc_connection_set_event_handler(connection) { event in
            // Handle connection errors only if continuation hasn't been resumed yet
            if xpc_get_type(event) == XPC_TYPE_ERROR && !continuationResumed {
              continuationResumed = true
              let errorDescription = "XPC connection error"
              continuation.resume(throwing: GRPCStatus(code: .internalError, message: errorDescription))
              return
            }
          }
          
          xpc_connection_resume(connection)
          
          // Create XPC object from IOSurface
          let surfaceRef = Unmanaged.passUnretained(surface).toOpaque()
          let ioSurfaceRef = unsafeBitCast(surfaceRef, to: IOSurfaceRef.self)
          let xpcObject = IOSurfaceCreateXPCObject(ioSurfaceRef)
          
          guard xpcObject != nil else {
            if !continuationResumed {
              continuationResumed = true
              continuation.resume(throwing: GRPCStatus(code: .internalError, message: "Failed to create XPC object from IOSurface"))
            }
            return
          }
          
          // Create message dictionary
          let message = xpc_dictionary_create(nil, nil, 0)
          xpc_dictionary_set_string(message, "cmd", "sendSurface")
          xpc_dictionary_set_value(message, "surf", xpcObject)
          
          // Send message with reply
          xpc_connection_send_message_with_reply(connection, message, DispatchQueue.main) { reply in
            defer {
              xpc_connection_cancel(connection)
            }
            
            // Only resume continuation if it hasn't been resumed yet
            guard !continuationResumed else { return }
            continuationResumed = true
            
            if xpc_get_type(reply) == XPC_TYPE_ERROR {
              let errorDescription = "XPC reply error"
              continuation.resume(throwing: GRPCStatus(code: .internalError, message: errorDescription))
              return
            }
            
            // Get status from reply
            let status = xpc_dictionary_get_string(reply, "status")
            let statusString = status != nil ? String(cString: status!) : "no status"
            
            continuation.resume(returning: statusString)
          }
        }
        
        return .with {
          $0.status = result
        }
      } catch {
        // Map specific error types to appropriate gRPC status codes
        let errorMessage = error.localizedDescription
        
        if errorMessage.contains("only supported for simulator targets") {
          throw GRPCStatus(code: .unimplemented, message: "IOSurface access is only supported for simulator targets")
        } else if errorMessage.contains("must be booted") {
          throw GRPCStatus(code: .failedPrecondition, message: "Simulator must be booted to access IOSurface")
        } else if errorMessage.contains("doesn't support framebuffer access") {
          throw GRPCStatus(code: .unimplemented, message: "Target doesn't support framebuffer access")
        } else if errorMessage.contains("Failed to connect to framebuffer") {
          throw GRPCStatus(code: .internalError, message: "Failed to connect to framebuffer")
        } else if errorMessage.contains("Timeout waiting for IOSurface") {
          throw GRPCStatus(code: .deadlineExceeded, message: "Timeout waiting for IOSurface to become available")
        } else if errorMessage.contains("No IOSurface available") {
          throw GRPCStatus(code: .unavailable, message: "No IOSurface currently available")
        } else if errorMessage.contains("Invalid IOSurface") {
          throw GRPCStatus(code: .dataLoss, message: "Invalid IOSurface properties")
        } else {
          // Generic error handling
          throw GRPCStatus(code: .internalError, message: "IOSurface access failed: \(errorMessage)")
        }
      }
    }
  }

  func video_stream(requestStream: GRPCAsyncRequestStream<Idb_VideoStreamRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_VideoStreamResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await VideoStreamMethodHandler(target: target, targetLogger: targetLogger, commandExecutor: commandExecutor)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }

  func crash_delete(request: Idb_CrashLogQuery, context: GRPCAsyncServerCallContext) async throws -> Idb_CrashLogResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await CrashDeleteMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func crash_list(request: Idb_CrashLogQuery, context: GRPCAsyncServerCallContext) async throws -> Idb_CrashLogResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await CrashListMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func crash_show(request: Idb_CrashShowRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_CrashShowResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await CrashShowMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func xctest_list_bundles(request: Idb_XctestListBundlesRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_XctestListBundlesResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await XCTestListBundlesMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func xctest_list_tests(request: Idb_XctestListTestsRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_XctestListTestsResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await XCTestListTestsMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func xctest_run(request: Idb_XctestRunRequest, responseStream: GRPCAsyncResponseStreamWriter<Idb_XctestRunResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await XCTestRunMethodHandler(target: target, commandExecutor: commandExecutor, reporter: reporter, targetLogger: targetLogger, logger: logger)
        .handle(request: request, responseStream: responseStream, context: context)
    }
  }

  func ls(request: Idb_LsRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_LsResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await LsMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func mkdir(request: Idb_MkdirRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_MkdirResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await MkdirMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func mv(request: Idb_MvRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_MvResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await MvMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func rm(request: Idb_RmRequest, context: GRPCAsyncServerCallContext) async throws -> Idb_RmResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await RmMethodHandler(commandExecutor: commandExecutor)
        .handle(request: request, context: context)
    }
  }

  func pull(request: Idb_PullRequest, responseStream: GRPCAsyncResponseStreamWriter<Idb_PullResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await PullMethodHandler(target: target, commandExecutor: commandExecutor)
        .handle(request: request, responseStream: responseStream, context: context)
    }
  }

  func push(requestStream: GRPCAsyncRequestStream<Idb_PushRequest>, context: GRPCAsyncServerCallContext) async throws -> Idb_PushResponse {
    return try await FBTeardownContext.withAutocleanup {
      try await PushMethodHandler(target: target, commandExecutor: commandExecutor)
        .handle(requestStream: requestStream, context: context)
    }
  }

  func tail(requestStream: GRPCAsyncRequestStream<Idb_TailRequest>, responseStream: GRPCAsyncResponseStreamWriter<Idb_TailResponse>, context: GRPCAsyncServerCallContext) async throws {
    return try await FBTeardownContext.withAutocleanup {
      try await TailMethodHandler(commandExecutor: commandExecutor)
        .handle(requestStream: requestStream, responseStream: responseStream, context: context)
    }
  }
}
