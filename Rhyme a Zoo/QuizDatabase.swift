//
//  QuizDatabase.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/30/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
import SQLite

///Global database. QuizDatabase -> Quiz -> Question -> Option
let RZQuizDatabase = QuizDatabase()

///SQLite.swift wrapper for the legacy databace from the PC version of Rhyme a Zoo.
private let sql = Database(NSBundle.mainBundle().pathForResource("LegacyDB", ofType: "db")!, readonly: true)
//QUIZ table
private let Quizes = sql["QUIZ"]
private let QuizNumber = Expression<Int>("QuizNo")
private let QuizName = Expression<String>("Name")
private let QuizLevel = Expression<Int>("Level")
private let QuizRhymeText = Expression<String>("RhymeText")
private let QuizDisplayOrder = Expression<Int>("D_ORDER")
//AUDIOTIME table
private let AudioTime = sql["AUDIOTIME"]
let AudioWord = Expression<Int>("Word")
let AudioStartTime = Expression<Int>("StartTime")
//QUESTION table
private let Questions = sql["Question"]
private let QuestionNumber = Expression<Int>("QuestionNo")
private let QuestionAnswer = Expression<String>("Answer")
private let QuestionCategory = Expression<String>("Category")
private let QuestionText = Expression<String>("QuestionText")
//WORDBANK table
private let WordBank = sql["WORDBANK"]
let WordText = Expression<String>("Word")
let WordCategory = Expression<Int>("Category")

//User Data Keys managed by the database
let RZFavoritesKey: NSString = "com.hearatale.raz.favorites"
let RZQuizResultsKey: NSString  = "com.hearatale.raz.quizResults"
let RZQuizLevelKey: NSString  = "com.hearatale.raz.quizLevel"
let RZPlayerBalanceKey: NSString  = "com.hearatale.raz.balance"
let RZAnimalsKey: NSString  = "com.hearatale.raz.animals"
let RZZooLevelKey: NSString  = "com.hearatale.raz.animalLevel"
let RZKeeperNumberKey: NSString  = "com.hearatale.raz.keeperNumber"
let RZKeeperGenderKey: NSString  = "com.hearatale.raz.keeperGender"

func userKey(key: NSString, forUser user: User) -> String {
    let originalKey = key as String
    return "\(originalKey).\(user.ID)"
}

func userKey(key: NSString) -> String {
    return userKey(key, forUser: RZCurrentUser)
}

///Top level database structure. Globally available at RZQuizDatabase. Contains many Quizes.
///Quiz Database -> Quiz -> Question -> Option
class QuizDatabase {
    
    private var quizNumberMap: [Int] = []
    var count: Int {
        get {
            return quizNumberMap.count
        }
    }
    var levelCount: Int = 24 //24 levels. This is just a fact.
    
    init() {
        for level in 1...levelCount {
            var displayOrderArray: [Int?] = [nil, nil, nil, nil, nil]
            for quiz in Quizes.filter(QuizLevel == level) {
                let quizNumber = quiz[QuizNumber]
                let quizDisplayOrder = quiz[QuizDisplayOrder]
                displayOrderArray[quizDisplayOrder - 1] = quizNumber
            }
            
            for quiz in displayOrderArray {
                if let quiz = quiz {
                    quizNumberMap.append(quiz)
                }
            }
        }
        
        
        for quiz in Quizes.select(QuizNumber) {
            quizNumberMap.append(quiz[QuizNumber])
        }
    }
    
    func getQuiz(index: Int) -> Quiz {
        let number = quizNumberMap[index]
        return Quiz(number)
    }
    
    func getRhyme(index: Int) -> Rhyme {
        return getQuiz(index)
    }
    
    func quizesInLevel(level: Int) -> [Quiz!] {
        var displayOrderArray: [Quiz!] = [nil, nil, nil, nil, nil]
        for quiz in Quizes.filter(QuizLevel == level) {
            let quizNumber = quiz[QuizNumber]
            let quizDisplayOrder = quiz[QuizDisplayOrder]
            displayOrderArray[quizDisplayOrder - 1] = Quiz(quizNumber)
        }
        return displayOrderArray.filter{ $0 != nil }
    }
    
    func getIndexForRhyme(rhyme: Rhyme) -> Int {
        for i in 0 ..< quizNumberMap.count {
            if quizNumberMap[i] == rhyme.number {
                return i
            }
        }
        return -1
    }
    
    func getQuizData() -> [String : String] {
        return data.dictionaryForKey(userKey(RZQuizResultsKey)) as? [String : String] ?? [:]
    }
    
    func setQuizData(quizData: [String : String]) {
        data.setValue(quizData, forKey: userKey(RZQuizResultsKey))
    }
    
    func getFavorites() -> [Int] {
        return data.arrayForKey(userKey(RZFavoritesKey)) as? [Int] ?? []
    }
    
    func setFavorites(favs: [Int]) {
        data.setValue(favs, forKey: userKey(RZFavoritesKey))
    }
    
    func isQuizFavorite(number: Int) -> Bool {
        if let favs = data.arrayForKey(userKey(RZFavoritesKey)) as? [Int] {
            return contains(favs, number)
        }
        return false
    }
    
    func numberOfFavories() -> Int {
        if var favs = data.arrayForKey(userKey(RZFavoritesKey)) as? [Int] {
            return favs.count
        }
        return 0
    }
    
    func currentLevel() -> Int {
        var level = data.integerForKey(userKey(RZQuizLevelKey))
        if level == 0 {
            data.setInteger(1, forKey: userKey(RZQuizLevelKey))
            return 1
        }
        return level
    }
    
    func setQuizLevel(level: Int) {
        data.setInteger(level, forKey: userKey(RZQuizLevelKey))
    }
    
    func advanceLevelIfCurrentIsComplete() -> Bool {
        let current = currentLevel()
        let complete = quizesInLevel(currentLevel()).filter{ $0.quizHasBeenPlayed() }.count == 5
        
        if complete {
            let newLevel = min(current + 1, levelCount)
            data.setInteger(newLevel, forKey: userKey(RZQuizLevelKey))
        }
        return complete
    }
    
    //bank 
    
    func getPlayerBalance() -> Double {
        return data.doubleForKey(userKey(RZPlayerBalanceKey))
    }
    
    func changePlayerBalanceBy(amount: Double) {
        let current = getPlayerBalance()
        let new = current + amount
        data.setDouble(new, forKey: userKey(RZPlayerBalanceKey))
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    func setPlayerBalance(value: Double) {
        data.setDouble(value, forKey: userKey(RZPlayerBalanceKey))
    }
    
    //zoo management
    
    func getOwnedAnimals() -> [String] {
        if let array = data.arrayForKey(userKey(RZAnimalsKey)) as? [String] {
            return array
        }
        //array doesn't exist
        data.setValue([], forKey: userKey(RZAnimalsKey))
        return []
    }
    
    func setOwnedAnimals(animals: [String]) {
        data.setValue(animals, forKey: userKey(RZAnimalsKey))
    }
    
    func playerOwnsAnimal(animal: String) -> Bool {
        return contains(getOwnedAnimals(), animal)
    }
    
    func canAffordAnimal() -> Bool {
        return getPlayerBalance() >= 20.0
    }
    
    func purchaseAnimal(animal: String) {
        if !canAffordAnimal() { return }
        
        changePlayerBalanceBy(-20.0)
        var animals = getOwnedAnimals()
        animals.append(animal)
        data.setValue(animals, forKey: userKey(RZAnimalsKey))
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    func currentZooLevel() -> Int {
        let level = data.integerForKey(userKey(RZZooLevelKey))
        if level == 0 {
            data.setInteger(1, forKey: userKey(RZZooLevelKey))
            return 1
        }
        return level
    }
    
    func advanceCurrentLevelIfComplete(animals: [String]) -> Bool {
        var complete = true
        for animal in animals {
            complete = complete && playerOwnsAnimal(animal)
        }
        if complete {
            let currentLevel = currentZooLevel()
            data.setInteger(currentLevel + 1, forKey: userKey(RZZooLevelKey))
        }
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
        return complete
    }
    
    func setZooLevel(level: Int) {
        data.setInteger(level, forKey: userKey(RZZooLevelKey))
    }
    
    //zookeeper
    
    func getKeeperGender() -> String {
        let gender = data.stringForKey(userKey(RZKeeperGenderKey))
        if gender == nil || (gender != "boy" && gender != "girl") {
            data.setValue("boy", forKey: userKey(RZKeeperGenderKey))
            return "boy"
        }
        return gender!
    }
    
    func setKeeperGender(gender: String) {
        data.setValue(gender, forKey: userKey(RZKeeperGenderKey))
    }
    
    func getKeeperNumber() -> Int {
        let number = data.integerForKey(userKey(RZKeeperNumberKey))
        if number == 0 {
            data.setValue(1, forKey: userKey(RZKeeperNumberKey))
            return 1
        }
        return number
    }
    
    func setKeeperNumber(number: Int) {
        data.setValue(number, forKey: userKey(RZKeeperNumberKey))
    }
    
    func getKeeperString() -> String {
        return "\(getKeeperGender())~\(getKeeperNumber())"
    }
    
    func setKeeperWithString(string: String) {
        let splits = split(string){ $0 == "~" }
        let gender = splits[0]
        setKeeperGender(gender)
        if let number = splits[1].toInt() {
            setKeeperNumber(number)
        }
    }
    
}

typealias Rhyme = Quiz

///Avaliable though RZQuizDatabase. Contains 4 Questions.
struct Quiz : Printable {
    
    let quiz: Query
    ///"QUIZ" table
    let number: Int
    let name: String
    let level: Int
    var questions: [Question] {
        get {
            var array: [Question] = []
            for question in Questions.filter(QuizNumber == number) {
                let questionNumber = question[QuestionNumber]
                array.append(Question(questionNumber))
            }
            return array
        }
    }
    var description: String {
        get{
            return "(Quiz \(number))[\(name)]"
        }
    }
    
    init(_ number: Int) {
        self.number = number
        
        quiz = Quizes.filter(QuizNumber == self.number)
        let data = quiz.select(QuizName, QuizLevel).first!
        self.name = data[QuizName]
        self.level = data[QuizLevel]
    }
    
    var rhymeText: String {
        get{
            let data = quiz.select(QuizRhymeText).first!
            return data[QuizRhymeText]
        }
    }
    
    var wordStartTimes: [Int] {
        get {
            let data = AudioTime.filter(QuizNumber == self.number).select(AudioStartTime)
            var array: [Int] = []
            for word in data {
                array.append(word[AudioStartTime])
            }
            return array
        }
    }
    
    func setFavoriteStatus(fav: Bool) {
        if var favs = data.arrayForKey(userKey(RZFavoritesKey)) as? [Int] {
            if fav && !contains(favs, number) {
                favs.append(number)
                data.setValue(favs, forKey: userKey(RZFavoritesKey))
            } else if !fav && contains(favs, number) {
                let index = (favs as NSArray).indexOfObject(number)
                favs.removeAtIndex(index)
                data.setValue(favs, forKey: userKey(RZFavoritesKey))
            }
        }
        else {
            //favs array doesn't exist
            let favs = [number]
            data.setValue(favs, forKey: userKey(RZFavoritesKey))
        }
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    func isFavorite() -> Bool {
        return RZQuizDatabase.isQuizFavorite(number)
    }
    
    func saveQuizResult(#gold: Int, silver: Int) {
        var results: [String : String] = [:]
        if let resultsDict = data.dictionaryForKey(userKey(RZQuizResultsKey)) as? [String : String] {
            results = resultsDict
        }
        
        let resultString = "\(gold):\(silver)"
        results.updateValue(resultString, forKey: number.threeCharacterString())
        
        data.setValue(results, forKey: userKey(RZQuizResultsKey))
        
        //also update player balance
        let cashInflux = Double(gold) + (Double(silver) * 0.5)
        RZQuizDatabase.changePlayerBalanceBy(cashInflux)
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    func quizHasBeenPlayed() -> Bool {
        if let resultsDict = data.dictionaryForKey(userKey(RZQuizResultsKey)) as? [String : String] {
            return contains(resultsDict.keys.array, number.threeCharacterString())
        }
        return false
    }
    
    func getQuizResult() -> (gold: Int, silver: Int) {
        if let resultsDict = data.dictionaryForKey(userKey(RZQuizResultsKey)) as? [String : String] {
            if let result = resultsDict[number.threeCharacterString()] {
                let splits = split(result){ $0 == ":" }
                if splits.count == 2 {
                    let gold = splits[0].toInt()
                    let silver = splits[1].toInt()
                    
                    if let gold = gold, let silver = silver {
                        return (gold, silver)
                    }
                }
            }
        }
        return (0,0)
    }
    
    func getNext(fromFavorites favs: Bool) -> Quiz? {
        return getWithOffsetIndex(1, fromFavorites: favs)
    }
    
    func getPrevious(fromFavorites favs: Bool) -> Quiz? {
        return getWithOffsetIndex(-1, fromFavorites: favs)
    }
    
    func getWithOffsetIndex(offset: Int, fromFavorites favs: Bool) -> Quiz? {
        var numbersArray = RZQuizDatabase.quizNumberMap
        
        if let favsArray = data.arrayForKey(userKey(RZFavoritesKey)) as? [Int] where favs {
            numbersArray = favsArray
        }
        
        if let thisIndex = find(numbersArray, self.number) {
            let searchIndex = thisIndex + offset
            if searchIndex < 0 || searchIndex >= numbersArray.count { return nil }
            let quiz = Quiz(numbersArray[searchIndex])
            
            if !favs && quiz.level > RZQuizDatabase.currentLevel() {
                return nil
            }
            return quiz
        }
        return nil
    }
    
    func getNextUnplayed(fromFavorites: Bool) -> Quiz? {
        var next = getNext(fromFavorites: fromFavorites)
        while next != nil && next!.quizHasBeenPlayed() {
            next = next!.getNext(fromFavorites: fromFavorites)
        }
        
        if next == nil {
            //there aren't any unplayed after, so check if there is an unplayed before
            var previous = getPrevious(fromFavorites: fromFavorites)
            var attemptCount = 0
            while previous != nil && previous!.quizHasBeenPlayed() && attemptCount < 5 {
                previous = previous!.getPrevious(fromFavorites: fromFavorites)
            }
            return previous
        }
        
        return next
    }

}

///Owned by a Quiz. Contains 4 Options.
struct Question: Printable {
    
    let question: Query
    //"QUESTION" table
    let quizNumber: Int
    let number: Int
    let answer: String
    let category: Int
    let text: String
    var shuffledOptions: [Option] {
        get {
            var array: [Option] = []
            for option in WordBank.filter(WordCategory == category) {
                let wordText = option[WordText]
                array.append(Option(word: wordText))
            }
            return array.shuffled()
        }
    }
    
    var description: String {
        get{
            return "(Question \(number))[\(text)]"
        }
    }

    init(_ number: Int) {
        self.number = number
        
        question = Questions.filter(QuestionNumber == self.number)
        let data = question.select(QuizNumber, QuestionAnswer, QuestionCategory, QuestionText).first!
        quizNumber = data[QuizNumber]
        answer = data[QuestionAnswer]
        category = data[QuestionCategory].toInt()!
        text = data[QuestionText]
    }
    
}

///Owned by a Question. The smallest element of the database.
struct Option: Printable {
    
    let word: String
    var description: String {
        get{
            return word
        }
    }
    
    init(word: String) {
        self.word = word
    }
    
    func playAudio() {
        var success = UAPlayer().play(word, ofType: ".mp3", ifConcurrent: .Interrupt)
        if !success {
            UAPlayer().play(word.lowercaseString, ofType: ".mp3", ifConcurrent: .Interrupt)
        }
    }
    
}

extension Array {
    func shuffled() -> [T] {
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            swap(&list[i], &list[j])
        }
        return list
    }
}

extension Int {
    func threeCharacterString() -> String {
        let start = "\(self)"
        let length = count(start)
        if length == 1 { return "00\(start)" }
        else if length == 2 { return "0\(start)" }
        else { return start }
    }
}
