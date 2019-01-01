import UIKit
import CoreGraphics
import CoreData

class PhotoZoomController: UIViewController {
    
    private var sharedIndicatorLineIndex: Int = 0
    
    var context: NSManagedObjectContext!
    
    private var drawingState: DrawingState = .highlighter
    
    private var minForce: CGFloat = 5
    
    //Photo View's Variables
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var lockButton: UIButton!
    
    var locked: Bool = false
    
    var photo: Photo!
    
    //Lines Variables
    
    private let empty: CGPoint = CGPoint(x: 0, y: 0)
    
    private var indicatorLines: [Line] = Array(repeating: Line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 0)), count: 4)
    private var objectLines: [Line] = Array(repeating: Line(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: 0)), count: 4)
    
    private var highlighterPoints: [CGPoint] = []
    
    //Brush Variables
    
    private let lineWidth: CGFloat = 15.0
    private let indicatorColor = UIColor.cyan.cgColor
    private let objectColor = UIColor.red.cgColor
    private let lineAlpha: CGFloat = 1.0
    
    private let highlighterColor = UIColor.cyan.cgColor
    private let highlighterBrushWidth: CGFloat = 40.0
    private let highlighterAlpha: CGFloat = 0.5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        photoImageView.image = photo.edittedImage
        photoImageView.sizeToFit()
        scrollView.contentSize = photoImageView.bounds.size
        
        updateZoomScale()
        updateConstraintsForSize(view.bounds.size)
        view.backgroundColor = .black
        
        photoImageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
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
    
    override func viewWillDisappear(_ animated: Bool) {
        photo.edittedImageData = UIImageJPEGRepresentation(photoImageView.image!, 1.0)! as NSData
    }
    
    @IBAction func lockOrUnlock(_ sender: Any) {
        locked = !locked
        if locked {
            lockButton.setTitle("Unlock", for: .normal)
        } else {
            lockButton.setTitle("Lock", for: .normal)
        }
        
        scrollView.isScrollEnabled = !locked
        scrollView.isUserInteractionEnabled = !locked
    }
}

/////////////////////////////////////////////////////////IMAGE EDGE DETECTION////////////////////////////////////////////////////////////
extension PhotoZoomController {
    private func highlightedPointsAsNSNumber() -> [[NSNumber]] {
        var points: [[NSNumber]] = []
        
        for point in highlighterPoints {
            points.append(point.toNSNumberArray())
        }
        
        return points
    }
    
    private func getEdgeLines() -> [CGPoint] {
        var image = OpenCVWrapper.grayscaleImage(photo.image)
        image = OpenCVWrapper.gaussianBlurImage(image)
        
        let lineEdges: [[NSNumber]] = OpenCVWrapper.cannyEdges(image) //Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
        
        let edgePoints: [[NSNumber]] = OpenCVWrapper.highlightedLines(highlightedPointsAsNSNumber(), in: lineEdges)
        
        return NSNumberArrayToCGPointArray(edgePoints)
    }
    
    private func NSNumberArrayToCGPointArray(_ numbers: [[NSNumber]]) -> [CGPoint] {
        
        
        return [CGPoint(x: 10, y: 10)]
    }
}

extension CGPoint {
    func toNSNumberArray() -> [NSNumber] {
        return [NSNumber(value: Float(self.x)), NSNumber(value: Float(self.y))]
    }
}

////////////////////////////////////////////LOGIC BEHIND DRAWING & MODIFYING THE LINES AND POINTS//////////////////////////////////
extension PhotoZoomController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let _ = touches.first else { return }
        
        photoImageView.image = photo.image//Reset Image
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        if touch.force >= minForce {
            if isNewPoint(touch.location(in: scrollView)) {
                highlighterPoints.append(touch.location(in: scrollView))
                
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        
        highlighterPoints.append(touch.location(in: scrollView))
        highlighterPoints.append(highlighterPoints[0])
        
        drawingState = .highlighter
        drawLine(between: highlighterPoints)
        
        print(getEdgeLines())
    }
    
    private func isNewPoint(_ point: CGPoint) -> Bool {
        if highlighterPoints.isEmpty {
            return true
        }
        return !(point.distanceTo(highlighterPoints[highlighterPoints.count - 1]) <= 25)
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
        
        switch drawingState {
        case .highlighter:
            context.setLineCap(.round)
            context.setLineWidth(highlighterBrushWidth)
            context.setStrokeColor(highlighterColor)
            context.setAlpha(highlighterAlpha)
        case .indicatorLine:
            context.setLineCap(.round)
            context.setLineWidth(lineWidth)
            context.setStrokeColor(indicatorColor)
            context.setAlpha(lineAlpha)
        case .objectLine:
            context.setLineCap(.round)
            context.setLineWidth(lineWidth)
            context.setStrokeColor(objectColor)
            context.setAlpha(lineAlpha)
        }
        
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
        
        let x = indicatorLines.count - 1
        
        for i in 1...x {
            distances.append(indicatorLines[i].closestDistanceTo(point))
            if (distances[i] < closestDistance) {
                closestDistance = distances[i]
                sharedIndicatorLineIndex = i
            }
        }
    }
    
    public func updateIndicatorLines() {
        let x = indicatorLines.count - 1
        if x == 0 {
            return
        }
        for i in 0...x - 1 {
            indicatorLines[i] = Line(from: photo.indicatorPoints[i], to: photo.indicatorPoints[i + 1])
        }
        
        indicatorLines[x] = Line(from: photo.indicatorPoints[x], to: photo.indicatorPoints[0])
    }
    
    public func updateObjectLines() {
        let x = objectLines.count - 1
        if x == 0 {
            return
        }
        for i in 0...x - 1 {
            objectLines[i] = Line(from: photo.objectPoints[i], to: photo.objectPoints[i + 1])
        }
        objectLines[x] = Line(from: photo.objectPoints[x], to: photo.objectPoints[0])
    }
    
    public func updateRatio(){
        let ratio: Double = (Double)(objectLines[0].length()/indicatorLines[sharedIndicatorLineIndex].length())
        photo.ratio = ratio
        
        context.saveChanges()
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

enum DrawingState {
    case indicatorLine
    case objectLine
    case highlighter
}
