//
//  ViewController.h
//  CoreMLTest
//
//  Created by Marco Marchesi on 04/09/2017.

//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet UIImageView* imageView;
@property (weak, nonatomic) IBOutlet UILabel* classificationLabel;

@property (nonatomic) unsigned long numberOfResults;
@property (retain, nonatomic) NSArray *results;

@property AVCaptureSession *session;
@property AVCaptureVideoDataOutput* videoDataOutput;
@property AVCapturePhotoSettings* photoSettings;

@end



