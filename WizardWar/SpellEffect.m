//
//  SpellEffect.m
//  WizardWar
//
//  Created by Sean Hess on 8/20/13.
//  Copyright (c) 2013 Orbital Labs. All rights reserved.
//

#import "SpellEffect.h"
#import "SpellBubble.h"
#import "EffectSleep.h"

// TEST bubble steal (should always steal)

// TODO if monster blows up bubbles, the fireballs still act carried. Monster should blow up anything inside? or at least reset it. Monster should blow up anything inside. somehow.

// Better links: when something happens to the parent, it happens to the child
// Better links: detect whether you can change a link by whether it is currently linked
// Well, ANYTHING that happens to the parent happens to child, right?
// speed, destroy, etc

// 1. If a spell is linked, it no longer interacts AT ALL (not even with its original spell)
// 2. If the parent is updated, propogate to child

@implementation SpellEffect
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    NSLog(@"OVERRIDE effectSpell");
    abort();
    return NO;
}
@end

@implementation SENone
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    return NO;
}
@end

@implementation SEWeaker
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    if (spell.direction == otherSpell.direction) return NO;
    if ([SECarry isCarried:spell otherSpell:otherSpell]) return NO;    
    spell.strength -= otherSpell.damage;
    if (spell.strength < 0)
        spell.strength = 0;
    return YES;
}
@end

@implementation SEDestroy
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    if (spell.direction == otherSpell.direction) return NO;
    if ([SECarry isCarried:spell otherSpell:otherSpell]) return NO;
    spell.strength = 0;
    return YES;
}
@end

@implementation SEDestroyOlder
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    // do not destroy if I am newer than them
    if (spell.createdTick > otherSpell.createdTick) return NO;
    if ([SECarry isCarried:spell otherSpell:otherSpell]) return NO;    
    spell.strength = 0;
    return YES;
}
@end


@implementation SEStronger
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    // it DOES interact with stronger, because I want it to :)
    spell.damage += 1;
    spell.strength += 1;
    return YES;
}
@end

@implementation SECarry
+(BOOL)isCarried:(Spell*)spell otherSpell:(Spell*)otherSpell {
    if ([spell.linkedSpell isKindOfClass:SpellBubble.class] && spell.linkedSpell.status != SpellStatusDestroyed && spell.linkedSpell != otherSpell) return YES;
//    if ([otherSpell.spellEffect isKindOfClass:SECarry.class]) return YES;
    return NO;
}

-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    if ([SECarry isCarried:spell otherSpell:otherSpell]) return NO;
    
    // TODO: make sure they don't hit multiple times, if already carried
    if (spell.position == otherSpell.position && spell.speed == otherSpell.speed && spell.direction == otherSpell.direction)
        return NO;
    
    NSLog(@"CARRY ME");
    spell.spellEffect = [SECarry new]; // I guess this means it is being carried
    spell.linkedSpell = otherSpell;
    spell.position = otherSpell.position;
    spell.speed = otherSpell.speed;
    spell.direction = otherSpell.direction;
    return YES;
}
@end

@implementation SESleep
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    if ([SECarry isCarried:spell otherSpell:otherSpell]) return NO;
    
    spell.speed = 0;
    spell.effect = [EffectSleep new];
    [spell.effect start:tick player:nil];
    return YES;
}
@end

@implementation SESpeed
+(id)setTo:(CGFloat)speed {
    SESpeed * effect = [SESpeed new];
    effect.set = speed;
    return effect;
}

+(id)speedUp:(CGFloat)up slowDown:(CGFloat)down {
    SESpeed * effect = [SESpeed new];
    effect.up = up;
    effect.down = down;
    return effect;
}

-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    if (spell.direction == otherSpell.direction) return NO;
    if ([SECarry isCarried:spell otherSpell:otherSpell]) return NO;
    if ([spell.effect isKindOfClass:[EffectSleep class]]) return NO;
    if (self.up > 0) {
        if (spell.direction == otherSpell.direction) {
            spell.speed += self.up;
        }
        else {
            spell.speed -= self.down;
            if (spell.speed < 0) {
                spell.direction *= -1;
                spell.speed *= -1;
            }            
        }
    } else {
        spell.speed = self.set;
    }
    return YES;
}

@end

@implementation SEReflect
-(BOOL)applyToSpell:(Spell*)spell otherSpell:(Spell*)otherSpell tick:(NSInteger)tick {
    if (spell.direction == otherSpell.direction) return NO;
    if ([SECarry isCarried:spell otherSpell:otherSpell]) return NO;    
    spell.direction = otherSpell.direction;
    return YES;
}
@end
