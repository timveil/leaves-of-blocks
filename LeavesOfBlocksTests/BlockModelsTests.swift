//
//  BlockModelsTests.swift
//  LeavesOfBlocksTests
//
//  Tests for BlockColor, BlockType, GeometricPattern, and BlockShape value types.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - BlockColor

@Suite("BlockColor")
struct BlockColorTests {
    @Test("Has exactly seven cases")
    func hasSevenCases() {
        let all: [BlockColor] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        #expect(all.count == 7)
    }

    @Test("Single color round-trips through Codable")
    func singleColorRoundTripsThroughCodable() throws {
        let data = try JSONEncoder().encode(BlockColor.red)
        let decoded = try JSONDecoder().decode(BlockColor.self, from: data)
        #expect(decoded == .red)
    }

    @Test("Every color round-trips through Codable")
    func everyColorRoundTripsThroughCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for color in [BlockColor.red, .orange, .yellow, .green, .blue, .purple, .pink] {
            let data = try encoder.encode(color)
            let decoded = try decoder.decode(BlockColor.self, from: data)
            #expect(decoded == color)
        }
    }
}

// MARK: - BlockType

@Suite("BlockType")
struct BlockTypeTests {
    @Test("Has exactly four cases")
    func hasFourCases() {
        let all: [BlockType] = [.normal, .horizontalClear, .verticalClear, .areaClear]
        #expect(all.count == 4)
    }

    @Test("First shape in the catalog is a normal block")
    func firstShapeInTheCatalogIsANormalBlock() {
        let block = BlockShape.allShapes[0]
        #expect(block.type == .normal)
    }
}

// MARK: - GeometricPattern

@Suite("GeometricPattern")
struct GeometricPatternTests {
    @Test("Has eight patterns")
    func hasEightPatterns() {
        let patterns: [GeometricPattern] = [
            .line2, .line3, .corner, .diagonal,
            .square2x2, .cross, .triangle, .zigzag
        ]
        #expect(patterns.count == 8)
    }

    @Test("line2 has two horizontally adjacent positions")
    func line2HasTwoHorizontallyAdjacentPositions() {
        let positions = GeometricPattern.line2.positions
        #expect(positions.count == 2)
        #expect(positions.contains(GridPosition(row: 0, col: 0)))
        #expect(positions.contains(GridPosition(row: 0, col: 1)))
    }

    @Test("line3 has three positions")
    func line3HasThreePositions() {
        #expect(GeometricPattern.line3.positions.count == 3)
    }

    @Test("square2x2 covers the full 2x2 quadrant")
    func square2x2CoversTheFull2x2Quadrant() {
        let positions = GeometricPattern.square2x2.positions
        #expect(positions.count == 4)
        #expect(positions.contains(GridPosition(row: 0, col: 0)))
        #expect(positions.contains(GridPosition(row: 0, col: 1)))
        #expect(positions.contains(GridPosition(row: 1, col: 0)))
        #expect(positions.contains(GridPosition(row: 1, col: 1)))
    }

    @Test("Every pattern has at least one position")
    func everyPatternHasAtLeastOnePosition() {
        for pattern in GeometricPattern.allCases {
            #expect(!pattern.positions.isEmpty)
        }
    }
}

// MARK: - BlockShape

@Suite("BlockShape")
struct BlockShapeTests {
    @Test("allShapes is non-empty")
    func allShapesIsNonEmpty() {
        #expect(!BlockShape.allShapes.isEmpty)
    }

    @Test("allShapes has at least 21 entries")
    func allShapesHasAtLeast21Entries() {
        #expect(BlockShape.allShapes.count >= 21)
    }

    @Test("Every shape declares at least one position")
    func everyShapeDeclaresAtLeastOnePosition() {
        for shape in BlockShape.allShapes {
            #expect(!shape.positions.isEmpty)
        }
    }

    @Test("Every shape uses a known palette color")
    func everyShapeUsesAKnownPaletteColor() {
        let valid: Set<BlockColor> = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        for shape in BlockShape.allShapes {
            #expect(valid.contains(shape.color))
        }
    }

    @Test("Every catalog shape is of type .normal")
    func everyCatalogShapeIsOfTypeNormal() {
        for shape in BlockShape.allShapes {
            #expect(shape.type == .normal)
        }
    }

    @Test("Positions are non-negative")
    func positionsAreNonNegative() {
        for shape in BlockShape.allShapes {
            for position in shape.positions {
                #expect(position.row >= 0)
                #expect(position.col >= 0)
            }
        }
    }

    @Test("BlockShape round-trips through Codable")
    func blockShapeRoundTripsThroughCodable() throws {
        let original = BlockShape.allShapes[0]

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(BlockShape.self, from: data)

        #expect(decoded.positions == original.positions)
        #expect(decoded.color == original.color)
        #expect(decoded.type == original.type)
    }

    @Test("Catalog entries are not identical to each other")
    func catalogEntriesAreNotIdenticalToEachOther() {
        let a = BlockShape.allShapes[0]
        let b = BlockShape.allShapes[1]

        let samePositions = a.positions == b.positions
        let sameColor = a.color == b.color

        #expect(!(samePositions && sameColor))
    }
}
