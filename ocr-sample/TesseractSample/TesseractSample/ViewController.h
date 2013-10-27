//
//  ViewController.h
//  TesseractSample
//
//  Created by Ângelo Suzuki on 11/1/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextViewController.h"

@class MBProgressHUD;

namespace tesseract {
    class TessBaseAPI;
};

@interface ViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
{
    MBProgressHUD *progressHud;
    
    tesseract::TessBaseAPI *tesseract;
    uint32_t *pixels;
    
    
}
@property (nonatomic, strong) MBProgressHUD *progressHud;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) TextViewController *textViewController;


- (IBAction)getCameraPicture:(id)sender;
- (IBAction)getGalleryPicture:(id)sender;
- (IBAction)getTestImage:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *zhSwitch;

- (void)setTesseractImage:(UIImage *)image;

@end
