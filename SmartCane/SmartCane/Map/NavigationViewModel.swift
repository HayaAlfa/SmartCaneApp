import Foundation
import SwiftUI
import UIKit
import MapKit
import CoreLocation
import AVFoundation
import Speech
import MediaPlayer
import os.log

// MARK: - Helpers
extension CLLocationCoordinate2D {
    func toCLLocation() -> CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

// MARK: - SmartCane Navigation View Model
class NavigationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @Published var mapPosition: MapCameraPosition = .automatic

    @Published var startText = ""
    @Published var endText = ""
    @Published var currentInstruction: String?
    @Published var showAlert = false
    @Published var isTestingMode = false
    @Published var annotations: [PlaceAnnotation] = []
    @Published var route: MKRoute?
    @Published var isListening = false
    @Published var isNavigating = false
    @Published var shouldAutoStartNavigation = false

    private let locationManager = CLLocationManager()
    private let synthesizer = AVSpeechSynthesizer()
    private var routeSteps: [MKRoute.Step] = []
    private var currentStepIndex = 0
    
    // Location properties
    @Published var currentLocation: CLLocation?

    // Speech recognition (only active when screen is on)
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var isListeningForCommands = false
    private var isScreenOn = true // Track screen state
    
    // Route deviation detection
    private var routeCoordinates: [CLLocation] = []
    private var currentSegmentIndex = 0
    private var deviationCounter = 0
    private let deviationThreshold: CLLocationDistance = 15.0 // meters
    private let deviationLimit = 3 // consecutive updates
    private var lastFeedbackTime = Date()
    private let feedbackCooldown: TimeInterval = 10.0 // seconds - increased to prevent spam
    
    // Movement and deviation tracking
    private var lastKnownLocation: CLLocation?
    private var lastDeviationDistance: CLLocationDistance = 0
    private var isOffRoute = false
    private var hasWarnedOffRoute = false
    private var lastMovementTime = Date()
    private let movementThreshold: CLLocationDistance = 5.0 // meters
    private let minTimeBetweenChecks: TimeInterval = 2.0 // seconds
    
    private var testingTimer: DispatchWorkItem?
    private var isCleaningUp = false
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    private var recursiveCallCount = 0
    private let maxRecursiveCalls = 3
    
    // Serial queue for navigation operations to prevent race conditions
    private let navigationQueue = DispatchQueue(label: "com.smartcane.navigation", qos: .userInitiated)
    
    // Production logging system
    private let logger = Logger(subsystem: "com.smartcane.navigation", category: "SmartCane")
    private let isDebugMode = true // Set to false for production
    
    // Early/final announcement tracking per step index
    private var announcedEarlySteps: Set<Int> = []
    private var announcedFinalSteps: Set<Int> = []
    
    // MARK: - Logging Helpers
    private func logInfo(_ message: String) {
        if isDebugMode {
            print("ℹ️ \(message)")
        }
        logger.info("\(message)")
    }
    
    private func logWarning(_ message: String) {
        if isDebugMode {
            print("⚠️ \(message)")
        }
        logger.warning("\(message)")
    }
    
    private func logError(_ message: String) {
        if isDebugMode {
            print("❌ \(message)")
        }
        logger.error("\(message)")
    }
    
    private func logDebug(_ message: String) {
        if isDebugMode {
            print("🔍 \(message)")
        }
        logger.debug("\(message)")
    }

    func requestPermission() {
        // Set up screen state detection
        setupScreenStateDetection()
        
        // Configure audio session for background capability first
        configureAudioSession()
        
        locationManager.delegate = self
        
        // Optimize location updates for battery efficiency
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters // Reduce accuracy for better performance
        locationManager.distanceFilter = 5.0 // Only update when moved 5 meters
        
        // Request location authorization first (Always for background updates)
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        // Setup audio interruption handling
        setupAudioInterruptionObserver()
        
        // Test background audio capability
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.logInfo("App initialized - background audio should be ready")
        }
    }
    
    // MARK: - Screen State Detection
    func setupScreenStateDetection() {
        // Listen for app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    @objc func appDidEnterBackground() {
        isScreenOn = false
        logInfo("App entered background - disabling voice recognition")
        stopListening()
        logInfo("Background mode - audio should continue working")
    }
    
    @objc func appWillEnterForeground() {
        isScreenOn = true
        logInfo("App entered foreground - enabling voice recognition")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Location Optimization
    func optimizeLocationForNavigation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.distanceFilter = 3.0
        logInfo("Location optimized for active navigation")
    }
    
    func optimizeLocationForBattery() {
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = 10.0
        logInfo("Location optimized for battery saving")
    }
    
    // MARK: - Remote Command Center
    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self else { return .success }
            if !self.synthesizer.isSpeaking { self.announceNextStep() }
            return .success
        }
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.synthesizer.stopSpeaking(at: .immediate)
            return .success
        }
        logInfo("Remote command center configured for lock screen controls")
    }
    
    // MARK: - Background Location Safety
    private func canUseBackgroundLocation() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        guard locationManager.authorizationStatus == .authorizedAlways else { return false }
        guard let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] else { return false }
        return backgroundModes.contains("location")
        #endif
    }
    
    // MARK: - Background Task Management
    func startBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.logWarning("Background task expired, ending task")
            self?.endBackgroundTask()
        }
        logInfo("Background task started: \(backgroundTask.rawValue)")
    }
    
    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            logInfo("Background task ended: \(backgroundTask.rawValue)")
            backgroundTask = .invalid
        }
    }

    func setupRoute() {
        navigationQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isNavigating {
                logInfo("Canceling current navigation to start new route...")
                self.clearRoute()
                self.recursiveCallCount += 1
                if self.recursiveCallCount > self.maxRecursiveCalls {
                    logWarning("Too many recursive calls, aborting to prevent infinite loop")
                    self.recursiveCallCount = 0
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.setupRoute() }
                return
            }
            guard !self.isCleaningUp else {
                self.logWarning("Cleanup in progress — please wait a moment.")
                self.speak("Please wait for cleanup to complete.")
                return
            }
            guard let startCoord = self.parseCoordinate(from: self.startText),
                  let endCoord = self.parseCoordinate(from: self.endText) else {
                self.speak("Invalid coordinates. Please enter valid numbers.")
                return
            }
            logInfo("Setting up walking route from \(startCoord.latitude), \(startCoord.longitude) to \(endCoord.latitude), \(endCoord.longitude)")
            DispatchQueue.main.async {
                self.annotations = [
                    PlaceAnnotation(coordinate: startCoord, name: "Start"),
                    PlaceAnnotation(coordinate: endCoord, name: "Destination")
                ]
                self.region.center = startCoord
            }
            self.getWalkingDirections(from: startCoord, to: endCoord)
            self.recursiveCallCount = 0
        }
    }

    func getWalkingDirections(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end))
        request.transportType = .walking
        MKDirections(request: request).calculate { [weak self] response, error in
            guard let route = response?.routes.first else {
                self?.logError("Unable to find walking route")
                self?.speak("Unable to find walking route.")
                return
            }
            self?.logInfo("Route found: \(String(format: "%.1f", route.distance))m, \(route.steps.count) steps")
            print("🧭 getWalkingDirections: setting route with \(route.steps.count) steps and distance \(String(format: "%.1f m", route.distance))")
            self?.routeSteps = route.steps.filter { !$0.instructions.isEmpty }
            self?.extractRouteCoordinates(from: route)
            self?.route = route
            if self?.shouldAutoStartNavigation == true {
                self?.startNavigation()
            } else {
                self?.askToStartNavigation()
            }
        }
    }

    func startNavigation() {
        guard !isNavigating else { logWarning("Navigation already in progress, ignoring duplicate start"); return }
        DispatchQueue.main.async { self.isNavigating = true }
        setupRemoteCommandCenter()
        // If we only have When In Use, request Always so background can work
        if locationManager.authorizationStatus == .authorizedWhenInUse {
            logInfo("Requesting Always authorization for background navigation…")
            locationManager.requestAlwaysAuthorization()
        }
        if canUseBackgroundLocation() {
            DispatchQueue.main.async {
                self.locationManager.allowsBackgroundLocationUpdates = true
                self.locationManager.pausesLocationUpdatesAutomatically = false
                self.logInfo("Background location updates enabled for navigation")
            }
            startBackgroundTask()
            logInfo("Background task started for Always location authorization")
        } else {
            logWarning("Background task not started - simulator, When In Use authorization, or missing UIBackgroundModes")
            logInfo("Navigation will work when screen is on, but not in background")
        }
        logInfo("Starting Walking Navigation...")
        logInfo("Mode: \(isTestingMode ? "Testing (Simulated)" : "Real GPS Tracking")")
        logInfo("Voice guidance will be provided for each step")
        logInfo("Background navigation enabled - works when screen is off")
        logInfo(String(repeating: "=", count: 50))
        currentStepIndex = 0
        isOffRoute = false
        hasWarnedOffRoute = false
        deviationCounter = 0
        lastKnownLocation = nil
        lastDeviationDistance = 0
        lastMovementTime = Date()
        if !isTestingMode {
            locationManager.delegate = self
            optimizeLocationForNavigation()
            locationManager.startUpdatingLocation()
            print("📍 GPS tracking enabled for real navigation")
        } else {
            print("⏱️ Testing mode: Steps will advance automatically every 10 seconds")
        }
        announceNextStep()
        // Reset announcement tracking for the new sequence
        announcedEarlySteps.removeAll()
        announcedFinalSteps.removeAll()
    }

    func announceNextStep() {
        guard currentStepIndex < routeSteps.count else {
            print("🎉 Navigation Complete - Arrived at destination!")
            print(String(repeating: "=", count: 50))
            speak("You have arrived at your destination.")
            DispatchQueue.main.async { self.currentInstruction = "Arrived"; self.isNavigating = false }
            endBackgroundTask()
            if !isTestingMode { locationManager.stopUpdatingLocation(); optimizeLocationForBattery(); print("📍 GPS tracking stopped") }
            return
        }
        let step = routeSteps[currentStepIndex]
        let simple = simplifyInstruction(step.instructions)
        DispatchQueue.main.async { self.currentInstruction = simple }
        logInfo("Step \(currentStepIndex + 1)/\(routeSteps.count): \(simple)")
        speak(simple)
        if isTestingMode {
            print("⏱️ Testing mode: Next step in 10 seconds...")
            testingTimer?.cancel(); testingTimer = nil
            testingTimer = DispatchWorkItem { [weak self] in
                guard let self = self else { return }
                self.currentStepIndex += 1
                self.announceNextStep()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: testingTimer!)
        } else {
            print("📍 Waiting for GPS to reach next waypoint...")
        }
    }

    func simplifyInstruction(_ text: String) -> String {
        let t = text.lowercased()
        if t.contains("u-turn") || t.contains("u turn") { return "Make a U-turn" }
        if t.contains("roundabout") { return "Enter the roundabout" }
        if t.contains("left") { return "Turn left" }
        if t.contains("right") { return "Turn right" }
        if t.contains("destination") || t.contains("arrive") { return "You have arrived at your destination" }
        if t.contains("continue") || t.contains("straight") { return "Continue straight" }
        if t.contains("start on") || t.contains("onto") || t.starts(with: "head") { return "Go ahead" }
        // Fallback to original if no keyword matched
        return text
    }

    func speak(_ text: String) {
        // Check if this is a cancellation message - only skip if VoiceOver is on
        let isCancelMessage = text.lowercased().contains("cancelled") && text.lowercased().contains("route cleared")
        if isCancelMessage {
            // Skip cancel message if VoiceOver is running to avoid double audio
            guard !UIAccessibility.isVoiceOverRunning else {
                logInfo("🔇 VoiceOver is active - skipping cancel message to avoid double audio")
                return
            }
        }
        // Navigation instructions always play (don't check VoiceOver for them)
        
        // Check if voice feedback is enabled in user settings
        // If disabled, don't speak anything (respects user preference)
        // Default to true if not set (first launch)
        let voiceEnabled = UserDefaults.standard.object(forKey: "voiceFeedbackEnabled") as? Bool ?? true
        guard voiceEnabled else {
            logInfo("🔇 Voice feedback is disabled - skipping speech")
            return
        }
        
        startBackgroundTask()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        utterance.volume = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.0
        synthesizer.speak(utterance)
        let estimatedDuration = Double(text.count) * 0.1 + 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + estimatedDuration) { self.endBackgroundTask() }
        logInfo("Speaking: \(text)")
    }
    
    func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .spokenAudio, options: [])
            try session.setActive(true)
            logInfo("Audio session configured for background playback")
        } catch {
            logError("Audio session configuration failed: \(error.localizedDescription)")
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback)
                try AVAudioSession.sharedInstance().setActive(true)
                logInfo("Basic audio session configured")
            } catch {
                logError("Even basic audio configuration failed: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Audio Interruption Handling
    func setupAudioInterruptionObserver() {
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance(),
            queue: .main
        ) { notification in
            guard let info = notification.userInfo,
                  let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
                  let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
            switch type {
            case .began:
                self.synthesizer.pauseSpeaking(at: .immediate)
                self.logInfo("🔇 Audio interrupted — paused speech")
            case .ended:
                if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt {
                    let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                    if options.contains(.shouldResume) {
                        self.synthesizer.continueSpeaking()
                        self.logInfo("🔊 Audio interruption ended — resumed speech")
                    }
                }
            default:
                break
            }
        }
    }
    
    func configureAudioSessionForRecording() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.allowBluetooth, .defaultToSpeaker])
            try session.setActive(true)
            logInfo("Audio session configured for speech recognition")
        } catch {
            logError("Failed to configure audio session for recording: \(error.localizedDescription)")
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                try AVAudioSession.sharedInstance().setActive(true)
                logInfo("Basic recording audio session configured")
            } catch {
                logError("Even basic recording configuration failed: \(error.localizedDescription)")
            }
        }
    }

    func parseCoordinate(from text: String) -> CLLocationCoordinate2D? {
        let parts = text.split(separator: ",").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard parts.count == 2 else { return nil }
        return CLLocationCoordinate2D(latitude: parts[0], longitude: parts[1])
    }
    
    func clearRoute() {
        print("🗑️ Clearing route and directions...")
        isCleaningUp = true
        stopListening()
        synthesizer.stopSpeaking(at: .immediate)
        endBackgroundTask()
        testingTimer?.cancel(); testingTimer = nil
        route = nil
        routeSteps = []
        currentStepIndex = 0
        currentInstruction = nil
        annotations = []
        routeCoordinates = []
        currentSegmentIndex = 0
        deviationCounter = 0
        isOffRoute = false
        hasWarnedOffRoute = false
        lastKnownLocation = nil
        lastDeviationDistance = 0
        DispatchQueue.main.async { self.isNavigating = false }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isCleaningUp = false
            self.recursiveCallCount = 0
        }
        print("✅ Route cleared successfully")
    }
    
    // MARK: - Route Deviation Detection
    func extractRouteCoordinates(from route: MKRoute) {
        routeCoordinates = []
        let polyline = route.polyline
        let pointCount = polyline.pointCount
        var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        routeCoordinates = coordinates.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
        currentSegmentIndex = 0
        deviationCounter = 0
        print("📍 Route coordinates extracted: \(routeCoordinates.count) points")
    }
    
    func checkRouteDeviation(userLocation: CLLocation) {
        guard !isTestingMode,
              currentSegmentIndex < routeCoordinates.count - 1,
              routeCoordinates.count > 1 else { return }
        let timeSinceLastCheck = Date().timeIntervalSince(lastMovementTime)
        guard timeSinceLastCheck >= minTimeBetweenChecks else { return }
        if let lastLocation = lastKnownLocation {
            let movementDistance = userLocation.distance(from: lastLocation)
            if movementDistance < movementThreshold { return }
        }
        let start = routeCoordinates[currentSegmentIndex]
        let end = routeCoordinates[currentSegmentIndex + 1]
        let currentDistance = perpendicularDistance(from: userLocation, start: start, end: end)
        if Int.random(in: 1...5) == 1 {
            print("📍 Deviation check - Distance from route: \(String(format: "%.1f", currentDistance)) meters")
        }
        let isMovingAway = lastDeviationDistance > 0 && currentDistance > lastDeviationDistance + 2.0
        if currentDistance > deviationThreshold {
            if isMovingAway || !isOffRoute {
                deviationCounter += 1
                print("⚠️ Off route detected - Counter: \(deviationCounter)/\(deviationLimit) (Moving away: \(isMovingAway))")
                if deviationCounter >= deviationLimit && !hasWarnedOffRoute {
                    let timeSinceLastFeedback = Date().timeIntervalSince(lastFeedbackTime)
                    if timeSinceLastFeedback >= feedbackCooldown {
                        DispatchQueue.main.async { self.speak("Warning! You may be off route. Please check your direction.") }
                        lastFeedbackTime = Date()
                        hasWarnedOffRoute = true
                        isOffRoute = true
                        print("🔊 Warning: Off route feedback given")
                    }
                }
            }
        } else {
            if isOffRoute {
                print("✅ Back on track - Distance: \(String(format: "%.1f", currentDistance)) meters")
                DispatchQueue.main.async { self.speak("You're back on the right track.") }
                lastFeedbackTime = Date()
            }
            deviationCounter = 0
            isOffRoute = false
            hasWarnedOffRoute = false
            let timeSinceLastFeedback = Date().timeIntervalSince(lastFeedbackTime)
            if timeSinceLastFeedback >= feedbackCooldown && currentDistance < 5.0 {
                DispatchQueue.main.async { self.speak("You're on the right track.") }
                lastFeedbackTime = Date()
                print("🔊 Positive feedback: On track")
            }
        }
        lastKnownLocation = userLocation
        lastDeviationDistance = currentDistance
        lastMovementTime = Date()
    }
    
    func perpendicularDistance(from point: CLLocation, start: CLLocation, end: CLLocation) -> CLLocationDistance {
        let ab = start.distance(from: end)
        let ap = start.distance(from: point)
        let bp = end.distance(from: point)
        if ab < 1.0 { return min(ap, bp) }
        let s = (ab + ap + bp) / 2
        let area = sqrt(s * (s - ab) * (s - ap) * (s - bp))
        return (2 * area) / ab
    }
    
    func advanceToNextSegment() {
        if currentSegmentIndex < routeCoordinates.count - 1 {
            currentSegmentIndex += 1
            deviationCounter = 0
            print("📍 Advanced to segment \(currentSegmentIndex + 1)/\(routeCoordinates.count)")
        }
    }
    
    // MARK: - Voice Command Recognition
    func askToStartNavigation() {
        navigationQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isNavigating {
                logInfo("Canceling current navigation to start new route...")
                self.clearRoute()
                self.recursiveCallCount += 1
                if self.recursiveCallCount > self.maxRecursiveCalls {
                    logWarning("Too many recursive calls, aborting to prevent infinite loop")
                    self.recursiveCallCount = 0
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.askToStartNavigation() }
                return
            }
            guard !self.isListeningForCommands && !self.isCleaningUp else {
                print("⚠️ Voice recognition or cleanup in progress — please wait a moment.")
                return
            }
            print("🎤 Starting voice + visual confirmation...")
            self.speak("Route from start to destination is set up. Say start or cancel")
            DispatchQueue.main.async { self.showAlert = true }
            if self.isScreenOn {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { self.listenForVoiceCommand() }
            }
        }
    }
    
    // MARK: - Voice Recognition Methods
    func listenForVoiceCommand() {
        guard isScreenOn else { logInfo("Screen is off - skipping voice recognition"); return }
        guard !isListeningForCommands && !isCleaningUp else { logWarning("Already listening or cleaning up — ignoring voice command request."); return }
        checkMicrophonePermission { [weak self] granted in
            guard let self = self else { return }
            if granted { self.startListening() } else { self.logError("Microphone permission denied - voice commands unavailable") }
        }
    }
    
    func startListening() {
        guard isScreenOn else { logInfo("Screen is off - not starting voice recognition"); return }
        guard !isListeningForCommands && !isCleaningUp else { logWarning("Already listening or cleaning up — ignoring start listening request."); return }
        stopListening()
        configureAudioSessionForRecording()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.setupSpeechRecognition() }
    }
    
    private func setupSpeechRecognition() {
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { logError("Failed to create recognition request"); return }
        recognitionRequest.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0 && recordingFormat.channelCount > 0 else {
            logError("Invalid recording format: sampleRate=\(recordingFormat.sampleRate), channels=\(recordingFormat.channelCount)")
            return
        }
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
            logInfo("Audio engine started successfully with format: \(recordingFormat.sampleRate)Hz, \(recordingFormat.channelCount) channels")
        } catch {
            logError("Failed to start audio engine: \(error.localizedDescription)")
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let spokenText = result.bestTranscription.formattedString.lowercased()
                self.logInfo("Recognized: \(spokenText)")
                if spokenText.contains("start") || spokenText.contains("go") || spokenText.contains("begin") || spokenText.contains("proceed") {
                    DispatchQueue.main.async { self.stopListening(); self.showAlert = false; self.startNavigation() }
                } else if spokenText.contains("cancel") || spokenText.contains("stop") || spokenText.contains("no") || spokenText.contains("exit") || spokenText.contains("abort") {
                    DispatchQueue.main.async { self.stopListening(); self.showAlert = false; self.clearRoute(); self.speak("Navigation cancelled. Route cleared.") }
                }
            }
            if let error = error {
                self.logError("Speech recognition error: \(error.localizedDescription)")
                DispatchQueue.main.async { self.stopListening() }
            }
        }
        DispatchQueue.main.async { self.isListening = true; self.isListeningForCommands = true }
        logInfo("Voice recognition started")
    }
    
    func stopListening() {
        if audioEngine.isRunning { audioEngine.stop(); audioEngine.inputNode.removeTap(onBus: 0) }
        recognitionTask?.cancel(); recognitionTask = nil
        recognitionRequest?.endAudio(); recognitionRequest = nil
        configureAudioSession()
        DispatchQueue.main.async { self.isListening = false; self.isListeningForCommands = false }
        logInfo("Voice recognition stopped")
    }
    
    func checkMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let authStatus = AVAudioApplication.shared.recordPermission
        switch authStatus {
        case .granted:
            logInfo("Microphone permission already granted"); completion(true)
        case .denied:
            logError("Microphone permission denied"); completion(false)
        case .undetermined:
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    if granted { self.logInfo("Microphone permission granted") } else { self.logError("Microphone permission denied") }
                    completion(granted)
                }
            }
        @unknown default:
            logError("Unknown microphone permission status"); completion(false)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            logInfo("Location authorization: Always (background updates enabled)")
            logInfo("Background location capability available - will be enabled during navigation")
        case .authorizedWhenInUse:
            logWarning("Location authorization: When In Use (background updates disabled)")
            logInfo("Navigation will work when screen is on, but not in background")
        case .denied, .restricted:
            logError("Location authorization denied or restricted")
        case .notDetermined:
            logInfo("Location authorization not determined yet")
        @unknown default:
            logError("Unknown location authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
            DispatchQueue.main.async {
                self.currentLocation = userLocation
                self.region.center = userLocation.coordinate
                print("📍 NavigationViewModel - Current location: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            }
        }
        guard !isTestingMode, currentStepIndex < routeSteps.count else { return }
        checkRouteDeviation(userLocation: userLocation)
        // Progress announcements in feet (early/final)
        updateNavigationProgress(currentLocation: userLocation)
        let nextStep = routeSteps[currentStepIndex]
        let stepLocation = CLLocation(latitude: nextStep.polyline.coordinate.latitude, longitude: nextStep.polyline.coordinate.longitude)
        let distance = userLocation.distance(from: stepLocation)
        print("📍 Distance to next waypoint: \(String(format: "%.1f", distance)) meters")
        if distance < 15 {
            print("✅ Close enough to next waypoint! Advancing to next step...")
            DispatchQueue.main.async {
                self.currentStepIndex += 1
                self.advanceToNextSegment()
                self.announceNextStep()
            }
        }
    }

    // MARK: - Progress Announcements in Feet
    private func updateNavigationProgress(currentLocation: CLLocation) {
        guard currentStepIndex < routeSteps.count else { return }
        let step = routeSteps[currentStepIndex]
        let stepCoordinate = step.polyline.coordinate
        let stepCL = CLLocation(latitude: stepCoordinate.latitude, longitude: stepCoordinate.longitude)
        let distanceMeters = currentLocation.distance(from: stepCL)
        let distanceFeet = distanceMeters * 3.28084

        // Early announcement around 150 feet (~45.7 meters)
        if distanceFeet < 150, distanceFeet > 60, !announcedEarlySteps.contains(currentStepIndex) {
            let short = simplifyInstruction(step.instructions)
            speak("In 150 feet, \(short.lowercased())")
            announcedEarlySteps.insert(currentStepIndex)
        }

        // Final announcement within 30 feet (~9.1 meters)
        if distanceFeet <= 30, !announcedFinalSteps.contains(currentStepIndex) {
            let short = simplifyInstruction(step.instructions)
            speak(short)
            announcedFinalSteps.insert(currentStepIndex)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logError("Location error: \(error.localizedDescription)")
        speak("Location services are not available. Please check your settings.")
    }
}

struct PlaceAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}


