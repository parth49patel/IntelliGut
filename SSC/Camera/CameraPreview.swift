//
//  CameraPreview.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-23.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
	
	@Binding var camera: Camera
    
	func makeUIView(context: Context) -> some UIView {
		let view = PreviewView()
		
		view.videoPreviewLayer.session = camera.session
		view.videoPreviewLayer.videoGravity = .resizeAspectFill
		
		return view
	}
	
	func updateUIView(_ uiView: UIViewType, context: Context) { }
}

class PreviewView: UIView {
	override class var layerClass: AnyClass {
		AVCaptureVideoPreviewLayer.self
	}
	
	var videoPreviewLayer: AVCaptureVideoPreviewLayer {
		layer as? AVCaptureVideoPreviewLayer ?? AVCaptureVideoPreviewLayer()
	}
}
