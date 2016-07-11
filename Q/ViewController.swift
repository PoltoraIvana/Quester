//
//  ViewController.swift
//  Q
//
//  Created by Ivan on 10/27/15.
//  Copyright © 2015 Ivan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CellDelegate {
    
    //создаём тэйблвью, но можно было делать и через тэйблвьюконтроллер
    @IBOutlet weak var tableView: UITableView!
    //массив квестов
    var quests = [Quest]()
    //распозднаёт "щепок"
    let pinchRecognizer = UIPinchGestureRecognizer()
    //константа для регулирования высоты ячеек
    let rowHeight: CGFloat = 90
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //для работы щепка
        pinchRecognizer.addTarget(self, action: "handlePinch:")
        tableView.addGestureRecognizer(pinchRecognizer)
        //регистрируем для работы тэйблвью
        tableView.dataSource = self
        tableView.delegate = self
        //для работы своего класса ячеек
        tableView.registerClass(Cell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.blackColor()
        tableView.rowHeight = rowHeight

        //если квестов нет, ничего не отображаем
        if quests.count > 0 {
            return
        }
        //примеры квестов
        quests.append(Quest(text: "Read chapter 4"))
        quests.append(Quest(text: "Read chapter 5"))
        quests.append(Quest(text: "Read chapter 6"))
        quests.append(Quest(text: "Read chapter 7"))
        quests.append(Quest(text: "Read chapter 8"))
        quests.append(Quest(text: "Read chapter 9"))
    }
    
    //методы для таблицы и ячеек
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //стандартный метод тэйблвью. Потом секциями можно будет сделать разные дни в "общем виде"
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return quests.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //регулируем ячейку
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! Cell
        cell.selectionStyle = .None
        //подвязываем квесты к ячейке
        let item = quests[indexPath.row]
        cell.delegate = self
        cell.quest = item
        return cell
    }
    
    //генерируем цвет
    func colorForIndex(index: Int) -> UIColor {
        //принцип: раскрашиваем ячейки, регулируя грин в ргб-формате.
        //отнимаем 1, чтобы количество соответствовало индексу.
        //В ином случае последние две ячейки будут одинаково красные.
        let itemCount = quests.count - 1
        let val = (CGFloat(index) / CGFloat(itemCount)) * 0.6
        return UIColor(red: 1.0, green: val, blue: 0.0, alpha: 1.0)
    }
    
    //используя предыдущий метод, раскрашиваем ячейке
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = colorForIndex(indexPath.row)
    }
    
    //квест-метод
    
    func deleteQuest(quest: Quest) {
        //линкаем квесты с NSArray, чтобы был метод "индекс оф обджект"
        let index = (quests as NSArray).indexOfObject(quest)
        if index == NSNotFound { return }
        quests.removeAtIndex(index)
        //определяем видимые ячейки.
        let visibleCells = tableView.visibleCells as! [Cell]
        //-1, чтобы был как индекс
        let lastView = visibleCells[visibleCells.count - 1] as Cell
        var delay = 0.0
        var startAnimating = false
        //доходим до удаляемой ячейки, затем анимируем все ячейки ниже
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if startAnimating {
            UIView.animateWithDuration(0.3, delay: delay, options: .CurveEaseInOut, animations: {() in
                cell.frame = CGRectOffset(cell.frame, 0.0, -cell.frame.size.height)},
                completion: {(finished: Bool) in
                    if cell == lastView {
                        self.tableView.reloadData()
                        }
                    }
                )
                delay += 0.03
            }
            //находим удаляемую ячейку, прячем её, переводим бул в тру
            if cell.quest == quest {
                startAnimating = true
                cell.hidden = true
            }
        }
        //обновляем табличку
        tableView.beginUpdates()
        let indexPathForRow = NSIndexPath(forRow: index, inSection: 0)
        tableView.deleteRowsAtIndexPaths([indexPathForRow], withRowAnimation: .Fade)
        tableView.endUpdates()
    }
    
    //"щепок"-методы
    
    //структура для записи касаний
    struct TouchPoints {
        var upper: CGPoint
        var lower: CGPoint
    }
    
    //нужен "невозможный" индекс, чтобы случайно не сработало
    var upperCellIndex = -100
    var lowerCellIndex = -100
    
    var initialTouchPoints: TouchPoints!
    //бул, нужный для определения необходимости создания нового квеста
    var pinchExceededRequiredDistance = false
    //бул, нужный для определения работы "щепка"
    var pinchInProgress = false
    
    //метод для щепка. Для каждого из состояний - свой метод.
    func handlePinch(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .Began {
            pinchStarted(recognizer)
        }
        //чтобы случайно не сработало, проверяем не только состояние рекогнайзера,
        //но и количество касаний + работу щепка
        if recognizer.state == .Changed && pinchInProgress && recognizer.numberOfTouches() == 2{
            pinchChanged(recognizer)
        }
        if recognizer.state == .Ended {
            pinchEnded(recognizer)
        }
        
    }
    
    func pinchStarted(recognizer: UIPinchGestureRecognizer) {
        //получаем точки касаний с помощью метода
        initialTouchPoints = getNormalizedTouchPoints(recognizer)
        upperCellIndex = -100
        lowerCellIndex = -100
        let visibleCells = tableView.visibleCells as! [Cell]
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if viewContainsPoint(cell, point: initialTouchPoints.upper) {
                upperCellIndex = i
                //для дебага - окрашиваем "касаемые ячейки"
                //cell.backgroundColor = UIColor.purpleColor()
            }
            if viewContainsPoint(cell, point: initialTouchPoints.lower) {
                lowerCellIndex = i
                //для дебага - окрашиваем "касаемые ячейки"
                //cell.backgroundColor = UIColor.purpleColor()
            }
        }
        //разница между соседними ячейками должна быть равна 1
        if abs(upperCellIndex - lowerCellIndex) == 1 {
            pinchInProgress = true
            //записываем, какая ячейка выше
            let precedingCell = visibleCells[upperCellIndex]
            //создаём временную ячейку
            placeHolderCell.frame = CGRectOffset(precedingCell.frame, 0.0, tableView.rowHeight / 2.0)
            //окрашиваем временную ячейку как предыдущую
            placeHolderCell.backgroundColor = precedingCell.backgroundColor
            tableView.insertSubview(placeHolderCell, atIndex: 0)
            
        }
    }
    
    func pinchChanged(recognizer: UIPinchGestureRecognizer) {
        //получаем новые тач-поинты
        let currentTouchPoints = getNormalizedTouchPoints(recognizer)
        //вычисляем разницу между точками касания
        let upperDelta = currentTouchPoints.upper.y - initialTouchPoints.upper.y
        let lowerDelta = initialTouchPoints.lower.y - currentTouchPoints.lower.y
        //берём минимальную разницу из всего
        let delta = -min(0, min(upperDelta, lowerDelta))
        let visibleCells = tableView.visibleCells as! [Cell]
        for i in 0..<visibleCells.count {
            //сдвигаем старые ячейки на дельту, в зависимости от того, выше они новой ячейки или ниже
            let cell = visibleCells[i]
            if i <= upperCellIndex {
                cell.transform = CGAffineTransformMakeTranslation(0, -delta)
            }
            if i >= lowerCellIndex {
                cell.transform = CGAffineTransformMakeTranslation(0, delta)
            }
        }
        //создаём "щель" между ячейками
        let gapSize = delta * 2
        //если меньше высоты ячейки, то создаём усечённую ячейку
        let cappedGapSize = min(gapSize, tableView.rowHeight)
        //усечение определяем отношением выражения выше к высоте ячейки
        placeHolderCell.transform = CGAffineTransformMakeScale(1.0, cappedGapSize / tableView.rowHeight)
        //в зависимости от того, на сколько большая щель, выбираем текст
        placeHolderCell.label.text = gapSize > tableView.rowHeight ? "Release to add item" : "Pull apart to add item"
        //если щель меньше ячейки, делаем альфу меньше
        placeHolderCell.alpha = min(1.0, gapSize / tableView.rowHeight)
        pinchExceededRequiredDistance = gapSize > tableView.rowHeight
    }
    
    func pinchEnded(recognizer: UIPinchGestureRecognizer) {
        //сразу переводим "работу щепка" в фолс
        pinchInProgress = false
        placeHolderCell.transform = CGAffineTransformIdentity
        placeHolderCell.removeFromSuperview()
        
        if pinchExceededRequiredDistance {
            pinchExceededRequiredDistance = false
            
            let visibleCells = self.tableView.visibleCells as! [Cell]
            for cell in visibleCells {
                cell.transform = CGAffineTransformIdentity
            }
            
            let indexOffset = Int(floor(tableView.contentOffset.y / tableView.rowHeight))
            questAddedAtIndex(lowerCellIndex + indexOffset)
        } else {
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: {() in
                let visibleCells = self.tableView.visibleCells as! [Cell]
                for cell in visibleCells {
                    cell.transform = CGAffineTransformIdentity
                }
                }, completion: nil)
        }
    }
    
    func getNormalizedTouchPoints(recognizer: UIGestureRecognizer) -> TouchPoints {
        var pointOne = recognizer.locationOfTouch(0, inView: tableView)
        var pointTwo = recognizer.locationOfTouch(1, inView: tableView)
        if pointOne.y > pointTwo.y {
            let temp = pointOne
            pointOne = pointTwo
            pointTwo = temp
        }
        return TouchPoints(upper: pointOne, lower: pointTwo)
    }
    
    func viewContainsPoint(view: UIView, point: CGPoint) -> Bool {
        let frame = view.frame
        return (frame.origin.y < point.y) && (frame.origin.y + frame.size.height > point.y)
    }
    
    // MARK: - UIScrollViewDelegate methods
    // contains scrollViewDidScroll, and other methods, to keep track of dragging the scrollView
    
    //a placeholder for a new cell
    let placeHolderCell = Cell(style: .Default, reuseIdentifier: "cell")
    //indicated the state of pulldown
    var pullDownInProgress = false
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        pullDownInProgress = scrollView.contentOffset.y <= 0.0
        placeHolderCell.backgroundColor = UIColor.redColor()
        if pullDownInProgress {
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var scrollViewContentOffsetY = scrollView.contentOffset.y
        if pullDownInProgress && scrollView.contentOffset.y <= 0.0 {
            placeHolderCell.frame = CGRect(x: 0, y: -tableView.rowHeight, width: tableView.frame.size.width, height: tableView.rowHeight)
            placeHolderCell.label.text = -scrollViewContentOffsetY > tableView.rowHeight ? "Release to add item" : "Pull to add item"
            placeHolderCell.alpha = min(1.0, -scrollViewContentOffsetY / tableView.rowHeight)
        } else {
            pullDownInProgress = false
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if pullDownInProgress && -scrollView.contentOffset.y > tableView.rowHeight {
            questAdded()
        }
        pullDownInProgress = false
        placeHolderCell.removeFromSuperview()
    }
    // MARK: - CellDelegate methods
    
    func cellDidBeginEditing(editingCell: Cell) {
        let editingOffset = tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        let visibleCells = tableView.visibleCells as! [Cell]
        for cell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in
                cell.transform = CGAffineTransformMakeTranslation(0, editingOffset)
                if cell != editingCell {
                    cell.alpha = 0.3
                }
            }
            )
        }
    }
    
    func cellDidEndEditing(editingCell: Cell) {
        let visibleCells = tableView.visibleCells as! [Cell]
        for cell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in
                cell.transform = CGAffineTransformIdentity
                if cell != editingCell {
                    cell.alpha = 1.0
                }
            })
        }
        if editingCell.quest!.text == "" {
            deleteQuest(editingCell.quest!)
        }
    }
    
    func questAdded() {
        questAddedAtIndex(0)
    }
    
    func questAddedAtIndex(index: Int) {
        let quest = Quest(text: "")
        quests.insert(quest, atIndex: index)
        tableView.reloadData()
        
        var editCell: Cell
        let visibleCells = tableView.visibleCells as! [Cell]
        for cell in visibleCells {
            if (cell.quest === quest) {
                editCell = cell
                editCell.label.becomeFirstResponder()
                break
            }
        }
    }

}

