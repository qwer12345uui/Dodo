//
//  DodoLoader.m
//  Dodo
//
//  Created by Noah Little on 8/8/2026.
//

#import <Tweak.h>

__attribute__((constructor)) static void init() {
    [Tweak setup];
}
