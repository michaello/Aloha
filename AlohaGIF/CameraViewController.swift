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

enum CameraType {
    case front
    case back
}

final class CameraViewController: UIViewController {

    private enum Constants {
        static let recordButtonIntervalIncrementTime = 0.1
        static let recordButtonMinimumRecordingTime = 1.0
    }
    
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet private weak var previewView: PreviewView!
    @IBOutlet private weak var bottomCameraView: UIView!
    @IBOutlet private weak var videosButton: UIButton!
    @IBOutlet fileprivate var popoverView: PopoverView!
    
    private var effectView: UIVisualEffectView!
    
    var isRecordingLongEnoughToProcess: Bool {
        return recording.end() > Constants.recordButtonMinimumRecordingTime
    }
    private var recordButtonTimer: Timer?
    private var recordButtonProgress: CGFloat = 0.0
    private var isRecording = false
    private var cameraType = CameraType.front
    private var recording = Recording()
    
    let assetController = AssetController()
    fileprivate let speechController = SpeechController()
    private lazy var cameraController = CameraController(previewView: self.previewView, delegate: self)
    private let permissionController = PermissionController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        cameraController.prepareCamera()
        permissionController.requestForAllPermissions { _ in }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraController.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraController.stopRunning()
    }
    
    func updateRecordButtonProgress() {
        recordButtonProgress = recordButtonProgress + (CGFloat(Constants.recordButtonIntervalIncrementTime) / maximumMovieLength)
        recordButton.setProgress(recordButtonProgress)
        if recordButtonProgress >= 1.0 {
            stopRecordingAction()
        }
    }
    
    func presentVideoPreviewViewController(with asset: AVAsset?, speechArray: [SpeechModel]? = nil) {
        guard let asset = asset else { return }
        let videoPreviewViewController = self.storyboard?.instantiateViewController(withIdentifier: String(describing: VideoPreviewViewController.self)) as! VideoPreviewViewController
        videoPreviewViewController.selectedVideo = asset
        if let speechArray = speechArray {
            videoPreviewViewController.speechArray = speechArray
        }
        present(videoPreviewViewController, animated: true)
    }
    
    @IBAction func changeCameraAction(_ sender: UIButton) {
        cameraController.changeCamera()
    }
    
    @IBAction func videosButtonAction(_ sender: UIButton) {
        present(ImagePickerController.defaultController(delegate: self), animated: true)
    }
    
    @IBAction func startRecordingAction() {
        recording.start()
        isRecording = true
        Logger.verbose("Started recording. \(Date())")
        recordButtonTimer = .scheduledTimer(timeInterval: Constants.recordButtonIntervalIncrementTime, target: self, selector: #selector(CameraViewController.updateRecordButtonProgress), userInfo: nil, repeats: true)
        cameraController.startRecording()
    }
    
    @IBAction func stopRecordingAction() {
        guard isRecording else { return }
        isRecording = false
        Logger.verbose("Ended recording. Recording time: \(recording.end()) seconds")
        recordButtonStopRecording()
        guard UIDevice.isNotSimulator else { return }
        cameraController.stopRecording()
    }
    
    fileprivate func performSpeechDetection(from asset: AVAsset) {
        speechController.detectSpeechPromise(from: asset)
            .then(on: DispatchQueue.main) { [unowned self] speechArray in
                self.presentVideoPreviewViewController(with: asset, speechArray: speechArray)
            }
            .catch(on: DispatchQueue.main) { _ in
                UIAlertController.show(.speechNotDetected)
            }
            .always(on: DispatchQueue.main) {
                self.recordButton.stopLoading()
        }
    }
    
    private func recordButtonStopRecording() {
        reactRecordButtonOnEndedRecording()
        recordButtonTimer?.invalidate()
        recordButtonProgress = 0.0
        recordButton.buttonState = .idle
    }
    
    private func reactRecordButtonOnEndedRecording() {
        if isRecordingLongEnoughToProcess {
            recordButton.startLoading()
        } else {
            popoverView.show(from: recordButton)
        }
    }
    
    private func setupLayout() {
        setupVideosButton()
        effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        effectView.frame = bottomCameraView.bounds
        bottomCameraView.insertSubview(effectView, at: 0)
    }
    
    private func setupVideosButton() {
        videosButton.setTitleColor(.themeColor, for: [])
    }
}

extension CameraViewController: CameraControllerDelegate {
    func didFinishRecording(asset: AVAsset) {
        guard isRecordingLongEnoughToProcess else {
            Logger.verbose("Recording too short to perform speech detection. Aborting.")
            return
        }
        performSpeechDetection(from: asset)
    }
}

extension CameraViewController: UINavigationControllerDelegate, UIVideoEditorControllerDelegate {
    func videoEditorController(_ editor: UIVideoEditorController, didSaveEditedVideoToPath editedVideoPath: String) {
        recordButton.startLoading()
        editor.dismiss(animated: true) {
            let asset = AVURLAsset(url: URL(fileURLWithPath: editedVideoPath))
            self.performSpeechDetection(from: asset)
        }
    }
}
extension CameraViewController: ImagePickerDelegate {
    func tooLongMovieSelected() {
        Logger.info("User tapped movie that is too long.")
        UIAlertController.show(.tooLongVideo(limit: Int(maximumMovieLength)))
    }
    
    func doneButtonDidPress(_ imagePicker: ImagePickerController, asset: PHAsset) {
        imagePicker.dismiss(animated: true) {
            self.assetController.AVAssetPromise(from: asset)
                .then(on: DispatchQueue.main) { [unowned self] videoAsset in
                    self.presentVideoEditorViewController(videoToEdit: videoAsset)
            }
        }
    }

    private func presentVideoEditorViewController(videoToEdit video: AVAsset) {
        guard let videoPath = (video as? AVURLAsset)?.url.path else { return }
        recordButton.startLoading()
        let videoEditorController = UIVideoEditorController.defaultController(maximumDuration: TimeInterval(maximumMovieLength), delegate: self, videoPath: videoPath)
        present(videoEditorController, animated: true) { [unowned self] in
            self.recordButton.stopLoading()
        }
    }
}
