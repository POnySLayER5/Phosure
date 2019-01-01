//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (UIImage *)grayscaleImage:(UIImage *)image;
+ (UIImage *)gaussianBlurImage:(UIImage *)image;
+ (NSArray<NSArray<NSNumber *> *> *)cannyEdges:(UIImage *)image;
//+ (NSArray<NSArray<NSNumber *> *> *)lineEdgesToNSNumber:(std::vector<cv::Vec4f>)lines;
+ (NSArray<NSArray<NSNumber *> *> *)highlightedLines:(NSArray<NSArray<NSNumber *> *> *)highlightedPoints in:(NSArray<NSArray<NSNumber *> *> *)line;
+ (NSNumber *)distance:(NSArray<NSNumber *> *)point1 and:(NSArray<NSNumber *> *)point2;
/*- method: https://blog.teamtreehouse.com/the-beginners-guide-to-objective-c-methods
 In Objective-C, method definitions begin with either a dash (-) or a plus (+). We’ll talk about this in more detail when we cover classes and objects, but the dash means that this is an instance method that can only be accessed by an instance of the class where the method is defined. A plus sign indicates that the method is a class method that can be accessed anytime by simply referencing the class.
 */

@end
