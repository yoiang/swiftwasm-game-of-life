import LifeGame
import JavaScriptKit

class App: BoardUpdater {
    var cells: [[Cell]]
    let canvas: BoardCanvas
    let rule: Rule

    var timer: JSValue?
    lazy var tickFn = JSClosure { [weak self] _ in
        self?.iterate()
        return .undefined
    }

    init(initial: [[Cell]], canvas: BoardCanvas, rule: Rule) {
        self.cells = initial
        self.canvas = canvas
        self.rule = rule

        forEachCell(initial) { (cell, point) in
            canvas.drawCell(cell, at: point)
        }
    }

    func update(at point: Point, cell: Cell) {
        cells[point.y][point.x] = cell
        canvas.drawCell(cell, at: point)
    }

    func noUpdate(at point: Point, cell: Cell) {
        if (canvas.shouldDrawCellOnNoUpdate) {
            canvas.drawCell(cell, at: point)
        }
    }

    func iterate() {
        LifeGame.iterate(cells, updater: self, rule: rule)
    }

    func start() {
        guard self.timer == nil else { return }
        self.timer = JSObject.global.setInterval!(tickFn, 50)
    }

    func stop() {
        guard let timer = self.timer else { return }
        _ = JSObject.global.clearInterval!(timer)
        self.timer = nil
    }
}

func initialCells(width: Int, height: Int) -> [[Cell]] {
    (0..<height).map { _ in
        (0..<width).map { _ in
            Cell(live: Bool.random())
        }
    }
}

let document = JSObject.global.document

let canvas = document.getElementById("app-canvas").object!
var iterateButton = document.getElementById("app-step-button")
var startButton = document.getElementById("app-start-button")
var stopButton = document.getElementById("app-stop-button")
var resetButton = document.getElementById("app-reset-button")

var ruleSelect = document.getElementById("app-rule")
var ruleCustomBirth = document.getElementById("app-rule-custom-birth")
var ruleCustomSurvive = document.getElementById("app-rule-custom-survive")
var rule = try Rule(ruleString: ruleSelect.value.string!)

var controlsContainer = document.getElementById("app-controls-container")

var liveColorInput = document.getElementById("app-live-color")

var canvasTypeSelect = document.getElementById("app-canvas-type")

let width = Int(document.body.clientWidth.number!) / (BasicBoardCanvas.cellSize + BasicBoardCanvas.boarderWidth)
let height = Int(document.body.clientHeight.number! - controlsContainer.clientHeight.number!) / (BasicBoardCanvas.cellSize + BasicBoardCanvas.boarderWidth)

func canvasForType(_ type: String) -> BoardCanvas {
    switch type {
        case "persisted":
            return PersistedBoardCanvas(canvas: canvas, size: (width, height), liveColor: liveColorInput.value.string!)
        default:
            return BasicBoardCanvas(canvas: canvas, size: (width, height), liveColor: liveColorInput.value.string!)
    }
}

var boardView = canvasForType(canvasTypeSelect.value.string!)

var lifeGame = App(initial: initialCells(width: width, height: height), canvas: boardView, rule: rule)

let iterateFn = JSClosure { _ in
    lifeGame.iterate()
    return .undefined
}

let startFn = JSClosure { _ in
    lifeGame.start()
    return .undefined
}

let stopFn = JSClosure { _ in
    lifeGame.stop()
    return .undefined
}

let resetFn = JSClosure { _ in
    lifeGame = App(initial: initialCells(width: width, height: height), canvas: boardView, rule: rule)
    return .undefined
}

let updateBoardFn = JSClosure { _ in
    boardView = canvasForType(canvasTypeSelect.value.string!)

    lifeGame = App(initial: initialCells(width: width, height: height), canvas: boardView, rule: rule)
    return .undefined
}

let updateRuleFn = JSClosure { _ in
    switch ruleSelect.value.string! {
    case "custom":
        ruleCustomBirth.disabled = .boolean(false)
        ruleCustomSurvive.disabled = .boolean(false)

        rule = try! Rule(ruleString: "B\(ruleCustomBirth.value.string!)/S\(ruleCustomSurvive.value.string!)")
    default:
        ruleCustomBirth.disabled = .boolean(true)
        ruleCustomSurvive.disabled = .boolean(true)

        rule = try! Rule(ruleString: ruleSelect.value.string!)
    }
    lifeGame = App(initial: initialCells(width: width, height: height), canvas: boardView, rule: rule)
    return .undefined
}

iterateButton.onclick = .object(iterateFn)
startButton.onclick = .object(startFn)
stopButton.onclick = .object(stopFn)
resetButton.onclick = .object(resetFn)

liveColorInput.onchange = .object(updateBoardFn)
canvasTypeSelect.onchange = .object(updateBoardFn)

ruleSelect.onchange = .object(updateRuleFn)
ruleCustomBirth.onchange = .object(updateRuleFn)
ruleCustomSurvive.onchange = .object(updateRuleFn)

