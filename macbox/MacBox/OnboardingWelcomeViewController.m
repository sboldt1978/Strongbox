//
//  OnboardingWelcomeViewController.m
//  MacBox
//
//  Created by Strongbox on 22/11/2020.
//  Copyright © 2020 Mark McGuill. All rights reserved.
//

#import "OnboardingWelcomeViewController.h"
#import "Strongbox-Swift.h"

@interface OnboardingWelcomeViewController ()

@property (weak) IBOutlet NSButton *checkboxTouchId;
@property (weak) IBOutlet NSButton *checkboxAutoFill;
@property (weak) IBOutlet NSButton *checkboxPin;
@property (weak) IBOutlet NSTextField *textFieldPin;

@property (nonatomic, strong) NSString *capturedPin;

@end


@interface OnboardingWelcomeViewController (SimplePinModalDelegate)
- (void)simplePinModalDidSubmitPin:(NSString *)pin;
- (void)simplePinModalDidCancel;
@end

@implementation OnboardingWelcomeViewController (SimplePinModalDelegate)

- (void)simplePinModalDidSubmitPin:(NSString *)pin {
    NSLog(@"🔐 PIN captured from modal in onboarding: %@", pin);
    self.capturedPin = pin;
}

- (void)simplePinModalDidCancel {
    NSLog(@"🔐 PIN modal was cancelled in onboarding");
    self.checkboxPin.state = NSControlStateValueOff;
    self.capturedPin = nil;
}

@end

@implementation OnboardingWelcomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setInitialState:self.showTouchID showAutoFill:self.showAutoFill enableAutoFill:self.enableAutoFill];
}

- (void)setInitialState:(BOOL)showTouchID
           showAutoFill:(BOOL)showAutoFill
         enableAutoFill:(BOOL)enableAutoFill
{
    self.textFieldPin.hidden = true;
    self.checkboxPin.hidden = false;
    self.checkboxPin.state = NSControlStateValueOff;
    self.checkboxTouchId.hidden = !showTouchID;
    
#ifndef DEBUG
    self.checkboxTouchId.state = NSControlStateValueOn;
#else
    self.checkboxTouchId.state = NSControlStateValueOff;
#endif
    
    self.checkboxAutoFill.hidden = !showAutoFill;
    self.checkboxAutoFill.state = enableAutoFill ? NSControlStateValueOn : NSControlStateValueOff;
}

- (IBAction)onDismiss:(id)sender {
    self.onNext(NO, NO, NO, nil);
}

- (IBAction)onNext:(id)sender {
    BOOL enableTouchID = self.checkboxTouchId.state == NSControlStateValueOn;
    BOOL enableAutoFill = self.checkboxAutoFill.state == NSControlStateValueOn;
    BOOL enablePin = self.checkboxPin.state == NSControlStateValueOn;
    
    NSString* pin = nil;
    
    if (enablePin) {
        pin = self.capturedPin;
        
        if (!pin || pin.length == 0) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = NSLocalizedString(@"pin_required_title", @"PIN Required");
            alert.informativeText = NSLocalizedString(@"pin_required_message", @"Please set a PIN using the PIN modal.");
            alert.alertStyle = NSAlertStyleWarning;
            [alert addButtonWithTitle:NSLocalizedString(@"generic_ok", @"OK")];
            [alert runModal];
            return;
        }

        if (pin.length < 4) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = NSLocalizedString(@"pin_too_short_title", @"PIN Too Short");
            alert.informativeText = NSLocalizedString(@"pin_too_short_message", @"PIN must be at least 4 characters long.");
            alert.alertStyle = NSAlertStyleWarning;
            [alert addButtonWithTitle:NSLocalizedString(@"generic_ok", @"OK")];
            [alert runModal];
            return;
        }
    }
    
    NSLog(@"🔐 Onboarding: enablePin=%@, pin=%@", enablePin ? @"YES" : @"NO", pin ?: @"nil");
    self.onNext(NO, enableTouchID, enableAutoFill, pin);
}

- (IBAction)pinCodeAction:(id)sender {
    if (self.checkboxPin.state == NSControlStateValueOn) {
        [SimplePinModal showFrom:self delegate:self];
    } else {
        self.textFieldPin.hidden = true;
        self.textFieldPin.stringValue = @"";
        self.capturedPin = nil;
    }
}

@end
