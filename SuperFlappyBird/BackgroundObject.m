//
//  BackgroundObject.m
//  FlappyMania
//
//  Created by Shahid Altaf on 05/03/2014.
//  Copyright (c) 2014 Shahid Altaf. All rights reserved.
//

#import "BackgroundObject.h"

//static const uint32_t birdCategory = 0x1 << 0;
//static const uint32_t obsticleCategory = 0x1 << 1;

@implementation BackgroundObject

-(id)initWithAtlas:(SKTextureAtlas*)atlas parentScene:(SKScene*)parentScene {
    if (self = [super init]) {
        
        // still background
        self = [BackgroundObject spriteNodeWithTexture:[atlas textureNamed:[NSString stringWithFormat:@"bg0%i.png", (arc4random() % 2) + 1]]];
        self.position = CGPointMake(parentScene.size.width/2, parentScene.size.height-self.size.height/2);
        
        
        // parallax trees
        
        
        // parallax floor
        
    }
    return self;
}

@end
