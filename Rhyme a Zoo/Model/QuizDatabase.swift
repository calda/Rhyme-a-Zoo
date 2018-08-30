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

//MARK: - Expressions and Keys for accessing data

///SQLite.swift wrapper for the legacy databace from the PC version of Rhyme a Zoo.
fileprivate enum SQL {
    
    static let database = try! Connection(Bundle.main.path(forResource: "LegacyDB", ofType: "db")!, readonly: true)
    
    enum Quiz {
        static let table = Table("QUIZ")
        
        static let number = Expression<Int>("QuizNo")
        static let name = Expression<String>("Name")
        static let level = Expression<Int>("Level")
        static let rhymeText = Expression<String>("RhymeText")
        static let displayOrder = Expression<Int>("D_ORDER")
    }
    
    enum AudioTime {
        static let table = Table("AUDIOTIME")
        static let word = Expression<Int>("Word")
        static let startTime = Expression<Int>("StartTime")
    }
    
    enum Question {
        static let table = Table("Question")
        static let number = Expression<Int>("QuestionNo")
        static let quizNumber = Expression<Int>("QuizNo")
        static let answer = Expression<String>("Answer")
        static let category = Expression<String>("Category")
        static let text = Expression<String>("QuestionText")
    }
    
    enum WordBank {
        static let table = Table("WORDBANK")
        static let word = Expression<String>("Word")
        static let category = Expression<Int>("Category")
    }
    
}

/// SQLite helpers
extension SQLite.Table {
    
    var array: [Row] {
        guard let databaseResult = try? SQL.database.prepare(self) else {
            fatalError("Could not access SQLite database.")
        }
        
        return Array(databaseResult)
    }
    
    func filtered(by expression: Expression<Bool>) -> Table {
        return self.filter(expression)
    }
    
}


//User Data Keys managed by the database

fileprivate enum Key: String {
    case favorites              = "com.hearatale.raz.favorites"
    case quizResults            = "com.hearatale.raz.quizResults"
    case percentCorrect         = "com.hearatale.raz.percentCorrect"
    case quizLevel              = "com.hearatale.raz.quizLevel"
    case playerBalance          = "com.hearatale.raz.balance"
    case totalMoneyEarned       = "com.hearatale.raz.totalMoney"
    case animals                = "com.hearatale.raz.animals"
    case zooLevel               = "com.hearatale.raz.animalLevel"
    case keeperNumber           = "com.hearatale.raz.keeperNumber"
    case keeperGender           = "com.hearatale.raz.keeperGender"
    case hasWatchedWelcomeVideo = "com.hearatale.raz.watchedWelcome"
    
    func forUser(_ user: User) -> String {
        return "\(self).\(user.ID)"
    }
    
    var forCurrentUser: String {
        return self.forUser(RZCurrentUser)
    }
}


//MARK: - Reading quiz data from the SQL database

///Top level database structure. Globally available at RZQuizDatabase. Contains many Quizes.
///Quiz Database -> Quiz -> Question -> Option
class QuizDatabase {
    
    fileprivate var quizNumberMap: [Int] = []
    var count: Int {
        get {
            return quizNumberMap.count
        }
    }
    var levelCount: Int = 24 //24 levels. This is just a fact.
    
    
    //any question in this array will override a question from the LegacyDB
    var dbOverride: [String : (text: String, options: [String])] = [:]
    
    
    init() {
        //load DB Override before loading questions
        let overrideFile = Bundle.main.url(forResource: "DB Override", withExtension: "csv")!
        let csv = csvToArray(overrideFile)
        for line in csv {
            let splits = line.split{ $0 == "," }.map { String($0) }
            let number = splits[0]
            let text = splits[1]
            let options = [splits[2], splits[3], splits[4], splits[5]]
            
            dbOverride.updateValue((text: text, options: options), forKey: number)
        }
        
        
        //load rhymes and questions
        for level in 1...levelCount {
            var displayOrderArray: [Int?] = [nil, nil, nil, nil, nil]
            
            for quiz in SQL.Quiz.table.filtered(by: SQL.Quiz.level == level).array {
                let quizNumber = quiz[SQL.Quiz.number]
                let quizDisplayOrder = quiz[SQL.Quiz.displayOrder]
                displayOrderArray[quizDisplayOrder - 1] = quizNumber
            }
            
            for quiz in displayOrderArray {
                if let quiz = quiz {
                    quizNumberMap.append(quiz)
                }
            }
        }
        
        for quiz in SQL.Quiz.table.select([SQL.Quiz.number]).array {
            quizNumberMap.append(quiz[SQL.Quiz.number])
        }
    }
    
    func getQuiz(_ index: Int) -> Quiz {
        let number = quizNumberMap[index]
        return Quiz(number)
    }
    
    func getRhyme(_ index: Int) -> Rhyme {
        return getQuiz(index)
    }
    
    func quizesInLevel(_ level: Int) -> [Quiz] {
        var displayOrderArray: [Quiz?] = [nil, nil, nil, nil, nil]
        
        for quiz in SQL.Quiz.table.filtered(by: SQL.Quiz.level == level).array {
            let quizNumber = quiz[SQL.Quiz.number]
            let quizDisplayOrder = quiz[SQL.Quiz.displayOrder]
            displayOrderArray[quizDisplayOrder - 1] = Quiz(quizNumber)
        }
        
        return displayOrderArray.compactMap { $0 }
    }
    
    func getIndexForRhyme(_ rhyme: Rhyme) -> Int {
        for i in 0 ..< quizNumberMap.count {
            if quizNumberMap[i] == rhyme.number {
                return i
            }
        }
        return -1
    }
    
    //MARK: - Player Data for Quizes
    
    func getQuizData() -> [String : String] {
        return data.dictionary(forKey: Key.quizResults.forCurrentUser) as? [String : String] ?? [:]
    }
    
    func setQuizData(_ quizData: [String : String]) {
        data.setValue(quizData, forKey: Key.quizResults.forCurrentUser)
    }
    
    func getFavorites() -> [Int] {
        return data.array(forKey: Key.favorites.forCurrentUser) as? [Int] ?? []
    }
    
    func setFavorites(_ favs: [Int]) {
        data.setValue(favs, forKey: Key.favorites.forCurrentUser)
    }
    
    func isQuizFavorite(_ number: Int) -> Bool {
        if let favs = data.array(forKey: Key.favorites.forCurrentUser) as? [Int] {
            return favs.contains(number)
        }
        return false
    }
    
    func numberOfFavories() -> Int {
        if let favs = data.array(forKey: Key.favorites.forCurrentUser) as? [Int] {
            return favs.count
        }
        return 0
    }
    
    func currentLevel() -> Int {
        let level = data.integer(forKey: Key.quizLevel.forCurrentUser)
        if level == 0 {
            data.set(1, forKey: Key.quizLevel.forCurrentUser)
            return 1
        }
        return level
    }
    
    func setQuizLevel(_ level: Int) {
        data.set(level, forKey: Key.quizLevel.forCurrentUser)
    }
    
    @discardableResult
    func advanceLevelIfCurrentIsComplete() -> Bool {
        let current = currentLevel()
        let levelIsComplete = quizesInLevel(currentLevel()).filter{ ($0.quizHasBeenPlayed()) }.count == 5
        
        if levelIsComplete {
            let newLevel = min(current + 1, levelCount)
            data.set(newLevel, forKey: Key.quizLevel.forCurrentUser)
        }
        
        return levelIsComplete
    }
    
    //MARK: - Bank
    
    func getPlayerBalance() -> Double {
        return data.double(forKey: Key.playerBalance.forCurrentUser)
    }
    
    func changePlayerBalanceBy(_ amount: Double) {
        let current = getPlayerBalance()
        let new = current + amount
        data.set(new, forKey: Key.playerBalance.forCurrentUser)
    }
    
    func setPlayerBalance(_ value: Double) {
        data.set(value, forKey: Key.playerBalance.forCurrentUser)
    }
    
    func getTotalMoneyEarned() -> (gold: Int, silver: Int) {
        if let array = data.stringArray(forKey: Key.totalMoneyEarned.forCurrentUser) {
            let dict = arrayToDict(array)
            if let gold = Int(dict["gold"] ?? "0"), let silver = Int(dict["silver"] ?? "0") {
                return (gold, silver)
            }
        }
        //unsuccessful
        return (0, 0)
    }
    
    func setTotalMoneyEarned(gold: Int, silver: Int) {
        let dict = ["gold" : "\(gold)", "silver" : "\(silver)"]
        let array = dictToArray(dict)
        data.setValue(array, forKey: Key.totalMoneyEarned.forCurrentUser)
    }
    
    func getTotalMoneyEarnedArray() -> [String] {
        let (gold, silver) = getTotalMoneyEarned()
        let dict = ["gold" : "\(gold)", "silver" : "\(silver)"]
        return dictToArray(dict)
    }
    
    func setTotalMoneyEarnedFromArray(_ array: [String]) {
        let dict = arrayToDict(array)
        if let gold = Int(dict["gold"] ?? "0"), let silver = Int(dict["silver"] ?? "0") {
            setTotalMoneyEarned(gold: gold, silver: silver)
        }
    }
    
    //MARK: - Zoo Management
    
    func getOwnedAnimals() -> [String] {
        if let array = data.array(forKey: Key.animals.forCurrentUser) as? [String] {
            return array
        }
        //array doesn't exist
        data.setValue([], forKey: Key.animals.forCurrentUser)
        return []
    }
    
    func setOwnedAnimals(_ animals: [String]) {
        data.setValue(animals, forKey: Key.animals.forCurrentUser)
    }
    
    func playerOwnsAnimal(_ animal: String) -> Bool {
        return getOwnedAnimals().contains(animal)
    }
    
    func canAffordAnimal() -> Bool {
        let zooLevel = currentZooLevel()
        let requiredBalance = zooLevel == 8 ? 10.0 : 20.0
        return getPlayerBalance() >= requiredBalance
    }
    
    func purchaseAnimal(_ animal: String) {
        if !canAffordAnimal() { return }
        
        let zooLevel = currentZooLevel()
        let requiredBalance = zooLevel == 8 ? 10.0 : 20.0
        changePlayerBalanceBy(-requiredBalance)
        var animals = getOwnedAnimals()
        animals.append(animal)
        data.setValue(animals, forKey: Key.animals.forCurrentUser)
    }
    
    func currentZooLevel() -> Int {
        let level = data.integer(forKey: Key.zooLevel.forCurrentUser)
        if level == 0 {
            data.set(1, forKey: Key.zooLevel.forCurrentUser)
            return 1
        }
        return level
    }
    
    func advanceCurrentLevelIfComplete(_ animals: [String]) -> Bool {
        var complete = true
        for animal in animals {
            complete = complete && playerOwnsAnimal(animal)
        }
        if complete {
            let currentLevel = currentZooLevel()
            data.set(currentLevel + 1, forKey: Key.zooLevel.forCurrentUser)
        }
        return complete
    }
    
    func setZooLevel(_ level: Int) {
        data.set(level, forKey: Key.zooLevel.forCurrentUser)
    }
    
    //MARK: - Zookeeper
    
    func getKeeperGender() -> String {
        let gender = data.string(forKey: Key.keeperGender.forCurrentUser)
        if gender == nil || (gender != "boy" && gender != "girl") {
            data.setValue("boy", forKey: Key.keeperGender.forCurrentUser)
            return "boy"
        }
        return gender!
    }
    
    func setKeeperGender(_ gender: String) {
        data.setValue(gender, forKey: Key.keeperGender.forCurrentUser)
    }
    
    func getKeeperNumber() -> Int {
        let number = data.integer(forKey: Key.keeperNumber.forCurrentUser)
        if number == 0 {
            data.setValue(1, forKey: Key.keeperNumber.forCurrentUser)
            return 1
        }
        return number
    }
    
    func setKeeperNumber(_ number: Int) {
        data.setValue(number, forKey: Key.keeperNumber.forCurrentUser)
    }
    
    func getKeeperString() -> String {
        return "\(getKeeperGender())~\(getKeeperNumber())"
    }
    
    func setKeeperWithString(_ string: String) {
        let splits = string.split{ $0 == "~" }.map { String($0) }
        let gender = splits[0]
        setKeeperGender(gender)
        if let number = Int(splits[1]) {
            setKeeperNumber(number)
        }
    }
    
    //MARK: - User Statistics
    
    func hasWatchedWelcomeVideo() -> Bool {
        return data.bool(forKey: Key.hasWatchedWelcomeVideo.forCurrentUser)
    }
    
    func setHasWatchedWelcomeVideo(_ status: Bool) {
        data.set(status, forKey: Key.hasWatchedWelcomeVideo.forCurrentUser)
    }
    
    func getPercentCorrectArray() -> [String] {
        if let array = data.stringArray(forKey: Key.percentCorrect.forCurrentUser) {
            if array.count != 4 {
                //create a new dictionary
                let dict = ["totalComprehension" : "0", "correctComprehension" : "0", "totalPhonetic" : "0", "correctPhonetic" : "0"]
                let array = dictToArray(dict)
                setPercentCorrectArray(array)
                return array
            }
            return array
        }
        else {
            //create a new dictionary
            let dict = ["totalComprehension" : "0", "correctComprehension" : "0", "totalPhonetic" : "0", "correctPhonetic" : "0"]
            let array = dictToArray(dict)
            setPercentCorrectArray(array)
            return array
        }
    }
    
    func setPercentCorrectArray(_ array: [String]) {
        data.setValue(array, forKey: Key.percentCorrect.forCurrentUser)
    }
    
    func getPercentCorrectDict() -> [String : Int] {
        let array = getPercentCorrectArray()
        let stringDict = arrayToDict(array)
        var dict: [String : Int] = [:]
        for (key, value) in stringDict {
            if let int = Int(value) {
                dict[key] = int
            }
        }
        return dict
    }
    
    func updatePercentCorrect(_ question: Question, correct: Bool) {
        var dict = getPercentCorrectDict()
        let isPhonetic = question.isPhonetic()
        let totalKey = isPhonetic ? "totalPhonetic" : "totalComprehension"
        let correctKey = isPhonetic ? "correctPhonetic" : "correctComprehension"
        dict[totalKey] = (dict[totalKey] ?? 0) + 1
        dict[correctKey] = (dict[correctKey] ?? 0) + (correct ? 1 : 0)
        
        //turn [String : String] into [String : Int]
        var stringDict: [String : String] = [:]
        for (key, int) in dict {
            stringDict[key] = "\(int)"
        }

        setPercentCorrectArray(dictToArray(stringDict))
    }
    
}

//MARK: - Quiz / Rhyme Data

typealias Rhyme = Quiz

///Avaliable though RZQuizDatabase. Contains 4 Questions.
struct Quiz : CustomStringConvertible {
    
    let quiz: Row
    
    ///"QUIZ" table
    let number: Int
    let name: String
    let level: Int
    
    var questions: [Question] {
        get {
            var array: [Question] = []
            for question in SQL.Question.table.filtered(by: SQL.Question.quizNumber == number).array {
                let questionNumber = question[SQL.Question.number]
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
        guard let quiz = SQL.Quiz.table.filtered(by: SQL.Quiz.number == number).array.first else {
            fatalError("Could not load quiz \(number)")
        }
        
        self.number = number
        self.quiz = quiz
        self.name = quiz[SQL.Quiz.name]
        self.level = quiz[SQL.Quiz.level]
    }
    
    var rhymeText: String {
        get{
            return quiz[SQL.Quiz.rhymeText]
        }
    }
    
    var wordStartTimes: [Int] {
        get {
            let data = SQL.AudioTime.table.filtered(by: SQL.Quiz.number == self.number).array
            var array: [Int] = []
            for word in data {
                array.append(word[SQL.AudioTime.startTime])
            }
            return array
        }
    }
    
    func setFavoriteStatus(_ fav: Bool) {
        if var favs = data.array(forKey: Key.favorites.forCurrentUser) as? [Int] {
            if fav && !favs.contains(number) {
                favs.append(number)
                data.setValue(favs, forKey: Key.favorites.forCurrentUser)
            } else if !fav && favs.contains(number) {
                let index = (favs as NSArray).index(of: number)
                favs.remove(at: index)
                data.setValue(favs, forKey: Key.favorites.forCurrentUser)
            }
        }
        else {
            //favs array doesn't exist
            let favs = [number]
            data.setValue(favs, forKey: Key.favorites.forCurrentUser)
        }
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    func isFavorite() -> Bool {
        return RZQuizDatabase.isQuizFavorite(number)
    }
    
    func saveQuizResult(gold: Int, silver: Int) {
        var results: [String : String] = [:]
        if let resultsDict = data.dictionary(forKey: Key.quizResults.forCurrentUser) as? [String : String] {
            results = resultsDict
        }
        
        let resultString = "\(gold):\(silver)"
        results.updateValue(resultString, forKey: number.threeCharacterString)
        
        data.setValue(results, forKey: Key.quizResults.forCurrentUser)
        
        //also update player balance
        let cashInflux = Double(gold) + (Double(silver) * 0.5)
        RZQuizDatabase.changePlayerBalanceBy(cashInflux)
        
        let (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        RZQuizDatabase.setTotalMoneyEarned(gold: totalGold + gold, silver: totalSilver + silver)
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    func quizHasBeenPlayed() -> Bool {
        if let resultsDict = data.dictionary(forKey: Key.quizResults.forCurrentUser) as? [String : String] {
            return resultsDict.keys.contains(number.threeCharacterString)
        }
        return false
    }
    
    func getQuizResult() -> (gold: Int, silver: Int) {
        if let resultsDict = data.dictionary(forKey: Key.quizResults.forCurrentUser) as? [String : String] {
            if let result = resultsDict[number.threeCharacterString] {
                let splits = result.split{ $0 == ":" }.map { String($0) }
                if splits.count == 2 {
                    let gold = Int(splits[0])
                    let silver = Int(splits[1])
                    
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
    
    func getWithOffsetIndex(_ offset: Int, fromFavorites favs: Bool) -> Quiz? {
        var numbersArray = RZQuizDatabase.quizNumberMap
        
        if let favsArray = data.array(forKey: Key.favorites.forCurrentUser) as? [Int], favs {
            numbersArray = favsArray
        }
        
        if let thisIndex = numbersArray.index(of: self.number) {
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
    
    func getNextUnplayed(_ fromFavorites: Bool) -> Quiz? {
        var next = getNext(fromFavorites: fromFavorites)
        while next != nil && next!.quizHasBeenPlayed() {
            next = next!.getNext(fromFavorites: fromFavorites)
        }
        
        if next == nil {
            //there aren't any unplayed after, so check if there is an unplayed before
            var previous = getPrevious(fromFavorites: fromFavorites)
            let attemptCount = 0
            while previous != nil && previous!.quizHasBeenPlayed() && attemptCount < 5 {
                previous = previous!.getPrevious(fromFavorites: fromFavorites)
            }
            return previous
        }
        
        return next
    }

}

///Owned by a Quiz. Contains 4 Options.
struct Question: CustomStringConvertible {
    
    let question: Row
    
    //"QUESTION" table
    let quizNumber: Int
    let number: Int
    var answer: String
    let category: Int
    var text: String
    
    fileprivate var options: [Option]
    
    var shuffledOptions: [Option] {
        return options.shuffled()
    }
    
    var description: String {
        return "(Question \(number))[\(text)]"
    }

    init(_ number: Int) {
        //get info for question
        guard let question = SQL.Question.table.filtered(by: SQL.Question.number == number).array.first else {
            fatalError("Could not load question \(number)")
        }
        
        self.number = number
        self.question = question
        self.quizNumber = question[SQL.Question.quizNumber]
        self.answer = question[SQL.Question.answer]
        self.category = Int(question[SQL.Question.category]) ?? 0
        self.text = question[SQL.Question.text]
        
        //get options
        var options: [Option] = []
        for option in SQL.WordBank.table.filtered(by: SQL.WordBank.category == self.category).array {
            let wordText = option[SQL.WordBank.word]
            options.append(Option(word: wordText))
        }
        self.options = options
        
        
        //check DB Override
        if let (overrideText, overrideOptions) = RZQuizDatabase.dbOverride["\(self.number)"] {
            self.text = overrideText
            
            self.options = []
            for optionText in overrideOptions {
                if optionText.uppercased() == optionText {
                    //is phonetic option
                    self.options.append(Option(word: "sound-\(optionText)"))
                }
                else {
                    self.options.append(Option(word: optionText))
                }
            }
            
            self.answer = self.options[0].word
        }
        
    }
    
    func isPhonetic() -> Bool {
        var phonetic = true
        
        for option in options {
            if option.word != option.word.uppercased() {
                //if the option is not 100% uppercase
                //then it isn't a phonetic question
                phonetic = false
            }
        }
        
        return phonetic
    }
    
}

///Owned by a Question. The smallest element of the database.
struct Option: CustomStringConvertible {
    
    let rawWord: String
    
    var word: String {
        //check for phonetic answer
        //format: sound-I-short
        //or: sound-P
        
        if rawWord.hasPrefix("sound-") {
            let splits = rawWord.split{ $0 == "-" }.map { String($0) }
            return splits[1]
        }
        else { return rawWord }
    }
    
    var description: String {
        get{
            return word
        }
    }
    
    init(word: String) {
        self.rawWord = word
    }
    
    func playAudio() {
        let success = UAPlayer().play(rawWord, ofType: ".mp3", ifConcurrent: .interrupt)
        if !success {
            UAPlayer().play(rawWord.lowercased(), ofType: ".mp3", ifConcurrent: .interrupt)
        }
    }
    
}
