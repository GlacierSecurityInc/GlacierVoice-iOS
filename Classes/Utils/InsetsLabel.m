//
//  InsetsLabel.m
//  Created by Glacier Security on 11/7/19.

#import "InsetsLabel.h"

@implementation InsetsLabel

- (id)init
{
    self = [super init];
    if (self) {
        self.contentInsets = UIEdgeInsetsZero;
    }
    
    return self;
}

- (void) drawText:(CGRect)rect {
    CGRect insetRect = UIEdgeInsetsInsetRect(rect, self.contentInsets);
    [super drawTextInRect:insetRect];
}

- (CGSize) sizeThatFits:(CGSize)size {
    return [self addInsets:[super sizeThatFits:size]];
}

- (CGSize) intrinsicContentSize {
    return [self addInsets:super.intrinsicContentSize];
}

- (CGSize) addInsets:(CGSize)size {
    CGFloat width = size.width + self.contentInsets.left + self.contentInsets.right;
    CGFloat height = size.height + self.contentInsets.top + self.contentInsets.bottom;
    return CGSizeMake(width, height);
}

@end
