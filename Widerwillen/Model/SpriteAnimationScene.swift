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
    private var enemyRigNode: SKNode?
    private var enemyRig: SpriteRig?
    private var enemyLabelNode: SKLabelNode?
    private var shadowCloneNode: SKNode?
    private var shadowCloneRig: SpriteRig?
    private var heroAnimationID = "nimbi_original"
    private var heroPartImageOverrides: [String: String] = [:]
    private var equippedWeaponImageName: String?
    private var equippedWeaponShadowCloneImageName: String?
    private var equippedWeaponBattleAppearance: WeaponBattleAppearance?
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
    private enum BattleParticleStyle {
        case impact
        case wind
        case shadow
        case blade
        case launch
    }
    private let gridColumns = 5
    private let gridCellWidthRatio: CGFloat = 0.15
    private let gridCellHeightRatio: CGFloat = 0.18
    private let gridCenterXRatio: CGFloat = 0.5
    private let gridRowOffsetRatio: CGFloat = 0.065
    private let gridBaseYRatio: CGFloat = 0.30
    private let heroXRatio: CGFloat = 0.34
    private let heroYRatio: CGFloat = 0.54
    private let heroScale: CGFloat = 0.28
    private var showcaseHeroXRatio: CGFloat?
    private var showcaseHeroYRatio: CGFloat?
    private var showcaseHeroScale: CGFloat?
    private let enemyXRatio: CGFloat = 0.75
    private let weaponVisualOffset = CGPoint(x: 10, y: 10)

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
        updateCharacterVisibility()
        updateRigWeapons()

        layoutCharacters()
    }

    func updateBattleCharacter(
        heroAnimationID: String,
        heroPartImageOverrides: [String: String] = [:],
        equippedWeaponImageName: String?,
        equippedWeaponShadowCloneImageName: String?,
        equippedWeaponBattleAppearance: WeaponBattleAppearance?
    ) {
        self.heroAnimationID = heroAnimationID
        self.heroPartImageOverrides = heroPartImageOverrides
        self.equippedWeaponImageName = equippedWeaponImageName
        self.equippedWeaponShadowCloneImageName =
            equippedWeaponShadowCloneImageName
        self.equippedWeaponBattleAppearance =
            equippedWeaponBattleAppearance

        setupCharactersIfNeeded()
        updateCharacterVisibility()
        updateHeroRigPartOverrides()
        updateRigWeapons()
        layoutCharacters()
    }

    func updateShowcaseLayout(
        heroXRatio: CGFloat,
        heroYRatio: CGFloat,
        heroScale: CGFloat
    ) {
        showcaseHeroXRatio = heroXRatio
        showcaseHeroYRatio = heroYRatio
        showcaseHeroScale = heroScale
        layoutCharacters()
    }

    func updateEnemy(_ enemy: EnemyDefinition, isBoss: Bool) {
        let didChange =
            currentEnemy?.id != enemy.id
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
        enemySpriteNode = nil
        enemyRigNode = nil
        enemyRig = nil
        enemyLabelNode = nil

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

        let animationID = enemy.animationID ?? enemy.imageName
        if let rig = rig(for: animationID) ?? rig(for: enemy.imageName) {
            let rigNode = makeRigNode(for: rig)
            rigNode.zPosition = 1
            container.addChild(rigNode)
            enemyRigNode = rigNode
            enemyRig = rig
            startRigIdle(on: rigNode)
            scheduleEnemyRigMotion()
        } else {
            let sprite = SKSpriteNode()
            sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            sprite.xScale = -1
            sprite.zPosition = 1
            configureSprite(
                sprite,
                animationID: animationID,
                columns: enemy.columns,
                rows: enemy.rows,
                frameCount: enemy.frameCount,
                fps: enemy.fps,
                actionKey: "enemyAnimation"
            )
            container.addChild(sprite)
            enemySpriteNode = sprite
        }

        container.addChild(label)
        addChild(container)

        enemyNode = container
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
        shadowCloneRig = nil

        guard let animationID else { return }

        if let rig = rig(for: animationID) {

            let clone = makeRigNode(for: rig)

            clone.name = "shadowClone"
            clone.alpha = 0.62
            clone.zPosition = 2_900
            shadowCloneRig = rig

            // Shadow-Version der ausgerüsteten Waffe
            configureShadowCloneWeapon(
                on: clone,
                isVisible: true
            )

            startRigIdle(on: clone)
            scheduleShadowCloneMotion(on: clone)

            clone.run(.fadeIn(withDuration: 0.16))

            addChild(clone)

            shadowCloneNode = clone

        } else {

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
        }

        layoutShadowClone()

        if let shadowCloneNode {
            spawnBattleParticles(
                .shadow,
                from: shadowCloneNode,
                offset: CGPoint(x: 0, y: 12),
                count: 42
            )
        }
    }

    func playHeroAttackAnimation(move: BattleCardMove = .punch) {
        guard
            let hero = characters.first(where: { isHeroAnimation(id: $0.id) }),
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
        let knownRigIDs = Set(
            configuredSheets.compactMap { rig(for: $0.id)?.id }
        )
        var allSheets = configuredSheets

        for rig in rigsByID.values.sorted(by: { $0.id < $1.id })
        where !knownIDs.contains(rig.id) && !knownRigIDs.contains(rig.id) {
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
                isHeroAnimation(id: character.id)
                ? (showcaseHeroScale ?? heroScale)
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
                    characterSize.width
                    / max(character.rig?.canvasSize ?? 32, 1)
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

    private func updateHeroRigPartOverrides() {
        for character in characters {
            guard let rig = character.rig else { continue }
            let overrides =
                isHeroAnimation(id: character.id) ? heroPartImageOverrides : [:]

            for partName in CharacterBodyPart.allCases.map(\.rigPartName) {
                guard
                    let imageName = overrides[partName] ?? rig.parts[partName],
                    let sprite = rigSpriteNode(
                        named: partName,
                        in: character.node
                    )
                else {
                    continue
                }

                sprite.texture = texture(named: imageName)
            }
        }
    }

    private func rigSpriteNode(named partName: String, in node: SKNode)
        -> SKSpriteNode?
    {
        guard let partNode = rigNode(named: partName, in: node) else {
            return nil
        }

        if let spriteNode = partNode as? SKSpriteNode {
            return spriteNode
        }

        return partNode.children.compactMap { $0 as? SKSpriteNode }.first
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
            addWeapon(from: rig, to: rightHandBone, attachesToRightHand: true)
        } else {
            addWeapon(from: rig, to: torsoBone, attachesToRightHand: false)
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

    private func addWeapon(
        from rig: SpriteRig,
        to parent: SKNode,
        attachesToRightHand: Bool
    ) {
        guard
            let imageName = rig.parts["weapon"],
            let joint = rig.joints["weapon"]
        else {
            return
        }

        let weaponBone = SKNode()
        weaponBone.name = "weapon"
        if attachesToRightHand, let handJoint = rig.joints["rightHand"] {
            weaponBone.position = CGPoint(
                x: joint.x - handJoint.x,
                y: joint.y - handJoint.y
            )
        } else {
            weaponBone.position = CGPoint(x: joint.x, y: joint.y)
        }
        weaponBone.zPosition = 12
        weaponBone.zRotation = -0.18
        weaponBone.isHidden = true
        storeRestTransform(for: weaponBone)

        let sprite = makeRigSprite(
            named: imageName,
            canvasSize: rig.canvasSize
        )

        sprite.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        sprite.name = "weaponSprite"

        // Waffe etwas von der Hand wegschieben
        sprite.position = weaponVisualOffset

        sprite.zPosition = 1
        sprite.setScale(1)

        weaponBone.addChild(sprite)
        parent.addChild(weaponBone)
    }

    private func updateRigWeapons() {
        for character in characters where character.rig != nil {
            configureEquippedWeapon(
                on: character.node,
                isVisible: isHeroAnimation(id: character.id)
            )
        }

        if let shadowCloneNode {
            configureShadowCloneWeapon(
                on: shadowCloneNode,
                isVisible: true
            )
        }
    }

    private func configureShadowCloneWeapon(
        on node: SKNode,
        isVisible: Bool
    ) {
        guard
            let weaponBone = rigNode(named: "weapon", in: node),
            let weaponSprite = weaponBone.childNode(
                withName: "weaponSprite"
            ) as? SKSpriteNode
        else {
            return
        }

        guard isVisible else {
            weaponBone.isHidden = true
            return
        }

        let shadowWeaponImageName =
            equippedWeaponShadowCloneImageName
            ?? shadowCloneRig?.parts["weapon"]
            ?? "shadow_clone_nimbi_sword"

        weaponBone.isHidden = false

        let weaponTexture = texture(named: shadowWeaponImageName)
        weaponTexture.filteringMode = .nearest
        weaponSprite.texture = weaponTexture

        let appearance = equippedWeaponBattleAppearance

        weaponSprite.position = CGPoint(
            x: appearance?.offsetX ?? weaponVisualOffset.x,
            y: appearance?.offsetY ?? weaponVisualOffset.y
        )

        weaponSprite.setScale(appearance?.scale ?? 1.0)

        weaponSprite.zRotation = radians(
            appearance?.rotation ?? 0
        )
    }

    private func configureEquippedWeapon(on node: SKNode, isVisible: Bool) {
        guard
            let weaponBone = rigNode(named: "weapon", in: node),
            let weaponSprite = weaponBone.childNode(
                withName: "weaponSprite"
            ) as? SKSpriteNode
        else {
            return
        }

        guard isVisible, let equippedWeaponImageName else {
            weaponBone.isHidden = true
            return
        }

        weaponBone.isHidden = false

        let weaponTexture = texture(named: equippedWeaponImageName)
        weaponTexture.filteringMode = .nearest
        weaponSprite.texture = weaponTexture

        let appearance = equippedWeaponBattleAppearance
        weaponSprite.position = CGPoint(
            x: appearance?.offsetX ?? weaponVisualOffset.x,
            y: appearance?.offsetY ?? weaponVisualOffset.y
        )
        weaponSprite.setScale(appearance?.scale ?? 1.0)
        weaponSprite.zRotation = radians(appearance?.rotation ?? 0)
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
        guard let enemy = currentEnemy, let enemyNode else {
            return
        }

        let enemySize = min(size.width, size.height) * CGFloat(enemy.scale)

        if let enemySpriteNode {
            let yPosition = floorHeight * 0.56 + enemySize * 0.5

            enemyNode.position = CGPoint(
                x: size.width * enemyXRatio,
                y: yPosition
            )

            enemySpriteNode.size = CGSize(
                width: enemySize,
                height: enemySize
            )

        } else if let enemyRigNode, let enemyRig {
            enemyNode.position = CGPoint(
                x: size.width * enemyXRatio,
                y: floorHeight * 0.56
            )

            let scaleFactor = enemySize / max(enemyRig.canvasSize, 1)
            enemyRigNode.xScale = -scaleFactor
            enemyRigNode.yScale = scaleFactor
        }

        enemyLabelNode?.position = CGPoint(
            x: 0,
            y: enemySize * 0.5 + 18
        )
    }

    private func layoutShadowClone() {
        guard let shadowCloneNode else { return }

        let cloneSize = min(size.width, size.height) * 0.26
        if let sprite = shadowCloneNode as? SKSpriteNode {
            sprite.position = CGPoint(
                x: size.width * 0.44,
                y: floorHeight * 0.56 + cloneSize * 0.5
            )
            sprite.size = CGSize(width: cloneSize, height: cloneSize)
        } else if let shadowCloneRig {
            shadowCloneNode.position = CGPoint(
                x: size.width * 0.44,
                y: floorHeight * 0.56
            )
            let scaleFactor = cloneSize / max(shadowCloneRig.canvasSize, 1)
            shadowCloneNode.xScale = scaleFactor
            shadowCloneNode.yScale = scaleFactor
        }
    }

    private func startRigIdle(on node: SKNode) {
        node.removeAction(forKey: "rigIdle")
        rigNode(named: "torso", in: node)?.removeAction(forKey: "rigIdle")

        // Alte Idle-Aktionen sauber entfernen.
        for child in animatedRigNodes(in: node) {
            child.removeAction(forKey: "rigPartIdle")
        }

        // Der Torso wippt minimal, der Root bleibt fest am Battle-Anker.
        // Dadurch bleiben Kopf und Körper optisch verbunden.
        let torsoMotion = SKAction.sequence([
            .moveBy(x: 0, y: 0.35, duration: 0.45),
            .moveBy(x: 0, y: -0.35, duration: 0.45),
        ])

        (rigNode(named: "torso", in: node) ?? node).run(
            .repeatForever(torsoMotion),
            withKey: "rigIdle"
        )

        for child in animatedRigNodes(in: node) {
            let amount: CGFloat

            switch child.name {
            case "head":
                amount = 0

            case "leftHand", "rightHand":
                amount = 2.5

            case "leftFoot", "rightFoot":
                amount = 1.5

            case "weapon":
                amount = 2.0

            case "tail", "leftEar", "rightEar":
                amount = 6.0

            default:
                amount = 0
            }

            guard amount != 0 else { continue }

            let motion = SKAction.sequence([
                .rotate(
                    toAngle: -radians(amount),
                    duration: 0.45,
                    shortestUnitArc: true
                ),
                .rotate(
                    toAngle: radians(amount),
                    duration: 0.45,
                    shortestUnitArc: true
                ),
            ])

            child.run(
                .repeatForever(motion),
                withKey: "rigPartIdle"
            )
        }
    }

    private func playRigAttack(on node: SKNode, move: BattleCardMove) {
        let resumeKey = "resumeRigIdle-\(ObjectIdentifier(node).hashValue)"

        // Alte Animationen vollständig stoppen.
        node.removeAction(forKey: "rigAttack")
        node.removeAction(forKey: "rigIdle")
        removeAction(forKey: resumeKey)

        for child in namedDescendants(in: node) {
            child.removeAction(forKey: "rigPartIdle")
            child.removeAction(forKey: "rigPartAttack")
            child.removeAction(forKey: "rigTorsoAttack")
            child.removeAction(forKey: "rigBodyMotion")
        }

        resetRigPose(in: node)

        guard let torso = rigNode(named: "torso", in: node) else {
            startRigIdle(on: node)
            return
        }

        let rightHand = rigNode(named: "rightHand", in: node)
        let leftHand = rigNode(named: "leftHand", in: node)
        let rightFoot = rigNode(named: "rightFoot", in: node)
        let leftFoot = rigNode(named: "leftFoot", in: node)
        let head = rigNode(named: "head", in: node)
        let weapon = rigNode(named: "weapon", in: node)

        // Hero = +1
        // gespiegelt dargestellter Enemy = -1
        let facing: CGFloat = node.xScale < 0 ? -1 : 1
        emitMoveParticles(for: move, from: node, facing: facing)

        var attackDuration: TimeInterval = 0.5

        switch move {

        // MARK: - Punch

        case .punch:
            attackDuration = 0.52

            // Körper: zurückziehen -> explosiv vor -> Recovery
            let bodyPrepare = SKAction.group([
                .moveBy(x: -2 * facing, y: -1, duration: 0.11),
                .rotate(
                    toAngle: radians(8),
                    duration: 0.11,
                    shortestUnitArc: true
                ),
            ])
            bodyPrepare.timingMode = .easeOut

            let bodyStrike = SKAction.group([
                .moveBy(x: 9 * facing, y: 1, duration: 0.065),
                .rotate(
                    toAngle: radians(-11),
                    duration: 0.065,
                    shortestUnitArc: true
                ),
            ])
            bodyStrike.timingMode = .easeIn

            let bodyRecover = SKAction.group([
                .moveBy(x: -7 * facing, y: 0, duration: 0.20),
                .rotate(
                    toAngle: 0,
                    duration: 0.20,
                    shortestUnitArc: true
                ),
            ])
            bodyRecover.timingMode = .easeOut

            torso.run(
                .sequence([
                    bodyPrepare,
                    bodyStrike,
                    .wait(forDuration: 0.045),
                    bodyRecover,
                ]),
                withKey: "rigBodyMotion"
            )

            rightHand?.run(
                .sequence([
                    // Faust weit zurück
                    .group([
                        .moveBy(x: -4, y: 1, duration: 0.11),
                        .rotate(
                            toAngle: radians(24),
                            duration: 0.11,
                            shortestUnitArc: true
                        ),
                    ]),

                    // Schneller Schlag
                    .group([
                        .moveBy(x: 15, y: 0, duration: 0.065),
                        .rotate(
                            toAngle: radians(-55),
                            duration: 0.065,
                            shortestUnitArc: true
                        ),
                    ]),

                    // Impact
                    .wait(forDuration: 0.045),

                    // Zurück
                    .group([
                        .moveBy(x: -11, y: -1, duration: 0.20),
                        .rotate(
                            toAngle: 0,
                            duration: 0.20,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            leftHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(18),
                        duration: 0.11,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.11),
                    .rotate(
                        toAngle: 0,
                        duration: 0.20,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            head?.run(
                .sequence([
                    .wait(forDuration: 0.08),
                    .rotate(
                        toAngle: radians(-7),
                        duration: 0.07,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: 0,
                        duration: 0.20,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

        // MARK: - Kick

        case .kick:
            attackDuration = 0.62

            // Gewicht erst auf das Standbein verlagern.
            torso.run(
                .sequence([
                    .group([
                        .moveBy(
                            x: -3 * facing,
                            y: -2,
                            duration: 0.12
                        )
                    ]),

                    .group([
                        .moveBy(
                            x: 7 * facing,
                            y: 3,
                            duration: 0.09
                        )
                    ]),

                    .wait(forDuration: 0.055),

                    .moveBy(
                        x: -4 * facing,
                        y: -1,
                        duration: 0.22
                    ),
                ]),
                withKey: "rigBodyMotion"
            )

            torso.run(
                .sequence([
                    .rotate(
                        toAngle: radians(12),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: radians(-8),
                        duration: 0.09,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.055),
                    .rotate(
                        toAngle: 0,
                        duration: 0.22,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigTorsoAttack"
            )

            rightFoot?.run(
                .sequence([
                    // Knie anziehen
                    .group([
                        .moveBy(x: -2, y: 5, duration: 0.12),
                        .rotate(
                            toAngle: radians(24),
                            duration: 0.12,
                            shortestUnitArc: true
                        ),
                    ]),

                    // Kick
                    .group([
                        .moveBy(x: 15, y: 5, duration: 0.09),
                        .rotate(
                            toAngle: radians(-62),
                            duration: 0.09,
                            shortestUnitArc: true
                        ),
                    ]),

                    .wait(forDuration: 0.055),

                    // Bein zurück
                    .group([
                        .moveBy(x: -13, y: -10, duration: 0.22),
                        .rotate(
                            toAngle: 0,
                            duration: 0.22,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            leftFoot?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(9),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.145),
                    .rotate(
                        toAngle: 0,
                        duration: 0.22,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            leftHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-18),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: radians(22),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: 0,
                        duration: 0.22,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

        // MARK: - Dash Slash

        case .dash:
            attackDuration = 0.56

            // Kurz Spannung aufbauen.
            torso.run(
                .sequence([
                    .group([
                        .rotate(
                            toAngle: radians(12),
                            duration: 0.11,
                            shortestUnitArc: true
                        ),
                        .scaleX(
                            to: 1.04,
                            y: 0.96,
                            duration: 0.11
                        ),
                    ]),

                    // Dash-Pose
                    .group([
                        .rotate(
                            toAngle: radians(-15),
                            duration: 0.07,
                            shortestUnitArc: true
                        ),
                        .scaleX(
                            to: 0.98,
                            y: 1.03,
                            duration: 0.07
                        ),
                    ]),

                    .wait(forDuration: 0.05),

                    .group([
                        .rotate(
                            toAngle: 0,
                            duration: 0.20,
                            shortestUnitArc: true
                        ),
                        .scaleX(
                            to: 1,
                            y: 1,
                            duration: 0.20
                        ),
                    ]),
                ]),
                withKey: "rigTorsoAttack"
            )

            // Explosiv vor und etwas langsamer zurück.
            torso.run(
                .sequence([
                    .moveBy(
                        x: -3 * facing,
                        y: -2,
                        duration: 0.11
                    ),

                    .moveBy(
                        x: 28 * facing,
                        y: 2,
                        duration: 0.075
                    ),

                    .wait(forDuration: 0.05),

                    .moveBy(
                        x: -25 * facing,
                        y: 0,
                        duration: 0.22
                    ),
                ]),
                withKey: "rigBodyMotion"
            )

            rightHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(28),
                        duration: 0.11,
                        shortestUnitArc: true
                    ),

                    .group([
                        .moveBy(x: 8, y: 0, duration: 0.075),
                        .rotate(
                            toAngle: radians(-52),
                            duration: 0.075,
                            shortestUnitArc: true
                        ),
                    ]),

                    .wait(forDuration: 0.05),

                    .group([
                        .moveBy(x: -8, y: 0, duration: 0.22),
                        .rotate(
                            toAngle: 0,
                            duration: 0.22,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            weapon?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(30),
                        duration: 0.11,
                        shortestUnitArc: true
                    ),

                    .rotate(
                        toAngle: radians(-72),
                        duration: 0.075,
                        shortestUnitArc: true
                    ),

                    .wait(forDuration: 0.05),

                    .rotate(
                        toAngle: 0,
                        duration: 0.22,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

        // MARK: - Roundhouse

        case .roundhouse:
            attackDuration = 0.76

            // Erst in Gegenrichtung aufladen.
            torso.run(
                .sequence([
                    .moveBy(
                        x: -3 * facing,
                        y: -1,
                        duration: 0.14
                    ),

                    .moveBy(
                        x: 9 * facing,
                        y: 2,
                        duration: 0.11
                    ),

                    .wait(forDuration: 0.055),

                    .moveBy(
                        x: -6 * facing,
                        y: -1,
                        duration: 0.24
                    ),
                ]),
                withKey: "rigBodyMotion"
            )

            torso.run(
                .sequence([
                    // Wind-up
                    .rotate(
                        toAngle: radians(20),
                        duration: 0.14,
                        shortestUnitArc: true
                    ),

                    // Ganze Hüfte schnappt herum
                    .rotate(
                        toAngle: radians(-32),
                        duration: 0.11,
                        shortestUnitArc: true
                    ),

                    .wait(forDuration: 0.055),

                    // Follow-through
                    .rotate(
                        toAngle: radians(-8),
                        duration: 0.10,
                        shortestUnitArc: true
                    ),

                    .rotate(
                        toAngle: 0,
                        duration: 0.16,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigTorsoAttack"
            )

            rightFoot?.run(
                .sequence([
                    // Bein laden
                    .group([
                        .moveBy(x: -3, y: 5, duration: 0.14),
                        .rotate(
                            toAngle: radians(30),
                            duration: 0.14,
                            shortestUnitArc: true
                        ),
                    ]),

                    // Großer Bogen
                    .group([
                        .moveBy(x: 17, y: 5, duration: 0.11),
                        .rotate(
                            toAngle: radians(-82),
                            duration: 0.11,
                            shortestUnitArc: true
                        ),
                    ]),

                    .wait(forDuration: 0.055),

                    // Überschwingen
                    .group([
                        .moveBy(x: -4, y: -2, duration: 0.10),
                        .rotate(
                            toAngle: radians(-28),
                            duration: 0.10,
                            shortestUnitArc: true
                        ),
                    ]),

                    // zurück
                    .group([
                        .moveBy(x: -10, y: -8, duration: 0.16),
                        .rotate(
                            toAngle: 0,
                            duration: 0.16,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            leftHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-28),
                        duration: 0.14,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: radians(34),
                        duration: 0.11,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.055),
                    .rotate(
                        toAngle: 0,
                        duration: 0.26,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            rightHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(22),
                        duration: 0.14,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: radians(-28),
                        duration: 0.11,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.055),
                    .rotate(
                        toAngle: 0,
                        duration: 0.26,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

        // MARK: - Tornado

        case .tornado:
            attackDuration = 1.02

            // Arme/Füße öffnen sich erst.
            leftHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(38),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.66),
                    .rotate(
                        toAngle: 0,
                        duration: 0.16,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            rightHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-38),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.66),
                    .rotate(
                        toAngle: 0,
                        duration: 0.16,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            leftFoot?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(24),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.66),
                    .rotate(
                        toAngle: 0,
                        duration: 0.16,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            rightFoot?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-24),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.66),
                    .rotate(
                        toAngle: 0,
                        duration: 0.16,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            // Crouch
            let crouch = SKAction.moveBy(
                x: 0,
                y: -4,
                duration: 0.11
            )
            crouch.timingMode = .easeIn

            // Explosiver Absprung
            let launch = SKAction.moveBy(
                x: 0,
                y: 39,
                duration: 0.16
            )
            launch.timingMode = .easeOut

            // Kleine seitliche Bewegung während des Wirbels.
            let airborneDrift = SKAction.sequence([
                .moveBy(
                    x: 7 * facing,
                    y: 5,
                    duration: 0.23
                ),
                .moveBy(
                    x: -14 * facing,
                    y: -3,
                    duration: 0.23
                ),
                .moveBy(
                    x: 7 * facing,
                    y: -2,
                    duration: 0.12
                ),
            ])

            // Landung exakt zurück.
            let land = SKAction.moveBy(
                x: 0,
                y: -35,
                duration: 0.17
            )
            land.timingMode = .easeIn

            torso.run(
                .sequence([
                    crouch,
                    launch,
                    airborneDrift,
                    land,
                ]),
                withKey: "rigBodyMotion"
            )

            // WICHTIG:
            // torso statt Root drehen.
            torso.run(
                .sequence([
                    // Squash vorm Absprung
                    .scaleX(
                        to: 1.06,
                        y: 0.93,
                        duration: 0.11
                    ),

                    // Körper streckt sich
                    .scaleX(
                        to: 0.97,
                        y: 1.05,
                        duration: 0.12
                    ),

                    // Drei komplette Spins in der Luft
                    .rotate(
                        byAngle: -.pi * 6,
                        duration: 0.58
                    ),

                    // Landing Squash
                    .scaleX(
                        to: 1.08,
                        y: 0.91,
                        duration: 0.07
                    ),

                    // zurück
                    .scaleX(
                        to: 1,
                        y: 1,
                        duration: 0.13
                    ),
                ]),
                withKey: "rigTorsoAttack"
            )

        // MARK: - Air Spin

        case .airSpin:
            attackDuration = 1.08

            // kompaktere Flugpose
            leftHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(26),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.66),
                    .rotate(
                        toAngle: 0,
                        duration: 0.18,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            rightHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-24),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.66),
                    .rotate(
                        toAngle: 0,
                        duration: 0.18,
                        shortestUnitArc: true
                    ),
                ]),
                withKey: "rigPartAttack"
            )

            rightFoot?.run(
                .sequence([
                    .group([
                        .moveBy(x: 1, y: 3, duration: 0.12),
                        .rotate(
                            toAngle: radians(-28),
                            duration: 0.12,
                            shortestUnitArc: true
                        ),
                    ]),
                    .wait(forDuration: 0.66),
                    .group([
                        .moveBy(x: -1, y: -3, duration: 0.18),
                        .rotate(
                            toAngle: 0,
                            duration: 0.18,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            let crouch = SKAction.moveBy(
                x: 0,
                y: -4,
                duration: 0.12
            )
            crouch.timingMode = .easeIn

            // höher und leicht nach vorne
            let launch = SKAction.moveBy(
                x: 5 * facing,
                y: 54,
                duration: 0.19
            )
            launch.timingMode = .easeOut

            // echte Flugkurve
            let flightArc = SKAction.sequence([
                .moveBy(
                    x: 12 * facing,
                    y: 8,
                    duration: 0.20
                ),
                .moveBy(
                    x: -12 * facing,
                    y: -8,
                    duration: 0.20
                ),
            ])

            let land = SKAction.moveBy(
                x: -5 * facing,
                y: -50,
                duration: 0.19
            )
            land.timingMode = .easeIn

            torso.run(
                .sequence([
                    crouch,
                    launch,
                    flightArc,
                    land,
                ]),
                withKey: "rigBodyMotion"
            )

            torso.run(
                .sequence([
                    // vor dem Sprung komprimieren
                    .scaleX(
                        to: 1.05,
                        y: 0.94,
                        duration: 0.12
                    ),

                    // Streckung beim Absprung
                    .scaleX(
                        to: 0.97,
                        y: 1.05,
                        duration: 0.13
                    ),

                    // Eine kontrollierte 360°-Drehung
                    .rotate(
                        byAngle: -.pi * 2,
                        duration: 0.43
                    ),

                    // Landungs-Squash
                    .scaleX(
                        to: 1.07,
                        y: 0.92,
                        duration: 0.08
                    ),

                    .scaleX(
                        to: 1,
                        y: 1,
                        duration: 0.15
                    ),
                ]),
                withKey: "rigTorsoAttack"
            )

        // MARK: - Uppercut

        case .uppercut:
            attackDuration = 0.72

            torso.run(
                .sequence([
                    .group([
                        .moveBy(x: -3 * facing, y: -4, duration: 0.12),
                        .rotate(
                            toAngle: radians(12),
                            duration: 0.12,
                            shortestUnitArc: true
                        ),
                        .scaleX(to: 1.07, y: 0.92, duration: 0.12),
                    ]),
                    .group([
                        .moveBy(x: 6 * facing, y: 18, duration: 0.10),
                        .rotate(
                            toAngle: radians(-18),
                            duration: 0.10,
                            shortestUnitArc: true
                        ),
                        .scaleX(to: 0.94, y: 1.08, duration: 0.10),
                    ]),
                    .wait(forDuration: 0.06),
                    .group([
                        .moveBy(x: -3 * facing, y: -14, duration: 0.24),
                        .rotate(
                            toAngle: 0,
                            duration: 0.24,
                            shortestUnitArc: true
                        ),
                        .scaleX(to: 1, y: 1, duration: 0.24),
                    ]),
                ]),
                withKey: "rigBodyMotion"
            )

            rightHand?.run(
                .sequence([
                    .group([
                        .moveBy(x: -2, y: 2, duration: 0.12),
                        .rotate(
                            toAngle: radians(20),
                            duration: 0.12,
                            shortestUnitArc: true
                        ),
                    ]),
                    .group([
                        .moveBy(x: 9, y: 17, duration: 0.10),
                        .rotate(
                            toAngle: radians(-92),
                            duration: 0.10,
                            shortestUnitArc: true
                        ),
                    ]),
                    .wait(forDuration: 0.06),
                    .group([
                        .moveBy(x: -7, y: -19, duration: 0.24),
                        .rotate(
                            toAngle: 0,
                            duration: 0.24,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            weapon?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(32),
                        duration: 0.12,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: radians(-118),
                        duration: 0.10,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.06),
                    .rotate(toAngle: 0, duration: 0.24, shortestUnitArc: true),
                ]),
                withKey: "rigPartAttack"
            )

            leftFoot?.run(
                .sequence([
                    .moveBy(x: -2, y: 2, duration: 0.12),
                    .wait(forDuration: 0.16),
                    .moveBy(x: 2, y: -2, duration: 0.22),
                ]),
                withKey: "rigPartAttack"
            )

        // MARK: - Phantom Slash

        case .phantomSlash:
            attackDuration = 0.68

            torso.run(
                .sequence([
                    .group([
                        .moveBy(x: -5 * facing, y: -2, duration: 0.10),
                        .rotate(
                            toAngle: radians(14),
                            duration: 0.10,
                            shortestUnitArc: true
                        ),
                    ]),
                    .group([
                        .moveBy(x: 32 * facing, y: 3, duration: 0.08),
                        .rotate(
                            toAngle: radians(-24),
                            duration: 0.08,
                            shortestUnitArc: true
                        ),
                    ]),
                    .wait(forDuration: 0.05),
                    .group([
                        .moveBy(x: -27 * facing, y: -1, duration: 0.24),
                        .rotate(
                            toAngle: 0,
                            duration: 0.24,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigBodyMotion"
            )

            rightHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(34),
                        duration: 0.10,
                        shortestUnitArc: true
                    ),
                    .group([
                        .moveBy(x: 11, y: 1, duration: 0.08),
                        .rotate(
                            toAngle: radians(-78),
                            duration: 0.08,
                            shortestUnitArc: true
                        ),
                    ]),
                    .wait(forDuration: 0.05),
                    .group([
                        .moveBy(x: -11, y: -1, duration: 0.24),
                        .rotate(
                            toAngle: 0,
                            duration: 0.24,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            weapon?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(58),
                        duration: 0.10,
                        shortestUnitArc: true
                    ),
                    .rotate(
                        toAngle: radians(-138),
                        duration: 0.08,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.05),
                    .rotate(toAngle: 0, duration: 0.24, shortestUnitArc: true),
                ]),
                withKey: "rigPartAttack"
            )

            head?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-10),
                        duration: 0.16,
                        shortestUnitArc: true
                    ),
                    .rotate(toAngle: 0, duration: 0.24, shortestUnitArc: true),
                ]),
                withKey: "rigPartAttack"
            )

        // MARK: - Meteor Kick

        case .meteorKick:
            attackDuration = 0.92

            torso.run(
                .sequence([
                    .group([
                        .moveBy(x: -2 * facing, y: -4, duration: 0.12),
                        .scaleX(to: 1.07, y: 0.91, duration: 0.12),
                    ]),
                    .group([
                        .moveBy(x: 4 * facing, y: 46, duration: 0.18),
                        .rotate(
                            toAngle: radians(28),
                            duration: 0.18,
                            shortestUnitArc: true
                        ),
                        .scaleX(to: 0.95, y: 1.06, duration: 0.18),
                    ]),
                    .group([
                        .moveBy(x: 13 * facing, y: -34, duration: 0.16),
                        .rotate(
                            toAngle: radians(-36),
                            duration: 0.16,
                            shortestUnitArc: true
                        ),
                    ]),
                    .group([
                        .moveBy(x: -15 * facing, y: -8, duration: 0.24),
                        .rotate(
                            toAngle: 0,
                            duration: 0.24,
                            shortestUnitArc: true
                        ),
                        .scaleX(to: 1, y: 1, duration: 0.24),
                    ]),
                ]),
                withKey: "rigBodyMotion"
            )

            rightFoot?.run(
                .sequence([
                    .group([
                        .moveBy(x: 0, y: 5, duration: 0.12),
                        .rotate(
                            toAngle: radians(24),
                            duration: 0.12,
                            shortestUnitArc: true
                        ),
                    ]),
                    .wait(forDuration: 0.16),
                    .group([
                        .moveBy(x: 15, y: -9, duration: 0.16),
                        .rotate(
                            toAngle: radians(-96),
                            duration: 0.16,
                            shortestUnitArc: true
                        ),
                    ]),
                    .group([
                        .moveBy(x: -15, y: 4, duration: 0.24),
                        .rotate(
                            toAngle: 0,
                            duration: 0.24,
                            shortestUnitArc: true
                        ),
                    ]),
                ]),
                withKey: "rigPartAttack"
            )

            leftHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(34),
                        duration: 0.16,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.20),
                    .rotate(toAngle: 0, duration: 0.24, shortestUnitArc: true),
                ]),
                withKey: "rigPartAttack"
            )

        // MARK: - Blade Storm

        case .bladeStorm:
            attackDuration = 1.05

            torso.run(
                .sequence([
                    .group([
                        .moveBy(x: 0, y: 9, duration: 0.12),
                        .scaleX(to: 0.96, y: 1.05, duration: 0.12),
                    ]),
                    .group([
                        .rotate(byAngle: -.pi * 4, duration: 0.58),
                        .moveBy(x: 6 * facing, y: 4, duration: 0.58),
                    ]),
                    .group([
                        .moveBy(x: -6 * facing, y: -13, duration: 0.22),
                        .scaleX(to: 1, y: 1, duration: 0.22),
                    ]),
                ]),
                withKey: "rigTorsoAttack"
            )

            rightHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-42),
                        duration: 0.10,
                        shortestUnitArc: true
                    ),
                    .rotate(byAngle: -.pi * 3, duration: 0.58),
                    .rotate(toAngle: 0, duration: 0.22, shortestUnitArc: true),
                ]),
                withKey: "rigPartAttack"
            )

            weapon?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(-86),
                        duration: 0.10,
                        shortestUnitArc: true
                    ),
                    .rotate(byAngle: -.pi * 5, duration: 0.58),
                    .rotate(toAngle: 0, duration: 0.22, shortestUnitArc: true),
                ]),
                withKey: "rigPartAttack"
            )

            leftHand?.run(
                .sequence([
                    .rotate(
                        toAngle: radians(38),
                        duration: 0.10,
                        shortestUnitArc: true
                    ),
                    .wait(forDuration: 0.58),
                    .rotate(toAngle: 0, duration: 0.22, shortestUnitArc: true),
                ]),
                withKey: "rigPartAttack"
            )
        }

        // Idle erst nach der wirklichen Animationsdauer starten.
        run(
            .sequence([
                .wait(forDuration: attackDuration),

                .run { [weak self, weak node] in
                    guard let self, let node else { return }

                    self.resetRigPose(in: node)
                    self.startRigIdle(on: node)
                },
            ]),
            withKey: resumeKey
        )
    }

    private func scheduleEnemyRigMotion() {
        guard let enemyNode, let enemyRigNode else { return }

        enemyNode.removeAction(forKey: "enemyRigMotion")
        let moves: [BattleCardMove] = [
            .punch,
            .kick,
            .dash,
            .uppercut,
            .meteorKick,
            .bladeStorm,
        ]
        let loop = SKAction.repeatForever(
            .sequence([
                .wait(forDuration: Double.random(in: 1.2...2.4)),
                .run { [weak self, weak enemyRigNode] in
                    guard let self, let enemyRigNode else { return }
                    let move = moves.randomElement() ?? .punch
                    self.playRigAttack(on: enemyRigNode, move: move)
                },
            ])
        )
        enemyNode.run(loop, withKey: "enemyRigMotion")
    }

    private func scheduleShadowCloneMotion(on clone: SKNode) {
        clone.removeAction(forKey: "shadowCloneRigMotion")

        let moves: [BattleCardMove] = [
            .punch,
            .dash,
            .uppercut,
            .phantomSlash,
            .tornado,
            .roundhouse,
            .airSpin,
            .bladeStorm,
        ]
        let loop = SKAction.repeatForever(
            .sequence([
                .wait(forDuration: Double.random(in: 0.65...1.35)),
                .run { [weak self, weak clone] in
                    guard let self, let clone else { return }

                    if Bool.random() {
                        self.playWeaponToss(on: clone)
                    } else {
                        let move = moves.randomElement() ?? .dash
                        self.playRigAttack(on: clone, move: move)
                    }
                },
            ])
        )

        clone.run(loop, withKey: "shadowCloneRigMotion")
    }

    private func playWeaponToss(on node: SKNode) {
        let resumeKey = "resumeRigIdle-\(ObjectIdentifier(node).hashValue)"
        guard let weapon = rigNode(named: "weapon", in: node) else {
            playRigAttack(on: node, move: .airSpin)
            return
        }

        removeAction(forKey: resumeKey)
        node.removeAction(forKey: "rigIdle")
        rigNode(named: "torso", in: node)?.removeAction(forKey: "rigIdle")
        for child in namedDescendants(in: node) {
            child.removeAction(forKey: "rigPartIdle")
            child.removeAction(forKey: "rigPartAttack")
            child.removeAction(forKey: "rigTorsoAttack")
            child.removeAction(forKey: "rigBodyMotion")
        }
        resetRigPose(in: node)
        spawnBattleParticles(
            .blade,
            from: node,
            offset: CGPoint(x: 8, y: 36),
            count: 20
        )

        let toss = SKAction.sequence([
            .group([
                .moveBy(x: 0, y: 8, duration: 0.14),
                .rotate(byAngle: radians(220), duration: 0.14),
            ]),
            .group([
                .moveBy(x: 3, y: 10, duration: 0.12),
                .rotate(byAngle: radians(300), duration: 0.12),
            ]),
            .group([
                .moveBy(x: -3, y: -18, duration: 0.18),
                .rotate(byAngle: radians(380), duration: 0.18),
            ]),
            .run { [weak self, weak node] in
                guard let self, let node else { return }
                self.resetRigPose(in: node)
                self.configureWeaponAfterAttack(on: node)
            },
        ])

        weapon.run(toss, withKey: "rigPartAttack")
        run(
            .sequence([
                .wait(forDuration: 0.52),
                .run { [weak self, weak node] in
                    guard let self, let node else { return }
                    self.startRigIdle(on: node)
                },
            ]),
            withKey: resumeKey
        )
    }

    private func configureWeaponAfterAttack(on node: SKNode) {
        if node === shadowCloneNode || node.name == "shadowClone" {
            configureShadowCloneWeapon(on: node, isVisible: true)
        } else {
            configureEquippedWeapon(on: node, isVisible: true)
        }
    }

    private func emitMoveParticles(
        for move: BattleCardMove,
        from node: SKNode,
        facing: CGFloat
    ) {
        switch move {
        case .punch:
            spawnBattleParticles(
                .impact,
                from: node,
                offset: CGPoint(x: 30 * facing, y: 22),
                count: 14,
                delay: 0.18
            )
        case .kick, .roundhouse:
            spawnBattleParticles(
                .impact,
                from: node,
                offset: CGPoint(x: 34 * facing, y: 18),
                count: 18,
                delay: 0.22
            )
        case .dash, .phantomSlash:
            spawnBattleParticles(
                .blade,
                from: node,
                offset: CGPoint(x: 34 * facing, y: 25),
                count: 26,
                delay: 0.18
            )
        case .tornado, .airSpin, .bladeStorm:
            spawnBattleParticles(
                .wind,
                from: node,
                offset: CGPoint(x: 8 * facing, y: 28),
                count: 30,
                delay: 0.16
            )
        case .uppercut:
            spawnBattleParticles(
                .launch,
                from: node,
                offset: CGPoint(x: 20 * facing, y: 34),
                count: 24,
                delay: 0.22
            )
        case .meteorKick:
            spawnBattleParticles(
                .impact,
                from: node,
                offset: CGPoint(x: 36 * facing, y: 12),
                count: 32,
                delay: 0.46
            )
        }
    }

    private func spawnBattleParticles(
        _ style: BattleParticleStyle,
        from node: SKNode,
        offset: CGPoint = .zero,
        count: Int,
        delay: TimeInterval = 0
    ) {
        run(
            .sequence([
                .wait(forDuration: delay),
                .run { [weak self, weak node] in
                    guard let self, let node else { return }
                    self.spawnBattleParticlesNow(
                        style,
                        from: node,
                        offset: offset,
                        count: count
                    )
                },
            ])
        )
    }

    private func spawnBattleParticlesNow(
        _ style: BattleParticleStyle,
        from node: SKNode,
        offset: CGPoint,
        count: Int
    ) {
        let origin = node.convert(offset, to: self)

        for _ in 0..<count {
            let particle = SKShapeNode(
                circleOfRadius: particleRadius(for: style)
            )
            particle.fillColor = particleColor(for: style)
            particle.strokeColor = particleStrokeColor(for: style)
            particle.lineWidth = particleLineWidth(for: style)
            particle.glowWidth = particleGlowWidth(for: style)
            particle.position = origin
            particle.zPosition = 4_800
            particle.alpha = particleAlpha(for: style)
            addChild(particle)

            let distance = CGFloat.random(
                in: particleDistanceRange(for: style)
            )
            let angle = CGFloat.random(in: particleAngleRange(for: style))
            let target = CGVector(
                dx: cos(angle) * distance,
                dy: sin(angle) * distance
            )
            let duration = TimeInterval.random(
                in: particleDurationRange(for: style)
            )

            particle.run(
                .sequence([
                    .group([
                        .move(by: target, duration: duration),
                        .scale(to: 0.2, duration: duration),
                        .fadeOut(withDuration: duration),
                    ]),
                    .removeFromParent(),
                ])
            )
        }
    }

    private func particleRadius(for style: BattleParticleStyle) -> CGFloat {
        switch style {
        case .shadow:
            CGFloat.random(in: 2.5...7)
        case .wind:
            CGFloat.random(in: 1.5...4)
        case .blade:
            CGFloat.random(in: 1.5...3.5)
        case .launch:
            CGFloat.random(in: 2...5)
        case .impact:
            CGFloat.random(in: 2...5)
        }
    }

    private func particleColor(for style: BattleParticleStyle) -> UIColor {
        switch style {
        case .shadow:
            UIColor(white: CGFloat.random(in: 0.02...0.12), alpha: 0.9)
        case .wind:
            UIColor(red: 0.72, green: 0.94, blue: 1.0, alpha: 0.85)
        case .blade:
            UIColor(red: 0.92, green: 0.98, blue: 1.0, alpha: 0.95)
        case .launch:
            UIColor(red: 0.8, green: 0.9, blue: 1.0, alpha: 0.9)
        case .impact:
            UIColor(red: 1.0, green: 0.92, blue: 0.28, alpha: 0.95)
        }
    }

    private func particleStrokeColor(for style: BattleParticleStyle) -> UIColor
    {
        switch style {
        case .shadow:
            .black
        case .blade, .wind, .launch:
            .white
        case .impact:
            UIColor(red: 1.0, green: 0.36, blue: 0.18, alpha: 0.9)
        }
    }

    private func particleLineWidth(for style: BattleParticleStyle) -> CGFloat {
        switch style {
        case .shadow:
            0
        default:
            1
        }
    }

    private func particleGlowWidth(for style: BattleParticleStyle) -> CGFloat {
        switch style {
        case .shadow:
            1
        case .wind, .blade, .launch:
            3
        case .impact:
            2
        }
    }

    private func particleAlpha(for style: BattleParticleStyle) -> CGFloat {
        switch style {
        case .shadow:
            CGFloat.random(in: 0.45...0.9)
        default:
            CGFloat.random(in: 0.62...0.95)
        }
    }

    private func particleDistanceRange(
        for style: BattleParticleStyle
    ) -> ClosedRange<CGFloat> {
        switch style {
        case .shadow:
            10...44
        case .wind:
            18...64
        case .blade:
            16...54
        case .launch:
            22...58
        case .impact:
            12...46
        }
    }

    private func particleAngleRange(
        for style: BattleParticleStyle
    ) -> ClosedRange<CGFloat> {
        switch style {
        case .shadow:
            0...(CGFloat.pi * 2)
        case .wind:
            (-CGFloat.pi * 0.2)...(CGFloat.pi * 1.2)
        case .blade:
            (-CGFloat.pi * 0.35)...(CGFloat.pi * 0.35)
        case .launch:
            (CGFloat.pi * 0.15)...(CGFloat.pi * 0.85)
        case .impact:
            (-CGFloat.pi * 0.1)...(CGFloat.pi * 1.1)
        }
    }

    private func particleDurationRange(
        for style: BattleParticleStyle
    ) -> ClosedRange<TimeInterval> {
        switch style {
        case .shadow:
            0.34...0.72
        case .wind:
            0.24...0.46
        case .blade:
            0.18...0.36
        case .launch:
            0.26...0.48
        case .impact:
            0.18...0.34
        }
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
        guard let name, let child = rigNode(named: name, in: node) else {
            return
        }

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
        userData["restScaleX"] = node.xScale
        userData["restScaleY"] = node.yScale

        node.userData = userData
    }

    private func resetRigPose(in node: SKNode) {
        for child in namedDescendants(in: node) {
            child.removeAction(forKey: "rigPartIdle")
            child.removeAction(forKey: "rigPartAttack")
            child.removeAction(forKey: "rigTorsoAttack")

            guard let userData = child.userData else {
                continue
            }

            let x =
                userData["restX"] as? CGFloat
                ?? child.position.x

            let y =
                userData["restY"] as? CGFloat
                ?? child.position.y

            let rotation =
                userData["restRotation"] as? CGFloat
                ?? 0

            let scaleX =
                userData["restScaleX"] as? CGFloat
                ?? 1

            let scaleY =
                userData["restScaleY"] as? CGFloat
                ?? 1

            child.position = CGPoint(x: x, y: y)
            child.zRotation = rotation
            child.xScale = scaleX
            child.yScale = scaleY
        }
    }

    private func animatedRigNodes(in node: SKNode) -> [SKNode] {
        let descendants =
            rigDescendantLookup[ObjectIdentifier(node)]
            ?? namedDescendants(in: node)
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
        let normalized =
            animationID
            .replacingOccurrences(of: "sprite_", with: "")
            .replacingOccurrences(of: "_original", with: "")
        let candidates = [
            animationID,
            "\(normalized)_original",
            normalized,
            "sprite_\(normalized)",
        ]

        return candidates.lazy.compactMap { self.rigsByID[$0] }.first
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
        if isHeroAnimation(id: id) {
            return CGPoint(
                x: size.width * (showcaseHeroXRatio ?? heroXRatio),
                y: floorHeight * (showcaseHeroYRatio ?? heroYRatio)
                    + fallbackYOffset
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
        isHeroAnimation(id: id) || isCompanionAnimation(id: id)
    }

    private func isHeroAnimation(id: String) -> Bool {
        animationID(id, matches: heroAnimationID)
    }

    private func isCompanionAnimation(id: String) -> Bool {
        companionAnimationIDs.contains { animationID(id, matches: $0) }
    }

    private func animationID(_ id: String, matches otherID: String) -> Bool {
        if id == otherID {
            return true
        }

        guard
            let leftRigID = rig(for: id)?.id,
            let rightRigID = rig(for: otherID)?.id
        else {
            return false
        }

        return leftRigID == rightRigID
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
                let factor =
                    min(container.width, container.height) * scale
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
