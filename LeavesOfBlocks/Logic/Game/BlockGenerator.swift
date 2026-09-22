import Foundation

// MARK: - Solvability Logging Extensions

extension BuildConfiguration {
    /// Specialized logging for solvability detection and resolution with performance optimization
    static func logSolvability(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        // Early exit if logging level won't be displayed (performance optimization)
        guard level.rawValue >= currentLogLevel.rawValue else { return }

        let prefix = "[SOLVABILITY]"
        log("\(prefix) \(message)", level: level, file: file, function: function, line: line)
    }
}

// MARK: - Block Creation Utilities

extension BlockGenerator {
    /// Creates a single block with random color - reduces code duplication
    private static func createSingleBlock(using generator: inout any RandomNumberGenerator) -> BlockShape {
        let randomColor = BlockColor.allCases.randomElement(using: &generator) ?? .blue
        return BlockShape(positions: [GridPosition(row: 0, col: 0)], color: randomColor)
    }

    /// Creates multiple single blocks efficiently
    private static func createSingleBlocks(count: Int, using generator: inout any RandomNumberGenerator) -> [BlockShape] {
        return (0..<count).map { _ in createSingleBlock(using: &generator) }
    }
}

// MARK: - Pressure-Based Block Generation
//
// Historically the generator picked a `TierConfiguration` (diverse /
// constrained / minimal / emergency) from `GridAnalysis`'s grid-quality
// score and used its `maxBlockSize` to cap what could be drawn — the worse
// the board scored, the smaller everything dealt got, bottoming out at 1–3
// cell blocks at `.emergency`. That rewarded bad play: a board that was
// mostly empty but had a few scattered isolated blocks on it could still
// tank the quality score (GridAnalysis's fragmentation term is about how
// isolated the *filled* cells are, at a -0.25 weight) and get capped just
// as hard as a genuinely crowded board (#177).
//
// This replaces the cap with rank-and-pick. Nothing is off-limits by size;
// instead several candidate sets are drawn from the same unconstrained
// distribution, each is scored by how much it actually helps the player
// right now, and `BoardPressure` — not block size — decides where on that
// ranking the deal comes from. A calm board deals generously; a board in
// genuine trouble (dense, fragmented, littered with dead cells, or just a
// long game) deals the least helpful set that's still solvable. The
// solvability guarantee itself (#37: no game is lost to the luck of the
// draw) is unchanged — see `constrainedFallback` for what happens when no
// candidate is solvable at all.
extension BlockGenerator {

    /// One dealt-but-not-yet-chosen candidate set, with how much it helps
    /// the player scored against the current grid.
    private struct ScoredCandidate {
        let blocks: [BlockShape]
        let helpfulness: Double
    }

    /// Generates blocks using pressure-based candidate selection.
    ///
    /// Draws from the system's random source. Use
    /// `generateTieredBlocks(count:difficulty:grid:behaviorTracker:blocksPlaced:using:)`
    /// to inject a seeded generator instead — the seam `GameSimulator` uses so
    /// a calibration run can be reproduced from a seed. See
    /// `conventions/game-logic-boundary.md`: "a random source without a
    /// passed-in generator is a parameter, not a lookup."
    static func generateTieredBlocks(
        count: Int = 3,
        difficulty: DifficultyMode = .easy,
        grid: [[GridCell]],
        behaviorTracker: PlayerBehaviorTracker? = nil,
        blocksPlaced: Int = 0
    ) -> [BlockShape] {
        var generator: any RandomNumberGenerator = SystemRandomNumberGenerator()
        return generateTieredBlocks(count: count, difficulty: difficulty, grid: grid, behaviorTracker: behaviorTracker, blocksPlaced: blocksPlaced, using: &generator)
    }

    /// Same as
    /// `generateTieredBlocks(count:difficulty:grid:behaviorTracker:blocksPlaced:)`,
    /// but draws from `generator` instead of the system's random source.
    static func generateTieredBlocks(
        count: Int = 3,
        difficulty: DifficultyMode = .easy,
        grid: [[GridCell]],
        behaviorTracker: PlayerBehaviorTracker? = nil,
        blocksPlaced: Int = 0,
        using generator: inout any RandomNumberGenerator
    ) -> [BlockShape] {
        let startTime = CFAbsoluteTimeGetCurrent()
        let pressure = BoardPressure.calculate(grid: grid, blocksPlaced: blocksPlaced, difficulty: difficulty)
        // Computed once per deal rather than once per block drawn: it only
        // depends on `difficulty`, which is constant for this whole call,
        // but generateCandidateSet may draw dozens of blocks across all its
        // candidate attempts.
        let baseWeights = getBlockWeights(for: difficulty)

        var solvable: [ScoredCandidate] = []
        for _ in 0..<AppConfiguration.Gameplay.pressureCandidateCount {
            if let candidate = generateCandidateSet(count: count, difficulty: difficulty, baseWeights: baseWeights, grid: grid, using: &generator) {
                solvable.append(ScoredCandidate(blocks: candidate, helpfulness: helpfulness(of: candidate, in: grid)))
            }
        }

        let finalBlocks: [BlockShape]
        if let picked = pick(from: solvable, pressure: pressure) {
            BuildConfiguration.logSolvability("Pressure \(String(format: "%.3f", pressure)): picked from \(solvable.count)/\(AppConfiguration.Gameplay.pressureCandidateCount) solvable candidates", level: .debug)
            finalBlocks = picked
        } else {
            BuildConfiguration.logSolvability("Pressure \(String(format: "%.3f", pressure)): no unconstrained candidate solvable, falling back", level: .info)
            let currentTier = GridAnalysis.determineDifficultyTier(for: grid)
            behaviorTracker?.recordFallbackActivation(from: currentTier, to: currentTier.degraded)
            finalBlocks = constrainedFallback(count: count, difficulty: difficulty, baseWeights: baseWeights, grid: grid, using: &generator)
        }

        let elapsedTime = CFAbsoluteTimeGetCurrent() - startTime
        BuildConfiguration.logSolvability("Generated \(finalBlocks.count) blocks (pressure \(String(format: "%.3f", pressure))) in \(String(format: "%.3f", elapsedTime))s", level: .debug)

        return finalBlocks
    }

    /// Picks a set from `solvable`, ranked least- to most-helpful, at the
    /// quantile `pressure` names — `1.0` (max pressure) takes the least
    /// helpful solvable set, `0.0` the most helpful, and values between
    /// interpolate. `nil` when nothing was solvable.
    private static func pick(from solvable: [ScoredCandidate], pressure: Double) -> [BlockShape]? {
        guard !solvable.isEmpty else { return nil }
        let ranked = solvable.sorted { $0.helpfulness < $1.helpfulness }
        let clampedPressure = max(0.0, min(1.0, pressure))
        let index = Int(((1.0 - clampedPressure) * Double(ranked.count - 1)).rounded())
        return ranked[index].blocks
    }

    /// Draws one candidate set: `count` blocks from the full weighted
    /// distribution (no size cap), with the same duplicate-prevention rules
    /// — and the same occasional special block — generation has always used.
    ///
    /// Built *constructively*: each normal block is drawn already restricted
    /// to shapes placeable on a scratch grid that reflects every block drawn
    /// earlier in this same candidate, and is then reserved there before the
    /// next draw. That guarantees the finished set is solvable — some
    /// assignment of positions exists, namely the one just constructed — so
    /// unlike the old tier-based generator, nothing here needs to fall back
    /// on `GameLogic.canAllBlocksBePlaced`'s backtracking search to find out
    /// after the fact. That search is still the fallback path's tool of
    /// last resort (`generateMinimumViableChallenge`), but it's no longer on
    /// the hot path: profiling an early version of this generator against
    /// the calibration simulator (`GameSimulationTests.swift`) showed
    /// sample-then-reject blowing well past a 600s test timeout on ordinary
    /// mid-game boards, because most of `pressureCandidateCount`'s
    /// unconstrained draws failed the joint check and each failure could
    /// burn through the full `placementBacktrackLimit`.
    ///
    /// Returns `nil` if some block couldn't be placed at all given what was
    /// drawn before it (the grid is tight enough that this particular
    /// sequence of draws didn't pan out) — the caller just tries another
    /// candidate. Special blocks never fail this way (any position is valid
    /// for them), and — unlike normal blocks — their effect on `scratch` is
    /// a clear, not a reservation: a drawn special is placed at a random
    /// position and its clear is credited, so later draws in the same
    /// candidate see the room it actually opens up (skipping that made a
    /// special dealt on a full or near-full grid effectively useless: every
    /// normal block dealt alongside it would find the board unchanged and
    /// construction would always abort — see
    /// `PressureBasedGenerationTests.specialBlockClearsRoomForLaterBlocksInTheSameBatch`).
    private static func generateCandidateSet(
        count: Int,
        difficulty: DifficultyMode,
        baseWeights: [BlockShape: Double],
        grid: [[GridCell]],
        using generator: inout any RandomNumberGenerator
    ) -> [BlockShape]? {
        var blocks: [BlockShape] = []
        var scratch = grid
        var usedShapeTypes: [String] = []
        var usedOrientations: [ShapeOrientation] = []
        var usedExactShapes: [String] = [] // Track exact shape signatures to prevent identical blocks
        var hasSpecialShape = false
        let specialChance = specialShapeProbability[difficulty] ?? 0.0

        for blockIndex in 0..<count {
            let shouldGenerateSpecial = Double.random(in: 0...1, using: &generator) < specialChance && !hasSpecialShape

            if shouldGenerateSpecial {
                // Pick uniformly from the three special-block templates. Each
                // `BlockShape.*ClearShape` access mints a fresh BlockShape
                // (with its own UUID id), so two draws of the same type
                // are still distinct instances.
                let specialBlock = Self.specialBlockPool.randomElement(using: &generator) ?? BlockShape.horizontalClearShape
                blocks.append(specialBlock)
                hasSpecialShape = true
                usedExactShapes.append(getShapeSignature(specialBlock))

                // Credit the clear on `scratch`, so later blocks in this
                // same candidate are drawn against the room this special
                // actually opens up. Without this, every later draw would
                // see the board as if the special had never been placed —
                // on a full or near-full grid specifically, that means no
                // normal block dealt alongside a special can ever find a
                // spot, and construction always aborts right when the
                // special was the one thing that could have made the rest
                // of the batch work. A random position stands in for "the
                // player placed this somewhere"; the exact position doesn't
                // otherwise affect this candidate's construction, since
                // `canPlaceBlockInline` accepts a special anywhere.
                let size = AppConfiguration.GameRules.gridSize
                let specialPosition = GridPosition(
                    row: Int.random(in: 0..<size, using: &generator),
                    col: Int.random(in: 0..<size, using: &generator)
                )
                GameLogic.placeBlock(specialBlock, at: specialPosition, in: &scratch)
            } else {
                let preventionConfig = DuplicatePreventionConfig.standard(
                    excludeExactShapes: usedExactShapes,
                    excludeShapeTypes: usedShapeTypes,
                    excludeOrientations: usedOrientations
                )
                // Restricted to `scratch`, so only shapes placeable given
                // everything drawn so far in this candidate are even
                // considered.
                let newBlock = generateBlockWithDuplicatePrevention(
                    baseWeights: baseWeights,
                    preventionConfig: preventionConfig,
                    grid: scratch,
                    attempt: blockIndex,
                    using: &generator
                )

                let validPositions = GameLogic.findValidPositions(for: newBlock, in: scratch)
                guard let position = validPositions.randomElement(using: &generator) else {
                    // Nothing left fits, even the single-cell terminal
                    // fallback inside generateBlockWithDuplicatePrevention —
                    // only possible when scratch has no empty cells at all.
                    return nil
                }
                GameLogic.placeBlock(newBlock, at: position, in: &scratch)

                blocks.append(newBlock)
                usedShapeTypes.append(getShapeType(newBlock))
                usedOrientations.append(getShapeOrientation(newBlock))
                usedExactShapes.append(getShapeSignature(newBlock))
            }
        }

        return blocks
    }

    /// How much a solvable candidate set actually helps the player right
    /// now: total placements across its blocks (mobility), a bonus if any
    /// block can complete a line immediately, and a penalty per ≤2-cell
    /// block — so a set of three singles scores near the bottom even though
    /// each individually "fits fine." Higher is more helpful.
    private static func helpfulness(of blocks: [BlockShape], in grid: [[GridCell]]) -> Double {
        var mobility = 0
        var canClearLine = false
        var smallBlockCount = 0

        for block in blocks {
            if block.positions.count <= 2 {
                smallBlockCount += 1
            }

            let positions = GameLogic.findValidPositions(for: block, in: grid)
            mobility += positions.count

            if !canClearLine {
                for position in positions {
                    let clears = GameLogic.linesThatWouldClear(placing: block, at: position, in: grid)
                    if !clears.rows.isEmpty || !clears.cols.isEmpty {
                        canClearLine = true
                        break
                    }
                }
            }
        }

        var score = Double(mobility)
        score -= Double(smallBlockCount) * AppConfiguration.Gameplay.helpfulnessSmallBlockPenalty
        if canClearLine {
            score += AppConfiguration.Gameplay.helpfulnessLineClearBonus
        }
        return score
    }

    /// Runs when no unconstrained candidate was solvable. Tries harder,
    /// constrained sampling first — at most one ≤2-cell block per set,
    /// unless the board is tight enough (`fallbackTightBoardThreshold`) that
    /// small blocks are often the only shapes that fit at all — and picks
    /// the least helpful of whatever comes back solvable, by enumeration
    /// rather than at random. Only when that also fails does it drop to the
    /// guaranteed-correct terminal fallback.
    private static func constrainedFallback(
        count: Int,
        difficulty: DifficultyMode,
        baseWeights: [BlockShape: Double],
        grid: [[GridCell]],
        using generator: inout any RandomNumberGenerator
    ) -> [BlockShape] {
        let emptyCells = grid.flatMap { $0 }.filter { !$0.isFilled }.count
        let capSmallBlocks = emptyCells > AppConfiguration.Gameplay.fallbackTightBoardThreshold

        var solvable: [ScoredCandidate] = []
        for _ in 0..<AppConfiguration.Gameplay.pressureFallbackCandidateCount {
            guard let candidate = generateCandidateSet(count: count, difficulty: difficulty, baseWeights: baseWeights, grid: grid, using: &generator) else {
                continue
            }
            if capSmallBlocks && candidate.filter({ $0.positions.count <= 2 }).count > 1 {
                continue
            }
            solvable.append(ScoredCandidate(blocks: candidate, helpfulness: helpfulness(of: candidate, in: grid)))
        }

        if let leastHelpful = solvable.min(by: { $0.helpfulness < $1.helpfulness }) {
            BuildConfiguration.logSolvability("Constrained fallback: picked least helpful of \(solvable.count)/\(AppConfiguration.Gameplay.pressureFallbackCandidateCount) solvable candidates", level: .info)
            return leastHelpful.blocks
        }

        BuildConfiguration.logSolvability("Constrained fallback exhausted, using minimum viable challenge", level: .warning)
        return generateMinimumViableChallenge(count: count, grid: grid, using: &generator)
    }

    /// Generates minimum viable challenge - avoids pure single blocks when possible
    private static func generateMinimumViableChallenge(count: Int, grid: [[GridCell]], using generator: inout any RandomNumberGenerator) -> [BlockShape] {
        var challengeBlocks: [BlockShape] = []
        let baseWeights = getBlockWeights(for: .easy)

        // Candidate small blocks that fit *individually* in the current grid.
        // Sorted for the same reason as `selectWeightedBlock` — see its doc
        // comment.
        let smallBlocks = baseWeights.keys
            .filter { block in
                block.positions.count <= 3 && GameLogic.canPlaceAnywhere(block, in: grid)
            }
            .sorted { getShapeSignature($0) < getShapeSignature($1) }

        for _ in 0..<count {
            if let selectedBlock = smallBlocks.randomElement(using: &generator) {
                let randomColor = BlockColor.allCases.randomElement(using: &generator) ?? .blue
                challengeBlocks.append(BlockShape(positions: selectedBlock.positions, color: randomColor))
            } else {
                // Only use single blocks as last resort
                challengeBlocks.append(createSingleBlock(using: &generator))
            }
        }

        // The picks above check each block's individual placement, not the set
        // as a whole. On tight grids (e.g. one row of empty cells with three
        // 3-cell blocks selected: 9 cells > 8 available), each block fits alone
        // but the set does not. Verify and degrade to single-cell blocks if so:
        // 1-cell blocks always fit individually as long as any cell is empty,
        // and they never collectively oversubscribe the empty count any worse
        // than the originals would have. This is the terminal fallback — past
        // here the only correct outcome is "no moves" / game over.
        if !GameLogic.canAllBlocksBePlaced(challengeBlocks, in: grid) {
            BuildConfiguration.logSolvability("Minimum viable challenge unsolvable as a set, degrading to single-cell blocks", level: .warning)
            return createSingleBlocks(count: count, using: &generator)
        }

        return challengeBlocks
    }
}

// MARK: - Block Generator

struct BlockGenerator {

    // MARK: - Configuration Constants

    /// Special shape generation probabilities by difficulty. Flat per-mode
    /// rates rather than per-tier ones — since generation no longer caps by
    /// tier, there's only one rate to pick per difficulty.
    private static let specialShapeProbability: [DifficultyMode: Double] = [
        .easy: 0.10,
        .moderate: 0.05,
        .hard: 0.02
    ]

    // MARK: - Special Block Pool

    /// The three special-block templates the generator draws from. Computed
    /// each access via `BlockShape.*ClearShape`'s `static var`, so a draw
    /// returns a freshly-minted shape with its own UUID — duplicate-type
    /// special blocks across draws are still distinct instances.
    ///
    /// Previously a private `SpecialBlockType` enum wrapped these three
    /// values with a `.blockShape` computed property; the enum was pure
    /// indirection once `BlockShape.*ClearShape` became static-var
    /// templates (H7), so it collapses to a `[BlockShape]` literal.
    private static var specialBlockPool: [BlockShape] {
        [
            BlockShape.horizontalClearShape,
            BlockShape.verticalClearShape,
            BlockShape.areaClearShape
        ]
    }

    // MARK: - Core Data Structures

    /// Shape orientation categories for variety tracking
    enum ShapeOrientation: CaseIterable {
        case horizontal, vertical, square, lShape, tShape, irregular
    }

    /// Configuration for duplicate prevention behavior. Used to be two
    /// flavors — `.standard` (used everywhere) and `.tiered` (added a size
    /// cap and a complexity bias from `TierConfiguration`) — but nothing
    /// caps by tier anymore, so `.tiered` and the fields it alone needed
    /// (`maxBlockSize`, `complexityPreference`) collapsed away with it.
    private struct DuplicatePreventionConfig {
        let excludeExactShapes: [String]
        let excludeShapeTypes: [String]
        let excludeOrientations: [ShapeOrientation]

        static func standard(
            excludeExactShapes: [String] = [],
            excludeShapeTypes: [String] = [],
            excludeOrientations: [ShapeOrientation] = []
        ) -> DuplicatePreventionConfig {
            return DuplicatePreventionConfig(
                excludeExactShapes: excludeExactShapes,
                excludeShapeTypes: excludeShapeTypes,
                excludeOrientations: excludeOrientations
            )
        }
    }

    /// Weight multiplier applied to a shape type/orientation that hasn't
    /// appeared yet in the set being built, so a batch tends toward variety
    /// rather than three of the same shape family.
    private static let varietyBonus = 1.5

    // MARK: - Block Analysis Helpers

    private static func getShapeType(_ block: BlockShape) -> String {
        // Handle special shapes
        switch block.type {
        case .horizontalClear:
            return "horizontal_clear"
        case .verticalClear:
            return "vertical_clear"
        case .areaClear:
            return "area_clear"
        case .normal:
            let cellCount = block.positions.count

            switch cellCount {
            case 1: return "single"
            case 2: return "double"
            case 3: return "triple"
            case 4: return "quad"
            case 5: return "penta"
            case 6: return "hexa"
            case 7: return "hepta"
            case 9: return "nona"
            default: return "other"
            }
        }
    }

    private static func getShapeOrientation(_ block: BlockShape) -> ShapeOrientation {
        let bounds = block.getBounds()

        let width = bounds.width
        let height = bounds.height

        if width == height {
            return .square
        } else if width > height {
            return .horizontal
        } else {
            return .vertical
        }
    }

    /// Creates a unique signature for a block shape to prevent exact duplicates
    private static func getShapeSignature(_ block: BlockShape) -> String {
        let normalizedPositions = block.positions
            .sorted { ($0.row, $0.col) < ($1.row, $1.col) }
            .map { "\($0.row),\($0.col)" }
            .joined(separator: "|")
        return "\(normalizedPositions)_\(String(describing: block.color))"
    }

    // MARK: - Core Block Generation Engine

    /// Unified block generation with duplicate prevention
    /// This is the core engine that handles all block generation logic
    private static func generateBlockWithDuplicatePrevention(
        baseWeights: [BlockShape: Double],
        preventionConfig: DuplicatePreventionConfig,
        grid: [[GridCell]] = [[GridCell]](),
        attempt: Int = 0,
        using generator: inout any RandomNumberGenerator
    ) -> BlockShape {
        // Create efficient lookup sets and counting dictionaries for O(1) performance
        let excludeExactSet = Set(preventionConfig.excludeExactShapes)

        // Create counting dictionaries for efficient duplicate detection
        let typeCounts = Dictionary(preventionConfig.excludeShapeTypes.map { ($0, 1) }, uniquingKeysWith: +)
        let orientationCounts = Dictionary(preventionConfig.excludeOrientations.map { ($0, 1) }, uniquingKeysWith: +)

        var filteredWeights: [BlockShape: Double] = [:]

        for (block, originalWeight) in baseWeights {
            let signature = getShapeSignature(block)

            // Completely exclude exact duplicates
            if excludeExactSet.contains(signature) {
                continue
            }

            // Completely exclude shapes that can't be placed anywhere on
            // `grid` at all. This is what makes candidate construction in
            // generateCandidateSet cheap: without it, a 9-cell square drawn
            // against a half-full grid would always have to be discovered
            // unplaceable the expensive way, one full `canAllBlocksBePlaced`
            // backtracking search at a time.
            guard GameLogic.canPlaceAnywhere(block, in: grid) else {
                continue
            }

            let shapeType = getShapeType(block)
            let orientation = getShapeOrientation(block)

            // Count duplicates efficiently using pre-computed dictionaries
            let typeCount = typeCounts[shapeType] ?? 0
            let orientationCount = orientationCounts[orientation] ?? 0

            // Apply duplicate prevention rules
            var adjustedWeight = originalWeight

            // Stronger duplicate prevention - completely exclude if we have 2+ of same type
            if typeCount >= 2 || orientationCount >= 2 {
                continue // Don't allow 3rd of same type/orientation
            } else if typeCount >= 1 || orientationCount >= 1 {
                // Reduce probability for 2nd of same type, but allow it
                adjustedWeight *= 0.15
            } else {
                // Boost new varieties
                adjustedWeight *= varietyBonus
            }

            filteredWeights[block] = max(0.1, adjustedWeight)
        }

        // Handle empty filter results
        if filteredWeights.isEmpty {
            BuildConfiguration.logSolvability("All blocks excluded by duplicate prevention (attempt \(attempt)), using fallback", level: .info)
            return generateFallbackBlock(baseWeights: baseWeights, grid: grid, excludeExactShapes: preventionConfig.excludeExactShapes, using: &generator)
        }

        // Select block using weighted random
        return selectWeightedBlock(from: filteredWeights, using: &generator)
    }

    /// Generates a fallback block when duplicate prevention is too restrictive
    private static func generateFallbackBlock(
        baseWeights: [BlockShape: Double],
        grid: [[GridCell]],
        excludeExactShapes: [String],
        using generator: inout any RandomNumberGenerator
    ) -> BlockShape {
        let excludeSet = Set(excludeExactShapes)

        // Try to find any block that's not an exact duplicate and can be
        // placed. Sorted for the same reason as `selectWeightedBlock` — see
        // its doc comment.
        let availableBlocks = baseWeights.keys
            .filter { block in
                let shapeSignature = getShapeSignature(block)
                return !excludeSet.contains(shapeSignature) &&
                       GameLogic.canPlaceAnywhere(block, in: grid)
            }
            .sorted { getShapeSignature($0) < getShapeSignature($1) }

        if let selectedBlock = availableBlocks.randomElement(using: &generator) {
            let randomColor = BlockColor.allCases.randomElement(using: &generator) ?? .blue
            return BlockShape(positions: selectedBlock.positions, color: randomColor)
        }

        // Ultimate fallback: single block with different color
        return createSingleBlock(using: &generator)
    }

    /// Selects a block using weighted random selection.
    ///
    /// Walks the entries sorted by shape signature rather than in dictionary
    /// order: `Dictionary` randomizes its iteration order per process launch
    /// (hash-flooding protection), so which entry a given `randomValue`
    /// threshold lands on would otherwise change from run to run even with
    /// the exact same `generator` seed and the exact same weights — silently
    /// defeating the reproducibility `GameSimulator` relies on.
    private static func selectWeightedBlock(from weights: [BlockShape: Double], using generator: inout any RandomNumberGenerator) -> BlockShape {
        let totalWeight = weights.values.reduce(0, +)
        let randomValue = Double.random(in: 0...totalWeight, using: &generator)
        let sortedEntries = weights.sorted { getShapeSignature($0.key) < getShapeSignature($1.key) }

        var currentWeight: Double = 0
        for (block, weight) in sortedEntries {
            currentWeight += weight
            if randomValue <= currentWeight {
                let randomColor = BlockColor.allCases.randomElement(using: &generator) ?? .blue
                return BlockShape(positions: block.positions, color: randomColor)
            }
        }

        // Fallback
        return createSingleBlock(using: &generator)
    }

    // MARK: - Block Weight System

    private static func getBlockWeights(for difficulty: DifficultyMode) -> [BlockShape: Double] {
        var weights: [BlockShape: Double] = [:]

        // Ensure we have weights for all shapes (now 22 total)
        for (index, shape) in BlockShape.allShapes.enumerated() {
            let cellCount = shape.positions.count

            switch difficulty {
            case .easy:
                weights[shape] = getEasyWeight(for: cellCount, index: index)
            case .moderate:
                weights[shape] = getModerateWeight(for: cellCount, index: index)
            case .hard:
                weights[shape] = getHardWeight(for: cellCount, index: index)
            }
        }

        return weights
    }

    private static func getEasyWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 1.5  // Single blocks less common
        case 2: return 2.0  // 2-block shapes moderate
        case 3: return 2.5  // 3-block shapes common
        case 4: return 3.0  // 4-block shapes common
        case 5: return 2.5  // 5-block shapes (new lines & L-shapes) common
        case 6: return 2.0  // 6-block rectangles moderate
        case 7: return 1.5  // 7-block L-shapes less common
        case 9: return 1.0  // 9-block square less common
        default: return 1.5
        }
    }

    private static func getModerateWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 1.0  // Single blocks rare
        case 2: return 1.5  // 2-block shapes less common
        case 3: return 2.0  // 3-block shapes moderate
        case 4: return 3.0  // 4-block shapes common
        case 5: return 3.5  // 5-block shapes very common
        case 6: return 3.0  // 6-block rectangles common
        case 7: return 2.5  // 7-block L-shapes common
        case 9: return 2.0  // 9-block square common
        default: return 2.5
        }
    }

    private static func getHardWeight(for cellCount: Int, index: Int) -> Double {
        switch cellCount {
        case 1: return 0.5  // Single blocks very rare
        case 2: return 0.8  // 2-block shapes very rare
        case 3: return 1.5  // 3-block shapes rare
        case 4: return 2.5  // 4-block shapes moderate
        case 5: return 4.0  // 5-block shapes extremely common
        case 6: return 3.5  // 6-block rectangles very common
        case 7: return 3.0  // 7-block L-shapes very common
        case 9: return 2.5  // 9-block square common
        default: return 3.0
        }
    }

    // MARK: - Public API

    /// Main entry point for block generation - uses pressure-based candidate
    /// selection to balance challenge with solvability.
    ///
    /// Draws from the system's random source. Use
    /// `generateWeightedBlocks(count:difficulty:grid:using:)` to inject a
    /// seeded generator instead.
    static func generateWeightedBlocks(count: Int = 3, difficulty: DifficultyMode = .easy, grid: [[GridCell]]) -> [BlockShape] {
        var generator: any RandomNumberGenerator = SystemRandomNumberGenerator()
        return generateWeightedBlocks(count: count, difficulty: difficulty, grid: grid, using: &generator)
    }

    /// Same as `generateWeightedBlocks(count:difficulty:grid:)`, but draws
    /// from `generator` instead of the system's random source.
    static func generateWeightedBlocks(count: Int = 3, difficulty: DifficultyMode = .easy, grid: [[GridCell]], using generator: inout any RandomNumberGenerator) -> [BlockShape] {
        return generateTieredBlocks(count: count, difficulty: difficulty, grid: grid, using: &generator)
    }

}
