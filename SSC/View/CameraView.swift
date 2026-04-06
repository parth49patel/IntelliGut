//
//  CameraView.swift
//  SSC
//
//  Created by Parth Patel on 2025-12-23.
//

import SwiftUI

struct CameraView: View {
	
	@State var camera = Camera()
	@State var didSetup = Bool()
	@State private var isAuthorized: Bool = true
	
	@Binding var showCamera: Bool
	@Binding var imageData: Data?
		
	@Environment(\.dismiss) private var dismiss
		
	var body: some View {
		Group {
			if camera.hasPhoto {
				imagePreview
			}
			else {
				if isAuthorized {
					cameraInterface
				}
				else {
					accessDeniedView
				}
			}
		}
		.overlay {
			// Simulator fallback to allow full testing without camera access or a physical ingredient label.
			#if targetEnvironment(simulator)
			VStack(spacing: 20) {
				Image(systemName: "macbook.and.iphone").font(.largeTitle).foregroundStyle(.white)
				Text("Simulator Mode").font(.largeTitle).bold().foregroundStyle(.white)
				Text("The camera is unavailable on the Simulator.").foregroundStyle(.gray)
				
				CapsuleButton(background: .accent) {
					imageData = UIImage(named: "sampleLabel")?.jpegData(compressionQuality: 0.8)
					showCamera = false
				} label: {
					Label("Use Sample Image", systemImage: "photo.fill")
						.foregroundStyle(.white)
				}
				
				CapsuleButton(background: .ultraThinMaterial) {
					dismiss()
				} label: {
					Text("Cancel")
						.foregroundStyle(.primary)
				}
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.background(Color.black)
			#endif
		}
		.task {
			isAuthorized = await camera.checkAuthorization()
			if isAuthorized {
				didSetup = camera.setup()
				showCamera = true
			}
		}
	}
	
		// MARK: - Image Preview
	@ViewBuilder
	private var imagePreview: some View {
		if let data = camera.photoData, let uiImage = UIImage(data: data) {
			ZStack {
				Color.black
					.ignoresSafeArea()
				
				Image(uiImage: uiImage)
					.resizable()
					.scaledToFit()
					.clipped()
				
				VStack {
					Spacer()
					HStack {
						Button {
							camera.retakePhoto()
						} label: {
							HStack(spacing: 8) {
								Image(systemName: "arrow.clockwise")
								Text("Retake")
							}
							.font(.headline)
							.foregroundStyle(.white)
							.padding(12)
							.background(.gray)
							.clipShape(Capsule())
						}
						.accessibilityLabel("Retake Photo")
						
						Spacer()
						
						Button {
							showCamera = false
							imageData = camera.photoData
						} label: {
							HStack(spacing: 8) {
								Image(systemName: "checkmark.circle.fill")
								Text("Use Photo")
							}
							.font(.headline)
							.foregroundStyle(.white)
							.padding(12)
							.background(.blue)
							.clipShape(Capsule())
						}
						.accessibilityLabel("Use Photo")
					}
				}
				.padding(.horizontal)
				.padding(.bottom, 20)
			}
		}
	}
	
	// MARK: - Camera Interface
	@ViewBuilder
	private var cameraInterface: some View {
		ZStack {
			CameraPreview(camera: $camera)
				.ignoresSafeArea()
			
			VStack {
				HStack {
					Spacer()
					Button {
						dismiss()
					} label: {
						Image(systemName: "xmark")
							.font(.title3)
							.fontWeight(.semibold)
							.foregroundStyle(.white)
							.padding(12)
							.background(.black.opacity(0.5))
							.clipShape(Circle())
					}
					.accessibilityLabel("Close Camera")
				}
				.padding()
				
				Spacer()
				
				Button {
					camera.capturePhoto()
				} label: {
					ZStack {
						Circle()
							.stroke(.white, lineWidth: 4)
							.frame(width: 80, height: 80)
						
						Circle()
							.fill(.white)
							.frame(width: 68, height: 68)
					}
				}
				.padding(.bottom, 40)
				.accessibilityLabel("Capture Photo")
				.accessibilityHint("Takes a photo of the ingredient label")
			}
		}
	}
	
	// MARK: - Access Denied
	@ViewBuilder
	private var accessDeniedView: some View {
		ZStack {
			LinearGradient(
				colors: [Color.red.opacity(0.1), Color.orange.opacity(0.05)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
			.ignoresSafeArea()
			
			VStack(spacing: 24) {
				ZStack {
					Circle()
						.fill(.red.opacity(0.1))
						.frame(width: 120, height: 120)
					
					Image(systemName: "video.slash.fill")
						.font(.system(size: 50))
						.foregroundStyle(.red)
				}
				
				VStack(spacing: 12) {
					Text("Camera Access Denied")
						.font(.title2)
						.fontWeight(.bold)
					
					Text("Need access to camera to scan ingredient labels.\n\nPlease enable camera access in Settings.")
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.multilineTextAlignment(.center)
				}
				.padding(.horizontal)
				
				VStack(spacing: 12) {
					CapsuleButton(background: .blue) {
						if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
							UIApplication.shared.open(settingsUrl)
						}
					} label: {
						Label("Open Settings", systemImage: "gear")
							.foregroundStyle(.white)
					}
					
					CapsuleButton(background: .green) {
						imageData = UIImage(named: "sampleLabel")?.jpegData(compressionQuality: 0.8)
						showCamera = false
					} label: {
						Label("Use Sample Image", systemImage: "photo.fill")
							.foregroundStyle(.white)
					}
					
					CapsuleButton(background: .ultraThinMaterial) {
						dismiss()
					} label: {
						Text("Cancel")
							.foregroundStyle(.primary)
					}
				}
				.font(.headline)
				.padding(.horizontal)
			}
		}
	}
}

/// A reusable capsule-shaped button with customizable background and label.
struct CapsuleButton<Background: ShapeStyle, LabelContent: View>: View {
	let background: Background
	let action: () -> Void
	@ViewBuilder let label: () -> LabelContent
	
	var body: some View {
		Button(action: action) {
			label()
				.padding()
				.frame(width: 280)
		}
		.background(background)
		.clipShape(.capsule)
	}
}

#Preview {
	CameraView(showCamera: .constant(true), imageData: .constant(nil))
}
