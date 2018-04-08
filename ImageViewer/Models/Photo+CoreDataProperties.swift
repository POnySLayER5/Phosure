//
//  Photo+CoreDataProperties.swift
//  ImageViewer
//
//  Created by Screencast on 9/27/17.
//  Copyright © 2017 Treehouse. All rights reserved.
//
//

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
    @NSManaged public var objectLength: Double
    @NSManaged public var indicatorLength: Double
    @NSManaged public var title: String?
}

extension Photo {
    static var entityName: String {
        return String(describing: Photo.self)
    }
    
    @nonobjc class func with(_ image: UIImage, in context: NSManagedObjectContext) -> Photo {
        let photo = NSEntityDescription.insertNewObject(forEntityName: Photo.entityName, into: context) as! Photo
        
        photo.creationDate = Date() as NSDate
        photo.imageData = UIImageJPEGRepresentation(image, 1.0)! as NSData
        photo.objectLength = 123.12
        photo.indicatorLength = 23.12
        photo.title = "No title for now"
        
        return photo
    }
}

extension Photo {
    var image: UIImage {
        return UIImage(data: self.imageData! as Data)!
    }
}






