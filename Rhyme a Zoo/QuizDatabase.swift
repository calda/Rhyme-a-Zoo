//
//  QuizDatabase.swift
//  Rhyme a Zoo
//
//  Created by Cal on 6/30/15.
//  Copyright (c) 2015 Cal Stephens. All rights reserved.
//

import Foundation
//import SQLite

///Global database. QuizDatabase -> Quiz -> Question -> Option
let RZQuizDatabase = QuizDatabase()

//MARK: - Expressions and Keys for accessing data

///SQLite.swift wrapper for the legacy databace from the PC version of Rhyme a Zoo.
//private let sql = Database(NSBundle.mainBundle().pathForResource("LegacyDB", ofType: "db")!, readonly: true)
//QUIZ table
//private let Quizes = sql["QUIZ"]
//private let QuizNumber = Expression<Int>("QuizNo")
//private let QuizName = Expression<String>("Name")
//private let QuizLevel = Expression<Int>("Level")
//private let QuizRhymeText = Expression<String>("RhymeText")
//private let QuizDisplayOrder = Expression<Int>("D_ORDER")
//AUDIOTIME table
//private let AudioTime = sql["AUDIOTIME"]
//let AudioWord = Expression<Int>("Word")
//let AudioStartTime = Expression<Int>("StartTime")
//QUESTION table
//private let Questions = sql["Question"]
//private let QuestionNumber = Expression<Int>("QuestionNo")
//private let QuestionAnswer = Expression<String>("Answer")
//private let QuestionCategory = Expression<String>("Category")
//private let QuestionText = Expression<String>("QuestionText")
//WORDBANK table
//private let WordBank = sql["WORDBANK"]
//let WordText = Expression<String>("Word")
//let WordCategory = Expression<Int>("Category")

//User Data Keys managed by the database
let RZFavoritesKey           = "com.hearatale.raz.favorites"
let RZQuizResultsKey         = "com.hearatale.raz.quizResults"
let RZPercentCorrectKey      = "com.hearatale.raz.percentCorrect"
let RZQuizLevelKey           = "com.hearatale.raz.quizLevel"
let RZPlayerBalanceKey       = "com.hearatale.raz.balance"
let RZTotalMoneyEarnedKey    = "com.hearatale.raz.totalMoney"
let RZAnimalsKey             = "com.hearatale.raz.animals"
let RZZooLevelKey            = "com.hearatale.raz.animalLevel"
let RZKeeperNumberKey        = "com.hearatale.raz.keeperNumber"
let RZKeeperGenderKey        = "com.hearatale.raz.keeperGender"
let RZHasWatchedWelcomeVideo = "com.hearatale.raz.watchedWelcome"

func userKey(_ key: String, forUser user: User) -> String {
    let originalKey = key
    return "\(originalKey).\(user.ID)"
}

func userKey(_ key: String) -> String {
    return userKey(key, forUser: RZCurrentUser)
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
//        for level in 1...levelCount {
//            var displayOrderArray: [Int?] = [nil, nil, nil, nil, nil]
//            for quiz in Quizes.filter(QuizLevel == level) {
//                let quizNumber = quiz[QuizNumber]
//                let quizDisplayOrder = quiz[QuizDisplayOrder]
//                displayOrderArray[quizDisplayOrder - 1] = quizNumber
//            }
//            
//            for quiz in displayOrderArray {
//                if let quiz = quiz {
//                    quizNumberMap.append(quiz)
//                }
//            }
//        }
//        
//        
//        for quiz in Quizes.select(QuizNumber) {
//            quizNumberMap.append(quiz[QuizNumber])
//        }
    }
    
    func getQuiz(_ index: Int) -> Quiz {
        let number = quizNumberMap[index]
        return Quiz(number)
    }
    
    func getRhyme(_ index: Int) -> Rhyme {
        return getQuiz(index)
    }
    
    func quizesInLevel(_ level: Int) -> [Quiz?] {
        return []
//        var displayOrderArray: [Quiz!] = [nil, nil, nil, nil, nil]
//        for quiz in Quizes.filter(QuizLevel == level) {
//            let quizNumber = quiz[QuizNumber]
//            let quizDisplayOrder = quiz[QuizDisplayOrder]
//            displayOrderArray[quizDisplayOrder - 1] = Quiz(quizNumber)
//        }
//        return displayOrderArray.filter{ $0 != nil }
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
        return data.dictionary(forKey: userKey(RZQuizResultsKey)) as? [String : String] ?? [:]
    }
    
    func setQuizData(_ quizData: [String : String]) {
        data.setValue(quizData, forKey: userKey(RZQuizResultsKey))
    }
    
    func getFavorites() -> [Int] {
        return data.array(forKey: userKey(RZFavoritesKey)) as? [Int] ?? []
    }
    
    func setFavorites(_ favs: [Int]) {
        data.setValue(favs, forKey: userKey(RZFavoritesKey))
    }
    
    func isQuizFavorite(_ number: Int) -> Bool {
        if let favs = data.array(forKey: userKey(RZFavoritesKey)) as? [Int] {
            return favs.contains(number)
        }
        return false
    }
    
    func numberOfFavories() -> Int {
        if let favs = data.array(forKey: userKey(RZFavoritesKey)) as? [Int] {
            return favs.count
        }
        return 0
    }
    
    func currentLevel() -> Int {
        let level = data.integer(forKey: userKey(RZQuizLevelKey))
        if level == 0 {
            data.set(1, forKey: userKey(RZQuizLevelKey))
            return 1
        }
        return level
    }
    
    func setQuizLevel(_ level: Int) {
        data.set(level, forKey: userKey(RZQuizLevelKey))
    }
    
    @discardableResult
    func advanceLevelIfCurrentIsComplete() -> Bool {
        let current = currentLevel()
        let complete = quizesInLevel(currentLevel()).filter{ ($0?.quizHasBeenPlayed())! }.count == 5
        
        if complete {
            let newLevel = min(current + 1, levelCount)
            data.set(newLevel, forKey: userKey(RZQuizLevelKey))
        }
        return complete
    }
    
    //MARK: - Bank
    
    func getPlayerBalance() -> Double {
        return data.double(forKey: userKey(RZPlayerBalanceKey))
    }
    
    func changePlayerBalanceBy(_ amount: Double) {
        let current = getPlayerBalance()
        let new = current + amount
        data.set(new, forKey: userKey(RZPlayerBalanceKey))
    }
    
    func setPlayerBalance(_ value: Double) {
        data.set(value, forKey: userKey(RZPlayerBalanceKey))
    }
    
    func getTotalMoneyEarned() -> (gold: Int, silver: Int) {
        if let array = data.stringArray(forKey: userKey(RZTotalMoneyEarnedKey)) {
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
        data.setValue(array, forKey: userKey(RZTotalMoneyEarnedKey))
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
        if let array = data.array(forKey: userKey(RZAnimalsKey)) as? [String] {
            return array
        }
        //array doesn't exist
        data.setValue([], forKey: userKey(RZAnimalsKey))
        return []
    }
    
    func setOwnedAnimals(_ animals: [String]) {
        data.setValue(animals, forKey: userKey(RZAnimalsKey))
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
        data.setValue(animals, forKey: userKey(RZAnimalsKey))
    }
    
    func currentZooLevel() -> Int {
        let level = data.integer(forKey: userKey(RZZooLevelKey))
        if level == 0 {
            data.set(1, forKey: userKey(RZZooLevelKey))
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
            data.set(currentLevel + 1, forKey: userKey(RZZooLevelKey))
        }
        return complete
    }
    
    func setZooLevel(_ level: Int) {
        data.set(level, forKey: userKey(RZZooLevelKey))
    }
    
    //MARK: - Zookeeper
    
    func getKeeperGender() -> String {
        let gender = data.string(forKey: userKey(RZKeeperGenderKey))
        if gender == nil || (gender != "boy" && gender != "girl") {
            data.setValue("boy", forKey: userKey(RZKeeperGenderKey))
            return "boy"
        }
        return gender!
    }
    
    func setKeeperGender(_ gender: String) {
        data.setValue(gender, forKey: userKey(RZKeeperGenderKey))
    }
    
    func getKeeperNumber() -> Int {
        let number = data.integer(forKey: userKey(RZKeeperNumberKey))
        if number == 0 {
            data.setValue(1, forKey: userKey(RZKeeperNumberKey))
            return 1
        }
        return number
    }
    
    func setKeeperNumber(_ number: Int) {
        data.setValue(number, forKey: userKey(RZKeeperNumberKey))
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
        return data.bool(forKey: userKey(RZHasWatchedWelcomeVideo))
    }
    
    func setHasWatchedWelcomeVideo(_ status: Bool) {
        data.set(status, forKey: userKey(RZHasWatchedWelcomeVideo))
    }
    
    func getPercentCorrectArray() -> [String] {
        if let array = data.stringArray(forKey: userKey(RZPercentCorrectKey)) {
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
        data.setValue(array, forKey: userKey(RZPercentCorrectKey))
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
    
    //let quiz: Query
    
    ///"QUIZ" table
    let number: Int
    let name: String
    let level: Int
    var questions: [Question] {
        get {
            return []
//            var array: [Question] = []
//            for question in Questions.filter(QuizNumber == number) {
//                let questionNumber = question[QuestionNumber]
//                array.append(Question(questionNumber))
//            }
//            return array
        }
    }
    var description: String {
        get{
            return "(Quiz \(number))[\(name)]"
        }
    }
    
    init(_ number: Int) {
        self.number = number
        self.name = "Placeholder"
        self.level = 0
//        self.number = number
//        
//        quiz = Quizes.filter(QuizNumber == self.number)
//        let data = quiz.select(QuizName, QuizLevel).first!
//        self.name = data[QuizName]
//        self.level = data[QuizLevel]
    }
    
    var rhymeText: String {
        get{
            return "todo"
//            let data = quiz.select(QuizRhymeText).first!
//            return data[QuizRhymeText]
        }
    }
    
    var wordStartTimes: [Int] {
        get {
            return []
//            let data = AudioTime.filter(QuizNumber == self.number).select(AudioStartTime)
//            var array: [Int] = []
//            for word in data {
//                array.append(word[AudioStartTime])
//            }
//            return array
        }
    }
    
    func setFavoriteStatus(_ fav: Bool) {
        if var favs = data.array(forKey: userKey(RZFavoritesKey)) as? [Int] {
            if fav && !favs.contains(number) {
                favs.append(number)
                data.setValue(favs, forKey: userKey(RZFavoritesKey))
            } else if !fav && favs.contains(number) {
                let index = (favs as NSArray).index(of: number)
                favs.remove(at: index)
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
    
    func saveQuizResult(gold: Int, silver: Int) {
        var results: [String : String] = [:]
        if let resultsDict = data.dictionary(forKey: userKey(RZQuizResultsKey)) as? [String : String] {
            results = resultsDict
        }
        
        let resultString = "\(gold):\(silver)"
        results.updateValue(resultString, forKey: number.threeCharacterString)
        
        data.setValue(results, forKey: userKey(RZQuizResultsKey))
        
        //also update player balance
        let cashInflux = Double(gold) + (Double(silver) * 0.5)
        RZQuizDatabase.changePlayerBalanceBy(cashInflux)
        
        let (totalGold, totalSilver) = RZQuizDatabase.getTotalMoneyEarned()
        RZQuizDatabase.setTotalMoneyEarned(gold: totalGold + gold, silver: totalSilver + silver)
        
        RZUserDatabase.saveCurrentUserToLinkedClassroom()
    }
    
    func quizHasBeenPlayed() -> Bool {
        if let resultsDict = data.dictionary(forKey: userKey(RZQuizResultsKey)) as? [String : String] {
            return resultsDict.keys.contains(number.threeCharacterString)
        }
        return false
    }
    
    func getQuizResult() -> (gold: Int, silver: Int) {
        if let resultsDict = data.dictionary(forKey: userKey(RZQuizResultsKey)) as? [String : String] {
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
        
        if let favsArray = data.array(forKey: userKey(RZFavoritesKey)) as? [Int], favs {
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
    
    //let question: Query
    
    //"QUESTION" table
    let quizNumber: Int
    let number: Int
    var answer: String
    let category: Int
    var text: String
    fileprivate var options: [Option]
    var shuffledOptions: [Option] {
        get {
            return options.shuffled()
        }
    }
    
    var description: String {
        get{
            return "(Question \(number))[\(text)]"
        }
    }

    init(_ number: Int) {
        self.number = number
        
        self.quizNumber = 0
        self.answer = "Placeholder"
        self.category = 0
        self.text = "Placeholder"
        self.text = "Placeholder"
        self.options = []
//        
//        //get info for question
//        question = Questions.filter(QuestionNumber == self.number)
//        let data = question.select(QuizNumber, QuestionAnswer, QuestionCategory, QuestionText).first!
//        quizNumber = data[QuizNumber]
//        answer = data[QuestionAnswer]
//        category = data[QuestionCategory].toInt()!
//        text = data[QuestionText]
//        
//        //get options
//        var options: [Option] = []
//        for option in WordBank.filter(WordCategory == category) {
//            let wordText = option[WordText]
//            options.append(Option(word: wordText))
//        }
//        self.options = options
        
        
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
