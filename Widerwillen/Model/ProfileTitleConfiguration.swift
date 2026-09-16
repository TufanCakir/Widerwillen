//
//  ProfileTitleConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct ProfileTitle: Decodable, Identifiable {
    let id: String
    let title: String
    let requiredAccountLevel: Int
}
