//
//  OpenCVSample.mm
//  OpenCVSample
//
//  Created by Pin-Chou Liu on 6/26/17.
//  Copyright © 2017 Pin-Chou Liu.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>

#import "math.h"

#import "opencv2/highgui.hpp"
#import <iostream>
#import "opencv2/imgproc.hpp"

#import "ImageViewer-Bridging-Header.h"

/*
 * add a method convertToMat to UIImage class
 */
@interface UIImage (OpenCVWrapper)
- (void)convertToMat: (cv::Mat *)pMat;
@end

@implementation UIImage (OpenCVWrapper)

- (void)convertToMat: (cv::Mat *)pMat {
    if (self.imageOrientation == UIImageOrientationRight) {
        /*
         * When taking picture in portrait orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_CLOCKWISE);
    } else if (self.imageOrientation == UIImageOrientationLeft) {
        /*
         * When taking picture in portrait upside-down orientation,
         * convert UIImage to OpenCV Matrix in landscape right-side-up orientation,
         * and then rotate OpenCV Matrix to portrait upside-down orientation
         */
        UIImageToMat([UIImage imageWithCGImage:self.CGImage scale:1.0 orientation:UIImageOrientationUp], *pMat);
        cv::rotate(*pMat, *pMat, cv::ROTATE_90_COUNTERCLOCKWISE);
    } else {
        /*
         * When taking picture in landscape orientation,
         * convert UIImage to OpenCV Matrix directly,
         * and then ONLY rotate OpenCV Matrix for landscape left-side-up orientation
         */
        UIImageToMat(self, *pMat);
        if (self.imageOrientation == UIImageOrientationDown) {
            cv::rotate(*pMat, *pMat, cv::ROTATE_180);
        }
    }
}

@end


/*
 *  class methods to execute OpenCV operations
 */
@implementation OpenCVWrapper : NSObject
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

/////////////////////////////////////////////////////////////////Edge Image/////////////////////////////////////////////////////////////////
+ (UIImage *)grayscaleImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat];
    
    cv::Mat gray;
    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }
    
    UIImage *grayImg = MatToUIImage(gray);
    return grayImg;
}

+ (UIImage *)gaussianBlurImage:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat];
    
    cv::Mat gray, blur;
    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }
    
    cv::GaussianBlur(gray, blur, cv::Size(5, 5), 3, 3);
    
    UIImage *blurImg = MatToUIImage(blur);
    return blurImg;
}

+ (NSArray<NSArray<NSNumber *> *> *)cannyEdges:(UIImage *)image {
    cv::Mat mat;
    [image convertToMat: &mat];
    
    cv::Mat gray, blur, edge;
    if (mat.channels() > 1) {
        cv::cvtColor(mat, gray, CV_RGB2GRAY);
    } else {
        mat.copyTo(gray);
    }
    
    cv::GaussianBlur(gray, blur, cv::Size(5, 5), 3, 3);
    
    cv::Canny(blur, edge, 50, 70, 3);
    
    /*Ptr<LineSegmentDetector>*/
    cv::Ptr<cv::LineSegmentDetector> ls = cv::createLineSegmentDetector(cv::LSD_REFINE_STD) ;
    
    std::vector<cv::Vec4f> lines_std;
    
    [image convertToMat: &mat];
    
    // Detect the lines
    ls->detect(mat, lines_std);
    
    //Converts Vector Array to NSArray
    NSMutableArray *edgeLines;
    
    printf("currently finding the edge lines");
    
    for (int i = 0; i < lines_std.size(); i ++) {
        NSMutableArray<NSNumber *> *vector;
        
        //Convert from Vec4f to NSNumber
        for (int k = 0; k < 4; k ++) {
            [vector addObject: @(lines_std[i][k])];//PROBLEM IS HERE
        }
        
        [edgeLines insertObject:vector atIndex:edgeLines.count];
    }
    
    return edgeLines;
}

//Converts the Vector Array to a NSArray
+ (NSArray<NSArray<NSNumber *> *> *)lineEdgesToNSNumber:(std::vector<cv::Vec4f>)lines {//////Array of Array of NSNumber
    NSMutableArray *edgeLines;
    
    std::vector<cv::Vec4f> lines_std;
    
    printf("currently finding the edge lines");
    
    for (int i = 0; i < lines.size(); i ++) {
        NSMutableArray<NSNumber *> *vector;
        
        //Convert from Vec4f to NSNumber
        for (int k = 0; k < 4; k ++) {
            [vector addObject: @(lines[i][k])];
        }
        
        [edgeLines insertObject:vector atIndex:edgeLines.count];
    }
    
    return edgeLines;
}

//Finds the Lines that are highlighted
+ (NSArray<NSArray<NSNumber *> *> *)highlightedLines:(NSArray<NSArray<NSNumber *> *> *)highlightedPoints in:(NSArray<NSArray<NSNumber *> *> *)lines {
    NSMutableArray<NSArray<NSNumber *> *> *highlightedLines;
    
    for (int i = 0; i < highlightedPoints.count; i ++) {
        NSNumber *pointdistance;
        int index1 = 0;
        int index2 = 0;
        
        //Finds the closest line edge to the tapped point
        for (int k = 0; k < lines.count; k ++) {
            NSArray<NSNumber *> *linePoint1 = [NSArray arrayWithObjects: lines[k][0], lines[k][1], nil];
            NSArray<NSNumber *> *linePoint2 = [NSArray arrayWithObjects: lines[k][2], lines[k][3], nil];
            
            float x1 = [linePoint1[0] floatValue];
            float y1 = [linePoint1[1] floatValue];
            
            float x2 = [linePoint2[0] floatValue];
            float y2 = [linePoint2[1] floatValue];
            
            NSNumber *distance1 = @(sqrt(([highlightedPoints[i][0] floatValue] - x1) * ([highlightedPoints[i][0] floatValue] - x1) + ([highlightedPoints[i][1] floatValue] - y1) * ([highlightedPoints[i][0] floatValue] - y1)));
            
            NSNumber *distance2 = @(sqrt(([highlightedPoints[i][0] floatValue] - x2) * ([highlightedPoints[i][0] floatValue] - x2) + ([highlightedPoints[i][1] floatValue] - y2) * ([highlightedPoints[i][1] floatValue] - y2)));
            
            if (distance1 < distance2) {
                if (distance1 < pointdistance) {
                    index1 = k;
                    index2 = 0;
                }
            } else {
                if (distance2 < pointdistance) {
                    index1 = k;
                    index2 = 2;
                }
            }
        }
        
        printf("found the closest point, added to array");
        
        [highlightedLines addObject: [NSArray arrayWithObjects: lines[index1][index2], lines[index1][index2 + 1], nil]];
    }
    
    return highlightedLines;
}

+ (NSNumber *)distance:(NSArray<NSNumber *> *)point1 and:(NSArray<NSNumber *> *)point2 {
    float x1 = [point1[0] floatValue];
    float y1 = [point1[1] floatValue];
    
    float x2 = [point2[0] floatValue];
    float y2 = [point2[1] floatValue];
    
    return @(sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)));
}

/*
 (Nov 8)
 Looking for the lines that the highlighted points are closest to in C++
 */

@end










/*//Converts the Vector Array to a NSArray
 + (NSArray<NSNumber *> *)lineEdges:(std::vector<cv::Vec4f>)lines {
 NSMutableArray *edgeLines;
 
 printf("currently finding the edge lines");
 
 for (int i = 0; i < lines.size(); i ++) {
 NSMutableArray<NSNumber *> *vector;
 
 //Convert from Vec4f to NSNumber
 for (int k = 0; k < 4; k ++) {
 [vector insertObject:@(lines[i][k]) atIndex:k];
 }
 
 [edgeLines insertObject:vector atIndex:edgeLines.count];
 }
 
 return edgeLines;
 }
 
 //Finds the Lines that are highlighted
 + (NSArray<float> *)highlightedLines:(NSArray<NSNumber *> *)highlightedPoints in:(NSArray<NSNumber *> *)lines {
 for (int i = 0; i < highlightedPoints.count; i ++) {
 NSMutableArray *pointdistances;
 
 for (int k = 0; k < lines.count; k ++) {
 
 }
 }
 
 return lines;
 }
 
 + (float *)distance:(NSArray<NSNumber *> *)point1 and:(NSArray<NSNumber *> *)point2 {
 
 
 return sqrt((point1[0] - point2[0])^2 + (point1[1] - point2[1])^2)
 }
 
 */















