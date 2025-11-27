//
//  GridModelsTests.swift
//  LeavesOfBlocksTests
//
//  Created by Claude on 11/27/25.
//

import XCTest
@testable import LeavesOfBlocks

// MARK: - GridPosition Tests

final class GridPositionTests: XCTestCase {

    func testGridPositionInitialization() {
        let position = GridPosition(row: 3, col: 5)

        XCTAssertEqual(position.row, 3)
        XCTAssertEqual(position.col, 5)
    }

    func testGridPositionEquality() {
        let position1 = GridPosition(row: 2, col: 4)
        let position2 = GridPosition(row: 2, col: 4)
        let position3 = GridPosition(row: 2, col: 5)

        XCTAssertEqual(position1, position2)
        XCTAssertNotEqual(position1, position3)
    }

    func testGridPositionHashable() {
        let position1 = GridPosition(row: 1, col: 1)
        let position2 = GridPosition(row: 1, col: 1)

        var set = Set<GridPosition>()
        set.insert(position1)
        set.insert(position2)

        XCTAssertEqual(set.count, 1)
    }

    func testGridPositionCodable() throws {
        let original = GridPosition(row: 4, col: 7)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(GridPosition.self, from: data)

        XCTAssertEqual(decoded, original)
    }

    func testGridPositionCanBeNegative() {
        let position = GridPosition(row: -1, col: -2)

        XCTAssertEqual(position.row, -1)
        XCTAssertEqual(position.col, -2)
    }
}

// MARK: - GridCell Tests

final class GridCellTests: XCTestCase {

    func testGridCellDefaultValues() {
        let cell = GridCell()

        XCTAssertFalse(cell.isFilled)
        XCTAssertEqual(cell.color, .blue)
    }

    func testGridCellCustomInitialization() {
        let cell = GridCell(isFilled: true, color: .red)

        XCTAssertTrue(cell.isFilled)
        XCTAssertEqual(cell.color, .red)
    }

    func testGridCellMutation() {
        var cell = GridCell()

        cell.isFilled = true
        cell.color = .green

        XCTAssertTrue(cell.isFilled)
        XCTAssertEqual(cell.color, .green)
    }
}

// MARK: - ClearedCell Tests

final class ClearedCellTests: XCTestCase {

    func testClearedCellInitialization() {
        let cell = ClearedCell(row: 2, col: 3, color: .orange)

        XCTAssertEqual(cell.row, 2)
        XCTAssertEqual(cell.col, 3)
        XCTAssertEqual(cell.color, .orange)
    }

    func testClearedCellEquality() {
        let cell1 = ClearedCell(row: 1, col: 2, color: .purple)
        let cell2 = ClearedCell(row: 1, col: 2, color: .purple)
        let cell3 = ClearedCell(row: 1, col: 2, color: .pink)

        XCTAssertEqual(cell1, cell2)
        XCTAssertNotEqual(cell1, cell3)
    }

    func testClearedCellCodable() throws {
        let original = ClearedCell(row: 5, col: 6, color: .yellow)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ClearedCell.self, from: data)

        XCTAssertEqual(decoded, original)
    }
}
