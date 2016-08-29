//
//  RxGeneratorViewController.swift
//  TheraScript
//
//  Created by Greybear on 8/22/15.
//  Copyright (c) 2015 Infinite Loop, LLC. All rights reserved.
//

import UIKit
import MessageUI

class RxGeneratorViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    //Variables
    //Provider data struct
    var provider =  TSClient.Provider()
    
    var icon: UIImage?
    
    //The icon size
    var iconSize = CGSizeMake(64.0, 64.0)

    //Outlets
    //Provider info
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var providerName: UILabel!
    @IBOutlet weak var providerPractice: UILabel!
    @IBOutlet weak var providerAddress: UILabel!
    @IBOutlet weak var providerAddress2: UILabel!
    @IBOutlet weak var rxDate: UILabel!
    
    //Patient Info
    @IBOutlet weak var ptName: UILabel!
    @IBOutlet weak var ptPhone: UILabel!
    
    //Therapy Practice info
    @IBOutlet weak var PTPractice: UILabel!
    @IBOutlet weak var PTAddress: UILabel!
    @IBOutlet weak var PTPhone: UILabel!
    
    //Diagnosis list
    @IBOutlet weak var dxLabel1: UILabel!
    @IBOutlet weak var dxLabel2: UILabel!
    @IBOutlet weak var dxLabel3: UILabel!

    
    //Prescription info
    @IBOutlet var RxView: UIView!
    @IBOutlet weak var visits: UILabel!
    @IBOutlet weak var report: UILabel!
    @IBOutlet weak var rxInstructions: UILabel!
    
    //Transmission buttons
    @IBOutlet weak var printRx: UIBarButtonItem!
    @IBOutlet weak var textRx: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        //Determine and configure the date
        //Get the timestamp
        let dateStamp = NSDate()
        //Configure the formtter
        let dateFormatter = NSDateFormatter()
        //Set the format
        dateFormatter.dateStyle = NSDateFormatterStyle.ShortStyle
        dateFormatter.timeStyle = .ShortStyle
        //And grab the date in readable form
        let dateString = dateFormatter.stringFromDate(dateStamp)
        //Finally, populate the date label
        rxDate.text = dateString
    }//viewDidLoad
    
    override func viewWillAppear(animated: Bool) {

        //This moves to specific buttons for each transmission function
        //Add a settings button to the nav bar
        //let settingsButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "sendSMS")
        
        //let settingsButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "sendPrescription")
        //self.navigationItem.rightBarButtonItem = settingsButton
        
        //Now, are we text enabled? 
        let sms = MFMessageComposeViewController.canSendText()
        //MMS enabled
        let mms = MFMessageComposeViewController.canSendAttachments()
        
        //We need at least one to work, so if neither work disable texting
        //Move this into the share function
        if sms == false || mms == false{
            textRx.enabled = false
        }
        else{
            textRx.enabled = true
        }
        
        //These are done here because the data may need to change between views
        //rather than loads
        
        //Load the provder data as we start up
        provider = TSClient.sharedInstance().getProviderInfo()
        
        //And the image
        icon = TSClient.Cache.imageCache.imageWithIdentifier(TSClient.Constants.userLogo)

        //We *should* always have provider info to get here, but just in case...
        //Empty field = no info
        if provider.firstName.isEmpty{
            //Pop an error dialog
            TSClient.sharedInstance().errorDialog(self, errTitle: "No Provider", action: "OK", errMsg: "Please set up provider information")
            //and return to the base screen
            self.navigationController?.popToRootViewControllerAnimated(true)
            
            //The user can elect to look at an empty prescription, so continue
        }else{
            //Populate the provider header
            iconImage.image = TSClient.sharedInstance().createIcon(icon!, size: iconSize)
            
            providerName.text = "\(provider.firstName) \(provider.middleName) \(provider.lastName) \(provider.degreeType)"
            providerPractice.text = provider.practiceName
            providerAddress.text = "\(provider.streetAddress)"
            providerAddress2.text = "\(provider.cityName) \(provider.stateName) \(provider.zipCode) ・ \(provider.phoneNumber)"
            
            //Populate the patient info
            ptName.text = TSClient.sharedInstance().patient.Name
            ptPhone.text = TSClient.sharedInstance().patient.Phone
            
            //Populate the therapist info
            PTPractice.text = TSClient.sharedInstance().therapy.practiceName
            PTAddress.text = TSClient.sharedInstance().therapy.practiceAddress
            PTPhone.text = TSClient.sharedInstance().therapy.practicePhone
            //println("|\(PTPhone.text)|")
            
            //Create an array of diagnosis strings
            var dxArray : [String?] = []
            
            //Populate the diagnosis list
            //First create an array of properly formatted strings
            for diagnosis in TSClient.sharedInstance().dxList{
                //Let's add descriptions, but trim them to a manageable length
                let icdString = diagnosis.description
                let trimmedICD = trim(icdString, length: 40)
                //Create a string we can append to our array
                //let dxString = diagnosis.icdCode + " - " + trimmedICD
                dxArray.append(diagnosis.icdCode + " - " + trimmedICD)
                //diagnosisList.text = diagnosisList.text! + diagnosis.icdCode + " - " + trimmedICD + "\n"

            }
            
            //Then assign the values of the array to the labels
            if dxArray.count > 2{
                dxLabel1.text = dxArray[0]
                dxLabel2.text = dxArray[1]
                dxLabel3.text = dxArray[2]
            }else if dxArray.count > 1{
                dxLabel1.text = dxArray[0]
                dxLabel2.text = dxArray[1]
            }else if dxArray.count > 0{
                dxLabel1.text = dxArray[0]
            }
            
            //Populate the prescription
            visits.text = String(Int(TSClient.sharedInstance().prescription.visits))
            report.text = TSClient.sharedInstance().prescription.report ? "Yes" : "No"

            //Create a text object, and place it in the UITextfield
            var rxString: String = ""
            
            //Look at the flags and add the text for each on that's set
            if TSClient.sharedInstance().prescription.modalities{
                rxString = rxString + TSClient.sharedInstance().prescriptionString.modalities + "\n"
            }
            if TSClient.sharedInstance().prescription.conditioning{
                rxString = rxString + TSClient.sharedInstance().prescriptionString.modalities + "\n"
            }
            if TSClient.sharedInstance().prescription.coreStab{
                rxString = rxString + TSClient.sharedInstance().prescriptionString.coreStab + "\n"
            }
            if TSClient.sharedInstance().prescription.manualTherapy{
                rxString = rxString + TSClient.sharedInstance().prescriptionString.manualTherapy + "\n"
            }
            if TSClient.sharedInstance().prescription.poolTherapy{
                rxString = rxString + TSClient.sharedInstance().prescriptionString.poolTherapy + "\n"
            }
            if TSClient.sharedInstance().prescription.neckSchool{
                rxString = rxString + TSClient.sharedInstance().prescriptionString.neckSchool + "\n"
            }
            if TSClient.sharedInstance().prescription.backSchool{
                rxString = rxString + TSClient.sharedInstance().prescriptionString.backSchool + "\n"
            }
/*
            //Checkmark city!
            //Values are the inverse of the saved state
            //(e.g. user selects a field = true, but hidden is the inverse)
            modalities.hidden = !TSClient.sharedInstance().prescription.modalities
            conditioning.hidden = !TSClient.sharedInstance().prescription.conditioning
            coreStab.hidden = !TSClient.sharedInstance().prescription.coreStab
            manualTherapy.hidden = !TSClient.sharedInstance().prescription.manualTherapy
            pool.hidden = !TSClient.sharedInstance().prescription.poolTherapy
            neckSchool.hidden = !TSClient.sharedInstance().prescription.neckSchool
            backSchool.hidden = !TSClient.sharedInstance().prescription.backSchool
            LSO.hidden = !TSClient.sharedInstance().prescription.lso
            TLSO.hidden = !TSClient.sharedInstance().prescription.tlso
            CTLSO.hidden = !TSClient.sharedInstance().prescription.ctlso
            TNS.hidden = !TSClient.sharedInstance().prescription.tns
            cSoftCollar.hidden = !TSClient.sharedInstance().prescription.cSoftCollar
            cHardCollar.hidden = !TSClient.sharedInstance().prescription.cHardCollar
 */
        }//if
    }//viewWillAppear
    
    //***************************************************
    // Delegate functions
    //***************************************************

    //***************************************************
    //Determines whether device is SMS enabled
    class func canSendText() -> Bool{
        return MFMessageComposeViewController.canSendText()
    }//canSendText
 
    //***************************************************
    //The message delegate handler
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResultCancelled.rawValue:
           TSClient.sharedInstance().errorDialog(controller, errTitle: "Message Cancelled", action: "OK", errMsg: "Message will not be sent")
            self.dismissViewControllerAnimated(true, completion: nil)
       case MessageComposeResultFailed.rawValue:
           TSClient.sharedInstance().errorDialog(controller, errTitle: "Message Send Failed", action: "OK", errMsg: "Message unable to be sent")
            self.dismissViewControllerAnimated(true, completion: nil)
        default:
            TSClient.sharedInstance().errorDialog(controller, errTitle: "Message Sent", action: "OK", errMsg: "Message sent successfully")
            self.dismissViewControllerAnimated(true, completion: nil)
       }//switch
    }//MessageControllerDidFinish
    
    //***************************************************
    // Action functions
    //***************************************************
    
    //***************************************************
    // Send a text message if device enabled
    @IBAction func sendSMS(){
        //Adapted from http://www.ioscreator.com/tutorials/send-sms-messages-tutorial-ios8-swift
        
        //create a message controller object
        let messageVC = MFMessageComposeViewController()
        messageVC.subject = TSClient.Constants.PTMessage + TSClient.sharedInstance().patient.Name
        //Create an NSData object from the view
        let attachment = dataFromView()
        //And attach it to the message
        messageVC.addAttachmentData(attachment, typeIdentifier: "images/png", filename: "PTRx.jpg")
        //We default to sending to the patient.
        messageVC.recipients = [TSClient.sharedInstance().patient.Phone]
        //Handle things ourselves
        messageVC.messageComposeDelegate = self
        //Present a modal view to complete the process
        self.presentViewController(messageVC, animated: false, completion: nil)
    }//sendSMS
   
    //***************************************************
    // Print the prescription as a PDF file
    @IBAction func printRx(sender: AnyObject) {
        
        //We're going to print a PDF, so convert the view
        let pdfRx = pdfFromView()
              
        //create the controller
        let printVC = UIPrintInteractionController.sharedPrintController()

        //Landscape? Nope
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.orientation = .Landscape
        
        printVC.printInfo = printInfo
        
        //point the controller to the pdf data
        printVC.printingItem = pdfRx
        
        printVC.presentAnimated(true, completionHandler: nil)
    }//printRx
    
    //***************************************************
    // Helper functions
    //***************************************************
    
    //***************************************************
    // Trim a string to a certain length
    func trim(target : String, length: Int, trailing : String? = "..." )-> String{
        if target.characters.count > length{
            return target.substringToIndex(target.startIndex.advancedBy(length)) + (trailing ?? "")
        }else{
            return target
        }//check string length
    }
    
    //***************************************************
    // Transform the view into NSData for attachment
    func dataFromView() -> NSData {
        
        var image: UIImage?
        
        //Hide the tool and nav bar
        self.navigationController?.setToolbarHidden(true, animated: false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
        //Render the view to a single image
        UIGraphicsBeginImageContext(self.view.frame.size)
        self.view.drawViewHierarchyInRect(self.view.frame, afterScreenUpdates: true)
        image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        //Transform the image into NSData
        let data: NSData = UIImagePNGRepresentation(image!)!
        
        //Show tool and nav bar
        self.navigationController?.setToolbarHidden(false, animated: false)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
        //return the NSData object
        return data
    }//dataFromView
   
    //***************************************************
    // Transform the view into a PDF
    func pdfFromView() -> NSMutableData{
        
        //Creat a mutable data object
        let pdfData =  NSMutableData()
        
        //Point the pdf convertor to the data object and the view
        UIGraphicsBeginPDFContextToData(pdfData, self.view.bounds, nil)
        //Begin the page
        
        //Using this gives you a large centered print
        //UIGraphicsBeginPDFPage()
        
        //Using this gives you a small upper left print
        //UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, 792, 1122), nil)
        
        //Centered 5.5 x 8.5 - image too big/rectangle too small
        //UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, 396, 612), nil)
        
        //5 x 7 - worse
        //UIGraphicsBeginPDFPageWithInfo(CGRectMake(0, 0, 396, 504), nil)
        
        //6 x 11 - BINGO!
        //UIGraphicsBeginPDFPageWithInfo(CGRectMake(-36, -72, 432, 792), nil)
        
        //Let's try making rectangle a bit bigger - this is even better
        UIGraphicsBeginPDFPageWithInfo(CGRectMake(-54, -36, 504, 864), nil)
        
        //get the context
        let pdfContext = UIGraphicsGetCurrentContext()
        //draw rect to view and capture with context
        self.view.layer.renderInContext(pdfContext!)
        //End the page
        UIGraphicsEndPDFContext()

        //return the pdf data
        return pdfData
    }//pdfFromView
    
}//class

