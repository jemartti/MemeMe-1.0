//
//  ViewController.swift
//  MemeMe-1.0
//
//  Created by Jacob Marttinen on 9/17/16.
//  Copyright © 2016 Jacob Marttinen. All rights reserved.
//

import UIKit


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var imagePickerView: UIImageView!
    @IBOutlet weak var topLabel: UITextField!
    @IBOutlet weak var bottomLabel: UITextField!
    
    @IBOutlet weak var topToolbar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    @IBOutlet weak var bottomToolbar: UIToolbar!
    @IBOutlet weak var cameraRollButton: UIBarButtonItem!
    @IBOutlet weak var cameraButton: UIBarButtonItem!

    
    // MARK: ViewController setup
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up top/bottom text attributes
        defineTextFieldAttributes(topLabel)
        defineTextFieldAttributes(bottomLabel)
        
        // Set up initial UI state
        shareButton.isEnabled = false
        topLabel.text = "TOP"
        bottomLabel.text = "BOTTOM"
    }
    
    // Sets a TextField to have the lovely Impact(ish) formatting
    func defineTextFieldAttributes(_ textField: UITextField) {
        // Defines Impact(ish) font, white with a black outline, size 40
        let memeTextAttributes = [
            NSStrokeColorAttributeName: UIColor.black,
            NSForegroundColorAttributeName: UIColor.white,
            NSFontAttributeName: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSStrokeWidthAttributeName: Float(-3.0)
        ] as [String : Any]
        
        textField.delegate = self
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = NSTextAlignment.center
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.subscribeToKeyboardNotifications()
    
        // Set up app lifecycle UI state
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
    }
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.unsubscribeFromKeyboardNotifications()
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    
    // MARK: Image Picker: Actions and Delegate Contract Fulfillment
    
    // Displays the photo picker
    @IBAction func pickAnImage(_ sender: UIBarButtonItem) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        
        // Determine whether we want to display the camera or the album picker
        if sender == cameraRollButton {
            pickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
        } else if sender == cameraButton {
            pickerController.sourceType = UIImagePickerControllerSourceType.camera
        }
        
        self.present(pickerController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            // If we were given a valid image, display it
            imagePickerView.image = image
            
            // Hurrah! We can share it now!
            shareButton.isEnabled = true
            
            // Clean up the UI state
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Clean up the UI state
        self.dismiss(animated: true, completion: nil)
    }
    
    
    // MARK: Text Field: Delegate Contract Fulfillment
    
    // Clear the text fields if they contain only default text
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField == topLabel && textField.text == "TOP") || (textField == bottomLabel && textField.text == "BOTTOM") {
            textField.text = ""
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Cleanup the UI state
        textField.resignFirstResponder()
        return true
    }
    
    
    // MARK: Meme: UI Actions
    
    func generateMemedImage() -> UIImage {
        // Hide UI elements
        topToolbar.isHidden = true
        bottomToolbar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        // Show UI elements
        topToolbar.isHidden = false
        bottomToolbar.isHidden = false
        
        return memedImage
    }
    
    
    // MARK: Share: Actions and Delegate Contract Fulfillment
    
    @IBAction func shareMeme(_ sender: AnyObject) {
        // Render the Meme
        let memedImage = self.generateMemedImage()
        
        // Load the Activity view
        let shareController = UIActivityViewController(activityItems: [memedImage], applicationActivities: nil)
        shareController.completionWithItemsHandler = { activity, success, items, error in
            if success {
                // We know original image exists because share button wouldn't be active
                save(
                    topText: self.topLabel.text!,
                    bottomText: self.bottomLabel.text!,
                    originalImage: self.imagePickerView.image!,
                    memedImage: memedImage
                )
            }
        }
        
        self.present(shareController, animated: true, completion: nil)
    }
    
    
    // MARK: Keyboard visibility
    
    // If we're editing the bottom label, we want to slide the view out of the way
    // This way, we don't obstruct the field we're editing
    func keyboardWillShow(_ notification: NSNotification) {
        if bottomLabel.isEditing {
            self.view.frame.origin.y -= getKeyboardHeight(notification: notification)
        }
    }
    
    // Every time the keyboard hides, reset the view position
    func keyboardWillHide(_ notification: NSNotification) {
        self.view.frame.origin.y = 0
    }
    
    // Calculates the height of the keyboard for the current device
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as!NSValue
        return keyboardSize.cgRectValue.height
    }
}
