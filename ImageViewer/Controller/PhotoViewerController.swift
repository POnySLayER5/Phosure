import UIKit
import CoreData

class PhotoViewerController: UIViewController {
    
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var indicatorLengthTextField: UITextField!
    @IBOutlet weak var objectLengthTextField: UILabel!
    var photo: Photo!
    
    var context: NSManagedObjectContext!
    
    var units: String = "cm"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoImageView.image = photo.image
        titleTextField.text = photo.title
        
        indicatorLengthTextField.text = "\(photo.indicatorLength)"
        updateObjectLengthText()
        
        indicatorLengthTextField.keyboardType = .decimalPad
    }
    
    @IBAction func launchPhotoZoomController(_ sender: Any) {
        guard let storyboard = storyboard else { return }
        
        let zoomController = storyboard.instantiateViewController(withIdentifier: "PhotoZoomController") as! PhotoZoomController
        zoomController.modalTransitionStyle = .crossDissolve
        zoomController.photo = photo
        zoomController.context = self.context
        
        zoomController.updateIndicatorLines()
        zoomController.updateObjectLines()
        
        navigationController?.present(zoomController, animated: true, completion: nil)
    }
    
    @IBAction func changedTitle(_ sender: UITextField) {
        photo.title = titleTextField.text
        context.saveChanges()
    }
    
    @IBAction func changedIndicatorLength(_ sender: UITextField) {
        guard let newIndicatorLength: Double = Double(indicatorLengthTextField.text!) else {
            //Pop-up Alert for invalid entry
            return
        }
        let ratio: Double = newIndicatorLength/photo.indicatorLength
        photo.objectLength *= ratio
        photo.indicatorLength = newIndicatorLength
        
        updateObjectLengthText()
        
        context.saveChanges()
    }
    
    @IBAction func deletePhoto(_ sender: UIButton) {
        if let photo = photo {
            context.delete(photo)
            context.saveChanges()
            navigationController?.popViewController(animated: true)
        }
    }
}

//Updating Object Line Text and Math Behind it
extension PhotoViewerController {
    
    override func viewWillAppear(_ animated: Bool) {
        updateObjectLengthText()
    }
    
    public func updateObjectLengthText(){
        if photo.indicatorLength == 0 || photo.objectLength == 0{
            objectLengthTextField.text = "0.0"
        }
        
        let decimals: Int = 2; //Placeholder
        
        objectLengthTextField.text = "\(roundMy(photo.objectLength, to: decimals)) \(units)"
    }
    
    private func roundMy(_ num: Double, to decimals: Int) -> Double {
        return round(num * pow(of: 10.0, to: decimals))/pow(of: 10.0, to: decimals)
    }
    
    private func pow(of num: Double, to exponent: Int) -> Double {
        var output: Double = 1
        if exponent < 0 {
            for _ in exponent...0 {
                output /= num
            }
        } else {
            for _ in 0...exponent {
                output *= num
            }
        }
        
        return output
    }
}




























