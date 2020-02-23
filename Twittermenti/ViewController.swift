//
//  ViewController.swift
//  Twittermenti
//
//  Created by Angela Yu on 17/07/2019.
//  Copyright © 2019 London App Brewery. All rights reserved.
//

import UIKit
import SwifteriOS
import CoreML
import SwiftyJSON

class ViewController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var sentimentLabel: UILabel!
    
    let tweetCount = 100
    
    let sentimentClassifier = TweetSentimentClassifier()
    
    var swifter: Swifter? {
        
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml //Format of the Property List.
        var plistData: [String: AnyObject] = [:] //Our data
        let plistPath: String? = Bundle.main.path(forResource: "Secrets", ofType: "plist")! //the path of the data
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do {//convert the data to a dictionary and handle errors.
            plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat) as! [String:AnyObject]
            
            let apiKey = plistData["API KEY"] as! String
            let apiSecret = plistData["API Secret"] as! String
            return Swifter(consumerKey: apiKey, consumerSecret: apiSecret)

        } catch {
            print("Error reading plist: \(error), format: \(propertyListFormat)")
            return nil
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func predictPressed(_ sender: Any) {
    
        fetchTweets()
    }
    
    func fetchTweets() {
        
        if let searchText = textField.text {
            if let myswifter = swifter {
                myswifter.searchTweet(using: searchText, lang: "en", count: tweetCount, tweetMode: .extended,success: { (results, metadata) in
                   
                    var tweets = [TweetSentimentClassifierInput]()
                    
                    for i in 0..<self.tweetCount {
                        if let tweet = results[i]["full_text"].string {
                            let tweetForClassification = TweetSentimentClassifierInput(text: tweet)
                            tweets.append(tweetForClassification)
                        }
                    }
                    
                    self.makePrediction(with: tweets)
                     
                    
                    
                }) { (error) in
                    print("There was a error with the Twitter API Request. \(error)")
                }
            }
        }
    }
    
    func makePrediction(with tweets: [TweetSentimentClassifierInput]) {
        do {
            let predictions = try self.sentimentClassifier.predictions(inputs: tweets)
            
            var sentimentScore = 0
            
            for pred in predictions {
                let sentiment = pred.label
                
                if sentiment == "Pos" {
                    sentimentScore += 1
                } else if sentiment == "Neg" {
                    sentimentScore -= 1
                }
            }
            
            print(sentimentScore)
            updateUI(with: sentimentScore)
            
            
        } catch {
            print("There was an error with making a prediction, \(error)")
        }
    }
    
    func updateUI(with sentimentScore: Int) {
        
        if sentimentScore > 20 {
            self.sentimentLabel.text = "😍"
        } else if sentimentScore > 10 {
            self.sentimentLabel.text = "😀"
        } else if sentimentScore > 0 {
            self.sentimentLabel.text = "🙂"
        } else if sentimentScore == 0 {
            self.sentimentLabel.text = "😐"
        } else if sentimentScore > -10 {
            self.sentimentLabel.text = "😕"
        } else if sentimentScore > -20 {
            self.sentimentLabel.text = "😡"
        } else {
            self.sentimentLabel.text = "🤮"
        }
    }
    
}

