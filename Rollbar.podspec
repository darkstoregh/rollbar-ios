Pod::Spec.new do |s|

  s.version                   = "1.12.14"
  s.name                      = "Rollbar"
  s.summary                   = "Objective-C library for crash reporting and logging with Rollbar. It works on iOS and macOS."
  s.description               = <<-DESC
    Find, fix, and resolve errors with Rollbar.
    Easily send error data using Rollbar's API.
    Analyze, de-dupe, send alerts, and prepare the data for further analysis.
    Search, sort, and prioritize via the Rollbar dashboard.
                                DESC
  s.homepage                  = "https://rollbar.com"
  s.license                   = { :type => "MIT", :file => "LICENSE" }
  s.author                    = { "Rollbar" => "support@rollbar.com" }
  s.social_media_url          = "http://twitter.com/rollbar"
  s.ios.deployment_target     = '9.0'
  s.osx.deployment_target     = '10.12'
  s.source                    = { :git => "https://github.com/darkstoregh/rollbar-ios.git", :submodules => true }
  
  s.source_files        = 'KSCrash/Source/KSCrash/**/*.{m,h,mm,c,cpp}',

                          'RollbarFramework/*.{h,m}',

                          'Rollbar/*.{h,m}',

                          'Rollbar/Abstraction_Common/*.{h,m}',
                          'Rollbar/Abstraction_DTO/*.{h,m}',
                          'Rollbar/Abstraction_Deploys/*.{h,m}',

                          'Rollbar/Common/*.{h,m}',

                          'Rollbar/Notifier/*.{h,m}',
                          'Rollbar/Notifier_DTOs/*.{h,m}',

                          'Rollbar/Deploys/*.{h,m}',
                          'Rollbar/Deploys_DTOs/*.{h,m}'

  s.public_header_files =
                            'RollbarFramework/Rollbar.h',

                            'Rollbar/Abstraction_Common/Persistent.h',
                            'Rollbar/Abstraction_Common/JSONSupport.h',

                            'Rollbar/Abstraction_DTO/RollbarDTOAbstraction.h',
                            'Rollbar/Abstraction_DTO/DataTransferObject.h',
                            'Rollbar/Abstraction_DTO/DataTransferObject+CustomData.h',

                            'Rollbar/Abstraction_Deploys/RollbarDeploysProtocol.h',

                            'Rollbar/Common/TriStateFlag.h',

                            'Rollbar/Notifier/RollbarFacade.h',
                            'Rollbar/Notifier/RollbarNotifier.h',
                            'Rollbar/Notifier/RollbarConfiguration.h',
                            'Rollbar/Notifier/RollbarTelemetry.h',
                            'Rollbar/Notifier/RollbarLog.h',
                            'Rollbar/Notifier/RollbarKSCrashReportSink.h',
                            'Rollbar/Notifier/RollbarKSCrashInstallation.h',
                            'Rollbar/Notifier/RollbarJSONFriendlyProtocol.h',
                            'Rollbar/Notifier/RollbarJSONFriendlyObject.h',

                            'Rollbar/Notifier_DTOs/RollbarPayloadDTOs.h',
                            'Rollbar/Notifier_DTOs/RollbarLevel.h',
                            'Rollbar/Notifier_DTOs/CaptureIpType.h',
                            'Rollbar/Notifier_DTOs/HttpMethod.h',
                            'Rollbar/Notifier_DTOs/RollbarAppLanguage.h',
                            'Rollbar/Notifier_DTOs/RollbarSource.h',
                            'Rollbar/Notifier_DTOs/RollbarPayload.h',
                            'Rollbar/Notifier_DTOs/RollbarData.h',
                            'Rollbar/Notifier_DTOs/RollbarBody.h',
                            'Rollbar/Notifier_DTOs/RollbarMessage.h',
                            'Rollbar/Notifier_DTOs/RollbarTrace.h',
                            'Rollbar/Notifier_DTOs/RollbarCallStackFrame.h',
                            'Rollbar/Notifier_DTOs/RollbarCallStackFrameContext.h',
                            'Rollbar/Notifier_DTOs/RollbarException.h',
                            'Rollbar/Notifier_DTOs/RollbarCrashReport.h',
                            'Rollbar/Notifier_DTOs/RollbarConfig.h',
                            'Rollbar/Notifier_DTOs/RollbarServerConfig.h',
                            'Rollbar/Notifier_DTOs/RollbarDestination.h',
                            'Rollbar/Notifier_DTOs/RollbarDeveloperOptions.h',
                            'Rollbar/Notifier_DTOs/RollbarProxy.h',
                            'Rollbar/Notifier_DTOs/RollbarScrubbingOptions.h',
                            'Rollbar/Notifier_DTOs/RollbarRequest.h',
                            'Rollbar/Notifier_DTOs/RollbarPerson.h',
                            'Rollbar/Notifier_DTOs/RollbarModule.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryOptions.h',
                            'Rollbar/Notifier_DTOs/RollbarLoggingOptions.h',
                            'Rollbar/Notifier_DTOs/RollbarServer.h',
                            'Rollbar/Notifier_DTOs/RollbarClient.h',
                            'Rollbar/Notifier_DTOs/RollbarJavascript.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryType.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryEvent.h',

                            'Rollbar/Notifier_DTOs/RollbarTelemetryBody.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryLogBody.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryViewBody.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryErrorBody.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryNavigationBody.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryNetworkBody.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryConnectivityBody.h',
                            'Rollbar/Notifier_DTOs/RollbarTelemetryManualBody.h',

                            'Rollbar/Deploys/RollbarDeploys.h',
                            'Rollbar/Deploys/RollbarDeploysManager.h',

                            'Rollbar/Deploys_DTOs/RollbarDeploysDTOs.h',
                            'Rollbar/Deploys_DTOs/Deployment.h',
                            'Rollbar/Deploys_DTOs/DeploymentDetails.h',
                            'Rollbar/Deploys_DTOs/DeployApiCallResult.h',
                            'Rollbar/Deploys_DTOs/DeployApiCallOutcome.h',

                            'KSCrash/Source/KSCrash/Recording/KSCrash.h',
                            'KSCrash/Source/KSCrash/Installations/KSCrashInstallation.h',
                            'KSCrash/Source/KSCrash/Installations/KSCrashInstallation+Private.h',
                            'KSCrash/Source/KSCrash/Reporting/Filters/KSCrashReportFilterBasic.h',
                            'KSCrash/Source/KSCrash/Reporting/Filters/KSCrashReportFilterAppleFmt.h',
                            'KSCrash/Source/KSCrash/Recording/KSCrashReportWriter.h',
                            'KSCrash/Source/KSCrash/Reporting/Filters/KSCrashReportFilter.h',
                            'KSCrash/Source/KSCrash/Recording/Monitors/KSCrashMonitorType.h'

  s.ios.frameworks =
                "Foundation",
                "SystemConfiguration",
                "UIKit",
                "MessageUI"
  s.osx.frameworks =
                "Foundation",
                "SystemConfiguration"
  s.libraries =
                "c++",
                "z"
  s.requires_arc = true

  s.pod_target_xcconfig = {
    "USE_HEADERMAP" => "NO",
    "HEADER_SEARCH_PATHS" => "\"$(PODS_ROOT)/Rollbar/**\""
  }

end
