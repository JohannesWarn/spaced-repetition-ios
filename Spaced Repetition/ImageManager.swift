//
//  ImageManager.swift
//  Spaced Repetition
//
//  Created by Johannes Warn on 2019-08-10.
//  Copyright © 2019 Johannes Wärn. All rights reserved.
//

import UIKit

struct CardSides {
    let name: String
    let level: Int
    let frontImage: UIImage?
    let backImage: UIImage?
    let frontImageURL: URL?
    let backImageURL: URL?
    
    var nameInt: Int? {
        if let range = name.range(of: #"\b\d+\b"#, options: .regularExpression) {
            let digitsString = name[range]
            if let nameInt = Int(String(digitsString)) {
                return nameInt
            }
        }
        return nil
    }
}

class ImageManager: NSObject {
    
    class func levelDirectory(forLevel level: Int) -> URL {
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentDirectory.appendingPathComponent("level-\(level)")
    }
    
    class func imagesURLsForNewCard() -> CardSides {
        var files: [URL] = []
        for i in 1...8 {
            files.append(contentsOf: fileURLs(forLevel: i))
        }
        let largestFileNameInt = files.reduce(0) { (result, file) -> Int in
            if let fileName = file.pathComponents.last, let range = fileName.range(of: #"\b\d+\b"#, options: .regularExpression) {
                let digitsString = fileName[range]
                if let nameInt = Int(String(digitsString)) {
                    return max(result, nameInt)
                }
            }
            return result
        }
        let name = String(largestFileNameInt + 1)
        
        return CardSides(
            name: name,
            level: 1,
            frontImage: nil,
            backImage: nil,
            frontImageURL: imageURL(name: name, level: 1, suffix: "front"),
            backImageURL: imageURL(name: name, level: 1, suffix: "back")
        )
    }
    
    class func containsAnyCards() -> Bool {
        for i in 1...8 {
            if fileURLs(forLevel: i).count > 0 {
                return true
            }
        }
        return false
    }
    
    class func numberOfCards(atLevel level: Int) -> Int {
        return deckOfImages(forLevel: level).count
    }
    
    class func move(card: CardSides, toLevel level: Int) {
        guard card.level != level else { return }
        
        let newCard = CardSides(
            name: card.name, level: level,
            frontImage: card.frontImage,
            backImage: card.backImage,
            frontImageURL: self.imageURL(name: card.name, level: level, suffix: "front"),
            backImageURL: self.imageURL(name: card.name, level: level, suffix: "back")
        )
        
        guard card.frontImageURL != nil && card.backImageURL != nil && newCard.frontImageURL != nil && newCard.backImageURL != nil else {
            return
        }
        try! FileManager.default.moveItem(at: card.frontImageURL!, to: newCard.frontImageURL!)
        try! FileManager.default.moveItem(at: card.backImageURL!, to: newCard.backImageURL!)
    }
    
    
    class func delete(card: CardSides) {
        guard card.frontImageURL != nil && card.backImageURL != nil else {
            return
        }
        try! FileManager.default.removeItem(at: card.frontImageURL!)
        try! FileManager.default.removeItem(at: card.backImageURL!)
    }
    
    class func imageURL(name: String, level: Int, suffix: String) -> URL {
        let directory = levelDirectory(forLevel: level)
        if !FileManager.default.fileExists(atPath: directory.absoluteString) {
            try! FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileName = "\(name)-\(suffix).png"
        return directory.appendingPathComponent(fileName)
    }
    
    class func fileURLs(forLevel level: Int) -> [URL] {
        let directory = levelDirectory(forLevel: level)
        guard let files = try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: [], options: []) else {
            return []
        }
        return files
    }
    
    class func deckOfImages(forLevel level: Int) -> [CardSides] {
        let directory = levelDirectory(forLevel: level)
        let files = fileURLs(forLevel: level)
        
        var cards: [CardSides] = []
        for fileURL in files {
            if fileURL.absoluteString.hasSuffix("front.png") {
                let name = fileURL.pathComponents.last!.replacingOccurrences(of: "-front.png", with: "")
                let frontImage = UIImage.init(data: try! Data(contentsOf: fileURL))!
                let backFileName = fileURL.pathComponents.last!.replacingOccurrences(of: "front", with: "back")
                let backFileURL = directory.appendingPathComponent(backFileName)
                let backImage = UIImage.init(data: try! Data(contentsOf: backFileURL))!

                cards.append(
                    CardSides(
                        name: name,
                        level: level,
                        frontImage: frontImage,
                        backImage: backImage,
                        frontImageURL: fileURL,
                        backImageURL: backFileURL
                    )
                )
            }
        }
        return cards
    }
    
    class func deckOfImages(forLevels levels: [Int]) -> [CardSides] {
        var cards: [CardSides] = []
        for level in levels {
            cards.append(contentsOf: deckOfImages(forLevel: level))
        }
        return cards
    }
    
}

extension Array where Element == CardSides {
    func sortedByCardName() -> Array<CardSides> {
        return sorted(by: { (cardA, cardB) -> Bool in
            guard let nameIntA = cardA.nameInt else {
                return (cardB.nameInt != nil) ? true : cardB.name < cardA.name
            }
            guard let nameIntB = cardB.nameInt else {
                return false
            }
            
            return nameIntB < nameIntA
        })
    }
}
