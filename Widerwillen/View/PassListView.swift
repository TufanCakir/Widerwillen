//
//  PassListView.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 15.08.26.
//

import SwiftUI

struct PassListView: View {
    let progress: GameProgressStore

    private let passConfiguration: PassConfiguration

    @State private var store = StoreKitStore()

    init(
        progress: GameProgressStore,
        passConfiguration: PassConfiguration =
            (try? PassConfiguration.load()) ?? PassConfiguration(passes: [])
    ) {
        self.progress = progress
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

                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(passConfiguration.passes) { pass in
                            PassView(
                                progress: progress,
                                pass: pass,
                                store: store
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

    private func buyPass(_ pass: BattlePassDefinition) async {
        guard let productID = pass.productID else { return }

        if await store.purchase(productID: productID) {
            progress.unlockPremiumPass(pass)
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
