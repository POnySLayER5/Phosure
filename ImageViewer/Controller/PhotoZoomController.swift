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

    private let empty: CGPoint = CGPoint(x: 0, y: 0)
    private var indicatorLines: [Line] = Array(repeating: Line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 0)), count: 4)
    private var objectLines: [Line] = Array(repeating: Line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 0)), count: 4)
    
    private var sharedIndicatorLineIndex: Int = 0
    
    var context: NSManagedObjectContext!
    
    var brushWidth: CGFloat = 15.0
    var brushColor: CGColor = UIColor.clear.cgColor
    
    private let indicatorColor = UIColor.cyan.cgColor
    private let objectColor = UIColor.red.cgColor
    
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
}

////////////////////////////////////////////LOGIC BEHIND DRAWING & MODIFYING THE LINES AND POINTS//////////////////////////////////
extension PhotoZoomController {
    @IBAction func tappedInside(_ sender: Any) {
        guard let sender = sender as? UITapGestureRecognizer else {
            return
        }
        let touch = sender.location(in: self.photoImageView)
        
        //Add an indicator Point
        for i in 0..<photo.indicatorPoints.count {
            if photo.indicatorPoints[i] == empty {
                photo.indicatorPoints[i] = touch
                updateIndicatorLines()
                
                if i > 0 {
                    brushColor = indicatorColor
                    drawLine(between: indicatorLines[i - 1].points())
                    if i == 3 {
                        drawLine(between: indicatorLines[i].points())
                    }
                }
                context.saveChanges()
                return
            }
        }
        
        //Add an object Point, when all the indicator points are added
        for i in 0..<photo.objectPoints.count {
            if photo.objectPoints[i] == empty {
                if i <= 1 {
                    if i == 0 {
                        updateSharedIndicatorLineIndex(to: touch)
                    }
                    photo.objectPoints[i] = indicatorLines[sharedIndicatorLineIndex].closestPoint(to: touch)// -- This is the process that is required to have the 1st and 2nd points, of both indicator and object, on the same line
                    if i == 1 {
                        brushColor = objectColor
                        updateObjectLines()
                        drawLine(between: objectLines[i - 1].points())
                    }
                } else {
                    photo.objectPoints[i] = touch
                    updateObjectLines()
                    brushColor = objectColor
                    drawLine(between: objectLines[i - 1].points())
                    
                    if i == photo.objectPoints.count - 1 {
                        drawLine(between: objectLines[i].points())
                        
                        photo.objectLength = updateObjectLength()
                        print("Calculated Object Length: \(photo.objectLength)")
                    }
                }
                context.saveChanges()
                return
            }
        }
        
        //When all the points are added, future touches will modify the closest point within a limit
        modifyAPoint(with: touch)
        
        return
    }
    
    private func restoreDrawing() {
        var previouslyDrawnObjectPoints: [CGPoint] = photo.objectPoints
        var previouslyDrawnIndicatorPoints: [CGPoint] = photo.indicatorPoints
        
        for i in (1..<previouslyDrawnObjectPoints.count).reversed() {
            if previouslyDrawnObjectPoints[i] == empty {
                previouslyDrawnObjectPoints.removeLast()
            } else {
                if i == photo.objectPoints.count - 1 {
                    previouslyDrawnObjectPoints.append(previouslyDrawnObjectPoints[0])
                }
                previouslyDrawnIndicatorPoints.append(previouslyDrawnIndicatorPoints[0])
                
                brushColor = indicatorColor
                drawLine(between: previouslyDrawnIndicatorPoints)
                
                brushColor = objectColor
                drawLine(between: previouslyDrawnObjectPoints)
                return // If the Object Lines were drawn, then the indicator lines were also drawn
            }
        }
        
        for i in (1..<previouslyDrawnIndicatorPoints.count).reversed() {
            if previouslyDrawnIndicatorPoints[i] == empty {
                previouslyDrawnIndicatorPoints.removeLast()
            } else {
                if i == photo.indicatorPoints.count - 1 {
                    previouslyDrawnIndicatorPoints.append(previouslyDrawnIndicatorPoints[0])
                }
                brushColor = indicatorColor
                drawLine(between: previouslyDrawnIndicatorPoints)
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
        //print(distances)
        
        let index: Int = indexAtLowestValue(in: distances)
        let modifyingLimitValue: Double = 50.0
        
        //Only modify a point if the touch is within the max distance value
        if distances[index] < modifyingLimitValue {
            if index < 4 {//Indicator Points
                photo.indicatorPoints[index] = touch
            } else {//Object Points
                photo.objectPoints[index - 4] = touch
            }
        }
    }
}

///////////////////////////////////////MATH BEHIND THE LINES AND POINTS AND STUFF/////////////////////////////////////////////
extension PhotoZoomController {
    private func drawLine(between points: [CGPoint]) {
        UIGraphicsBeginImageContextWithOptions(self.photoImageView.bounds.size, false, 0)
        
        photoImageView.image?.draw(in: self.photoImageView.bounds)
        
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        
        context.setLineCap(.round)
        context.setLineWidth(brushWidth)
        context.setStrokeColor(brushColor)
        
        context.addLines(between: points)
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
    
    public func updateObjectLength() -> Double {
        photo.objectLength = Double(objectLines[0].length())
        
        if photo.indicatorLength == 0.00 {
            return 0.00
        }
        
        let ratio: CGFloat = objectLines[0].length()/indicatorLines[sharedIndicatorLineIndex].length()
        photo.objectLength = Double(ratio) * photo.indicatorLength
        return photo.objectLength
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
        //print(sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y)))
        return sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y))
    }
    
    func points() -> [CGPoint] {
        return [point1, point2]
    }
}

extension CGPoint {
    func distanceTo(_ point: CGPoint) -> Double {
        let a =  (self.x - point.x) * (self.x - point.x) + (self.y - point.y) * (self.y - point.y)
        return Double(sqrt(a))
    }
}


/*
 DOCTYPE=html
 <head>
 <title>Richard's Diary</title>
 </head>
 <body>
 Friday, August 3rd, 2018
 Cold....hungry.....starving....also I miss Kat xoxox
 If I don't write another entry, I must have been mauled by a bear
 Probably because I wa stoo busy eating
 GOodye
 </body>
 
 <style>
 </style>
 
 </html>
 
 Thanks Jessie Huang
 */

