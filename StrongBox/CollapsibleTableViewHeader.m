//
//  CollapsibleTableViewHeader.m
//  Strongbox-iOS
//
//  Created by Mark on 01/05/2019.
//  Copyright © 2014-2021 Mark McGuill. All rights reserved.
//

#import "CollapsibleTableViewHeader.h"
#import "Utils.h"

@interface CollapsibleTableViewHeader ()

@property UILabel* titleLabel;
@property UIButton* button1;
@property UIButton* toggleCollapseButton;
@property (nonatomic, copy) void (^onCopyButton)(void);

@end

@implementation CollapsibleTableViewHeader

- (void)addTopBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
    UIView *border = [UIView new];
    border.backgroundColor = color;
    [border setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin];
    border.frame = CGRectMake(0, 0, self.frame.size.width, borderWidth);
    [self addSubview:border];
}

- (void)addBottomBorderWithColor:(UIColor *)color andWidth:(CGFloat) borderWidth {
    UIView *border = [UIView new];
    border.backgroundColor = color;
    [border setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    border.frame = CGRectMake(0, self.frame.size.height - borderWidth, self.frame.size.width, borderWidth);
    [self addSubview:border];
}

- (instancetype)initWithOnCopy:(void(^)(void))onCopy {
    if (self = [super initWithFrame:CGRectZero]) {
        self.onCopyButton = onCopy;

        self.titleLabel = [[UILabel alloc] init];
        self.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
        self.titleLabel.textColor = UIColor.secondaryLabelColor;
        self.button1 = [[UIButton alloc] init];
        UIImage* image1 = [UIImage systemImageNamed:@"doc.on.doc.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
        [self.button1 setImage:image1 forState:UIControlStateNormal];
        [self.button1 addTarget:self action:@selector(onCopyButton:) forControlEvents:UIControlEventTouchUpInside];

        self.toggleCollapseButton = [[UIButton alloc] init];
        UIImage* image3 = [UIImage systemImageNamed:@"chevron.right.circle.fill" withConfiguration:[UIImageSymbolConfiguration configurationWithScale:UIImageSymbolScaleLarge]];
        self.toggleCollapseButton.tintColor = UIColor.secondaryLabelColor;
        [self.toggleCollapseButton setImage:image3 forState:UIControlStateNormal];
        [self.toggleCollapseButton addTarget:self action:@selector(sectionHeaderWasTouched:) forControlEvents:UIControlEventTouchUpInside];

        [self.contentView addSubview:self.titleLabel];
        [self.contentView addSubview:self.button1];
        [self.contentView addSubview:self.toggleCollapseButton];

        UITapGestureRecognizer *headerTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sectionHeaderWasTouched:)];
        [self addGestureRecognizer:headerTapGesture];

        self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        self.button1.translatesAutoresizingMaskIntoConstraints = NO;
        self.toggleCollapseButton.translatesAutoresizingMaskIntoConstraints = NO;

        [self.contentView.heightAnchor constraintEqualToConstant:48].active = YES;

        if (onCopy) {
            [self.button1.widthAnchor constraintEqualToConstant:32].active = YES;
            [self.button1.heightAnchor constraintEqualToConstant:32].active = YES;
        } else {
            [self.button1.widthAnchor constraintEqualToConstant:0].active = YES;
            [self.button1.heightAnchor constraintEqualToConstant:0].active = YES;
        }
        [self.toggleCollapseButton.widthAnchor constraintEqualToConstant:32].active = YES;
        [self.toggleCollapseButton.heightAnchor constraintEqualToConstant:32].active = YES;

        [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.titleLabel setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
        [self.button1 setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        [self.toggleCollapseButton setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];

        UIView *cv = self.contentView;

        [NSLayoutConstraint activateConstraints:@[
            [self.titleLabel.leadingAnchor constraintEqualToAnchor:cv.leadingAnchor constant:20],
            [self.toggleCollapseButton.trailingAnchor constraintEqualToAnchor:cv.trailingAnchor constant:-20.0],
            [self.button1.trailingAnchor constraintEqualToAnchor:self.toggleCollapseButton.leadingAnchor constant:-20.0],
            [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:self.button1.leadingAnchor constant:-8.0],
            [self.titleLabel.centerYAnchor constraintEqualToAnchor:cv.centerYAnchor],
            [self.button1.centerYAnchor constraintEqualToAnchor:cv.centerYAnchor],
            [self.toggleCollapseButton.centerYAnchor constraintEqualToAnchor:cv.centerYAnchor],
            [self.button1.heightAnchor constraintGreaterThanOrEqualToConstant:32.0],
            [self.toggleCollapseButton.heightAnchor constraintGreaterThanOrEqualToConstant:32.0],
        ]];

        BOOL dark = self.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
        self.contentView.backgroundColor = dark ? ColorFromRGB(0x0d1117) : ColorFromRGB(0xf6f8fa);

        [self addBottomBorderWithColor:UIColor.systemBackgroundColor andWidth:1.0f];
        [self addTopBorderWithColor:UIColor.systemBackgroundColor andWidth:1.0f];
    }
    return self;
}

- (void)setTitleText:(NSString * _Nullable)title {
    self.textLabel.hidden = YES;
    self.textLabel.text = nil;

    self.titleLabel.text = title;
    self.titleLabel.hidden = (title.length == 0);
    self.titleLabel.alpha = title.length == 0 ? 0.0 : 1.0;
    self.accessibilityLabel = title;
}

- (void)sectionHeaderWasTouched:(id)sender {
    if(self.onToggleSection) {
        self.onToggleSection();
    }
}

- (void)onCopyButton:(id)sender {
    if(self.onCopyButton) {
        self.onCopyButton();
    }
}

- (void)setCollapsed:(BOOL)collapsed {
    [self.toggleCollapseButton setTransform:CGAffineTransformMakeRotation(collapsed ? 0.0 : M_PI / 2)];
}

@end
