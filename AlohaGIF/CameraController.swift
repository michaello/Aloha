//
//  CameraController.swift
//  AlohaGIF
//
//  Created by Michal Pyrka on 13/10/2017.
//  Copyright © 2017 Michal Pyrka. All rights reserved.
//

import AVFoundation
import UIKit.UIDevice

protocol CameraControllerDelegate: class {
    func didFinishRecording(asset: AVAsset)
}

final class CameraController: NSObject {
    
    private enum Constants {
        static let allPossibleCameras: [(cameraType: AVCaptureDeviceType, position: AVCaptureDevicePosition)] = [
            (AVCaptureDeviceType.builtInDualCamera, AVCaptureDevicePosition.back),
            (AVCaptureDeviceType.builtInWideAngleCamera, AVCaptureDevicePosition.back),
            (AVCaptureDeviceType.builtInWideAngleCamera, AVCaptureDevicePosition.front)
        ]
        static let movieExtension = "mov"
    }
    
    weak var delegate: CameraControllerDelegate?
    
    private unowned var previewView: PreviewView
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let sessionPresetQuality = AVCaptureSessionPresetMedium
    private let movieFileOutput = AVCaptureMovieFileOutput()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var anyCamera: AVCaptureDevice? {
        return Constants.allPossibleCameras.flatMap { AVCaptureDevice.defaultDevice(withDeviceType: $0.cameraType, mediaType: AVMediaTypeVideo, position: $0.position) }.first
    }
    private var frontCamera: AVCaptureDevice? {
        guard let frontCameraType = Constants.allPossibleCameras.last else { fatalError("Cannot access any camera") }
        return AVCaptureDevice.defaultDevice(withDeviceType: frontCameraType.cameraType, mediaType: AVMediaTypeVideo, position: frontCameraType.position)
    }
    private var cameraType = CameraType.front
    
    init(previewView: PreviewView, delegate: CameraControllerDelegate?) {
        self.delegate = delegate
        self.previewView = previewView
    }
    
    func prepareCamera() {
        setupSession()
    }
    
    func startRunning() {
        session.startRunning()
    }
    
    func stopRunning() {
        session.stopRunning()
    }
    
    func startRecording() {
        guard UIDevice.isNotSimulator, session.isRunning else { return }
        let outputFileName = NSUUID().uuidString
        let outputFilePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(outputFileName).appendingPathExtension(Constants.movieExtension)
        movieFileOutput.startRecording(toOutputFileURL: outputFilePath, recordingDelegate: self)
    }

    func stopRecording() {
        movieFileOutput.stopRecording()
    }
    
    func changeCamera() {
        self.cameraType = cameraType == .front ? .back : .front
        sessionQueue.async { [unowned self] in
            self.addVideoInput(type: self.cameraType)
        }
    }
    
    private func setupSession() {
        guard UIDevice.isNotSimulator else { return }
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
                self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
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
}

extension CameraController: AVCaptureFileOutputRecordingDelegate {
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        delegate?.didFinishRecording(asset: AVURLAsset(url: outputFileURL))
    }
}
