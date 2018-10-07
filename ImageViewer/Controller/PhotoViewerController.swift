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
    
    private let empty: CGPoint = CGPoint(x: 0, y: 0)
    
    private var brushColor: CGColor = UIColor.clear.cgColor
    private var brushWidth: CGFloat = 10.0
    
    private var indicatorColor = UIColor.cyan.cgColor
    private let objectColor = UIColor.red.cgColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///////////////Load Photo Core Properties and Update View
        photoImageView.image = photo.edittedImage
        titleTextField.text = photo.title
        indicatorLengthTextField.text = "\(photo.indicatorLength)"
        
        indicatorLengthTextField.keyboardType = .decimalPad
        
        NotificationCenter.default.addObserver(self, selector: #selector(PhotoViewerController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(PhotoViewerController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        setDoneOnKeyboard(with: titleTextField)
        setDoneOnKeyboard(with: indicatorLengthTextField)
    }
    
    @IBAction func reset(_ sender: Any) {
        //Pop-up alert for are you sure?
        photo.title = ""
        photo.indicatorLength = 0.0
        photo.ratio = 0.0
        updateAllTexts()
        
        for i in 0..<photo.indicatorPoints.count {
            photo.indicatorPoints[i] = empty
            photo.objectPoints[i] = empty
        }
        
        photoImageView.image = photo.image
        
        context.saveChanges()
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
    
    @IBAction func deletePhoto(_ sender: UIButton) {
        if let photo = photo {
            context.delete(photo)
            context.saveChanges()
            navigationController?.popViewController(animated: true)
        }
    }
}

/////////////////////////////////////Updating Object Line Text and Math Behind it///////////////////////////////////////////
extension PhotoViewerController {
    
    override func viewWillAppear(_ animated: Bool) {
        updateObjectLengthText()
        photoImageView.image = photo.edittedImage
    }
    
    public func updateObjectLengthText(){
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
    
    func updateAllTexts() {
        titleTextField.text = photo.title
        indicatorLengthTextField.text = "\(photo.indicatorLength)"
        updateObjectLengthText()
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
        photo.indicatorLength = newIndicatorLength
        updateObjectLengthText()
        
        context.saveChanges()
    }
}

////////////////////////////////////////////////Keyboard Stuff/////////////////////////////////////////////////////////

extension PhotoViewerController {
    @objc func keyboardWillShow(notification: NSNotification) {
        if indicatorLengthTextField.isEditing {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y == 0{
                    self.view.frame.origin.y -= keyboardSize.height
                }
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if indicatorLengthTextField.isEditing {
            if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
                if self.view.frame.origin.y != 0{
                    self.view.frame.origin.y += keyboardSize.height + UIToolbar().frame.height
                }
            }
        }
    }
    
    func setDoneOnKeyboard(with textField: UITextField) {
        let keyboardToolbar = UIToolbar()
        keyboardToolbar.sizeToFit()
        let flexBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(self.dismissKeyboard))
        keyboardToolbar.items = [flexBarButton, doneBarButton]
        textField.inputAccessoryView = keyboardToolbar
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}



















