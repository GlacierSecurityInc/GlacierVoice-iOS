//
//  InsetsLabel.h
//  Created by Glacier Security on 11/7/19.

#import <UIKit/UIKit.h>

@interface InsetsLabel : UILabel

@property(nonatomic, assign) UIEdgeInsets contentInsets;
@property(nonatomic, readonly) CGSize intrinsicContentSize;

- (void) drawText:(CGRect)rect;
- (CGSize) sizeThatFits:(CGSize)size;

@end
