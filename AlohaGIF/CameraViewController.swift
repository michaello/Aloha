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

let maximumMovieLength: CGFloat = 15.0
let resourceName = "IMG_0418"

final class CameraViewController: UIViewController {

    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var bottomCameraView: UIView!
    @IBOutlet private weak var videosButton: UIButton!
    private var effectView: UIVisualEffectView!
    
    private var recordButton: RecordButton!
    private var recordButtonTimer: Timer!
    private var recordButtonProgress: CGFloat = 0.0
    private var isSimulator: Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }
    fileprivate let speechController = SpeechController()
    fileprivate let assetController = AssetController()
    private let permissionController = PermissionController()
    private var recording = Recording()
    
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
    private let sessionPresetQuality = AVCaptureSessionPresetHigh
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    var anyCamera: AVCaptureDevice? {
        return Constants.allPossibleCameras.flatMap { AVCaptureDevice.defaultDevice(withDeviceType: $0.cameraType, mediaType: AVMediaTypeVideo, position: $0.position) }.first
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupSession()
        permissionController.requestForAllPermissions { _ in }
//        debugTestConvertVideoToDynamicSubtitles()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
    
    func updateRecordButtonProgress() {
        recordButtonProgress = recordButtonProgress + (CGFloat(Constants.recordButtonIntervalIncrementTime) / maximumMovieLength)
        recordButton.setProgress(recordButtonProgress)
        if recordButtonProgress >= 1.0 {
            recordButtonTimer.invalidate()
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
                self.presentVideoPreviewViewController(with: asset, speechArray: speechArray)
            }
    }
    
    @objc private func startRecording() {
        recording.start()
        Logger.verbose("Started recording. \(Date())")
        recordButtonTimer = .scheduledTimer(timeInterval: Constants.recordButtonIntervalIncrementTime, target: self, selector: #selector(CameraViewController.updateRecordButtonProgress), userInfo: nil, repeats: true)
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent((outputFileName as NSString).appendingPathExtension("mov")!)
        guard !isSimulator else { return }
        movieFileOutput.startRecording(toOutputFileURL: URL(fileURLWithPath: outputFilePath), recordingDelegate: self)
    }
    
    @objc private func stopRecording() {
        Logger.verbose("Ended recording. Recording time: \(recording.end())")
        guard !isSimulator else { return }
        movieFileOutput.stopRecording()
    }
    
    private func setupLayout() {
        setupRecordButton()
        setupVideosButton()
        effectView = CustomBlurRadiusView()
        effectView.frame = bottomCameraView.bounds
        bottomCameraView.insertSubview(effectView, at: 0)
    }
    
    private func debugTestConvertVideoToDynamicSubtitles() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            let movieFromProject = Bundle.main.url(forResource: resourceName, withExtension: "MOV")!
            let assetFromURL = AVURLAsset(url: movieFromProject)
            self.convertAssetToVideoWithDynamicSubtitles(asset: assetFromURL)
        }
    }
    
    private func setupSession() {
        guard !isSimulator else { return }
        previewView.session = session
        checkAuthorization()
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
    }
    
    private func addVideoInput() {
        guard let anyCamera = anyCamera, let videoDeviceInput = try? AVCaptureDeviceInput(device: anyCamera) else { return }
        if session.canAddInput(videoDeviceInput) {
            session.addInput(videoDeviceInput)
            self.videoDeviceInput = videoDeviceInput
            DispatchQueue.main.async {
                self.previewView.videoPreviewLayer.connection.videoOrientation = .portrait
            }
        }
    }
    
    private func addAudioInput() {
        let audioDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
        let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice)
        
        if let audioDeviceInput = audioDeviceInput, session.canAddInput(audioDeviceInput) {
            session.addInput(audioDeviceInput)
        }
    }
    
    private func configureSession() {
        addVideoInput()
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
        recordButton.center = CGPoint(x: bottomCameraView.center.x, y: bottomCameraView.frame.height / 2)
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
        imagePicker.dismiss(animated: true) {
            self.assetController.AVAssetPromise(from: asset)
                .then { [unowned self] videoAsset in
                    self.performSpeechDetection(from: videoAsset)
            }
        }
    }
    
    //For debug purposes
    fileprivate func convertAssetToVideoWithDynamicSubtitles(asset: AVAsset) {
        let speechController = SpeechController()
        speechController.createVideoWithDynamicSubtitles(from: asset, completion: { url in
            DispatchQueue.main.async {
                let assetFromURL = AVURLAsset(url: url)
                self.presentVideoPreviewViewController(with: assetFromURL)
            }
        })
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
}
