//
//  StoreKitStore.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation
import Observation
import StoreKit

@MainActor
@Observable
final class StoreKitStore {
    private(set) var products: [Product] = []
    private(set) var purchasedProductIDs: Set<String> = []
    private(set) var isLoading = false
    private(set) var message = ""

    func loadProducts(productIDs: [String]) async {
        let ids = Array(Set(productIDs)).filter { !$0.isEmpty }
        guard !ids.isEmpty else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: ids)
                .sorted { $0.displayPrice < $1.displayPrice }
            await refreshCurrentEntitlements()
        } catch {
            message = "Store unavailable"
            print("[StoreKit] Failed to load products: \(error)")
        }
    }

    func product(for productID: String) -> Product? {
        products.first { $0.id == productID }
    }

    func displayPrice(for productID: String) -> String {
        product(for: productID)?.displayPrice ?? "Buy"
    }

    @discardableResult
    func purchase(productID: String) async -> Bool {
        guard let product = product(for: productID) else {
            message = "Product not loaded"
            return false
        }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try verifiedTransaction(verification)
                purchasedProductIDs.insert(transaction.productID)
                await transaction.finish()
                message = "Purchase complete"
                return true
            case .userCancelled:
                message = "Purchase cancelled"
                return false
            case .pending:
                message = "Purchase pending"
                return false
            @unknown default:
                message = "Purchase unavailable"
                return false
            }
        } catch {
            message = "Purchase failed"
            print("[StoreKit] Purchase failed for \(productID): \(error)")
            return false
        }
    }

    func refreshCurrentEntitlements() async {
        for await result in Transaction.currentEntitlements {
            guard let transaction = try? verifiedTransaction(result) else {
                continue
            }

            purchasedProductIDs.insert(transaction.productID)
        }
    }

    private func verifiedTransaction(
        _ result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            transaction
        case .unverified:
            throw StoreKitStoreError.failedVerification
        }
    }
}

private enum StoreKitStoreError: Error {
    case failedVerification
}
