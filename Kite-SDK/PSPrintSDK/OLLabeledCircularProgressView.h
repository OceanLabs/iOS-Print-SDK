//
//  DALabeledCircularProgressView.h
//  DACircularProgressExample
//
//  Created by Josh Sklar on 4/8/14.
//  Copyright (c) 2014 Shout Messenger. All rights reserved.
//

#import "OLCircularProgressView.h"

/**
 @class OLLabeledCircularProgressView
 
 @brief Subclass of OLCircularProgressView that adds a UILabel.
 */
@interface OLLabeledCircularProgressView : OLCircularProgressView

/**
 UILabel placed right on the OLCircularProgressView.
 */
@property (strong, nonatomic) UILabel *progressLabel;

@end
