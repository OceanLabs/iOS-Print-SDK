//
//  MPTransitionEnumerations.h
//  MPFoldTransition (v1.0.1)
//
//  Created by Mark Pospesel on 5/14/12.
//  Copyright (c) 2012 Mark Pospesel. All rights reserved.
//

#ifndef OLFoldTransition_OLTransitionEnumerations_h
#define OLFoldTransition_OLTransitionEnumerations_h

// Action to take upon completion of the transition
enum {
	OLTransitionActionAddRemove, // add/remove subViews upon completion
	OLTransitionActionShowHide,	 // show/hide subViews upon completion
	OLTransitionActionNone		 // take no action (use when container view controller will handle add/remove)
} typedef OLTransitionAction;


#endif
