//
//  BirdObject.m
//  FlappyMania
//
//  Created by Shahid Altaf on 05/03/2014.
//  Copyright (c) 2014 Shahid Altaf. All rights reserved.
//

#import "BirdObject.h"

@interface BirdObject ()

@property (nonatomic) NSArray *birdFlapFrames;
@property (nonatomic) SKScene *parentScene;

@end

#define BIRD_MIN_Y 136
#define BIRD_VELOCITY_MULTIPLIER 0.00195

static const uint32_t birdCategory = 0x1 << 0;
static const uint32_t obsticleCategory = 0x1 << 1;

@implementation BirdObject

-(id)initWithAtlas:(SKTextureAtlas*)atlas position:(CGPoint)position parentScene:(SKScene*)parentScene {
    if (self = [super init]) {
        self = [BirdObject spriteNodeWithTexture:[atlas textureNamed:@"bird1.png"]];
        self.position = position;
        self.name = @"Bird";
        self.zPosition = 1.0;
        self.parentScene = parentScene;
        
        SKTexture *b1 = [atlas textureNamed:@"bird1.png"];
        SKTexture *b2 = [atlas textureNamed:@"bird2.png"];
        SKTexture *b3 = [atlas textureNamed:@"bird3.png"];
        self.birdFlapFrames = @[b1, b2, b3, b2];
    }
    return self;
}

-(void)addPhysics {
    self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:self.size.height/2];
    self.physicsBody.dynamic = YES;
    self.physicsBody.categoryBitMask = birdCategory;
    self.physicsBody.contactTestBitMask = obsticleCategory;
    self.physicsBody.collisionBitMask = 0;
    self.physicsBody.usesPreciseCollisionDetection = YES;
}

-(void)makeBirdHover {
    SKAction *flapWings = [SKAction repeatActionForever:[SKAction animateWithTextures:self.birdFlapFrames timePerFrame:0.1f resize:NO restore:YES]];
    
    // TODO: fix hovering...
    
    SKAction *birdHoverUp = [SKAction moveToY:self.position.y+5 duration:0.4];
    SKAction *birdHoverDown = [SKAction moveToY:self.position.y-5 duration:0.4];
    SKAction *birdHoverUpDown = [SKAction repeatActionForever:[SKAction sequence:@[birdHoverUp, birdHoverDown]]];
    
    [self runAction:[SKAction group:@[flapWings, birdHoverUpDown]]];
}

-(void)makeBirdFlap {
     
     [self removeAllActions];
     
     int birdMaxY = self.parentScene.size.height - self.size.height/2;
     int birdY = (self.position.y > birdMaxY) ? birdMaxY : self.position.y + 54;
     
     SKAction *birdFly = [SKAction moveTo:CGPointMake(self.position.x, birdY) duration:0.4f];
     SKAction *birdUpTwist = [SKAction rotateToAngle:0.40 duration:0.2f]; // 20 degrees
     birdFly.timingMode = SKActionTimingEaseOut;
     
     SKAction *flapWings = [SKAction repeatAction:[SKAction animateWithTextures:self.birdFlapFrames timePerFrame:0.05f resize:NO restore:YES] count:4];
     
     float birdVelocity = self.position.y * BIRD_VELOCITY_MULTIPLIER;
     SKAction *birdDive = [SKAction moveTo:CGPointMake(self.position.x, BIRD_MIN_Y) duration:birdVelocity];
     birdDive.timingMode = SKActionTimingEaseIn;
     SKAction *birdDownTwistDelay = [SKAction waitForDuration:0.2];
     SKAction *birdDownTwistAction = [SKAction rotateToAngle:-1.57 duration:0.3f]; // 90 degrees/1.57
     SKAction *birdDownTwist = [SKAction sequence:@[birdDownTwistDelay, birdDownTwistAction]];
     
     SKAction *flyGroup = [SKAction group:@[birdFly, birdUpTwist]];
     SKAction *diveGroup = [SKAction group:@[birdDive, birdDownTwist]];
     
     [self runAction:[SKAction group:@[[SKAction sequence:@[flyGroup, diveGroup]], flapWings]]];
    
}

@end
