//
//  CharacterConfiguration.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 14.08.26.
//

import Foundation

struct CharacterConfiguration: Decodable {
    let characters: [CharacterDefinition]

    static func load(named resourceName: String = "character") throws
        -> CharacterConfiguration
    {
        try JSONLoader.load(named: resourceName)
    }

    var defaultCharacter: CharacterDefinition? {
        characters.first { $0.isDefault } ?? characters.first
    }

    func character(id: String) -> CharacterDefinition? {
        characters.first { $0.id == id }
    }

    func skin(id: String, for characterID: String) -> CharacterSkin? {
        character(id: characterID)?.skins.first { $0.id == id }
    }

    func defaultSkin(for characterID: String) -> CharacterSkin? {
        guard let character = character(id: characterID) else { return nil }
        return character.skins.first { $0.id == character.defaultSkinID }
            ?? character.skins.first
    }
}

struct CharacterDefinition: Decodable, Identifiable {
    let id: String
    let name: String
    let rarity: SpriteRarity
    let baseTapDamage: Int
    let maxStars: Int
    let defaultSkinID: String
    let isDefault: Bool
    let skins: [CharacterSkin]
}

struct CharacterSkin: Decodable, Identifiable {
    let id: String
    let name: String
    let imageName: String
    let animationID: String
    let unlockSource: String
}
