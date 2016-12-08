//
//  MPFlipEnumerations.h
//  MPTransition (v1.1.0)
//
//  Created by Mark Pospesel on 5/15/12.
//  Copyright (c) 2012 Mark Pospesel. All rights reserved.
//

#ifndef OLFoldTransition_OLFlipEnumerations_h
#define OLFoldTransition_OLFlipEnumerations_h

// Bit 0: Direction - Forward (unset) vs.Backward (set)
// Forward = page flip from right to left (horizontal) or bottom to top (vertical)
// Backward = page flip from left to right (horizontal) or top to bottom (vertical)

// Bit 1: Orientation - Horizontal (unset) vs. Vertical (set)
// Horizontal = page flips right to left about a vertical spine
// Vertical = page flips bottom to top about a horizontal spine

// Bit 2: Perspective - Normal (unset) vs. Reverse (set)
// Normal = page flips towards viewer
// Reverse = page flips away from viewer

#import <Foundation/Foundation.h>

enum {
	// current view folds away into center, next view slides in flat from top & bottom
	OLFlipStyleDefault				= 0,
	OLFlipStyleDirectionBackward	= 1 << 0,
	OLFlipStyleOrientationVertical	= 1 << 1,
	OLFlipStylePerspectiveReverse	= 1 << 2
};
typedef NSUInteger OLFlipStyle;

enum {
	OLFlipAnimationStage1 = 0,
	OLFlipAnimationStage2 = 1
} typedef OLFlipAnimationStage;

#define OLFlipStyleDirectionMask	OLFlipStyleDirectionBackward
#define OLFlipStyleOrientationMask	OLFlipStyleOrientationVertical
#define OLFlipStylePerspectiveMask	OLFlipStylePerspectiveReverse

static inline OLFlipStyle OLFlipStyleFlipDirectionBit(OLFlipStyle style) { return (style & ~OLFlipStyleDirectionMask) | ((style & OLFlipStyleDirectionMask) == OLFlipStyleDirectionBackward? 0 : OLFlipStyleDirectionBackward); }

#endif
