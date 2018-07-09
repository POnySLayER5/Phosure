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
    
    //Photo View's Variables
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    var photo: Photo!
    
    private var indicatorLines: [Line] = Array(repeating: Line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 0)), count: 4)
    private var objectLines: [Line] = Array(repeating: Line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 0)), count: 4)
    
    private var sharedIndicatorLineIndex: Int = 0
    
    var context: NSManagedObjectContext!
    
    var brushWidth: CGFloat = 10.0;
    var brushColor: CGColor = UIColor.cyan.cgColor
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoImageView.image = photo.image
        photoImageView.sizeToFit()
        scrollView.contentSize = photoImageView.bounds.size
        
        //If there are points, draw them
        restoreDrawing()
        
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
        //print(touch)
        
        for i in 0...3 {
            if photo.indicatorPoints[i].x == 0 {
                photo.indicatorPoints[i] = touch
                updateIndicatorLines()
                
                context.saveChanges()
                
                if(i == 3) {
                    drawLine(between: photo.indicatorPoints)
                }
                return
            }
        }
        
        for i in 0...3 {
            if photo.objectPoints[i].x == 0 {
                if i == 0 {
                    updateSharedIndicatorLineIndex(to: touch)
                    photo.objectPoints[i] = indicatorLines[sharedIndicatorLineIndex].closestPoint(to: touch)// -- This is the process that is required to have the 1st and 2nd points, of both indicator and object, on the same line
                    context.saveChanges()
                } else if i == 1 {
                    photo.objectPoints[i] = indicatorLines[sharedIndicatorLineIndex].closestPoint(to: touch)
                    context.saveChanges()
                } else {
                    photo.objectPoints[i] = touch
                    if(i == 3) {
                        drawLine(between: photo.objectPoints)
                        updateObjectLines()
                        
                        photo.objectLength = objectLength()
                        
                        print("Calculated Object Length: \(photo.objectLength)")
                        
                        context.saveChanges()
                    }
                }
                return
            }
        }
        //modifyAPoint(with: touch)
        
        return
    }
    
    private func restoreDrawing() {
        var previouslyDrawnObjectLines: [CGPoint] = photo.objectPoints
        for i in (1...3).reversed() {
            if photo.objectPoints[i] != CGPoint(x: 0, y: 0) {
                drawLine(between: previouslyDrawnObjectLines)
            }
            previouslyDrawnObjectLines.removeLast()
        }
        
        var previouslyDrawnIndicatorLines: [CGPoint] = photo.indicatorPoints
        for i in (1...3).reversed() {
            if photo.indicatorPoints[i] != CGPoint(x: 0, y: 0) {
                drawLine(between: previouslyDrawnIndicatorLines)
            }
            previouslyDrawnIndicatorLines.removeLast()
        }
    }
}

//Dealing with Points, Lines and such
extension PhotoZoomController {
    func drawLine(between points: [CGPoint]) {
        UIGraphicsBeginImageContextWithOptions(self.photoImageView.bounds.size, false, 0)
        
        photoImageView.image?.draw(in: self.photoImageView.bounds)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setLineCap(.round)
        context.setLineWidth(brushWidth)
        context.setStrokeColor(brushColor)
        
        var pointsToBeDrawn: [CGPoint] = points
        pointsToBeDrawn.append(points[0])
        
        context.addLines(between: pointsToBeDrawn)
        context.strokePath()
        //Sets new image
        if let edittedImage = UIGraphicsGetImageFromCurrentImageContext() {
            photoImageView.image = edittedImage
        }
        
        UIGraphicsEndImageContext()
    }
    
    private func indexAtLowestValue(in array: [Double]) -> Int {
        var lowestValue = array.first
        var index: Int = 0
        
        for i in 0..<array.count {
            if array[i] < lowestValue! {
                lowestValue = array[i]
                index = i
            }
        }
        
        return index
    }
    
    private func updateSharedIndicatorLineIndex (to point: CGPoint) {
        /*
        var indexOfClosestDistance = 0;
        for i in 1...3 {
            if(indicatorLines[i].closestDistanceTo(point) < indicatorLines[indexOfClosestDistance].closestDistanceTo(point)) {
                indexOfClosestDistance = i
            }
        }
        
        return indexOfClosestDistance
 */
        
        var distances = [Double]()
        var closestDistance = indicatorLines[0].closestDistanceTo(point)
        distances.append(closestDistance)
        
        for i in 1...3 {
            distances.append(indicatorLines[i].closestDistanceTo(point))
            if (distances[i] < closestDistance) {
                closestDistance = distances[i]
                sharedIndicatorLineIndex = i
            }
        }
    }
    
    private func modifyAPoint(with touch: CGPoint) {
        var distances: [Double] = [Double]()
        
        for i in 0...3 {
            distances.append(photo.indicatorPoints[i].distanceTo(touch))
        }
        
        for i in 4...7 {
            distances.append(photo.objectPoints[i - 4].distanceTo(touch))
        }
        print(distances)
        
        let index: Int = indexAtLowestValue(in: distances)
        
        if index < 4 {//Indicator Points
            photo.indicatorPoints[index] = touch
        } else {//Object Points
            photo.objectPoints[index - 4] = touch
        }
    }
    
    public func updateIndicatorLines() {
        for i in 0...2 {
            indicatorLines[i] = Line(from: photo.indicatorPoints[i], to: photo.indicatorPoints[i + 1])
        }
        
        indicatorLines[3] = Line(from: photo.indicatorPoints[3], to: photo.indicatorPoints[0])
    }
    
    public func updateObjectLines() {
        for i in 0...2 {
            objectLines[i] = Line(from: photo.objectPoints[i], to: photo.objectPoints[i + 1])
        }
        objectLines[3] = Line(from: photo.objectPoints[3], to: photo.objectPoints[0])
    }
    
    public func objectLength() -> Double {
        photo.objectLength = Double(objectLines[0].length())
        
        if photo.indicatorLength == 0.00 {
            return 0.00
        }
        
        let ratio: CGFloat = objectLines[0].length()/indicatorLines[sharedIndicatorLineIndex].length()
        return Double(ratio) * photo.indicatorLength
    }
}

///////////////////////////////////////////////////////////////SCROLL STUFF/////////////////////////////////////////////////////

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

///////////////////////////////////////////////////////////////LINE STUFF/////////////////////////////////////////////////////

class Line {
    var point1: CGPoint
    var point2: CGPoint
    
    init(from point1: CGPoint, to point2: CGPoint) {
        self.point1 = point1
        self.point2 = point2
    }
    
    init(between points: [CGPoint]) {
        point1 = points[0]
        point2 = points[1]
    }
    
    func slope() -> CGFloat {
        return (point1.y - point2.y)/(point1.x - point2.x)
    }
    
    func yIntercept() -> CGFloat {
        return point1.y - slope() * point1.x
    }
    
    func intersection(withSlope slope: CGFloat, andYIntercept yIntercept: CGFloat) -> CGPoint {
        let x: CGFloat = (yIntercept - self.yIntercept())/(self.slope() - slope)
        let y: CGFloat = slope * x + yIntercept
        
        return CGPoint(x: x, y: y)
    }
    
    func intersection(with line: Line) -> CGPoint {
        let x: CGFloat = (line.yIntercept() - self.yIntercept())/(self.slope() - line.slope())
        let y: CGFloat = slope() * x + yIntercept()
        
        return CGPoint(x: x, y: y)
    }
    
    func closestPoint(to point: CGPoint) -> CGPoint {
        let perpedicularSlope: CGFloat = -1/slope()
        let perpendicularYIntercept: CGFloat = point.y - perpedicularSlope * point.x
        
        return self.intersection(withSlope: perpedicularSlope, andYIntercept: perpendicularYIntercept)
    }
    
    func closestDistanceTo(_ point: CGPoint) -> Double {
        return closestPoint(to: point).distanceTo(point)
    }

    func length() -> CGFloat {
        print(sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y)))
        return sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y))
    }
}

extension CGPoint {
    func distanceTo(_ point: CGPoint) -> Double {
        let a =  (self.x - point.x) * (self.x - point.x) + (self.y - point.y) * (self.y - point.y)
        return Double(sqrt(a))
    }
}
