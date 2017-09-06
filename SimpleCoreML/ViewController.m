//
//  ViewController.m
//  CoreMLTest
//
//  Created by Marco Marchesi on 04/09/2017.

//

#import "ViewController.h"
#import <CoreML/CoreML.h>
#import <Vision/Vision.h>
#import "Inceptionv3.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    _session = [[AVCaptureSession alloc] init];
    [_session setSessionPreset:AVCaptureSessionPresetPhoto];
    
    AVCaptureDevice *inputDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    NSError *error;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:inputDevice error:&error];
    
    if ([_session canAddInput:deviceInput]) {
        [_session addInput:deviceInput];
    }
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_session];
    [previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    CALayer *rootLayer = [[self view] layer];
    [rootLayer setMasksToBounds:YES];
    CGRect frame = self.imageView.frame;
    [previewLayer setFrame:frame];
    [rootLayer insertSublayer:previewLayer atIndex:0];
    
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoDataOutput setSampleBufferDelegate:self queue:dispatch_queue_create("sampling video",DISPATCH_QUEUE_SERIAL)];
    

    [_session addOutput:_videoDataOutput];
    [_session startRunning];
    
    
    // Start capturing frames
    [self captureFrame];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)classifyImage:(CIImage*)image{
    
    NSLog(@"Classifing image...");
    // Inception V3 model
    MLModel *model = [[[Inceptionv3 alloc] init] model];
    VNCoreMLModel *coreMLModel = [VNCoreMLModel modelForMLModel:model error:nil];
    VNCoreMLRequest *coreMLRequest = [[VNCoreMLRequest alloc] initWithModel: coreMLModel completionHandler: (VNRequestCompletionHandler) ^(VNRequest *request, NSError *error){
        dispatch_async(dispatch_get_main_queue(), ^{
            self.classificationLabel.text = @"done";
            self.numberOfResults = request.results.count;
            self.results = [request.results copy];
            VNClassificationObservation *topResult = ((VNClassificationObservation *)(self.results[0]));
            self.classificationLabel.text = [NSString stringWithFormat: @"%f: %@", topResult.confidence, topResult.identifier];
            
            // Capture next frame
            [self captureFrame];
        });
    }];
    
    NSDictionary *d = [[NSDictionary alloc] init];
    NSArray *a = @[coreMLRequest];
    
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:image options:d];
    dispatch_async(dispatch_get_main_queue(), ^{
        [handler performRequests:a error:nil];
    });
    
}

-(void)captureFrame{
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in _videoDataOutput.connections) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
}

-(void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"Capturing frame");
    
    CVImageBufferRef cvImage = CMSampleBufferGetImageBuffer(sampleBuffer);
    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:cvImage];
    [self classifyImage: ciImage];
}

@end
