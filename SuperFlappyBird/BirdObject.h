//
//  BirdObject.h
//  FlappyMania
//
//  Created by Shahid Altaf on 05/03/2014.
//  Copyright (c) 2014 Shahid Altaf. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface BirdObject : SKSpriteNode

-(id)initWithAtlas:(SKTextureAtlas *)atlas position:(CGPoint)position parentScene:(SKScene*)parentScene;
-(void)addPhysics;
-(void)makeBirdFlap;
-(void)makeBirdHover;

@end

