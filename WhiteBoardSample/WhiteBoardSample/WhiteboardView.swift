//
//  WhiteboardView.swift
//  WhiteBoardSample
//
//  Created by Aleksandr Khorobrykh on 16/01/2018.
//  Copyright © 2018 Apizee. All rights reserved.
//

import UIKit
import ApiRTC

// FIXME: fix all access levels !
// FIXME: move to framework

internal struct WhiteboardClient {
    var userId: String
    var elements: [DrawElement] // FIXME: sort
    var lastElementId: Int {
        return elements.last?.id ?? 0
    }
}

class WhiteboardView: UIImageView {
    
    var sheetId = 1
    
    var localElementIndex = 1
    var lastUndoIndex = 0
    var lastPoint = CGPoint.zero

    var drawTimer: Timer?
    
    var localElementsBuffer: [DrawElement] = []
    
    var clients: [String: WhiteboardClient] = [:]
    
    var localImage: UIImage?
    var remoteImage: UIImage?
    
    var redoElements: [[DrawElement]] = []

    var onUpdate: ((_ data: WhiteboardData) -> Void)?

    // MARK: Touches

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let point = touches.first?.location(in: self) else {
            return
        }

        lastUndoIndex += 1

        lastPoint = point

        // FIXME: make property for frequency
        drawTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(drawTimerAction), userInfo: nil, repeats: true)
        drawTimer?.fire()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        let element = DrawElement(id: localElementIndex, undoIndex: lastUndoIndex, fromPoint: lastPoint, toPoint: point)
        
        drawLocalElement(element)
        
        lock(localElementsBuffer) {
            localElementsBuffer.append(element)
        }
        
        addElementsToLocalClient([element])

        lastPoint = point
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

        drawTimer?.invalidate()
        drawTimer = nil
        drawTimerAction()
    }

    @objc private func drawTimerAction() {

        guard localElementsBuffer.count > 0 else {
            return
        }

        lock(localElementsBuffer) {
            let data = WhiteboardData(sheetId: sheetId, elements: localElementsBuffer)
            onUpdate?(data)
            localElementsBuffer = []
        }
    }

    // MARK: Drawing

    private func drawLine(fromPoint: CGPoint, toPoint: CGPoint, byCurrentUser: Bool = true) {

        draw(byCurrentUser: byCurrentUser) { context in
            context.move(to: fromPoint)
            context.addLine(to: toPoint)
            context.setLineWidth(1)
            context.setStrokeColor(UIColor.blue.cgColor)
            context.strokePath()
        }
    }

    func draw(byCurrentUser: Bool = true, draw: ((_ context: CGContext) -> Void)) {

        UIGraphicsBeginImageContextWithOptions(self.frame.size, false, 0)

        guard let context = UIGraphicsGetCurrentContext() else {
            print("No context")
            return
        }

        draw(context)

        if byCurrentUser {
            localImage?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .colorBurn, alpha: 1.0)
            localImage = UIGraphicsGetImageFromCurrentImageContext()
        }
        else {
            remoteImage?.draw(in: CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height), blendMode: .colorBurn, alpha: 1.0)
            remoteImage = UIGraphicsGetImageFromCurrentImageContext()
        }

        remerge()

        UIGraphicsEndImageContext()
    }
    
    private func erase() {
        // FIXME:
    }
    
    private func remerge() {
        
        var newImage = remoteImage
        
        if let currentUserImage = localImage {
            newImage = newImage?.combineImage(image: currentUserImage) ?? currentUserImage
        }
        
        self.image = newImage
    }
    
    private func drawLocalElement(_ element: DrawElement) {

        localElementIndex += 1

        switch element.tool {
        case .pen:
            drawLine(fromPoint: element.fromPoint, toPoint: element.toPoint, byCurrentUser: true)
        }
    }
    
    private func redrawLocalElements() {
        
        self.image = nil
        localImage = nil
        
        let localElements = getLocalClient().elements
        
        for localElement in localElements {
            drawLocalElement(localElement)
        }
        
        remerge()
    }
    
    private func drawRemoteElement(_ element: DrawElement) {
        
        switch element.tool {
        case .pen:
            drawLine(fromPoint: element.fromPoint, toPoint: element.toPoint, byCurrentUser: false)
        }
    }
    
    private func redrawRemoteElements() {
        
        self.image = nil
        remoteImage = nil
        
        guard let remoteElements = getRemoteElements() else {
            remerge()
            return
        }
        
        for remoteElement in remoteElements {
            drawRemoteElement(remoteElement)
        }
    }
    
    private func redraw() {
        redrawRemoteElements()
        redrawLocalElements()
    }
    
    // MARK: Handlers
    
    func update(_ data: WhiteboardData) {
        
        // FIXME: need local sync
        
        if data.sheetId != sheetId {
            sheetId = data.sheetId
            reset()
            return
        }
        
        if !data.isDrawing {
            return // FIXME: need handle? cursor?
        }
        
        let client = getClient(forUserId: data.senderId)
        
        if data.isDeleting {
            removeElementsFromClient(withUserId: data.senderId, elements: data.elements)
            redrawRemoteElements()
            return
        }
        
        var newElements: [DrawElement] = []
        
        for element in data.elements {
            guard element.userId != ApiRTC.session.user.id else {
                continue
            }
            guard element.userId == client.userId else {
                continue
            }
            guard element.id > client.lastElementId else {
                continue
            }

            newElements.append(element)
        }
        
        addElementsToClient(withUserId: data.senderId, elements: newElements)
        
        guard newElements.count > 0 else {
            return
        }
        
        for newElement in newElements {
            drawRemoteElement(newElement)
        }
    }
    
    // MARK: Actions
    
    func undo() {

        var removingElements: [DrawElement] = []
        let localElements = getLocalClient().elements
        
        for localElement in localElements {
            if localElement.undoIndex == lastUndoIndex {
                removingElements.append(localElement)
            }
        }
        
        lastUndoIndex -= 1
        
        let data = WhiteboardData(sheetId: sheetId, elements: removingElements, isDeleting: true)
        onUpdate?(data)
        
        removeElementsFromLocalClient(removingElements)
        
        redrawLocalElements()
        
        redoElements.append(removingElements)
    }
    
    func redo() {
        
        guard let elements = redoElements.last else {
            return
        }
        
        for element in elements {
            drawLocalElement(element)
        }
        
        let data = WhiteboardData(sheetId: sheetId, elements: elements)
        onUpdate?(data)
        
        addElementsToLocalClient(elements)
        
        redoElements.removeLast()
        
        lastUndoIndex += 1
    }
    
    func createNewSheet() {
        reset()
        
        sheetId += 1
        let data = WhiteboardData(sheetId: sheetId, elements: [])
        onUpdate?(data)
    }
    
    // MARK:
    
    open func onUpdate(_ onUpdate: @escaping (_ data: WhiteboardData) -> Void) {
        self.onUpdate = onUpdate
    }
    
    // MARK: Helpers
    
    func reset() {
        clients = [:]
        redoElements = []
        redraw()
        
        localElementIndex = 1
        lastUndoIndex = 0
        lastPoint = CGPoint.zero
        
        localElementsBuffer = []
        
        localImage = nil
        remoteImage = nil
    }
    
    func getClient(forUserId userId: String) -> WhiteboardClient {
        return lock(clients) { () -> WhiteboardClient in
            if let client = clients[userId] {
                return client
            }
            else {
                let client = WhiteboardClient(userId: userId, elements: [])
                clients[userId] = client
                return client
            }
        }
    }
    
    func getLocalClient() -> WhiteboardClient {
        return getClient(forUserId: ApiRTC.session.user.id)
    }
    
    func addElementsToClient(withUserId userId: String, elements: [DrawElement]) {
        _ = getClient(forUserId: userId)
        lock(clients) {
            clients[userId]?.elements.append(contentsOf: elements)
        }
    }
    
    func addElementsToLocalClient(_ elements: [DrawElement]) {
        addElementsToClient(withUserId: ApiRTC.session.user.id, elements: elements)
    }
    
    func removeElementsFromClient(withUserId userId: String, elements: [DrawElement]) {
        var client = getClient(forUserId: userId)
        for element in elements {
            client.elements = client.elements.filter({ $0.id != element.id })
        }
        lock(clients) {
            clients[userId]?.elements = client.elements
        }
    }
    
    func removeElementsFromLocalClient(_ elements: [DrawElement]) {
        removeElementsFromClient(withUserId: ApiRTC.session.user.id, elements: elements)
    }
    
    func getRemoteElements() -> [DrawElement]? {
        
        var remoteElements: [DrawElement] = []
        
        for (userId, client) in clients {
            if userId == ApiRTC.session.user.id {
                continue
            }
            
            remoteElements.append(contentsOf: client.elements)
        }
        
        remoteElements.sort(by: { return $0.time > $1.time }) // FIXME: check
        
        return remoteElements.count > 0 ? remoteElements : nil
    }
}

// MARK: Threads

func lock<T>(_ lock: Any, _ body: () throws -> T) rethrows -> T {
    objc_sync_enter(lock)
    defer {
        objc_sync_exit(lock)
    }
    return try body()
}

extension UIImage {
    
    func combineImage(image: UIImage) -> UIImage? {
        
        let newImageWidth  = max(self.size.width,  image.size.width )
        let newImageHeight = max(self.size.height, image.size.height)
        let newImageSize = CGSize(width : newImageWidth, height: newImageHeight)
        
        UIGraphicsBeginImageContextWithOptions(newImageSize, false, UIScreen.main.scale)
        
        let firstImageDrawX  = round((newImageSize.width  - self.size.width  ) / 2)
        let firstImageDrawY  = round((newImageSize.height - self.size.height ) / 2)
        
        let secondImageDrawX = round((newImageSize.width  - image.size.width ) / 2)
        let secondImageDrawY = round((newImageSize.height - image.size.height) / 2)
        
        self.draw(at: CGPoint(x: firstImageDrawX,  y: firstImageDrawY))
        image.draw(at: CGPoint(x: secondImageDrawX, y: secondImageDrawY))
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
