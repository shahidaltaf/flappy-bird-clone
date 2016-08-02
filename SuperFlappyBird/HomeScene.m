//
//  HomeScene.m
//  FlappyMania
//
//  Created by Shahid Altaf on 28/02/2014.
//  Copyright (c) 2014 Shahid Altaf. All rights reserved.
//

#import "HomeScene.h"
#import "GameScene.h"
#import "BackgroundObject.h"
#import "BirdObject.h"

@interface HomeScene ()
@property (nonatomic) SKTextureAtlas *atlas;
@property (nonatomic) BirdObject *bird;
@end

@implementation HomeScene

-(id)initWithSize:(CGSize)size {
    if (self = [super initWithSize:size]) {
        
        self.atlas = [SKTextureAtlas atlasNamed:@"sprites"];
        
        SKSpriteNode *bgObject = [[BackgroundObject alloc] initWithAtlas:self.atlas parentScene:self];
        [self addChild: bgObject];
        
        self.bird = [[BirdObject alloc] initWithAtlas:self.atlas position:CGPointMake(self.frame.size.width/2, self.frame.size.height/2) parentScene:self];
        [self addChild: self.bird];
        [self.bird makeBirdHover];
        
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"play-button.png"]];
        playButton.position = CGPointMake(self.frame.size.width/2, [self yFromTopForSprite:playButton desiredY:1]);
        playButton.name = @"playButton";
        [self addChild:playButton];
        
    }
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if ([node.name isEqualToString:@"playButton"]) {
        SKTransition *fade = [SKTransition fadeWithDuration:1.0f];
        SKScene *gameScene = [[GameScene alloc] initWithSize:self.size];
        [self.view presentScene:gameScene transition: fade];
    }
}

#pragma mark - Utility methods

-(int)yFromTopForSprite:(SKSpriteNode *)sprite desiredY:(int)desiredY {
    
	return (self.size.height - sprite.size.height/2) - desiredY;
}

@end
