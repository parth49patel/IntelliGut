//
//  OnboardingView.swift
//  SSC
//
//  Created by Parth Patel on 2026-02-15.
//

import SwiftUI

struct OnboardingView: View {
	
	@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
	@State private var currentPage = 0
	@Environment(\.dismiss) private var dismiss
	
	private let totalPages = 5
	
	var body: some View {
		ZStack {
			AnimatedGradientBackground(currentPage: currentPage)
			
			VStack(spacing: 0) {
				TabView(selection: $currentPage) {
					WelcomePage().tag(0).accessibilityLabel("Welcome Page. My story about experiencing pain from a protein bar.")
					
					ProblemPage().tag(1)
					
					SolutionPage().tag(2)
					
					HowItWorksPage().tag(3)
					
					GetStartedPage().tag(4)
				}
				.tabViewStyle(.page(indexDisplayMode: .never))
				.animation(.easeInOut, value: currentPage)
				
				// Navigation Button
				VStack(spacing: 20) {
					Button {
						handleNextButton()
					} label: {
						HStack {
							Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
								.font(.headline)
								.fontWeight(.bold)
							
							Image(systemName: "arrow.right")
								.font(.headline)
						}
						.foregroundStyle(currentPage == totalPages - 1 ? .black : .white)
						.frame(maxWidth: .infinity)
						.padding()
						.background(currentPage == totalPages - 1 ? Color.white : Color.white.opacity(0.2))
						.clipShape(Capsule())
						.overlay(
							Capsule()
								.stroke(.white.opacity(0.5), lineWidth: 1)
						)
					}
					.padding(.horizontal, 32)
					.padding(.bottom, 20)
					.accessibilityLabel(currentPage == totalPages - 1 ? "Get started" : " Next Page")
				}
			}
		}
		.ignoresSafeArea()
	}
	
	private func handleNextButton() {
		if currentPage < totalPages - 1 {
			withAnimation {
				currentPage += 1
			}
		} else {
			completeOnboarding()
		}
	}
	
	private func completeOnboarding() {
		withAnimation {
			hasCompletedOnboarding = true
			dismiss()
		}
	}
}

// MARK: - Page 1: Welcome / Your Story

struct WelcomePage: View {
	@State private var isAnimated = false
	@Environment(\.verticalSizeClass) var verticalSizeClass
	
	var body: some View {
		ScrollablePageContainer {
			Image(systemName: "bolt.heart.fill")
				.font(.system(size: 100))
				.foregroundStyle(.white)
				.symbolEffect(.pulse, isActive: isAnimated)
				.shadow(color: .black.opacity(0.2), radius: 10, y: 10)
			
			VStack(spacing: 16) {
				Text("My Story")
					.font(.largeTitle)
					.fontWeight(.bold)
					.foregroundStyle(.white)
				
				Text("One night, I ended up in severe pain after eating a protein bar.")
					.font(.title3)
					.multilineTextAlignment(.center)
					.foregroundStyle(.white.opacity(0.95))
					.padding(.horizontal, 32)
				
				Text("I had no idea what the ingredients would do to my body.")
					.font(.body)
					.multilineTextAlignment(.center)
					.foregroundStyle(.white.opacity(0.8))
					.padding(.horizontal, 32)
			}
		}
		.onAppear { isAnimated = true }
		.accessibilityElement(children: .combine)
		.accessibilityAddTraits(.isHeader)
	}
}

// MARK: - Page 2: The Problem

struct ProblemPage: View {
	@State private var isAnimated = false
	@Environment(\.verticalSizeClass) var verticalSizeClass
	
	var body: some View {
		ScrollablePageContainer {
			ZStack {
				Circle()
					.fill(.white.opacity(0.1))
					.frame(width: 140, height: 140)
					.scaleEffect(isAnimated ? 1.0 : 0.8)
				
				Image(systemName: "doc.text.magnifyingglass")
					.font(.system(size: 60))
					.foregroundStyle(.white)
					.scaleEffect(isAnimated ? 1.0 : 0.5)
			}
			
			VStack(spacing: 16) {
				Text("The Problem")
					.font(.largeTitle)
					.fontWeight(.bold)
					.foregroundStyle(.white)
				
				VStack(alignment: .leading, spacing: 20) {
					ProblemPoint(icon: "questionmark.folder.fill", text: "Confusing labels")
					ProblemPoint(icon: "timer", text: "Hours spent googling")
					ProblemPoint(icon: "exclamationmark.shield.fill", text: "Unknown side effects")
				}
				.padding(.horizontal, 40)
			}
		}
		.onAppear {
			withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
				isAnimated = true
			}
		}
	}
}

struct ProblemPoint: View {
	let icon: String
	let text: String
	
	var body: some View {
		HStack(spacing: 16) {
			Image(systemName: icon)
				.font(.title2)
				.foregroundStyle(.white)
				.frame(width: 32)
			
			Text(text)
				.font(.title3)
				.fontWeight(.medium)
				.foregroundStyle(.white.opacity(0.9))
			
			Spacer()
		}
	}
}

// MARK: - Page 3: The Solution

struct SolutionPage: View {
	@State private var isAnimated = false
	@Environment(\.verticalSizeClass) var verticalSizeClass
	
	var body: some View {
		ScrollablePageContainer {
			ZStack {
				Circle()
					.fill(.white)
					.frame(width: 140, height: 140)
					.shadow(color: .white.opacity(0.3), radius: 20)
				
				Image(systemName: "checkmark.shield.fill")
					.font(.system(size: 70))
					.foregroundStyle(.blue)
					.symbolEffect(.bounce, value: isAnimated)
			}
			
			VStack(spacing: 16) {
				Text("GutCheck")
					.font(.system(size: 44, weight: .heavy))
					.foregroundStyle(.white)
				
				Text("Know Before You Eat")
					.font(.title3)
					.foregroundStyle(.white.opacity(0.9))
				
				Divider()
					.background(.white.opacity(0.5))
					.padding(.horizontal, 64)
					.padding(.vertical, 8)
				
				Text("Scan ingredient labels and instantly know how they'll affect your digestion.")
					.font(.body)
					.multilineTextAlignment(.center)
					.foregroundStyle(.white.opacity(0.9))
					.padding(.horizontal, 32)
			}
		}
		.onAppear { isAnimated = true }
	}
}

// MARK: - Page 4: How It Works

struct HowItWorksPage: View {
	@State private var showSteps = [false, false, false]
	@Environment(\.verticalSizeClass) var verticalSizeClass
	
	var body: some View {
		ScrollablePageContainer {
			Text("How It Works")
				.font(.largeTitle)
				.fontWeight(.bold)
				.foregroundStyle(.white)
			
			VStack(spacing: 20) {
				OnboardingStep(
					icon: "camera.viewfinder",
					title: "Scan Label",
					description: "Point at any ingredient list",
					isVisible: showSteps[0]
				)
				
				OnboardingStep(
					icon: "brain.head.profile",
					title: "AI Analysis",
					description: "Instant safety prediction",
					isVisible: showSteps[1]
				)
				
				OnboardingStep(
					icon: "hand.thumbsup.fill",
					title: "Eat Safely",
					description: "Make confident choices",
					isVisible: showSteps[2]
				)
			}
			.padding(.horizontal, 24)
		}
		.onAppear {
			for i in 0..<3 {
				withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(i) * 0.2)) {
					showSteps[i] = true
				}
			}
		}
	}
}

struct OnboardingStep: View {
	let icon: String
	let title: String
	let description: String
	let isVisible: Bool
	
	var body: some View {
		HStack(spacing: 16) {
			Image(systemName: icon)
				.font(.title)
				.foregroundStyle(.blue)
				.frame(width: 50, height: 50)
				.background(.white)
				.clipShape(Circle())
			
			VStack(alignment: .leading, spacing: 4) {
				Text(title)
					.font(.headline)
					.foregroundStyle(.white)
				
				Text(description)
					.font(.subheadline)
					.foregroundStyle(.white.opacity(0.8))
			}
			Spacer()
		}
		.padding()
		.background(.white.opacity(0.1))
		.clipShape(RoundedRectangle(cornerRadius: 16))
		.overlay(
			RoundedRectangle(cornerRadius: 16)
				.stroke(.white.opacity(0.2), lineWidth: 1)
		)
		.scaleEffect(isVisible ? 1.0 : 0.9)
		.opacity(isVisible ? 1.0 : 0.0)
	}
}

// MARK: - Page 5: Get Started

struct GetStartedPage: View {
	@State private var isAnimated = false
	@Environment(\.verticalSizeClass) var verticalSizeClass
	
	var body: some View {
		ScrollablePageContainer {
			HStack(spacing: 24) {
				Image(systemName: "exclamationmark.triangle.fill")
					.font(.system(size: 50))
					.foregroundStyle(.white.opacity(0.6))
				
				Image(systemName: "arrow.right")
					.font(.title)
					.foregroundStyle(.white.opacity(0.8))
				
				Image(systemName: "checkmark.shield.fill")
					.font(.system(size: 60))
					.foregroundStyle(.white)
					.symbolEffect(.bounce, value: isAnimated)
			}
			
			VStack(spacing: 16) {
				Text("Ready to Start?")
					.font(.largeTitle)
					.fontWeight(.bold)
					.foregroundStyle(.white)
				
				Text("From confusion to confidence.\nFrom fear to freedom.")
					.font(.title3)
					.multilineTextAlignment(.center)
					.foregroundStyle(.white.opacity(0.95))
					.padding(.horizontal, 32)
			}
		}
		.onAppear { isAnimated = true }
	}
}

// MARK: - Helper Component for Landscape Support
/// This container automatically centers content in Portrait, but becomes scrollable in Landscape

struct ScrollablePageContainer<Content: View>: View {
	@ViewBuilder let content: Content
	@Environment(\.verticalSizeClass) var verticalSizeClass
	
	var body: some View {
		GeometryReader { geometry in
			ScrollView(.vertical, showsIndicators: false) {
				VStack(spacing: verticalSizeClass == .compact ? 16 : 32) {
					Spacer(minLength: 20)
					content
					Spacer(minLength: 20)
				}
				.frame(width: geometry.size.width)
				.frame(minHeight: geometry.size.height)
			}
		}
	}
}
// MARK: - Gradient Background

struct AnimatedGradientBackground: View {
	let currentPage: Int
	
	var gradient: LinearGradient {
		switch currentPage {
		case 0:
			return LinearGradient(
				colors: [Color(red: 0.6, green: 0.1, blue: 0.1), Color(red: 0.8, green: 0.3, blue: 0.2)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		case 1:
			return LinearGradient(
				colors: [Color(red: 0.8, green: 0.4, blue: 0.0), Color(red: 0.6, green: 0.3, blue: 0.1)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		case 2:
			return LinearGradient(
				colors: [Color.blue, Color(red: 0.0, green: 0.2, blue: 0.6)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		case 3:
			return LinearGradient(
				colors: [Color.indigo, Color.purple],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		case 4:
			return LinearGradient(
				colors: [Color.teal, Color(red: 0.0, green: 0.5, blue: 0.4)],
				startPoint: .topLeading,
				endPoint: .bottomTrailing
			)
		default:
			return LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
		}
	}
	
	var body: some View {
		Rectangle()
			.fill(gradient)
			.ignoresSafeArea()
			.animation(.easeInOut(duration: 0.6), value: currentPage)
	}
}

#Preview {
	OnboardingView()
}
