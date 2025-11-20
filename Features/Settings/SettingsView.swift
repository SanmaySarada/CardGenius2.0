//
//  SettingsView.swift
//  CardGenius
//
//  Settings Sheet
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateViewModel
    @State private var requireBiometric: Bool = false
    @State private var hideBalances: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                // Profile Section
                Section {
                    HStack(spacing: Spacing.m) {
                        Circle()
                            .fill(Color.cgPrimary.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .overlay(
                                Text("JS")
                                    .font(.cgHeadline(24))
                                    .foregroundColor(.cgPrimary)
                            )
                        
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("John Smith")
                                .font(.cgHeadline(17))
                                .foregroundColor(.cgPrimaryText)
                            Text("john.smith@example.com")
                                .font(.cgBody(13))
                                .foregroundColor(.cgSecondaryText)
                        }
                    }
                    .padding(.vertical, Spacing.s)
                }
                
                // Security Section
                Section("Security") {
                    Toggle("Require Face ID / Touch ID", isOn: $requireBiometric)
                    Toggle("Hide balances by default", isOn: $hideBalances)
                }
                
                // Connected Institutions
                Section("Connected Institutions") {
                    ForEach(MockData.sampleInstitutions.filter { $0.connectionStatus == .linked }) { institution in
                        HStack {
                            RoundedRectangle(cornerRadius: Radius.small)
                                .fill(Color.cgTertiaryBackground)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text(String(institution.name.prefix(1)))
                                        .font(.cgHeadline(16))
                                        .foregroundColor(.cgSecondaryText)
                                )
                            
                            Text(institution.name)
                                .font(.cgBody(15))
                            
                            Spacer()
                            
                            Button("Manage") {
                                // Handle manage
                            }
                            .font(.cgBody(13))
                            .foregroundColor(.cgPrimary)
                        }
                    }
                }
                
                // Privacy Section
                Section("Privacy") {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Text("CardGenius does not store your full card numbers (PANs). We only store metadata and tokens from your connected institutions.")
                            .font(.cgBody(13))
                            .foregroundColor(.cgSecondaryText)
                    }
                    .padding(.vertical, Spacing.xs)
                }
                
                // App Info
                Section("App Info") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.cgSecondaryText)
                    }
                    
                    Button("Terms of Service") {}
                    Button("Privacy Policy") {}
                    Button("Support") {}
                }
                
                // Reset Onboarding (for testing)
                Section {
                    Button(action: {
                        appState.resetOnboarding()
                        dismiss()
                    }) {
                        Text("Reset Onboarding")
                            .foregroundColor(.cgError)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

