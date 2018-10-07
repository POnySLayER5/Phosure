import Foundation
import CoreData
import UIKit

public class Photo: NSManagedObject {
    
}

extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        return request
    }
    
    @NSManaged public var creationDate: NSDate?
    @NSManaged public var imageData: NSData?
    @NSManaged public var edittedImageData: NSData?
    @NSManaged public var ratio: Double
    @NSManaged public var indicatorLength: Double
    @NSManaged public var title: String?
    
    @NSManaged public var indicatorPoints: [CGPoint]
    @NSManaged public var objectPoints: [CGPoint]
}

extension Photo {
    static var entityName: String {
        return String(describing: Photo.self)
    }
    
    @nonobjc class func with(_ image: UIImage, in context: NSManagedObjectContext) -> Photo {
        let photo = NSEntityDescription.insertNewObject(forEntityName: Photo.entityName, into: context) as! Photo
        
        photo.creationDate = Date() as NSDate
        photo.imageData = UIImageJPEGRepresentation(image, 1.0)! as NSData
        photo.edittedImageData = UIImageJPEGRepresentation(image, 1.0)! as NSData
        photo.ratio = 0.0
        photo.indicatorLength = 0.0
        photo.title = ""
        
        photo.indicatorPoints = Array(repeating: CGPoint(x: 0, y: 0), count: 4)
        photo.objectPoints = Array(repeating: CGPoint(x: 0, y: 0), count: 4)
        
        return photo
    }
}

extension Photo {
    var image: UIImage {
        return UIImage(data: self.imageData! as Data)!
    }
    
    var edittedImage: UIImage {
        return UIImage(data: self.edittedImageData! as Data)!
    }
    
    var objectLength: Double {
        return ratio * indicatorLength
    }
}






