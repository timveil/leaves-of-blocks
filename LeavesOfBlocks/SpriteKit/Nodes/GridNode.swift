import SpriteKit

// MARK: - Grid Node

/// Renders the 8x8 game grid as a SpriteKit node tree with folk-art black gridlines.
///
/// `GridNode` draws bold black gridlines as a path-based shape and places cell nodes
/// in the gaps between lines. Empty cells use a solid white fill.
///
/// ## Coordinate System
///
/// SpriteKit natively uses a bottom-left origin with Y increasing upward.
/// `contentNode` is flipped (`yScale = -1`) and translated so the public
/// surface behaves like top-down: row 0 is at the top, row index grows
/// downward, matching the SwiftUI grid model that drives this layer.
///
/// Effects and cells share this **content-local** coordinate system,
/// rooted at `contentNode`, where (0, 0) is the top-left of the first cell
/// (the outer border is handled separately by `contentNode.position`):
///
/// ```
/// x = col * (cellSize + spacing)
/// y = row * (cellSize + spacing)
/// ```
///
/// **Always parent effect nodes to `contentNode`** (not to `GridNode`
/// itself) so they inherit the flip. Effects that compute their own
/// positions must use `cellPosition(row:col:)` or
/// `SpriteKitEffects.cellPoint(row:col:cellSize:spacing:)` — both return
/// content-local coordinates that respect the flip. The one deliberate
/// exception is `ComboBannerEffect`, which attaches text to `GridNode`
/// directly so the label isn't rendered upside-down by the flip.
class GridNode: SKNode {

    // MARK: - Node Name Constants

    static func cellName(row: Int, col: Int) -> String {
        "cell_\(row)_\(col)"
    }

    static let gameOverOverlayName = "gameOverOverlay"

    // MARK: - Properties

    let cellSize: CGFloat
    let spacing: CGFloat
    let gridSize: Int

    private var cellNodes: [[SKShapeNode]] = []

    /// Content container offset by borderWidth — cells and effects share this coordinate space.
    let contentNode: SKNode

    /// Holds line-clear preview overlay tiles during drag. Cleared on every grid sync.
    private let previewOverlayNode = SKNode()

    /// Holds the pulsing hint overlay. Sibling of `previewOverlayNode`, sits
    /// one level above so a hint always wins over a stray drag preview.
    private let hintOverlayNode = SKNode()

    /// Action key used to schedule the hint auto-clear. Stored so a manual
    /// `clearHint()` can cancel the pending fade.
    private static let hintAutoclearActionKey = "hintAutoclear"

    private let borderWidth = GameTheme.Layout.gridBorderWidth

    /// Content dimension (cells + internal spacing, no border)
    var gridWidth: CGFloat {
        CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * spacing
    }

    var gridHeight: CGFloat {
        gridWidth
    }

    /// Total size including border on all sides
    var totalSize: CGFloat {
        gridWidth + borderWidth * 2
    }

    // MARK: - Initialization

    init(cellSize: CGFloat = 40, spacing: CGFloat = 3, gridSize: Int = 8) {
        self.cellSize = cellSize
        self.spacing = spacing
        self.gridSize = gridSize

        let bw = GameTheme.Layout.gridBorderWidth
        let contentDim = CGFloat(gridSize) * cellSize + CGFloat(gridSize - 1) * spacing
        let total = contentDim + bw * 2

        // Solid black background — cells sit on top, gaps between them form the gridlines
        let bgRect = CGRect(x: 0, y: 0, width: total, height: total)
        let gridBackgroundNode = SKShapeNode(rect: bgRect)
        gridBackgroundNode.fillColor = SpriteKitColors.gridLineColor
        gridBackgroundNode.strokeColor = .clear
        gridBackgroundNode.lineWidth = 0
        gridBackgroundNode.zPosition = 0

        // Content node offset by border — cells and effects live here
        // yScale flipped so row 0 renders at the top (SpriteKit Y is bottom-up)
        contentNode = SKNode()
        contentNode.yScale = -1
        contentNode.position = CGPoint(x: bw, y: bw + contentDim)

        super.init()

        addChild(gridBackgroundNode)
        addChild(contentNode)
        previewOverlayNode.zPosition = 2
        contentNode.addChild(previewOverlayNode)
        hintOverlayNode.zPosition = 3
        contentNode.addChild(hintOverlayNode)
        buildGrid()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Grid Construction

    private func buildGrid() {
        for row in 0..<gridSize {
            var rowNodes: [SKShapeNode] = []
            for col in 0..<gridSize {
                let cellNode = createCellNode()
                cellNode.position = cellPosition(row: row, col: col)
                cellNode.name = GridNode.cellName(row: row, col: col)
                contentNode.addChild(cellNode)
                rowNodes.append(cellNode)
            }
            cellNodes.append(rowNodes)
        }
    }

    private func createCellNode() -> SKShapeNode {
        let rect = CGRect(x: 0, y: 0, width: cellSize, height: cellSize)
        let node = SKShapeNode(rect: rect)
        node.fillColor = SpriteKitColors.gridCellEmpty
        node.strokeColor = .clear
        node.lineWidth = 0
        node.zPosition = 1
        return node
    }

    /// Returns the cell position in content-local coordinates (no border offset).
    ///
    /// Callers are expected to pass row/col within `0..<gridSize` — out-of-bounds
    /// indices yield a CGPoint that's silently off-screen, which is almost
    /// always a bug. A DEBUG precondition fails fast; release builds keep the
    /// permissive arithmetic so a regression doesn't crash the app.
    func cellPosition(row: Int, col: Int) -> CGPoint {
        assert(
            (0..<gridSize).contains(row) && (0..<gridSize).contains(col),
            "cellPosition out of bounds: row=\(row), col=\(col), gridSize=\(gridSize)"
        )
        let x = CGFloat(col) * (cellSize + spacing)
        let y = CGFloat(row) * (cellSize + spacing)
        return CGPoint(x: x, y: y)
    }

    // MARK: - Grid Synchronization

    func syncGrid(_ grid: [[GridCell]]) {
        clearLineClearPreview()
        for row in 0..<min(gridSize, grid.count) {
            for col in 0..<min(gridSize, grid[row].count) {
                let cell = grid[row][col]
                let node = cellNodes[row][col]

                if cell.isFilled {
                    node.fillColor = SpriteKitColors.blockColor(for: cell.color)
                } else {
                    node.fillColor = SpriteKitColors.gridCellEmpty
                }
                node.strokeColor = .clear
                node.lineWidth = 0
            }
        }
    }

    // MARK: - Preview Highlighting

    func showPreview(block: BlockShape, at position: GridPosition, canPlace: Bool) {
        guard canPlace else { return }

        let previewColor = SpriteKitColors.blockColor(for: block.color).withAlphaComponent(0.6)

        switch block.type {
        case .horizontalClear:
            // Special block clears the whole row, including already-filled cells —
            // tint them all so the user sees the full impact zone.
            for col in 0..<gridSize {
                highlightCell(row: position.row, col: col, color: previewColor, overrideFilled: true)
            }
        case .verticalClear:
            for row in 0..<gridSize {
                highlightCell(row: row, col: position.col, color: previewColor, overrideFilled: true)
            }
        case .areaClear:
            for dRow in -1...1 {
                for dCol in -1...1 {
                    let r = position.row + dRow
                    let c = position.col + dCol
                    if r >= 0 && r < gridSize && c >= 0 && c < gridSize {
                        highlightCell(row: r, col: c, color: previewColor, overrideFilled: true)
                    }
                }
            }
        case .normal:
            // Normal blocks can't be placed over filled cells; preserve the
            // existing fill so the player still sees the obstruction.
            for blockPos in block.positions {
                let r = position.row + blockPos.row
                let c = position.col + blockPos.col
                if r >= 0 && r < gridSize && c >= 0 && c < gridSize {
                    highlightCell(row: r, col: c, color: previewColor, overrideFilled: false)
                }
            }
        }
    }

    private func highlightCell(row: Int, col: Int, color: UIColor, overrideFilled: Bool) {
        guard row >= 0 && row < gridSize && col >= 0 && col < gridSize else { return }
        let node = cellNodes[row][col]
        if overrideFilled || node.fillColor == SpriteKitColors.gridCellEmpty {
            node.fillColor = color
        }
    }

    /// Overlays a thick gold border + warm tint across every cell in any row
    /// or column that would clear if the in-flight drag were committed. A
    /// gentle pulse on the overlay container draws the eye toward the
    /// "good move" feedback without being noisy.
    func showLineClearPreview(rows: Set<Int>, cols: Set<Int>) {
        clearLineClearPreview()

        let strokeColor = SpriteKitColors.lineCompletionSecondary
        let fillColor = SpriteKitColors.lineCompletionPrimary.withAlphaComponent(0.35)
        var painted: Set<GridPosition> = []

        for row in rows {
            for col in 0..<gridSize {
                addPreviewOverlay(row: row, col: col, fill: fillColor, stroke: strokeColor)
                painted.insert(GridPosition(row: row, col: col))
            }
        }

        for col in cols {
            for row in 0..<gridSize {
                let pos = GridPosition(row: row, col: col)
                guard !painted.contains(pos) else { continue }
                addPreviewOverlay(row: row, col: col, fill: fillColor, stroke: strokeColor)
                painted.insert(pos)
            }
        }

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.7, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ]))
        previewOverlayNode.removeAllActions()
        previewOverlayNode.alpha = 1.0
        previewOverlayNode.run(pulse)
    }

    /// Removes any line-clear preview tint applied by `showLineClearPreview`.
    func clearLineClearPreview() {
        previewOverlayNode.removeAllActions()
        previewOverlayNode.alpha = 1.0
        previewOverlayNode.removeAllChildren()
    }

    private func addPreviewOverlay(row: Int, col: Int, fill: UIColor, stroke: UIColor) {
        let rect = CGRect(x: 0, y: 0, width: cellSize, height: cellSize)
        let overlay = SKShapeNode(rect: rect, cornerRadius: GameTheme.Layout.cellCornerRadius)
        overlay.fillColor = fill
        overlay.strokeColor = stroke
        overlay.lineWidth = 4
        overlay.position = cellPosition(row: row, col: col)
        previewOverlayNode.addChild(overlay)
    }

    // MARK: - Hint Overlay

    /// Pulses a soft tint on every supplied grid cell for ~2 seconds, then
    /// fades out automatically. Cancellable via `clearHint()` (e.g., when the
    /// player starts a drag during the hint window). Mirrors the
    /// `previewOverlayNode` pattern — sibling node, `removeAllChildren` to
    /// clear, `SKAction` to animate.
    func showHintCells(_ cells: [GridPosition]) {
        clearHint()
        guard !cells.isEmpty else { return }

        let fill = SpriteKitColors.lineCompletionPrimary.withAlphaComponent(0.45)
        let stroke = SpriteKitColors.lineCompletionSecondary
        for cell in cells where (0..<gridSize).contains(cell.row) && (0..<gridSize).contains(cell.col) {
            let rect = CGRect(x: 0, y: 0, width: cellSize, height: cellSize)
            let overlay = SKShapeNode(rect: rect, cornerRadius: GameTheme.Layout.cellCornerRadius)
            overlay.fillColor = fill
            overlay.strokeColor = stroke
            overlay.lineWidth = 4
            overlay.position = cellPosition(row: cell.row, col: cell.col)
            hintOverlayNode.addChild(overlay)
        }

        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.55, duration: 0.4),
            SKAction.fadeAlpha(to: 1.0, duration: 0.4)
        ]))
        hintOverlayNode.alpha = 1.0
        hintOverlayNode.run(pulse)

        let fadeOut = SKAction.sequence([
            SKAction.wait(forDuration: 1.7),
            SKAction.fadeAlpha(to: 0.0, duration: 0.3),
            SKAction.run { [weak self] in self?.clearHint() }
        ])
        hintOverlayNode.run(fadeOut, withKey: GridNode.hintAutoclearActionKey)
    }

    /// Cancels any active hint pulse and removes the overlay cells.
    func clearHint() {
        hintOverlayNode.removeAction(forKey: GridNode.hintAutoclearActionKey)
        hintOverlayNode.removeAllActions()
        hintOverlayNode.alpha = 1.0
        hintOverlayNode.removeAllChildren()
    }
}
