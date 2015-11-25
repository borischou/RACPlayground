//
//  RWViewController.m
//  RWReactivePlayground
//
//  Created by Colin Eberhardt on 18/12/2013.
//  Copyright (c) 2013 Colin Eberhardt. All rights reserved.
//

#import "RWViewController.h"
#import "RWDummySignInService.h"
#import <ReactiveCocoa/ReactiveCocoa.h>

@interface RWViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UILabel *signInFailureText;

//@property (nonatomic) BOOL passwordIsValid;
//@property (nonatomic) BOOL usernameIsValid;
@property (strong, nonatomic) RWDummySignInService *signInService;

@end

@implementation RWViewController

- (void)viewDidLoad {
  [super viewDidLoad];
  
  //[self updateUIState];
  
  self.signInService = [RWDummySignInService new];
  
  // handle text changes for both text fields
  //[self.usernameTextField addTarget:self action:@selector(usernameTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  //[self.passwordTextField addTarget:self action:@selector(passwordTextFieldChanged) forControlEvents:UIControlEventEditingChanged];
  
  // initially hide the failure message
  self.signInFailureText.hidden = YES;
    
    //RACCommand
    
    //custom code here
    RACSignal *validUsernameSignal = [self.usernameTextField.rac_textSignal map:^id(NSString *text) {
        return @([self isValidUsername:text]);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordTextField.rac_textSignal map:^id(NSString *pass) {
        return @([self isValidPassword:pass]);
    }];
    
    //react to background color
    RAC(self.passwordTextField, backgroundColor) = [validPasswordSignal map:^id(NSNumber *passwordValid) {
        return passwordValid.boolValue? [UIColor clearColor]: [UIColor yellowColor];
    }];
    
    RAC(self.usernameTextField, backgroundColor) = [validUsernameSignal map:^id(NSNumber *usernameValid) {
        return usernameValid.boolValue? [UIColor clearColor]: [UIColor yellowColor];
    }];
    
    //react to sign in button
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUsernameSignal, validPasswordSignal] reduce:^id(NSNumber *usernameValid, NSNumber *passwordValid) {
        return @(usernameValid.boolValue && passwordValid.boolValue);
    }];
    
    [signUpActiveSignal subscribeNext:^(NSNumber *signUpActive) {
        self.signInButton.enabled = signUpActive.boolValue;
    }];
    
    [[[[self.signInButton rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(id x) {
        self.signInButton.enabled = NO;
        self.signInFailureText.hidden = YES;
    }] flattenMap:^id(id value) {
        return [self signInSignal];
    }] subscribeNext:^(NSNumber *signedIn) {
        self.signInButton.enabled = YES;
        BOOL success = signedIn.boolValue;
        self.signInFailureText.hidden = success;
        if (success) {
            [self performSegueWithIdentifier:@"signInSuccess" sender:self];
        }
    }];
}

- (BOOL)isValidUsername:(NSString *)username {
  return username.length > 3;
}

- (BOOL)isValidPassword:(NSString *)password {
  return password.length > 3;
}

-(RACSignal *)signInSignal
{
    return [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [self.signInService signInWithUsername:self.usernameTextField.text password:self.passwordTextField.text complete:^(BOOL success) {
            [subscriber sendNext:@(success)];
            [subscriber sendCompleted];
        }];
        return nil;
    }];
}

//- (IBAction)signInButtonTouched:(id)sender {
//  // disable all UI controls
//  self.signInButton.enabled = NO;
//  self.signInFailureText.hidden = YES;
//  
//  // sign in
//  [self.signInService signInWithUsername:self.usernameTextField.text
//                            password:self.passwordTextField.text
//                            complete:^(BOOL success) {
//                              self.signInButton.enabled = YES;
//                              self.signInFailureText.hidden = success;
//                              if (success) {
//                                [self performSegueWithIdentifier:@"signInSuccess" sender:self];
//                              }
//                            }];
//}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self.usernameTextField resignFirstResponder];
    [self.passwordTextField resignFirstResponder];
}

// updates the enabled state and style of the text fields based on whether the current username
// and password combo is valid
//- (void)updateUIState {
  //self.usernameTextField.backgroundColor = self.usernameIsValid ? [UIColor clearColor] : [UIColor yellowColor];
  //self.passwordTextField.backgroundColor = self.passwordIsValid ? [UIColor clearColor] : [UIColor yellowColor];
  //self.signInButton.enabled = self.usernameIsValid && self.passwordIsValid;
//}

//- (void)usernameTextFieldChanged {
  //self.usernameIsValid = [self isValidUsername:self.usernameTextField.text];
  //[self updateUIState];
//}

//- (void)passwordTextFieldChanged {
  //self.passwordIsValid = [self isValidPassword:self.passwordTextField.text];
  //[self updateUIState];
//}

@end
