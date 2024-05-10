//
//  ViewController.swift
//  WordScramble
//
//  Created by Rodrigo Cavalcanti on 02/04/24.
//

import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = [String]()
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        usedWords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords[indexPath.row]
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadWords()
        initializeGame()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(restartGame))
    }

    func loadWords() {
        if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
            if let startWords = try? String(contentsOf: startWordsURL) {
                allWords = startWords.components(separatedBy: "\n")
            }
        }

        if allWords.isEmpty {
            allWords = ["silkworm"]
        }
    }
    
    func initializeGame() {
        let defaults = UserDefaults.standard
        let previousTitle = defaults.string(forKey: "title")
        let previousUsedWords = defaults.stringArray(forKey: "usedWords")
        
        if let previousTitle, let previousUsedWords {
            title = previousTitle
            usedWords = previousUsedWords
        } else {
            title = allWords.randomElement()
            usedWords.removeAll(keepingCapacity: true)
            tableView.reloadData()
            saveToUserDefaults()
        }
    }
    
    @objc func restartGame() {
        title = allWords.randomElement()
        usedWords.removeAll(keepingCapacity: true)
        tableView.reloadData()
        saveToUserDefaults()
    }
    
    func saveToUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.setValue(title, forKey: "title")
        defaults.setValue(usedWords, forKey: "usedWords")
    }
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter Answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else {return}
            self?.submit(answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        if let title = title?.lowercased(), lowerAnswer != title {
            if lowerAnswer.count >= 3 {
                if isPossible(word: lowerAnswer) {
                    if isOriginal(word: lowerAnswer) {
                        if isReal(word: lowerAnswer) {
                            usedWords.insert(answer, at: 0)
                            
                            let indexPath = IndexPath(row: 0, section: 0)
                            tableView.insertRows(at: [indexPath], with: .automatic)
                            saveToUserDefaults()
                            
                            return
                        } else {
                            showErrorMessage(title: "Word not recognized", message: "You can't just make them up, you know!")
                        }
                    } else {
                        showErrorMessage(title: "Word used already", message: "Be more original!")
                    }
                } else {
                    showErrorMessage(title: "Word not possible", message: "You can't spell that word from \(title)")
                }
            } else {
                showErrorMessage(title: "Word is too short", message: "Don't be lazy!")
            }
        } else {
            showErrorMessage(title: "Word is the same", message: "Be more creative!")
        }
    }
    
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        return true
    }

    func isOriginal(word: String) -> Bool {
        return usedWords.first { $0.lowercased() == word.lowercased() } == nil
    }

    func isReal(word: String) -> Bool {
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        
        return misspelledRange.location == NSNotFound
    }
    
    func showErrorMessage(title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

