//
//  Camera.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-23.
//

import AVFoundation
import SwiftUI

@Observable
class Camera: NSObject, AVCapturePhotoCaptureDelegate {
	
	var session = AVCaptureSession()
	var preview = AVCaptureVideoPreviewLayer()
	var output = AVCapturePhotoOutput()
	
	var photoData: Data? = nil
	var hasPhoto: Bool = false
	
	/// Check if user has authorized the use of camera
	func checkAuthorization() async -> Bool {
		switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized:
				return true
			case .notDetermined:
				let status = await AVCaptureDevice.requestAccess(for: .video)
				return status
			case .denied:
				return false
			case .restricted:
				return false
			@unknown default:
				return false
		}
	}
	
	func setup() -> Bool {
		session.beginConfiguration()
		
		guard let device = AVCaptureDevice.default(for: .video) else { return false }
		guard let deviceInput = try? AVCaptureDeviceInput(device: device) else { return false }
		guard session.canAddInput(deviceInput) else { return false }
		guard session.canAddOutput(output) else { return false }
		
		session.addInput(deviceInput)
		session.addOutput(output)
		session.sessionPreset = .photo
		session.commitConfiguration()
	
		Task.detached(priority: .background) {
			await self.session.startRunning()
		}
		
		return true
	}
	
	func capturePhoto() {
		output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
	}
	
	func retakePhoto() {
		photoData = nil
		hasPhoto = false
		
		Task.detached(priority: .background) {
			await self.session.startRunning()
		}
	}
	
	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
		let data = photo.fileDataRepresentation()
		Task.detached(priority: .background) {
			await self.session.stopRunning()
			await MainActor.run {
				self.photoData = data
				self.hasPhoto = true
			}
		}
	}
}
