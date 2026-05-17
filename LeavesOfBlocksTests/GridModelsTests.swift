//
//  GridModelsTests.swift
//  LeavesOfBlocksTests
//
//  Tests for GridPosition, GridCell, and ClearedCell value types.
//

import Foundation
import Testing
@testable import LeavesOfBlocks

// MARK: - GridPosition

@Suite("GridPosition")
struct GridPositionTests {
    @Test("Init stores row and column verbatim")
    func initStoresRowAndColumn() {
        let position = GridPosition(row: 3, col: 5)
        #expect(position.row == 3)
        #expect(position.col == 5)
    }

    @Test("Equality compares row and column")
    func equalityComparesRowAndColumn() {
        let a = GridPosition(row: 2, col: 4)
        let b = GridPosition(row: 2, col: 4)
        let c = GridPosition(row: 2, col: 5)

        #expect(a == b)
        #expect(a != c)
    }

    @Test("Hashable: equal positions collapse in a Set")
    func hashableEqualPositionsCollapseInSet() {
        var set = Set<GridPosition>()
        set.insert(GridPosition(row: 1, col: 1))
        set.insert(GridPosition(row: 1, col: 1))

        #expect(set.count == 1)
    }

    @Test("Codable round-trip preserves row and column")
    func codableRoundTripPreservesRowAndColumn() throws {
        let original = GridPosition(row: 4, col: 7)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(GridPosition.self, from: data)

        #expect(decoded == original)
    }

    @Test("Negative indices are permitted by the type")
    func negativeIndicesArePermittedByTheType() {
        let position = GridPosition(row: -1, col: -2)
        #expect(position.row == -1)
        #expect(position.col == -2)
    }
}

// MARK: - GridCell

@Suite("GridCell")
struct GridCellTests {
    @Test("Default cell is empty and blue")
    func defaultCellIsEmptyAndBlue() {
        let cell = GridCell()
        #expect(cell.isFilled == false)
        #expect(cell.color == .blue)
    }

    @Test("Explicit init sets fill state and color")
    func explicitInitSetsFillStateAndColor() {
        let cell = GridCell(isFilled: true, color: .red)
        #expect(cell.isFilled == true)
        #expect(cell.color == .red)
    }

    @Test("Properties are mutable")
    func propertiesAreMutable() {
        var cell = GridCell()
        cell.isFilled = true
        cell.color = .green

        #expect(cell.isFilled == true)
        #expect(cell.color == .green)
    }
}

// MARK: - ClearedCell

@Suite("ClearedCell")
struct ClearedCellTests {
    @Test("Init stores row, column, and color")
    func initStoresRowColumnAndColor() {
        let cell = ClearedCell(row: 2, col: 3, color: .orange)
        #expect(cell.row == 2)
        #expect(cell.col == 3)
        #expect(cell.color == .orange)
    }

    @Test("Equality compares row, column, and color")
    func equalityComparesAllFields() {
        let a = ClearedCell(row: 1, col: 2, color: .purple)
        let b = ClearedCell(row: 1, col: 2, color: .purple)
        let c = ClearedCell(row: 1, col: 2, color: .pink)

        #expect(a == b)
        #expect(a != c)
    }

    @Test("Codable round-trip preserves all fields")
    func codableRoundTripPreservesAllFields() throws {
        let original = ClearedCell(row: 5, col: 6, color: .yellow)

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ClearedCell.self, from: data)

        #expect(decoded == original)
    }
}
