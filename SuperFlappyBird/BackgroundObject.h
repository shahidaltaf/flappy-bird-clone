//
//  BackgroundObject.h
//  FlappyMania
//
//  Created by Shahid Altaf on 05/03/2014.
//  Copyright (c) 2014 Shahid Altaf. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface BackgroundObject : SKSpriteNode

-(id)initWithAtlas:(SKTextureAtlas *)atlas parentScene:(SKScene*)parentScene;

@end
