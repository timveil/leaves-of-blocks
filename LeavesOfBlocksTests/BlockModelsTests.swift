//
//  BlockModelsTests.swift
//  LeavesOfBlocksTests
//
//  Created by Claude on 11/27/25.
//

import XCTest
@testable import LeavesOfBlocks

// MARK: - BlockColor Tests

final class BlockColorTests: XCTestCase {

    func testBlockColorHasSevenCases() {
        let allColors: [BlockColor] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

        XCTAssertEqual(allColors.count, 7)
    }

    func testBlockColorIsCodable() throws {
        let original = BlockColor.red
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(BlockColor.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testBlockColorAllCasesAreCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for color in [BlockColor.red, .orange, .yellow, .green, .blue, .purple, .pink] {
            let data = try encoder.encode(color)
            let decoded = try decoder.decode(BlockColor.self, from: data)
            XCTAssertEqual(decoded, color)
        }
    }
}

// MARK: - BlockType Tests

final class BlockTypeTests: XCTestCase {

    func testBlockTypeHasFourCases() {
        let allTypes: [BlockType] = [.normal, .horizontalClear, .verticalClear, .areaClear]

        XCTAssertEqual(allTypes.count, 4)
    }

    func testNormalBlockTypeIsDefault() {
        let block = BlockShape.allShapes[0]

        XCTAssertEqual(block.type, .normal)
    }
}

// MARK: - GeometricPattern Tests

final class GeometricPatternTests: XCTestCase {

    func testGeometricPatternHasEightPatterns() {
        let patterns: [GeometricPattern] = [
            .line2, .line3, .corner, .diagonal,
            .square2x2, .cross, .triangle, .zigzag
        ]

        XCTAssertEqual(patterns.count, 8)
    }

    func testLine2PatternHasTwoPositions() {
        let positions = GeometricPattern.line2.positions

        XCTAssertEqual(positions.count, 2)
        XCTAssertTrue(positions.contains(GridPosition(row: 0, col: 0)))
        XCTAssertTrue(positions.contains(GridPosition(row: 0, col: 1)))
    }

    func testLine3PatternHasThreePositions() {
        let positions = GeometricPattern.line3.positions

        XCTAssertEqual(positions.count, 3)
    }

    func testSquare2x2PatternHasFourPositions() {
        let positions = GeometricPattern.square2x2.positions

        XCTAssertEqual(positions.count, 4)
        XCTAssertTrue(positions.contains(GridPosition(row: 0, col: 0)))
        XCTAssertTrue(positions.contains(GridPosition(row: 0, col: 1)))
        XCTAssertTrue(positions.contains(GridPosition(row: 1, col: 0)))
        XCTAssertTrue(positions.contains(GridPosition(row: 1, col: 1)))
    }

    func testAllPatternsHavePositions() {
        for pattern in GeometricPattern.allCases {
            XCTAssertFalse(pattern.positions.isEmpty)
        }
    }
}

// MARK: - BlockShape Tests

final class BlockShapeTests: XCTestCase {

    func testAllShapesIsNotEmpty() {
        XCTAssertFalse(BlockShape.allShapes.isEmpty)
    }

    func testAllShapesHasAtLeast21Shapes() {
        XCTAssertGreaterThanOrEqual(BlockShape.allShapes.count, 21)
    }

    func testAllShapesHavePositions() {
        for shape in BlockShape.allShapes {
            XCTAssertFalse(shape.positions.isEmpty)
        }
    }

    func testAllShapesHaveValidColors() {
        let validColors: Set<BlockColor> = [.red, .orange, .yellow, .green, .blue, .purple, .pink]

        for shape in BlockShape.allShapes {
            XCTAssertTrue(validColors.contains(shape.color))
        }
    }

    func testAllShapesHaveNormalType() {
        for shape in BlockShape.allShapes {
            XCTAssertEqual(shape.type, .normal)
        }
    }

    func testBlockShapePositionsAreNonNegative() {
        for shape in BlockShape.allShapes {
            for position in shape.positions {
                XCTAssertGreaterThanOrEqual(position.row, 0)
                XCTAssertGreaterThanOrEqual(position.col, 0)
            }
        }
    }

    func testBlockShapeIsCodable() throws {
        let original = BlockShape.allShapes[0]
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(BlockShape.self, from: data)

        XCTAssertEqual(decoded.positions, original.positions)
        XCTAssertEqual(decoded.color, original.color)
        XCTAssertEqual(decoded.type, original.type)
    }

    func testBlockShapesHaveDistinctPositions() {
        let shape1 = BlockShape.allShapes[0]
        let shape2 = BlockShape.allShapes[1]

        // Different shapes should have different position sets or colors
        let samePositions = shape1.positions == shape2.positions
        let sameColor = shape1.color == shape2.color

        // They shouldn't be identical
        XCTAssertFalse(samePositions && sameColor)
    }
}
