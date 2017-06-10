//
//  SSUEmailLoginViewController.m
//  SSUMobile
//
//  Created by Eric Amorde on 2/7/15.
//  Copyright (c) 2015 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSUEmailLoginViewController.h"
#import "SSULDAPCredentials.h"
#import "SSUMobile-Swift.h"

@interface SSUEmailLoginViewController () <UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;
@property (weak, nonatomic) IBOutlet UISwitch *rememberSwitch;

- (IBAction)loginButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation SSUEmailLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    SSULDAPCredentials * credentials = [SSULDAPCredentials sharedInstance];
    if (credentials.hasCredentials) {
        self.usernameTextField.text = credentials.username;
        self.passwordTextField.text = credentials.password;
        self.rememberSwitch.on = credentials.rememberLogin;
    }
}

- (NSString *) username {
    return self.usernameTextField.text;
}

- (NSString *) password {
    return self.passwordTextField.text;
}

- (BOOL) rememberLogin {
    return self.rememberSwitch.on;
}

- (void) sanitize {
    // Remove "@sonoma.edu" from the username, if it's there
//    NSString * emailSuffix = [NSString stringWithFormat:@"@%@",[[SSUConfiguration sharedInstance] stringForKey:SSUEmailDomainKey]];
//    self.usernameTextField.text = [self.usernameTextField.text stringByReplacingOccurrencesOfString:emailSuffix withString:@""];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.usernameTextField) {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField) {
        // Hitting "Enter" on the password field should attempt to login
        [self login];
    }
    
    return YES;
}

#pragma mark - Actions

- (void) login {
    [self sanitize];
    if ([self.delegate respondsToSelector:@selector(loginControllerDidLogin:)]) {
        [self.delegate loginControllerDidLogin:self];
    }
}

- (void) cancel {
    if ([self.delegate respondsToSelector:@selector(loginControllerDidCancel:)]) {
        [self.delegate loginControllerDidCancel:self];
    }
}

#pragma mark - Button Actions

- (IBAction)loginButtonPressed:(UIBarButtonItem *)sender {
    [self login];
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self cancel];
}

@end
