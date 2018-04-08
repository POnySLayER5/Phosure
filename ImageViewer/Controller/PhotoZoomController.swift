//
//  PhotoZoomController.swift
//  ImageViewer
//
//  Created by Screencast on 10/2/17.
//  Copyright © 2017 Treehouse. All rights reserved.
//

import UIKit
import CoreGraphics
import CoreData

class PhotoZoomController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    //Photo View's Variables
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    var photo: Photo!
    
    var points: [CGPoint] = [CGPoint(x: 0, y: 0), CGPoint(x: 0, y: 0)]
    
    var context: NSManagedObjectContext!
    
    var brushWidth: CGFloat = 5.0;
    var brushColor: CGColor = UIColor.cyan.cgColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoImageView.image = photo.image
        photoImageView.sizeToFit()
        scrollView.contentSize = photoImageView.bounds.size
        updateZoomScale()
        updateConstraintsForSize(view.bounds.size)
        view.backgroundColor = .black
    }
    
    var minZoomScale: CGFloat {
        let viewSize = view.bounds.size
        let widthScale = viewSize.width/photoImageView.bounds.width
        let heightScale = viewSize.height/photoImageView.bounds.height
        
        return min(widthScale, heightScale)
    }
    
    func updateZoomScale() {
        scrollView.minimumZoomScale = minZoomScale
        scrollView.zoomScale = minZoomScale
    }
    
    func updateConstraintsForSize(_ size: CGSize) {
        let verticalSpace = size.height - photoImageView.frame.height
        let yOffset = max(0, verticalSpace/2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        
        let xOffset = max(0, (size.width - photoImageView.frame.width)/2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
    }
    
    @IBAction func tappedInside(_ sender: Any) {
        guard let sender = sender as? UITapGestureRecognizer else {
            return
        }
        
        let touch = sender.location(in: self.photoImageView)
        
        if points[0] == CGPoint(x: 0, y: 0) {
            points[0] = touch
        } else {
            points[1] = touch
            drawLine(between: points)
        }
    }
    
    func drawLine(between points: [CGPoint]) {
        UIGraphicsBeginImageContext(self.photoImageView.bounds.size)//intrinsicContentSize
        
        photoImageView.image?.draw(in: self.photoImageView.bounds)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setLineWidth(brushWidth)
        context.setStrokeColor(brushColor)
        context.addLines(between: points)
        context.strokePath()
        
        UIGraphicsEndImageContext()
        
        print("drew line")
    }
}

extension PhotoZoomController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
        
        if scrollView.zoomScale < minZoomScale {
            dismiss(animated: true, completion: nil)
        }
    }
}


