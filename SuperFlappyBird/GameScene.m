//
//  GameScene.m
//  FlappyMania
//
//  Created by Shahid Altaf on 09/02/2014.
//  Copyright (c) 2014 Shahid Altaf. All rights reserved.
//

#import "GameScene.h"
#import "HomeScene.h"
#import "BMGlyphFont.h"
#import "BMGlyphLabel.h"
#import "BackgroundObject.h"
#import "BirdObject.h"

@interface GameScene () <SKPhysicsContactDelegate>
@property (nonatomic) SKTextureAtlas *atlas;
@property (nonatomic) BirdObject *bird;
@property (nonatomic) SKSpriteNode *floor;
@property (nonatomic) SKSpriteNode *tap;
@property (nonatomic) SKSpriteNode *getReady;
@property (nonatomic) NSArray *birdFlapFrames;
@property (nonatomic) SKLabelNode *scoreLabel;
@property (nonatomic) SKNode *gameLayer;
@property BOOL gameHasStarted;
@property BOOL gameHasEnded;
@property BOOL pipesReady;
@property int score;
@property (nonatomic) NSTimeInterval lastSpawnTimeInterval;
@property (nonatomic) NSTimeInterval lastUpdateTimeInterval;
@property (nonatomic) NSTimeInterval timeStarted;
@end

#define TIME_BETWEEN_PIPE 1.8
#define PIPE_DELAY 2
#define PIPE_GAP 106
#define PIPE_MIN_X 154
#define BIRD_MIN_Y 136
#define BIRD_VELOCITY_MULTIPLIER 0.00195

static const uint32_t birdCategory = 0x1 << 0;
static const uint32_t obsticleCategory = 0x1 << 1;

@implementation GameScene

-(id)initWithSize:(CGSize)size {    
    if (self = [super initWithSize:size]) {
        
        self.gameHasStarted = NO;
        self.gameHasEnded = NO;
        self.pipesReady = NO;
        self.score = 0;
        self.atlas = [SKTextureAtlas atlasNamed:@"sprites"];
        
        self.gameLayer = [[SKNode alloc] init];
        [self addChild:self.gameLayer];
        
        self.physicsWorld.gravity = CGVectorMake(0,0);
        self.physicsWorld.contactDelegate = self;
        
        SKSpriteNode *bgObject = [[BackgroundObject alloc] initWithAtlas:self.atlas parentScene:self];
        [self.gameLayer addChild: bgObject];
        
        [self rollParallaxGround];
        
        self.scoreLabel = [SKLabelNode labelNodeWithFontNamed:@"04b_19"];
        self.scoreLabel.text = [NSString stringWithFormat:@"%d", self.score];
        self.scoreLabel.fontSize = 44;
        self.scoreLabel.fontColor = [SKColor whiteColor];
        self.scoreLabel.position = CGPointMake(self.size.width/2, self.size.height-(90+46));
        self.scoreLabel.zPosition = 3;
        [self.gameLayer addChild:self.scoreLabel];
        
        
        // instructions
        self.getReady = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"get-ready.png"]];
        self.getReady.position = CGPointMake(self.size.width/2, (self.size.height/3*2));
        self.getReady.alpha = 0;
        [self addChild:self.getReady];
        
        SKAction *fadeInAction = [SKAction fadeInWithDuration:0.3f];
        [self.getReady runAction:fadeInAction];
        
        self.tap = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tap.png"]];
        self.tap.position = CGPointMake(self.size.width/2, self.size.height/2-20);
        [self addChild:self.tap];
        
        
        // bird object
        self.bird = [[BirdObject alloc] initWithAtlas:self.atlas position:CGPointMake(98, self.frame.size.height/2) parentScene:self];
        [self.gameLayer addChild: self.bird];
        [self.bird addPhysics];
        [self.bird makeBirdHover];
        
    }
    return self;
}

#pragma mark - Game loop logic

- (void)updateWithTimeSinceLastUpdate:(CFTimeInterval)timeSinceLast {
    
    if(!self.pipesReady) return;
    if(self.gameHasEnded) return;
    
    self.lastSpawnTimeInterval += timeSinceLast;
    if (self.lastSpawnTimeInterval > TIME_BETWEEN_PIPE) {
        self.lastSpawnTimeInterval = 0;
        [self addPipes];
    }
}

-(void)update:(CFTimeInterval)currentTime {
    
    CFTimeInterval timeSinceLast = currentTime - self.lastUpdateTimeInterval;
    self.lastUpdateTimeInterval = currentTime;
    
    if (timeSinceLast > 1) {
        timeSinceLast = 1.0 / 60.0;
        self.lastUpdateTimeInterval = currentTime;
    }
    
    if (self.gameHasStarted) {
        CFTimeInterval elaspedTimeSinceStart = NSDate.date.timeIntervalSince1970 - self.timeStarted;
        if (elaspedTimeSinceStart > PIPE_DELAY) {
            self.pipesReady = YES;
        }
    }
    
    [self updateWithTimeSinceLastUpdate:timeSinceLast];
}

#pragma mark - Game scene actions

-(void)startGame {
    
    SKAction *fadeOutAction = [SKAction fadeOutWithDuration:0.6f];
    [self.tap runAction:fadeOutAction];
    [self.getReady runAction:fadeOutAction];
    
    [self.bird makeBirdFlap];
    self.timeStarted = NSDate.date.timeIntervalSince1970;
}

- (void)didBeginContact:(SKPhysicsContact *)contact {
    if (!self.gameHasEnded) [self endGame];
}

-(void)endGame {

    self.gameHasEnded = YES;
    
    for (SKNode *node in self.children) {
        if(![node.name isEqual: @"Bird"]){
            [node removeAllActions];
        }
    }
    
    [self flashAndShakeScene];
}

-(void)flashAndShakeScene {
    
    SKSpriteNode *flash = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"flash.png"]];
    flash.position = CGPointMake(self.size.width/2, self.size.height/2);
    flash.zPosition = 3.0;
    flash.size = self.size;
    [self addChild:flash];
    
    SKAction *flashFadeOut = [SKAction fadeOutWithDuration:0.15f];
    [flash runAction:flashFadeOut];
    
    SKAction *shakeRight = [SKAction moveTo:CGPointMake(-3, -3) duration:0.035f];
    SKAction *shakeLeft = [SKAction moveTo:CGPointMake(3, 3) duration:0.035f];
    SKAction *returnDefault = [SKAction moveTo:CGPointMake(0, 0) duration:0.0f];
    SKAction *shake = [SKAction sequence:@[shakeLeft, shakeRight]];
    SKAction *showSummary = [SKAction runBlock:^{
        [self gameOverSequence];
        [self populateAndShowGameSummary];
    }];
    
    [self.gameLayer runAction:[SKAction sequence:@[[SKAction repeatAction:shake count:26], returnDefault, showSummary]]];
}

-(void)gameOverSequence {
    
    SKAction *scoreFadeOut = [SKAction fadeOutWithDuration:0.15f];
    [self.scoreLabel runAction:scoreFadeOut];
    
    SKSpriteNode *gameOver = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"game-over.png"]];
    float yPosition = (self.size.height/3*2) + gameOver.size.height/2;
    gameOver.position = CGPointMake(self.size.width/2, yPosition);
    gameOver.zPosition = 3.0;
    gameOver.alpha = 0;
    [self addChild:gameOver];
    
    SKAction *gameOverUp = [SKAction moveToY:yPosition+10 duration:0.1f];
    gameOverUp.timingMode = SKActionTimingEaseOut;
    SKAction *gameOverFadeIn = [SKAction fadeInWithDuration:0.1f];
    SKAction *gameOverUpFade = [SKAction group:@[gameOverUp, gameOverFadeIn]];
    SKAction *gameOverDown = [SKAction moveToY:yPosition duration:0.1f];
    gameOverDown.timingMode = SKActionTimingEaseIn;
    [gameOver runAction:[SKAction sequence:@[gameOverUpFade, gameOverDown]]];
    
}

-(void)populateAndShowGameSummary {
    
    SKSpriteNode *summary = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"summary.png"]];
    summary.position = CGPointMake(self.size.width/2, -summary.size.height/2);
    summary.zPosition = 3.0;
    [self addChild:summary];
    
    SKLabelNode *summaryScore = [SKLabelNode labelNodeWithFontNamed:@"04b_19"];
    summaryScore.text = [NSString stringWithFormat:@"%d", 0];
    summaryScore.fontSize = 22;
    summaryScore.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    summaryScore.fontColor = [SKColor whiteColor];
    summaryScore.position = CGPointMake(92, 3);
    [summary addChild:summaryScore];
    
    SKAction *animateSummary = [SKAction moveTo:CGPointMake(self.size.width/2, self.size.height/2) duration:0.4f];
    animateSummary.timingMode = SKActionTimingEaseOut;
    SKAction *showButtonsAndIncremetScore = [SKAction runBlock:^{
        
        SKSpriteNode *playButton = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"play-button.png"]];
        playButton.position = CGPointMake(-summary.size.width/2+playButton.size.width/2, -summary.size.height);
        playButton.name = @"playButton";
        [summary addChild:playButton];
        
        SKSpriteNode *homeButton = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"home-button.png"]];
        homeButton.position = CGPointMake(summary.size.width/2-homeButton.size.width/2, -summary.size.height);
        homeButton.name = @"homeButton";
        [summary addChild:homeButton];
        
        __block int tempScore = 0;
        SKAction *scoreDelayAndIncrement = [SKAction sequence:@[[SKAction waitForDuration:0.1f], [SKAction runBlock:^{
            tempScore++;
            summaryScore.text = [NSString stringWithFormat:@"%d", tempScore];
        }]]];
        
        SKAction *scoreAction = [SKAction repeatAction:scoreDelayAndIncrement count:self.score];
        
        [summaryScore runAction:[SKAction sequence:@[scoreAction, [SKAction runBlock:^{
            [self addMedal:summary];
        }]]]];

    }];
    
    [summary runAction:[SKAction sequence:@[[SKAction waitForDuration:0.6f], animateSummary, [SKAction waitForDuration:0.2f], showButtonsAndIncremetScore]]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if (self.score > [defaults integerForKey:@"bestScore"]) {
        [defaults setInteger:self.score forKey:@"bestScore"];
        [defaults synchronize];
        
        SKSpriteNode *new = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"new.png"]];
        new.position = CGPointMake(38, -8);
        [summary addChild:new];
    }
    
    SKLabelNode *summaryBest = [SKLabelNode labelNodeWithFontNamed:@"04b_19"];
    summaryBest.text = [NSString stringWithFormat:@"%ld", (long)[defaults integerForKey:@"bestScore"]];
    summaryBest.fontSize = 22;
    summaryBest.horizontalAlignmentMode = SKLabelHorizontalAlignmentModeRight;
    summaryBest.fontColor = [SKColor whiteColor];
    summaryBest.position = CGPointMake(92, -39);
    [summary addChild:summaryBest];
    
}

-(void)addMedal: (SKSpriteNode*)summaryNode {
    
    // TODO: sprite frame bug
    
    BOOL medalWorthy = NO;
    
    if (self.score >= 10) {
        SKSpriteNode *bronzeMedal = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"bronze.png"]];
        bronzeMedal.position = CGPointMake(-66, -8);
        bronzeMedal.name = @"medal";
        [summaryNode addChild:bronzeMedal];
        medalWorthy = YES;
    }
    if (self.score >= 20) {
        SKSpriteNode *silverMedal = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"silver.png"]];
        silverMedal.position = CGPointMake(-66, -8);
        silverMedal.name = @"medal";
        [summaryNode addChild:silverMedal];
        medalWorthy = YES;
    }
    if (self.score >= 30) {
        SKSpriteNode *goldMedal = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"gold.png"]];
        goldMedal.position = CGPointMake(-66, -8);
        goldMedal.name = @"medal";
        [summaryNode addChild:goldMedal];
        medalWorthy = YES;
    }
    if (self.score >= 40) {
        SKSpriteNode *platinumMedal = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"platinum.png"]];
        platinumMedal.position = CGPointMake(-66, -8);
        platinumMedal.name = @"medal";
        [summaryNode addChild:platinumMedal];
        medalWorthy = YES;
    }
    
    if (medalWorthy) {
        
        SKSpriteNode *sparkleNode = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"sparkle03.png"]];
        sparkleNode.position = CGPointMake(0, 0);
        [[summaryNode childNodeWithName:@"medal"] addChild:sparkleNode];
        
        SKTexture *s1 = [self.atlas textureNamed:@"sparkle01.png"];
        SKTexture *s2 = [self.atlas textureNamed:@"sparkle02.png"];
        SKTexture *s3 = [self.atlas textureNamed:@"sparkle03.png"];
        NSArray *sparkleFrames = @[s1, s2, s3, s2, s1];
        
        SKAction *sparkleAnimation = [SKAction animateWithTextures:sparkleFrames timePerFrame:0.15f resize:NO restore:NO];
        
        SKAction *sparkleDelay = [SKAction waitForDuration:0.4f];
        
        SKAction *sparkleRandomPosition = [SKAction runBlock:^{
            int halfRange = [SKSpriteNode spriteNodeWithTexture: [self.atlas textureNamed:@"bronze.png"]].size.width / 2;
            int randomX = arc4random() % halfRange;
            int randomY = arc4random() % halfRange;
            sparkleNode.position = CGPointMake(-halfRange + (randomX*2), -halfRange + (randomY*2));
        }];
        
        [sparkleNode runAction:[SKAction repeatActionForever:[SKAction sequence:@[sparkleRandomPosition, sparkleAnimation, sparkleDelay]]]];
    }
}


#pragma mark - Touch events

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if (!self.gameHasStarted) {
        self.gameHasStarted = YES;
        [self startGame];
        return;
    }
    
    if (!self.gameHasEnded) {
        [self.bird makeBirdFlap];
        return;
    }
    
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInNode:self];
    SKNode *node = [self nodeAtPoint:location];
    
    if ([node.name isEqualToString:@"playButton"]) {
        SKTransition *fade = [SKTransition fadeWithDuration:1.0f];
        SKScene *gameScene = [[GameScene alloc] initWithSize:self.size];
        [self.view presentScene:gameScene transition: fade];
    }
    
    if ([node.name isEqualToString:@"homeButton"]) {
        SKTransition *fade = [SKTransition fadeWithDuration:1.0f];
        SKScene *homeScene = [[HomeScene alloc] initWithSize:self.size];
        [self.view presentScene:homeScene transition: fade];
    }
}

#pragma mark - Other game objects

-(void)rollParallaxGround {
    
    SKSpriteNode *ground1 = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"ground.png"]];
    int groundY = ground1.size.height/2;
    ground1.position = CGPointMake(ground1.size.width/2, groundY);
    ground1.zPosition = 2.0;
    [self addChild:ground1];
    
    SKAction *move = [SKAction moveTo:CGPointMake(-ground1.size.width/2, groundY) duration:3.4f];
    SKAction *reset = [SKAction moveTo:CGPointMake(ground1.size.width/2, groundY) duration:0.0f];
    SKAction *moveReset = [SKAction sequence:@[move, reset]];
    [ground1 runAction:[SKAction repeatActionForever:moveReset]];
    
    ground1.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ground1.size];
    ground1.physicsBody.dynamic = YES;
    ground1.physicsBody.categoryBitMask = obsticleCategory;
    ground1.physicsBody.contactTestBitMask = birdCategory;
    ground1.physicsBody.collisionBitMask = 0;
    
    SKSpriteNode *ground2 = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"ground.png"]];
    ground2.position = CGPointMake(ground2.size.width+ground2.size.width/2, groundY);
    ground2.zPosition = 2.0;
    [self addChild:ground2];
    
    SKAction *move2 = [SKAction moveTo:CGPointMake(ground2.size.width/2, groundY) duration:3.4f];
    SKAction *reset2 = [SKAction moveTo:CGPointMake(ground2.size.width+ground2.size.width/2, groundY) duration:0.0f];
    SKAction *moveReset2 = [SKAction sequence:@[move2, reset2]];
    [ground2 runAction:[SKAction repeatActionForever:moveReset2]];
    
    ground2.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:ground2.size];
    ground2.physicsBody.dynamic = YES;
    ground2.physicsBody.categoryBitMask = obsticleCategory;
    ground2.physicsBody.contactTestBitMask = birdCategory;
    ground2.physicsBody.collisionBitMask = 0;
}

-(void)addPipes {
    
    SKSpriteNode *pipeBottom = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"pipe-bottom.png"]];
    int halfWidth = pipeBottom.size.width/2;
    int halfHeight = pipeBottom.size.height/2;
    int randomY = (arc4random() % PIPE_MIN_X);
    pipeBottom.position = CGPointMake(self.frame.size.width+halfWidth, (-randomY) + halfHeight);
    
    pipeBottom.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipeBottom.size];
    pipeBottom.physicsBody.dynamic = YES;
    pipeBottom.physicsBody.categoryBitMask = obsticleCategory;
    pipeBottom.physicsBody.contactTestBitMask = birdCategory;
    pipeBottom.physicsBody.collisionBitMask = 0;
    
    SKSpriteNode *pipeTop = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"pipe-top.png"]];
    pipeTop.position = CGPointMake(0, (pipeBottom.size.height) + PIPE_GAP);
    
    pipeTop.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:pipeTop.size];
    pipeTop.physicsBody.dynamic = YES;
    pipeTop.physicsBody.categoryBitMask = obsticleCategory;
    pipeTop.physicsBody.contactTestBitMask = birdCategory;
    pipeTop.physicsBody.collisionBitMask = 0;
    
    [pipeBottom addChild:pipeTop];
    [self addChild:pipeBottom];
    
    SKAction *pipeMove = [SKAction moveTo:CGPointMake(-pipeBottom.size.width, (-randomY) + halfHeight) duration:4.0f];
    SKAction *pipeMoveDone = [SKAction removeFromParent];
    SKAction *pipeMovement = [SKAction sequence:@[pipeMove, pipeMoveDone]];
    
    SKAction *scoreDelay = [SKAction waitForDuration:2.5f];
    SKAction *scoreUpdate = [SKAction runBlock:^{
        self.score++;
        self.scoreLabel.text = [NSString stringWithFormat:@"%d", self.score];
    }];
    
    SKAction *scoreDelayUpdate = [SKAction sequence:@[scoreDelay, scoreUpdate]];
    
    [pipeBottom runAction:[SKAction group:@[pipeMovement, scoreDelayUpdate]]];
}



#pragma mark - Utility methods

-(int)yFromTopForSprite:(SKSpriteNode *)sprite desiredY:(int)desiredY {
    
	return (self.size.height - sprite.size.height/2) - desiredY;
}

@end
