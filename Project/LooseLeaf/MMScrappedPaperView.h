//
//  MMScrappedPaperView.h
//  LooseLeaf
//
//  Created by Adam Wulf on 8/23/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import "MMEditablePaperView.h"
#import "MMPanAndPinchScrapGestureRecognizer.h"
#import "MMScrapsOnPaperStateDelegate.h"
#import "MMDecompressImagePromiseDelegate.h"
#import <MessageUI/MFMailComposeViewController.h>

/**
 * the purpose of this subclass is to encompass all of the
 * scrap functionality for a page
 */
@interface MMScrappedPaperView : MMEditablePaperView<MFMailComposeViewControllerDelegate,MMPanAndPinchScrapGestureRecognizerDelegate,MMScrapsOnPaperStateDelegate,MMDecompressImagePromiseDelegate>{
    UIImageView* cachedImgView;
}

-(void) addScrap:(MMScrapView*)scrap;
-(MMScrapView*) addScrapWithPath:(UIBezierPath*)path andScale:(CGFloat)scale;
-(MMScrapView*) addScrapWithPath:(UIBezierPath*)path andRotation:(CGFloat)lastBestRotation andScale:(CGFloat)scale;
-(BOOL) hasScrap:(MMScrapView*)scrap;

-(BOOL) hasScrapStateLoaded;

-(void) didUpdateAccelerometerWithRawReading:(CGFloat)currentRawReading;

-(void) saveToDisk;

#pragma mark - Scissors

-(void) beginScissorAtPoint:(CGPoint)point;

-(BOOL) continueScissorAtPoint:(CGPoint)point;

-(void) finishScissorAtPoint:(CGPoint)point;

-(void) cancelScissorAtPoint:(CGPoint)point;

-(void) completeScissorsCutWithPath:(UIBezierPath*)scissorPath;

-(NSString*) scrappedThumbnailPath;

-(UIImage*) scrappedImgViewImage;

@end
