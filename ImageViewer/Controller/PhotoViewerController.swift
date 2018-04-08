//
//  PhotoViewerController.swift
//  ImageViewer
//
//  Created by Screencast on 9/29/17.
//  Copyright © 2017 Treehouse. All rights reserved.
//

import UIKit
import CoreData

class PhotoViewerController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var indicatorLengthTextField: UITextField!
    @IBOutlet weak var objectLengthTextField: UILabel!
    var photo: Photo!
    
    var context: NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoImageView.image = photo.image
        titleTextField.text = photo.title
        indicatorLengthTextField.text = "\(photo.indicatorLength)"
        objectLengthTextField.text = "\(photo.objectLength)cm"
        
        indicatorLengthTextField.keyboardType = .decimalPad
    }
    
    @IBAction func launchPhotoZoomController(_ sender: Any) {
        guard let storyboard = storyboard else { return }
        
        let zoomController = storyboard.instantiateViewController(withIdentifier: "PhotoZoomController") as! PhotoZoomController
        zoomController.modalTransitionStyle = .crossDissolve
        zoomController.photo = photo
        zoomController.context = self.context
        
        navigationController?.present(zoomController, animated: true, completion: nil)
    }
    
    @IBAction func changedTitle(_ sender: UITextField) {
        photo.title = titleTextField.text
        context.saveChanges()
    }
    
    @IBAction func changedIndicatorLength(_ sender: UITextField) {
        //Fix string to double
        guard let newIndicatorLength = Double("indicatorLengthTextField.text") else {
            print("Not good"); return }
        photo.indicatorLength = newIndicatorLength
        photo.objectLength = objectLength()
        context.saveChanges()
    }
    
    @IBAction func deletePhoto(_ sender: UIButton) {
        if let photo = photo {
            context.delete(photo)
            context.saveChanges()
            navigationController?.popViewController(animated: true)
        }
    }
    
    func objectLength() -> Double {
        return 0.00//placeholder for massive calculations
    }
}




