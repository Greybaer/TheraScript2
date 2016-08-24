//
//  EditFavoriteViewController.swift
//  TheraScript
//
//  Created by Greybear on 10/13/15.
//  Copyright © 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit
import CoreData

class EditFavoriteViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    //Shorthand for the CoreData context
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
    }
    
    //Struct to hold the practice info we're editing
    var target = TSClient.Therapy()
    
    //Outlets
    @IBOutlet weak var PTName: UITextField!
    @IBOutlet weak var PTAddress: UITextField!
    @IBOutlet weak var PTPhone: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        //We're our own delegate
        PTName.delegate = self
        //We'll have to figure out how to handle textview input here soon
        PTAddress.delegate = self
        PTPhone.delegate = self
  }//viewDidLoad

    override func viewWillAppear(animated: Bool) {
        //Add a completion button to the nav bar
        //Adding nav items has to be done here because tabs don't reload on navigation between views
        
        let acceptButton = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "savePTInfo")
        navigationItem.rightBarButtonItem = acceptButton
        
        //Hide the toolbar here
        self.navigationController?.toolbarHidden = true
        
        //Populate the fields
        PTName.text = target.practiceName
        PTAddress.text = target.practiceAddress
        PTPhone.text = target.practicePhone
        
    }//viewWillAppear
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
    }//viewWillDisappear

    //***************************************************
    // Delegate Functions
    //***************************************************

    //TextView functions
    func textViewDidChange(textView: UITextView) {
        //We'll handle return here eventually
    }

    
    // Textfield functions
    //***************************************************
    // Handle returns by shifting focus
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField{
        case PTName:
            PTName.resignFirstResponder()
            PTAddress.becomeFirstResponder()
        case PTAddress:
            PTAddress.resignFirstResponder()
            PTPhone.becomeFirstResponder()
        case PTPhone:
            PTPhone.resignFirstResponder()
            PTName.becomeFirstResponder()
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
        
        //Make sure every field contains something as a basic integrity check
        if(PTName.text!.isEmpty || PTAddress.text!.isEmpty || PTPhone.text!.isEmpty){
            //Pop an error and return
            TSClient.sharedInstance().errorDialog(self, errTitle: "PT Information Entry Incomplete", action: "OK", errMsg: "One or more PT practice fields are incomplete. Please ensure that all fields are completed")
        }else{
            //Find the original entry that we edited
            //Build predicates for name and address so we can look for them
            let predicate1 = NSPredicate(format: "name = %@", self.target.practiceName)
            let predicate2 = NSPredicate(format: "address = %@", self.target.practiceAddress)
            
            //Now perform a fetch, looking for results that match
            let request = NSFetchRequest(entityName: "PTPractice")
            request.returnsObjectsAsFaults = false
            
            //Form the predicate search term
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate1, predicate2])
            
            //Get the entry
            let results : NSArray = try! sharedContext.executeFetchRequest(request)

            //Massage it into a PTPractice object
            var entry = results as! [PTPractice]
            
            //Update the entry with the edited info
            entry.first?.name = PTName.text!
            entry.first?.address = PTAddress.text!
            entry.first?.phone = PTPhone.text!
            
            //And save the context
            dispatch_async(dispatch_get_main_queue()) {
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
            //And pop back to the calling view
            self.navigationController?.popViewControllerAnimated(true)
        }
        
        /*
        if(PTName.text!.isEmpty || PTAddress.text!.isEmpty || PTPhone.text!.isEmpty){
            //Pop an error and return
            TSClient.sharedInstance().errorDialog(self, errTitle: "PT Information Entry Incomplete", action: "OK", errMsg: "One or more PT practice fields are incomplete. Please ensure that all fields are completed")
        }else{
            
            //Is this entry already saved to favorites?
            let duplicate = TSClient.sharedInstance().checkDuplicate()
            
            if !duplicate{
                //Populate the data structure for Core Data storage
                TSClient.sharedInstance().therapy.practiceName = PTName.text!
                TSClient.sharedInstance().therapy.practiceAddress = PTAddress.text!
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
               PTPhone.text = ""
            }else{
                //Show an error dialog to let the user know it's a duplicate
                TSClient.sharedInstance().errorDialog(self, errTitle: "Duplicate Entry", action: "OK", errMsg: "This practice is already in the favorites list")
            }
        }//if/else
    */
    }//savePTInfo
}//class
