//
//  AddFavoriteViewController.swift
//  TheraScript
//
//  Created by Greybear on 10/13/15.
//  Copyright © 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit
import CoreData

class AddFavoriteViewController: UIViewController, UITextFieldDelegate {

    //Variables
    //var kbUp = false
    
    //Shorthand for the CoreData context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }

    //Outlets
    @IBOutlet weak var PTName: UITextField!
    @IBOutlet weak var PTAddress: UITextField!
    @IBOutlet weak var PTCity: UITextField!
    @IBOutlet weak var PTState: UITextField!
    @IBOutlet weak var PTZip: UITextField!
    @IBOutlet weak var PTPhone: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        //We're our own delegate
        PTName.delegate = self
        PTAddress.delegate = self
        PTCity.delegate = self
        PTState.delegate = self
        PTZip.delegate = self
        PTPhone.delegate = self
  }//viewDidLoad

    override func viewWillAppear(animated: Bool) {
        //Add a completion button to the nav bar
        //Adding nav items has to be done here because tabs don't reload on navigation between views
        
        let acceptButton = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Plain, target: self, action: "savePTInfo")
        navigationItem.rightBarButtonItem = acceptButton
        
        //Hide the toolbar here
        self.navigationController?.toolbarHidden = true
        
        // Sign up for Keyboard notifications
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        //KB Hide Notification
        //NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillDisappear:", name: UIKeyboardWillHideNotification,
        //    object: nil)
        
    }//viewWillAppear
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //Remove us from keyboard notifications
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: "keyboardWillShow:", object: nil)
        //NSNotificationCenter.defaultCenter().removeObserver(self, name: "keyboardWillDisappear:", object: nil)
    }//viewWillDisappear

    //***************************************************
    // Delegate Functions
    //***************************************************

/*
    //Slide the picture up to show bottom textfields when the keyboard slides in
    func keyboardWillShow(notification: NSNotification){
        //Getting multiple notifications, so we'll add a test to make sure we only respond to the first one
        if (PTCity.editing || PTState.editing || PTZip.editing || PTPhone.editing ) && !kbUp{
            self.view.frame.origin.y -= TSClient.sharedInstance().getKeyboardHeight(notification)
            //Set the flag to block additional notifications for this session
            kbUp = true
            //println("Sliding Frame up: \(self.view.frame.origin.y)")
        }//if
    }//keyboardWillShow
    
    //...and slide it back down when the view requires
    func keyboardWillDisappear(notification: NSNotification){
        if PTPhone.isFirstResponder() && kbUp{
            //just reset the origin to zero since we're getting multiple notifications
            self.view.frame.origin.y = 0
            //reset the flag
            kbUp = false
            //println("Sliding Frame down: \(self.view.frame.origin.y)")
        }
    }//keyboardWillDisappear
*/
    //***************************************************
    // Handle returns by shifting focus
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField{
        case PTName:
            PTName.resignFirstResponder()
            PTAddress.becomeFirstResponder()
        case PTAddress:
            PTAddress.resignFirstResponder()
            PTCity.becomeFirstResponder()
        case PTCity:
            PTCity.resignFirstResponder()
            PTState.becomeFirstResponder()
        case PTState:
            PTState.resignFirstResponder()
            PTZip.becomeFirstResponder()
        case PTZip:
            PTZip.resignFirstResponder()
            PTPhone.becomeFirstResponder()
        case PTPhone:
            PTPhone.resignFirstResponder()
        default:
            PTName.becomeFirstResponder()
        }//switch
        return false
    }//shouldReturn

    //***************************************************
    //Handle formatting in phone and zip fields
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool{
        switch textField{
        case PTPhone:
            
            //Empty string? (backspace) allow it
            if string.isEmpty{
                return true
            }
            //Is the new input a number? If not, disallow it
            let isnum = Int(string)
            
            if isnum == nil{
                return false
            }
            
            // Adapted from http://stackoverflow.com/questions/27609104/xcode-swift-formatting-text-as-phone-number
            let newString = (textField.text as NSString!).stringByReplacingCharactersInRange(range, withString: string)
            let components = newString.componentsSeparatedByCharactersInSet(NSCharacterSet.decimalDigitCharacterSet().invertedSet)
            
            let decimalString = components.joinWithSeparator("") as NSString
            let length = decimalString.length
            let hasLeadingOne = length > 0 && decimalString.characterAtIndex(0) == 49 //unichar value of 1
            
            if length == 0 || (length > 10 && !hasLeadingOne) || length > 11{
                let newLength = (textField.text as NSString!).length + (string as NSString).length - range.length as Int
                
                return (newLength > 10) ? false : true
            }
            var index = 0 as Int
            let formattedString = NSMutableString()
            
            //If no leading one add one
            if !hasLeadingOne{
                formattedString.appendString("1")
            }
            
            if hasLeadingOne{
                formattedString.appendString("1")
                index += 1
            }
            
            if (length - index) > 3{
                let areaCode = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("(%@)", areaCode)
                index += 3
            }
            
            if length - index > 3{
                let prefix = decimalString.substringWithRange(NSMakeRange(index, 3))
                formattedString.appendFormat("%@-", prefix)
                index += 3
            }
            
            let remainder = decimalString.substringFromIndex(index)
            formattedString.appendString(remainder)
            textField.text = formattedString as String
            return false
            
        case PTState:
            //Empty string? return it (backspace)
            if string.isEmpty{
                return true
            }
            
            //2 letters only
            let isnum = Int(string)
            if isnum != nil{
                return false
            }
            
            //An make it 2 chars long
            let newLength = textField.text!.characters.count + string.characters.count - range.length
            if (newLength > 2){
                return false
            }
            //Make sure it's all uppercase
            textField.text = textField.text! + string.uppercaseString
            return false
            
        case PTZip:
            //Empty string? return it (backspace)
            if string.isEmpty{
                return true
            }
            //Is the new input a number? If not, disallow it
            let isnum = Int(string)
            
            if isnum == nil{
                return false
            }
            
            //Is the length greater than 5? If so, disallow it
            let newLength = textField.text!.characters.count + string.characters.count - range.length
            if (newLength > 5){
                return false
            }
            return true
        default:
            return true
        }//switch
    }//shouldChangeCharactersInRange
    
    //***************************************************
    // Action Functions
    //***************************************************
    
    //***************************************************
    // savePTInfo - Save the manually entered practice info
    func savePTInfo(){
        if(PTName.text!.isEmpty || PTAddress.text!.isEmpty || PTCity.text!.isEmpty || PTState.text!.isEmpty || PTZip.text!.isEmpty || PTPhone.text!.isEmpty){
            //Pop an error and return
            TSClient.sharedInstance().errorDialog(self, errTitle: "PT Information Entry Incomplete", action: "OK", errMsg: "One or more PT practice fields are incomplete. Please ensure that all fields are completed")
        }else{
            
            //Is this entry already saved to favorites?
            let duplicate = TSClient.sharedInstance().checkDuplicate()
            
            if !duplicate{
                //Populate the data structure for Core Data storage
                TSClient.sharedInstance().therapy.practiceName = PTName.text!
                TSClient.sharedInstance().therapy.practiceAddress = "\(PTAddress.text!) \(PTCity.text!) \(PTState.text!) \(PTZip.text!)"
                TSClient.sharedInstance().therapy.practicePhone = PTPhone.text!

                //We'll do the add ourselves here rather than in the confirmation dialog
                //The user already has implicitly chosen to add it
                TSClient.sharedInstance().addFavorite()
                
                //And empty it out once saved, so we don't add it to the prescription
                TSClient.sharedInstance().therapy.practiceName = ""
                TSClient.sharedInstance().therapy.practiceAddress = ""
                TSClient.sharedInstance().therapy.practicePhone = ""
                
                //We don't go away in order to allow multiple adds if desired,
                //but clear the fields and display a success dialog
                TSClient.sharedInstance().errorDialog(self, errTitle: "Favorite Added", action: "OK", errMsg: "Practice added to Favorites List")
                PTName.text = ""
                PTAddress.text = ""
                PTCity.text = ""
                PTState.text = ""
                PTZip.text = ""
                PTPhone.text = ""
            }else{
                //Show an error dialog to let the user know it's a duplicate
                TSClient.sharedInstance().errorDialog(self, errTitle: "Duplicate Entry", action: "OK", errMsg: "This practice is already in the favorites list")
            }
        }//if/else
    }//savePTInfo
}//class
