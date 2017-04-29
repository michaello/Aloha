//
//  CameraViewController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 16/04/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

let maximumMovieLength: CGFloat = 10.0
let isSimulator = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil

enum CameraType {
    case front
    case back
}

final class CameraViewController: UIViewController {

    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var bottomCameraView: UIView!
    @IBOutlet private weak var videosButton: UIButton!
    fileprivate var recordButton: RecordButton!
    private var effectView: CustomBlurRadiusView!
    
    private var recordButtonTimer: Timer!
    private var recordButtonProgress: CGFloat = 0.0
    private var isRecording = false
    private var recording = Recording()
    private var cameraType = CameraType.front
    
    fileprivate let speechController = SpeechController()
    fileprivate let assetController = AssetController()
    private let permissionController = PermissionController()

    
    private struct Constants {
        static let recordButtonIntervalIncrementTime = 0.1
        static let allPossibleCameras: [(cameraType: AVCaptureDeviceType, position: AVCaptureDevicePosition)] = [
(AVCaptureDeviceType.builtInDualCamera, AVCaptureDevicePosition.back),
(AVCaptureDeviceType.builtInWideAngleCamera, AVCaptureDevicePosition.back),
(AVCaptureDeviceType.builtInWideAngleCamera, AVCaptureDevicePosition.front)
        ]
    }
    
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue", attributes: [], target: nil)
    private let sessionPresetQuality = AVCaptureSessionPresetMedium
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var anyCamera: AVCaptureDevice? {
        return Constants.allPossibleCameras.flatMap { AVCaptureDevice.defaultDevice(withDeviceType: $0.cameraType, mediaType: AVMediaTypeVideo, position: $0.position) }.first
    }
    private var frontCamera: AVCaptureDevice? {
        let frontCameraType = Constants.allPossibleCameras.last!
        return AVCaptureDevice.defaultDevice(withDeviceType: frontCameraType.cameraType, mediaType: AVMediaTypeVideo, position: frontCameraType.position)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupSession()
        permissionController.requestForAllPermissions { _ in }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        effectView.setToCustomBlurRadius()
        //TODO: Fix to avoid crash between commitConfiguration and startRunning
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.3) {
            self.session.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
    
    func updateRecordButtonProgress() {
        recordButtonProgress = recordButtonProgress + (CGFloat(Constants.recordButtonIntervalIncrementTime) / maximumMovieLength)
        recordButton.setProgress(recordButtonProgress)
        if recordButtonProgress >= 1.0 {
            stopRecording()
        }
    }
    
    @IBAction func changeCameraAction(_ sender: UIButton) {
        cameraType = cameraType == .front ? .back : .front
        sessionQueue.async { [unowned self] in
            self.addVideoInput(type: self.cameraType)
        }
    }

    @IBAction func videosButtonAction(_ sender: UIButton) {
        var config = Configuration()
        config.doneButtonTitle = "Finish"
        config.noImagesTitle = "Sorry! There are no images here!"
        
        let imagePicker = ImagePickerController()
        imagePicker.view.backgroundColor = .clear
        imagePicker.modalPresentationStyle = .overCurrentContext
        
        imagePicker.configuration = config
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    fileprivate func performSpeechDetection(from asset: AVAsset) {
        speechController.detectSpeechPromise(from: asset)
            .then { [unowned self] speechArray in
                DispatchQueue.main.async {
                    self.presentVideoPreviewViewController(with: asset, speechArray: speechArray)
                }
            }
            .catch { _ in
                DispatchQueue.main.async { UIAlertController.showSpeechNotDetectedAlert() }
            }
            .always {
                DispatchQueue.main.async { self.recordButton.stopLoading() }
            }
    }
    
    @objc private func startRecording() {
        recording.start()
        isRecording = true
        Logger.verbose("Started recording. \(Date())")
        recordButtonTimer = .scheduledTimer(timeInterval: Constants.recordButtonIntervalIncrementTime, target: self, selector: #selector(CameraViewController.updateRecordButtonProgress), userInfo: nil, repeats: true)
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
        guard !isSimulator else { return }
        movieFileOutput.startRecording(toOutputFileURL: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
    }
    
    @objc private func stopRecording() {
        guard isRecording else { return }
        isRecording = false
        Logger.verbose("Ended recording. Recording time: \(recording.end()) seconds")
        recordButtonStopRecording()
        guard !isSimulator else { return }
        movieFileOutput.stopRecording()
    }
    
    private func recordButtonStopRecording() {
        recordButtonTimer.invalidate()
        recordButtonProgress = 0.0
        recordButton.buttonState = .idle
        recordButton.startLoading()
    }
    
    private func setupLayout() {
        setupRecordButton()
        setupVideosButton()
        effectView = CustomBlurRadiusView()
        effectView.frame = bottomCameraView.bounds
        bottomCameraView.insertSubview(effectView, at: 0)
    }
    
    private func setupSession() {
        guard !isSimulator else { return }
        previewView.session = session
        checkAuthorization()
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
    }
    
    private func addVideoInput(type: CameraType) {
        let camera = type == .front ? frontCamera : anyCamera
        guard let cameraToSet = camera, let videoDeviceInput = try? AVCaptureDeviceInput(device: cameraToSet) else { return }
        removePreviousCameraDeviceInputIfNeeded()
        if session.canAddInput(videoDeviceInput) {
            session.beginConfiguration()
            session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            session.commitConfiguration()
            DispatchQueue.main.async {
                self.previewView.videoPreviewLayer.connection.videoOrientation = .portrait
            }
        }
    }
    
    private func removePreviousCameraDeviceInputIfNeeded() {
        guard let input = videoDeviceInput else { return }
        session.beginConfiguration()
        session.removeInput(input)
        session.commitConfiguration()
    }
    
    private func addAudioInput() {
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice)
        
        if let audioDeviceInput = audioDeviceInput, session.canAddInput(audioDeviceInput) {
            session.addInput(audioDeviceInput)
        }
    }
    
    private func configureSession() {
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        addVideoInput(type: cameraType)
        addAudioInput()

        if session.canAddOutput(movieFileOutput) {
            session.beginConfiguration()
            session.addOutput(movieFileOutput)
            session.sessionPreset = sessionPresetQuality
            if let connection = movieFileOutput.connection(withMediaType: AVMediaTypeVideo) {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            session.commitConfiguration()
        }
    }
    
    private func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .notDetermined:
            requestForCameraAccess()
        default: ()
        }
    }
    
    private func requestForCameraAccess() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] isGranted in
            self.sessionQueue.async { [unowned self] in
                self.configureSession()
            }
            self.sessionQueue.resume()
        })
    }
    
    private func setupVideosButton() {
        videosButton.setTitleColor(.themeColor, for: [])
    }
    
    private func setupRecordButton() {
        recordButton = RecordButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        recordButton.progressColor = .white
        recordButton.center = CGPoint(x: bottomCameraView.center.x - (recordButton.frame.width / 4), y: bottomCameraView.frame.height / 2)
        bottomCameraView.addSubview(recordButton)
        setupRecordButtonActions()
    }
    
    private func setupRecordButtonActions() {
        recordButton.addTarget(self, action: #selector(CameraViewController.startRecording), for: .touchDown)
        recordButton.addTarget(self, action: #selector(CameraViewController.stopRecording), for: UIControlEvents.touchUpInside)
    }
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        let asset = AVURLAsset(url: outputFileURL)
        performSpeechDetection(from: asset)
    }
}

extension CameraViewController: ImagePickerDelegate {
    func tooLongMovieSelected() {
        Logger.info("User tapped movie that is too long.")
        UIAlertController.showTooLongVideoAlert()
    }
    
    func wrapperDidPress(_ imagePicker: ImagePickerController, images: [UIImage]) {}
    func cancelButtonDidPress(_ imagePicker: ImagePickerController) {}

    func doneButtonDidPress(_ imagePicker: ImagePickerController, asset: PHAsset) {
        recordButton.startLoading()
        imagePicker.dismiss(animated: true) {
            self.assetController.AVAssetPromise(from: asset)
                .then { [unowned self] videoAsset in
                    DispatchQueue.main.async {
                        self.presentVideoEditorViewController(videoToEdit: videoAsset)
                    }
            }
        }
    }
    
    fileprivate func presentVideoPreviewViewController(with asset: AVAsset?, speechArray: [SpeechModel]? = nil) {
        guard let asset = asset else { return }
        let videoPreviewViewController = self.storyboard?.instantiateViewController(withIdentifier: String(describing: VideoPreviewViewController.self)) as! VideoPreviewViewController
        videoPreviewViewController.selectedVideo = asset
        if let speechArray = speechArray {
            videoPreviewViewController.speechArray = speechArray
        }
        present(videoPreviewViewController, animated: true, completion: nil)
    }
    
    private func presentVideoEditorViewController(videoToEdit video: AVAsset) {
        guard let videoPath = (video as? AVURLAsset)?.url.path else { return }
        let videoEditorController = UIVideoEditorController()
        videoEditorController.videoMaximumDuration = TimeInterval(maximumMovieLength)
        videoEditorController.videoQuality = .typeMedium
        videoEditorController.delegate = self
        videoEditorController.videoPath = videoPath
        present(videoEditorController, animated: true, completion: nil)
    }
}

extension CameraViewController: UINavigationControllerDelegate, UIVideoEditorControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) { 
            editor.dismiss(animated: true) {
                let asset = AVURLAsset(url: URL(fileURLWithPath: editedVideoPath))
                self.performSpeechDetection(from: asset)
            }
        }
    }
}
