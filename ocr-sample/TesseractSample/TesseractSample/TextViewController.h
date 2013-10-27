//
//  TextViewController.h
//  TesseractSample
//
//  Created by Xin Fan on 7/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TextViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (nonatomic, retain) NSString *text;
@end
