//
//  ViewController.m
//  TesseractSample
//
//  Created by Ângelo Suzuki on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

#import "MBProgressHUD.h"

#include "baseapi.h"

#include "environ.h"
#import "pix.h"

@implementation ViewController
@synthesize zhSwitch;

@synthesize progressHud;
@synthesize imageView = _imageView;
@synthesize textViewController = _textViewController;


#pragma mark - View lifecycle

- (void)startTesseract
{
    // Set up the tessdata path. This is included in the application bundle
    // but is copied to the Documents directory on the first run.
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = ([documentPaths count] > 0) ? [documentPaths objectAtIndex:0] : nil;
    
    NSString *dataPath = [documentPath stringByAppendingPathComponent:@"tessdata"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // If the expected store doesn't exist, copy the default store.
    if (![fileManager fileExistsAtPath:dataPath]) {
        // get the path to the app bundle (with the tessdata dir)
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        NSString *tessdataPath = [bundlePath stringByAppendingPathComponent:@"tessdata"];
        if (tessdataPath) {
            [fileManager copyItemAtPath:tessdataPath toPath:dataPath error:NULL];
        }
    }
    setenv("TESSDATA_PREFIX", [[documentPath stringByAppendingString:@"/"] UTF8String], 1);
    
    // init the tesseract engine.
    tesseract = new tesseract::TessBaseAPI();
    tesseract->Init([dataPath cStringUsingEncoding:NSUTF8StringEncoding], "eng+rus");
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = @"Tesseract";
        [self startTesseract];
    }
    return self;
}

- (void)dealloc {
    delete tesseract;
    tesseract = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setImageView:nil];

    [self setZhSwitch:nil];
    [super viewDidUnload];
    
    if (![self.progressHud isHidden])
        [self.progressHud hide:NO];
    self.progressHud = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)processOcrAt:(UIImage *)image
{
    [self setTesseractImage:image];
    //comment it as it does not work well with chi_sim
    tesseract->Recognize(NULL);
    char* utf8Text = tesseract->GetUTF8Text();
    
    [self performSelectorOnMainThread:@selector(ocrProcessingFinished:)
                           withObject:[NSString stringWithUTF8String:utf8Text]
                        waitUntilDone:NO];
}

- (void)ocrProcessingFinished:(NSString *)result
{
    [[[UIAlertView alloc] initWithTitle:@"Tesseract Sample"
                                message:@"OCR Finished"
                               delegate:nil
                      cancelButtonTitle:nil
                      otherButtonTitles:@"OK", nil] show];
    self.textViewController.text = result;
    [self.textViewController loadView];
}

- (void)setTesseractImage:(UIImage *)image
{
    free(pixels);
    
    CGSize size = [image size];
    int width = size.width;
    int height = size.height;
	
	if (width <= 0 || height <= 0)
		return;
	
    // the pixels will be painted to this array
    pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace, 
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
	
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// we're done with the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    tesseract->SetImage((const unsigned char *) pixels, width, height, sizeof(uint32_t), width * sizeof(uint32_t));
}


- (IBAction)getCameraPicture:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentModalViewController:picker animated:YES];
}

- (IBAction)getGalleryPicture:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentModalViewController:picker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image 
                  editingInfo:(NSDictionary *)editingInfo
{
    self.imageView.image = image;
    [picker dismissModalViewControllerAnimated:YES];    
    self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
    self.progressHud.labelText = @"Processing OCR";
      
    [self.view addSubview:self.progressHud];
    [self.progressHud showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:image animated:YES];
}

- (TextViewController *)textViewController
{
    if (_textViewController == nil) {
        _textViewController = [[TextViewController alloc] initWithNibName:@"TextViewController" bundle:nil];
    }
    return _textViewController;
}


- (IBAction)outputText:(id)sender {
    [self.navigationController pushViewController:self.textViewController animated:YES];

}

- (IBAction)getTestImage:(id)sender {
    static BOOL en = NO;
    en=!en;
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"test.%@.png", en? @"eng":@"ru" ]];
    
    if(!image)
        return;
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.frame = self.view.frame;
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    self.progressHud = [[MBProgressHUD alloc] initWithView:self.view];
    self.progressHud.labelText = @"Processing OCR";

    [self.view addSubview:self.progressHud];
    [self.progressHud showWhileExecuting:@selector(processOcrAt:) onTarget:self withObject:image animated:YES];
}

@end
