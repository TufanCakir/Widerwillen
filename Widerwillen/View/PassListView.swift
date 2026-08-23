//
//  PassListView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import SwiftUI

struct PassListView: View {
    let progress: GameProgressStore
    let playSoundEffect: (String) -> Void

    private let passConfiguration: PassConfiguration

    @State private var store = StoreKitStore()

    init(
        progress: GameProgressStore,
        playSoundEffect: @escaping (String) -> Void = { _ in },
        passConfiguration: PassConfiguration =
            (try? PassConfiguration.load()) ?? PassConfiguration(passes: [])
    ) {
        self.progress = progress
        self.playSoundEffect = playSoundEffect
        self.passConfiguration = passConfiguration
    }

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                GameHeader(progress: progress)
                    .padding(.top, 18)

                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                }

                restorePurchasesButton
                    .padding(.horizontal, 16)

                if !store.message.isEmpty {
                    Text(store.message)
                        .font(.system(size: 12, weight: .heavy))
                        .foregroundStyle(.white.opacity(0.82))
                        .shadow(
                            color: .black.opacity(0.9),
                            radius: 3,
                            x: 0,
                            y: 0
                        )
                }

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(passConfiguration.passes) { pass in
                            PassView(
                                progress: progress,
                                pass: pass,
                                store: store,
                                playSoundEffect: playSoundEffect
                            ) { pass in
                                await buyPass(pass)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 110)
                }
            }
        }
        .task {
            await store.loadProducts(
                productIDs: passConfiguration.passes.compactMap(\.productID)
            )
            syncOwnedPasses()
        }
    }

    private var restorePurchasesButton: some View {
        Button {
            playSoundEffect("ui_select")
            Task {
                await restorePurchases()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.clockwise.circle.fill")
                    .font(.system(size: 15, weight: .heavy))

                Text("Restore Purchases")
                    .font(.system(size: 13, weight: .heavy))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.82), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading)
        .opacity(store.isLoading ? 0.55 : 1)
    }

    private func buyPass(_ pass: BattlePassDefinition) async {
        guard let productID = pass.productID else { return }

        if await store.purchase(productID: productID) {
            progress.unlockPremiumPass(pass)
        }
    }

    private func restorePurchases() async {
        if await store.restorePurchases() {
            syncOwnedPasses()
        }
    }

    private func syncOwnedPasses() {
        for pass in passConfiguration.passes
        where pass.purchaseType == .nonConsumable {
            guard let productID = pass.productID,
                store.purchasedProductIDs.contains(productID)
            else {
                continue
            }

            progress.unlockPremiumPass(pass)
        }
    }
}

#Preview {
    PassListView(progress: GameProgressStore())
}
