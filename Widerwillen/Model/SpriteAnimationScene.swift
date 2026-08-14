//
//  SpriteAnimationScene.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SpriteKit

final class SpriteAnimationScene: SKScene {

    private let arena: ArenaConfiguration
    private let spriteSheets: [SpriteSheet]
    private var characters: [CharacterInstance] = []
    private var heroAnimationID = "sprite_nimbi"
    private var companionAnimationIDs: Set<String> = []
    private let gridColumns = 5
    private let gridCellWidthRatio: CGFloat = 0.15
    private let gridCellHeightRatio: CGFloat = 0.18
    private let gridCenterXRatio: CGFloat = 0.5
    private let gridRowOffsetRatio: CGFloat = 0.065
    private let gridBaseYRatio: CGFloat = 0.30
    private let heroXRatio: CGFloat = 0.38
    private let heroYRatio: CGFloat = 0.12
    private let heroScale: CGFloat = 0.32

    private var floorHeight: CGFloat {
        size.height * arena.floorHeightRatio
    }

    private var gridBaseY: CGFloat {
        floorHeight * gridBaseYRatio
    }

    var availableSpriteCount: Int {
        spriteSheets.count
    }

    init(size: CGSize, arena: ArenaConfiguration) {
        self.arena = arena
        self.spriteSheets = (try? SpriteSheet.loadAll()) ?? []
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear

        setupCharactersIfNeeded()

        layoutCharacters()
    }

    func updateBattleSprites(
        heroAnimationID: String,
        companionAnimationIDs: Set<String>
    ) {
        self.heroAnimationID = heroAnimationID
        self.companionAnimationIDs = companionAnimationIDs
        updateCharacterVisibility()
        layoutCharacters()
    }

    func playHeroAttackAnimation() {
        guard
            let hero = characters.first(where: { $0.id == heroAnimationID }),
            !hero.node.isHidden
        else {
            return
        }

        hero.animation.playOnce(on: hero.node)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutCharacters()
    }

    private func setupCharactersIfNeeded() {
        guard characters.isEmpty else { return }

        let sheets =
            spriteSheets.isEmpty
            ? [try? SpriteSheet.load()].compactMap { $0 } : spriteSheets

        characters = sheets.enumerated().map { index, sheet in
            let animation = SpriteSheetAnimation(config: sheet)
            let node = SKSpriteNode(texture: animation.firstTexture)
            node.anchorPoint = CGPoint(x: 0.5, y: 0)
            node.zPosition = 2

            let shadow = makeShadow()
            shadow.zPosition = 1
            let isVisible = isVisibleAnimation(id: sheet.id)
            shadow.isHidden = !isVisible

            node.isHidden = !isVisible
            addChild(shadow)
            addChild(node)

            if isVisible {
                startAnimation(for: sheet.id, animation: animation, node: node)
            }

            return CharacterInstance(
                id: sheet.id,
                index: index,
                config: sheet,
                animation: animation,
                node: node,
                shadow: shadow
            )
        }
    }

    private func layoutCharacters() {
        for index in characters.indices {
            let character = characters[index]
            let scale =
                character.id == heroAnimationID
                ? heroScale
                : character.config.scale ?? arena.characterScale
            let xPosition =
                character.config.xPosition
                ?? defaultXPosition(
                    for: character.index,
                    count: characters.count
                )
            let yOffset = character.config.yOffset ?? 0

            character.node.size = character.animation.size(
                fitting: size,
                scale: scale
            )
            let position = characterPosition(
                for: character.config,
                id: character.id,
                index: character.index,
                fallbackXPosition: xPosition,
                fallbackYOffset: yOffset
            )
            let yPosition = position.y
            character.node.position = position
            character.node.zPosition = zPosition(for: yPosition)
        }

        updateShadowPositions()
        updateCharacterVisibility()
    }

    private func updateCharacterVisibility() {
        for character in characters {
            let isUnlocked = isVisibleAnimation(id: character.id)
            let wasHidden = character.node.isHidden

            character.node.isHidden = !isUnlocked
            character.shadow.isHidden = !isUnlocked

            if isUnlocked && wasHidden {
                startAnimation(
                    for: character.id,
                    animation: character.animation,
                    node: character.node
                )
            } else if !isUnlocked && !wasHidden {
                character.animation.stop(on: character.node)
            }
        }
    }

    private func startAnimation(
        for id: String,
        animation: SpriteSheetAnimation,
        node: SKSpriteNode
    ) {
        if id == heroAnimationID {
            animation.showFirstFrame(on: node)
        } else {
            animation.start(on: node)
        }
    }

    private func defaultXPosition(for index: Int, count: Int) -> CGFloat {
        guard count > 1 else { return arena.characterXPosition }

        let spacing: CGFloat = 0.18
        let centerOffset = CGFloat(index) - CGFloat(count - 1) * 0.5
        return min(
            max(arena.characterXPosition + centerOffset * spacing, 0.12),
            0.88
        )
    }

    private func updateShadowPositions() {
        for character in characters {
            let xPosition =
                character.config.xPosition
                ?? defaultXPosition(
                    for: character.index,
                    count: characters.count
                )
            let position = characterPosition(
                for: character.config,
                id: character.id,
                index: character.index,
                fallbackXPosition: xPosition,
                fallbackYOffset: character.config.yOffset ?? 0
            )
            character.shadow.position = CGPoint(
                x: position.x,
                y: position.y + 2
            )
            character.shadow.xScale = max(character.node.size.width / 120, 0.18)
            character.shadow.yScale = max(character.node.size.width / 160, 0.14)
            character.shadow.zPosition = character.node.zPosition - 1
        }
    }

    private func characterPosition(
        for config: SpriteSheet,
        id: String,
        index: Int,
        fallbackXPosition: CGFloat,
        fallbackYOffset: CGFloat
    ) -> CGPoint {
        if id == heroAnimationID {
            return CGPoint(
                x: size.width * heroXRatio,
                y: floorHeight * heroYRatio + fallbackYOffset
            )
        }

        guard
            let gridColumn = config.gridColumn
                ?? automaticGridColumn(for: index),
            let gridRow = config.gridRow ?? automaticGridRow(for: index)
        else {
            return CGPoint(
                x: size.width * min(max(fallbackXPosition, 0), 1),
                y: gridBaseY + fallbackYOffset
            )
        }

        let clampedColumn = min(max(gridColumn, 0), gridColumns - 1)
        let clampedRow = max(gridRow, 0)
        let centerColumn = CGFloat(gridColumns - 1) * 0.5
        let columnOffset = CGFloat(clampedColumn) - centerColumn
        let rowOffset = CGFloat(clampedRow)
        let x =
            size.width * gridCenterXRatio
            + columnOffset * size.width * gridCellWidthRatio
            + alternatingRowOffset(for: clampedRow)
        let y = gridBaseY + rowOffset * floorHeight * gridCellHeightRatio

        return CGPoint(x: x, y: y)
    }

    private func isVisibleAnimation(id: String) -> Bool {
        id == heroAnimationID || companionAnimationIDs.contains(id)
    }

    private func alternatingRowOffset(for row: Int) -> CGFloat {
        row.isMultiple(of: 2) ? 0 : size.width * gridRowOffsetRatio
    }

    private func automaticGridColumn(for index: Int) -> Int? {
        index % gridColumns
    }

    private func automaticGridRow(for index: Int) -> Int? {
        index / gridColumns
    }

    private func zPosition(for yPosition: CGFloat) -> CGFloat {
        1_000 - yPosition
    }

    private func makeShadow() -> SKShapeNode {
        let shadow = SKShapeNode()
        let path = CGMutablePath()
        path.addEllipse(in: CGRect(x: -55, y: -8, width: 110, height: 16))
        shadow.path = path
        shadow.fillColor = .black.withAlphaComponent(0.32)
        shadow.strokeColor = .clear
        return shadow
    }

    private struct CharacterInstance {
        let id: String
        let index: Int
        let config: SpriteSheet
        let animation: SpriteSheetAnimation
        let node: SKSpriteNode
        let shadow: SKShapeNode
    }
}
