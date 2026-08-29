//
//  SpriteAnimationScene.swift
//  Widerwillen
//
//  Created by Tufan Cakir on 10.08.26.
//

import SpriteKit
import UIKit

final class SpriteAnimationScene: SKScene {

    private let arena: ArenaConfiguration
    let spriteSheets: [SpriteSheet]
    private let rigsByID: [String: SpriteRig]
    private var characters: [CharacterInstance] = []
    private var enemyNode: SKNode?
    private var enemySpriteNode: SKSpriteNode?
    private var enemyLabelNode: SKLabelNode?
    private var shadowCloneNode: SKSpriteNode?
    private var heroAnimationID = "sprite_nimbi"
    private var equippedWeaponImageName: String?
    private var companionAnimationIDs: Set<String> = []
    private var currentEnemy: EnemyDefinition?
    private var isCurrentEnemyBoss = false
    private var activeShadowCloneAnimationID: String?
    private var rigNodeLookup: [ObjectIdentifier: [String: SKNode]] = [:]
    private var rigDescendantLookup: [ObjectIdentifier: [SKNode]] = [:]
    private let animatedRigPartNames: Set<String> = [
        "head",
        "leftHand",
        "rightHand",
        "weapon",
        "leftFoot",
        "rightFoot",
        "tail",
        "leftEar",
        "rightEar",
    ]
    private let gridColumns = 5
    private let gridCellWidthRatio: CGFloat = 0.15
    private let gridCellHeightRatio: CGFloat = 0.18
    private let gridCenterXRatio: CGFloat = 0.5
    private let gridRowOffsetRatio: CGFloat = 0.065
    private let gridBaseYRatio: CGFloat = 0.30
    private let heroXRatio: CGFloat = 0.34
    private let heroYRatio: CGFloat = 0.54
    private let heroScale: CGFloat = 0.28

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
        let rigs = (try? SpriteRig.loadAll()) ?? []
        self.rigsByID = Dictionary(
            uniqueKeysWithValues: rigs.map { ($0.id, $0) }
        )
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        view.ignoresSiblingOrder = true

        setupCharactersIfNeeded()

        layoutCharacters()
    }

    func updateBattleSprites(
        heroAnimationID: String,
        equippedWeaponImageName: String?,
        companionAnimationIDs: Set<String>
    ) {
        self.heroAnimationID = heroAnimationID
        self.equippedWeaponImageName = equippedWeaponImageName
        self.companionAnimationIDs = companionAnimationIDs
        updateCharacterVisibility()
        updateRigWeapons()
        layoutCharacters()
    }

    func updateEnemy(_ enemy: EnemyDefinition, isBoss: Bool) {
        let didChange = currentEnemy?.id != enemy.id
            || currentEnemy?.animationID != enemy.animationID
            || currentEnemy?.imageName != enemy.imageName
            || isCurrentEnemyBoss != isBoss
        currentEnemy = enemy
        isCurrentEnemyBoss = isBoss

        guard didChange || enemyNode == nil else {
            layoutEnemy()
            return
        }

        enemyNode?.removeFromParent()

        let container = SKNode()
        container.name = "enemy"
        container.zPosition = 3_000

        let label = SKLabelNode(
            text: isBoss ? "Boss · \(enemy.name)" : enemy.name
        )
        label.fontName = "AvenirNext-Heavy"
        label.fontSize = 13
        label.fontColor = isBoss ? .red : .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 2

        let sprite = SKSpriteNode()
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sprite.xScale = -1
        sprite.zPosition = 1
        configureSprite(
            sprite,
            animationID: enemy.animationID ?? enemy.imageName,
            columns: enemy.columns,
            rows: enemy.rows,
            frameCount: enemy.frameCount,
            fps: enemy.fps,
            actionKey: "enemyAnimation"
        )

        container.addChild(sprite)
        container.addChild(label)
        addChild(container)

        enemyNode = container
        enemySpriteNode = sprite
        enemyLabelNode = label
        layoutEnemy()
    }

    func updateShadowClone(animationID: String?) {
        guard activeShadowCloneAnimationID != animationID else {
            layoutShadowClone()
            return
        }

        activeShadowCloneAnimationID = animationID
        shadowCloneNode?.removeFromParent()
        shadowCloneNode = nil

        guard let animationID else { return }

        let sprite = SKSpriteNode()
        sprite.name = "shadowClone"
        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sprite.alpha = 0.62
        sprite.xScale = -1
        sprite.zPosition = 2_900
        configureSprite(
            sprite,
            animationID: animationID,
            columns: 3,
            rows: 1,
            frameCount: 3,
            fps: 8,
            actionKey: "shadowCloneAnimation"
        )
        sprite.run(.fadeIn(withDuration: 0.16))

        addChild(sprite)
        shadowCloneNode = sprite
        layoutShadowClone()
    }

    func playHeroAttackAnimation(move: BattleCardMove = .punch) {
        guard
            let hero = characters.first(where: { $0.id == heroAnimationID }),
            !hero.node.isHidden
        else {
            return
        }

        if let animation = hero.animation,
            let spriteNode = hero.node as? SKSpriteNode
        {
            animation.playOnce(on: spriteNode)
        } else {
            playRigAttack(on: hero.node, move: move)
        }
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutCharacters()
        layoutEnemy()
        layoutShadowClone()
    }

    private func setupCharactersIfNeeded() {
        guard characters.isEmpty else { return }

        let sheets = allCharacterConfigurations()

        characters = sheets.enumerated().map { index, sheet in
            let rig = rig(for: sheet.id)
            let animation =
                rig == nil ? SpriteSheetAnimation(config: sheet) : nil
            let node: SKNode
            if let rig {
                node = makeRigNode(for: rig)
            } else {
                node = SKSpriteNode(texture: animation?.firstTexture)
            }

            if let spriteNode = node as? SKSpriteNode {
                spriteNode.anchorPoint = CGPoint(x: 0.5, y: 0)
            }
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
                rig: rig,
                node: node,
                shadow: shadow
            )
        }
    }

    private func allCharacterConfigurations() -> [SpriteSheet] {
        let configuredSheets =
            spriteSheets.isEmpty
            ? [try? SpriteSheet.load()].compactMap { $0 } : spriteSheets
        var knownIDs = Set(configuredSheets.map(\.id))
        var allSheets = configuredSheets

        for rig in rigsByID.values.sorted(by: { $0.id < $1.id })
        where !knownIDs.contains(rig.id) {
            allSheets.append(
                SpriteSheet(
                    id: rig.id,
                    imageName: rig.id,
                    scale: arena.characterScale
                )
            )
            knownIDs.insert(rig.id)
        }

        return allSheets
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

            let characterSize = character.size(fitting: size, scale: scale)
            if let spriteNode = character.node as? SKSpriteNode {
                spriteNode.size = characterSize
            } else {
                let scaleFactor =
                    characterSize.width / max(character.rig?.canvasSize ?? 32, 1)
                character.node.xScale = scaleFactor
                character.node.yScale = scaleFactor
            }
            let position = characterPosition(
                for: character.config,
                id: character.id,
                index: character.index,
                fallbackXPosition: xPosition,
                fallbackYOffset: yOffset
            )
            let clampedPosition = clampedCharacterPosition(
                position,
                characterSize: characterSize
            )
            let yPosition = clampedPosition.y
            character.node.position = clampedPosition
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
                if let animation = character.animation,
                    let spriteNode = character.node as? SKSpriteNode
                {
                    animation.stop(on: spriteNode)
                }
            }
        }
    }

    private func startAnimation(
        for id: String,
        animation: SpriteSheetAnimation?,
        node: SKNode
    ) {
        if let animation, let spriteNode = node as? SKSpriteNode {
            animation.start(on: spriteNode)
        } else {
            startRigIdle(on: node)
        }
    }

    private func makeRigNode(for rig: SpriteRig) -> SKNode {
        let root = SKNode()
        let torsoBone = SKNode()
        torsoBone.name = "torso"
        torsoBone.position = CGPoint(x: 0, y: rig.canvasSize * 0.5)
        storeRestTransform(for: torsoBone)
        root.addChild(torsoBone)

        addRigBone("tail", from: rig, to: torsoBone, zPosition: 1)
        addRigBone("leftFoot", from: rig, to: torsoBone, zPosition: 2)
        addRigBone("rightFoot", from: rig, to: torsoBone, zPosition: 2)
        addStaticRigPart("body", from: rig, to: torsoBone, zPosition: 3)
        addRigBone("head", from: rig, to: torsoBone, zPosition: 6)
        addRigBone("leftEar", from: rig, to: torsoBone, zPosition: 7)
        addRigBone("rightEar", from: rig, to: torsoBone, zPosition: 7)
        addRigBone("leftHand", from: rig, to: torsoBone, zPosition: 5)
        let rightHandBone = addRigBone(
            "rightHand",
            from: rig,
            to: torsoBone,
            zPosition: 5
        )

        if let rightHandBone {
            addWeapon(from: rig, to: rightHandBone)
        } else {
            addWeapon(from: rig, to: torsoBone)
        }

        cacheRigNodes(for: root)
        return root
    }

    private func cacheRigNodes(for root: SKNode) {
        let descendants = namedDescendants(in: root)
        let namedNodes = descendants.reduce(into: [String: SKNode]()) {
            result,
            node in
            guard let name = node.name else { return }
            result[name] = node
        }

        let id = ObjectIdentifier(root)
        rigDescendantLookup[id] = descendants
        rigNodeLookup[id] = namedNodes
    }

    @discardableResult
    private func addRigBone(
        _ partName: String,
        from rig: SpriteRig,
        to parent: SKNode,
        zPosition: CGFloat
    ) -> SKNode? {
        guard
            let imageName = rig.parts[partName],
            let joint = rig.joints[partName]
        else {
            return nil
        }

        let bone = SKNode()
        bone.name = partName
        bone.position = CGPoint(x: joint.x, y: joint.y)
        bone.zPosition = zPosition
        storeRestTransform(for: bone)

        let sprite = makeRigSprite(named: imageName, canvasSize: rig.canvasSize)
        sprite.position = CGPoint(x: -joint.x, y: -joint.y)
        bone.addChild(sprite)
        parent.addChild(bone)
        return bone
    }

    private func addStaticRigPart(
        _ partName: String,
        from rig: SpriteRig,
        to parent: SKNode,
        zPosition: CGFloat
    ) {
        guard let imageName = rig.parts[partName] else { return }

        let sprite = makeRigSprite(named: imageName, canvasSize: rig.canvasSize)
        sprite.name = partName
        sprite.zPosition = zPosition
        parent.addChild(sprite)
    }

    private func addWeapon(from rig: SpriteRig, to parent: SKNode) {
        guard
            let imageName = rig.parts["weapon"],
            let joint = rig.joints["weapon"]
        else {
            return
        }

        let weaponBone = SKNode()
        weaponBone.name = "weapon"
        weaponBone.position = CGPoint(x: joint.x, y: joint.y)
        weaponBone.zPosition = -1
        weaponBone.zRotation = -0.18
        storeRestTransform(for: weaponBone)

        let sprite = makeRigSprite(named: imageName, canvasSize: rig.canvasSize)
        sprite.anchorPoint = CGPoint(x: 0.08, y: 0.5)
        sprite.name = "weaponSprite"
        sprite.position = CGPoint(x: -0.8, y: 0)
        sprite.setScale(0.3)
        weaponBone.addChild(sprite)
        parent.addChild(weaponBone)
    }

    private func updateRigWeapons() {
        for character in characters where character.rig != nil {
            guard
                let weaponBone = rigNode(named: "weapon", in: character.node),
                let weaponSprite = weaponBone.childNode(
                    withName: "weaponSprite"
                ) as? SKSpriteNode
            else {
                continue
            }

            weaponBone.isHidden = character.id != heroAnimationID

            if character.id == heroAnimationID,
                let equippedWeaponImageName
            {
                let weaponTexture = texture(named: equippedWeaponImageName)
                weaponTexture.filteringMode = .nearest
                weaponSprite.texture = weaponTexture
            }
        }
    }

    private func makeRigSprite(
        named imageName: String,
        canvasSize: CGFloat
    ) -> SKSpriteNode {
        let texture = texture(named: imageName)
        texture.filteringMode = .nearest

        let node = SKSpriteNode(texture: texture)
        node.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        node.size = CGSize(width: canvasSize, height: canvasSize)
        return node
    }

    private func layoutEnemy() {
        guard let enemy = currentEnemy, let enemyNode, let enemySpriteNode else {
            return
        }

        let enemySize = min(size.width, size.height) * CGFloat(enemy.scale)
        let yPosition = floorHeight * 0.56 + enemySize * 0.5
        enemyNode.position = CGPoint(x: size.width * 0.66, y: yPosition)
        enemySpriteNode.size = CGSize(width: enemySize, height: enemySize)
        enemyLabelNode?.position = CGPoint(x: 0, y: enemySize * 0.5 + 18)
    }

    private func layoutShadowClone() {
        guard let shadowCloneNode else { return }

        let cloneSize = min(size.width, size.height) * 0.26
        shadowCloneNode.position = CGPoint(
            x: size.width * 0.44,
            y: floorHeight * 0.56 + cloneSize * 0.5
        )
        shadowCloneNode.size = CGSize(width: cloneSize, height: cloneSize)
    }

    private func startRigIdle(on node: SKNode) {
        node.removeAllActions()

        for child in animatedRigNodes(in: node) {
            let amount: CGFloat =
                child.name == "tail" || child.name?.contains("Ear") == true
                ? 8
                : 4
            let motion = SKAction.sequence([
                .rotate(
                    toAngle: -radians(amount),
                    duration: 0.36,
                    shortestUnitArc: true
                ),
                .rotate(
                    toAngle: radians(amount),
                    duration: 0.36,
                    shortestUnitArc: true
                ),
            ])
            child.run(.repeatForever(motion), withKey: "rigPartIdle")
        }
    }

    private func playRigAttack(on node: SKNode, move: BattleCardMove) {
        node.removeAction(forKey: "rigAttack")
        node.removeAction(forKey: "rigIdle")
        animatedRigNodes(in: node).forEach {
            $0.removeAction(forKey: "rigPartIdle")
            $0.removeAction(forKey: "rigPartAttack")
        }
        resetRigPose(in: node)

        switch move {
        case .punch:
            movePart("rightHand", on: node, x: 18, y: 2, angle: -55)
            rotatePart("leftHand", on: node, angle: 28)
            rotatePart("weapon", on: node, angle: -70)
            rotatePart("head", on: node, angle: -8)
        case .kick:
            movePart("rightFoot", on: node, x: 20, y: 8, angle: -62)
            rotatePart("leftFoot", on: node, angle: 26)
            rotatePart("head", on: node, angle: 6)
        case .dash:
            movePart("rightHand", on: node, x: 22, y: 3, angle: -44)
            movePart("leftHand", on: node, x: -8, y: -3, angle: 26)
            rotatePart("weapon", on: node, angle: -78)
        case .tornado:
            movePart("rightFoot", on: node, x: 18, y: 12, angle: -92)
            rotatePart("leftFoot", on: node, angle: 45)
            rotatePart("rightHand", on: node, angle: -55)
            rotatePart("leftHand", on: node, angle: 55)
            rotatePart("weapon", on: node, angle: -110)
            rotatePart("head", on: node, angle: 24)
        case .roundhouse:
            movePart("rightFoot", on: node, x: 22, y: 9, angle: -98)
            rotatePart("leftHand", on: node, angle: 40)
            rotatePart("rightHand", on: node, angle: -30)
            rotatePart("weapon", on: node, angle: 32)
            rotatePart("head", on: node, angle: 10)
        case .airSpin:
            for child in animatedRigNodes(in: node) {
                rotatePart(child.name, on: node, angle: 62)
            }
        }

        run(
            .sequence([
                .wait(forDuration: 0.64),
                .run { [weak self, weak node] in
                    guard let node else { return }
                    self?.startRigIdle(on: node)
                },
            ]),
            withKey: "resumeRigIdle"
        )
    }

    private func movePart(
        _ name: String,
        on node: SKNode,
        x: CGFloat,
        y: CGFloat,
        angle: CGFloat
    ) {
        guard let child = rigNode(named: name, in: node) else { return }

        child.run(
            .sequence([
                .group([
                    .moveBy(x: x, y: y, duration: 0.12),
                    .rotate(
                        toAngle: radians(angle),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                ]),
                .wait(forDuration: 0.06),
                .group([
                    .moveBy(x: -x, y: -y, duration: 0.2),
                    .rotate(
                        toAngle: 0,
                        duration: 0.2,
                        shortestUnitArc: true
                    ),
                ]),
            ]),
            withKey: "rigPartAttack"
        )
    }

    private func rotatePart(_ name: String?, on node: SKNode, angle: CGFloat) {
        guard let name, let child = rigNode(named: name, in: node) else { return }

        child.run(
            .sequence([
                .rotate(
                    toAngle: radians(angle),
                    duration: 0.12,
                    shortestUnitArc: true
                ),
                .wait(forDuration: 0.06),
                .rotate(
                    toAngle: 0,
                    duration: 0.2,
                    shortestUnitArc: true
                ),
            ]),
            withKey: "rigPartAttack"
        )
    }

    private func rigNode(named name: String, in node: SKNode) -> SKNode? {
        if let cached = rigNodeLookup[ObjectIdentifier(node)]?[name] {
            return cached
        }

        if node.name == name {
            return node
        }

        for child in node.children {
            if let match = rigNode(named: name, in: child) {
                return match
            }
        }

        return nil
    }

    private func storeRestTransform(for node: SKNode) {
        let userData = node.userData ?? NSMutableDictionary()
        userData["restX"] = node.position.x
        userData["restY"] = node.position.y
        userData["restRotation"] = node.zRotation
        node.userData = userData
    }

    private func resetRigPose(in node: SKNode) {
        for child in namedDescendants(in: node) {
            child.removeAction(forKey: "rigPartIdle")
            child.removeAction(forKey: "rigPartAttack")

            guard let userData = child.userData else { continue }

            let x = userData["restX"] as? CGFloat ?? child.position.x
            let y = userData["restY"] as? CGFloat ?? child.position.y
            let rotation = userData["restRotation"] as? CGFloat ?? 0
            child.position = CGPoint(x: x, y: y)
            child.zRotation = rotation
        }
    }

    private func animatedRigNodes(in node: SKNode) -> [SKNode] {
        let descendants =
            rigDescendantLookup[ObjectIdentifier(node)] ?? namedDescendants(in: node)
        return descendants.filter { child in
            guard let name = child.name else { return false }
            return animatedRigPartNames.contains(name)
        }
    }

    private func namedDescendants(in node: SKNode) -> [SKNode] {
        if let cached = rigDescendantLookup[ObjectIdentifier(node)] {
            return cached
        }

        return node.children.flatMap { child -> [SKNode] in
            [child] + namedDescendants(in: child)
        }
    }

    private func rig(for animationID: String) -> SpriteRig? {
        rigsByID[animationID]
            ?? rigsByID[animationID.replacingOccurrences(of: "sprite_", with: "") + "_original"]
            ?? rigsByID[
                animationID
                    .replacingOccurrences(of: "sprite_", with: "")
                    .replacingOccurrences(of: "_original", with: "")
            ]
    }

    private func radians(_ degrees: CGFloat) -> CGFloat {
        degrees * .pi / 180
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
            let position = character.node.position
            character.shadow.position = CGPoint(
                x: position.x,
                y: position.y + 2
            )
            let displayWidth = character.displayWidth(in: size)
            character.shadow.xScale = max(displayWidth / 120, 0.18)
            character.shadow.yScale = max(displayWidth / 160, 0.14)
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

    private func clampedCharacterPosition(
        _ position: CGPoint,
        characterSize: CGSize
    ) -> CGPoint {
        guard size.width > 0, size.height > 0 else { return position }

        let horizontalInset = max(characterSize.width * 0.5, 12)
        let minimumX = min(horizontalInset, size.width * 0.5)
        let maximumX = max(minimumX, size.width - horizontalInset)
        let minimumY = max(characterSize.height * 0.08, 0)
        let maximumY = max(minimumY, size.height - characterSize.height * 0.35)

        return CGPoint(
            x: min(max(position.x, minimumX), maximumX),
            y: min(max(position.y, minimumY), maximumY)
        )
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
        let animation: SpriteSheetAnimation?
        let rig: SpriteRig?
        let node: SKNode
        let shadow: SKShapeNode

        func size(fitting container: CGSize, scale: CGFloat) -> CGSize {
            if let rig {
                let factor = min(container.width, container.height) * scale
                    / max(rig.canvasSize, 1)
                return CGSize(
                    width: rig.canvasSize * factor,
                    height: rig.canvasSize * factor
                )
            }

            return animation?.size(fitting: container, scale: scale) ?? .zero
        }

        func displayWidth(in container: CGSize) -> CGFloat {
            if let spriteNode = node as? SKSpriteNode {
                return spriteNode.size.width
            }

            return (rig?.canvasSize ?? 32) * node.xScale
        }
    }
}
