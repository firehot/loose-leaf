//
//  MMScrapsOnPaperStateDelegate.h
//  LooseLeaf
//
//  Created by Adam Wulf on 9/26/13.
//  Copyright (c) 2013 Milestone Made, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MMScrapView, MMScrapsOnPaperState, MMScrapContainerView,MMScrapsInBezelContainerView,MMScrappedPaperView,MMScrapCollectionState;

@protocol MMScrapsOnPaperStateDelegate <NSObject>

-(MMScrappedPaperView*) page;

-(NSString*) uuid;

-(MMScrapView*) scrapForUUIDIfAlreadyExistsInOtherContainer:(NSString*)scrapUUID;

-(BOOL) isEditable;

/**
 * triggered when a scrap is laoded from disk that is
 * actively showing on the page
 */
-(void) didLoadScrapOnPage:(MMScrapView*)scrap;

/**
 * triggered when a scrap is laoded from disk that is
 * NOT actively showing on the page, and is only
 * available inside the page's undo/redo stacks
 */
-(void) didLoadScrapOffPage:(MMScrapView*)scrap;

-(void) didLoadAllScrapsFor:(MMScrapCollectionState*)scrapState;

-(void) didUnloadAllScrapsFor:(MMScrapCollectionState*)scrapState;

-(NSString*) pagesPath;

-(NSString*) bundledPagesPath;

@end
