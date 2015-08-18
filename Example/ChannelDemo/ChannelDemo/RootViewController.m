//
//  RootViewController.m
//  ChannelDemo
//
//  Created by Justin Schneck on 8/17/15.
//  Copyright (c) 2015 PhoenixFramework. All rights reserved.
//

#import "RootViewController.h"
#import <PhoenixClient/PhoenixClient.h>

@interface RootViewController () <UITextFieldDelegate>

@property (nonatomic, retain) PhxSocket *socket;
@property (nonatomic, retain) PhxChannel *channel;
@property (nonatomic, retain) IBOutlet UITextView *textView;
@property (nonatomic, retain) IBOutlet UITextField *message;
@property (nonatomic, retain) IBOutlet UITextField *username;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *sendButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *keyboardHeight;
- (IBAction)dismissKeyboard:(id)sender;
@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.message.delegate = self;
    self.textView.layoutManager.allowsNonContiguousLayout = NO;
    self.socket = [[PhxSocket alloc] initWithURL:[NSURL URLWithString:@"http://localhost:4000/socket/websocket"] heartbeatInterval:20];
    [self.socket connectWithParams:@{@"user_id":@123}];
    self.channel = [[PhxChannel alloc] initWithSocket:self.socket topic:@"rooms:lobby" params:@{}];
    
    [self.channel onEvent:@"new:msg" callback:^(id message, id ref) {
        NSLog(@"New Message Received: %@", message);
        NSString* user = [message valueForKey:@"user"];
        NSString* body = [message valueForKey:@"body"];
        if ([user isEqual:[NSNull null]]) {user = @"anonymous";}
        
        [self appendString:[NSString stringWithFormat:@"[%@] %@", user, body]];
    }];
    
    [self.channel onEvent:@"user:entered" callback:^(id message, id ref) {
        NSLog(@"New User Entered: %@", message);
        NSString* user = [message valueForKey:@"user"];
        if ([user isEqual:[NSNull null]]) {user = @"anonymous";}
        [self appendString:[NSString stringWithFormat:@"[%@ entered]", user]];
    }];
    
    [self.channel join];
    [self observeKeyboard];
    [self resizeToolbarItems:self.view.frame.size];
}

- (void)observeKeyboard {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// The callback for frame-changing of keyboard
- (void)keyboardWillShow:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *kbFrame = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect keyboardFrame = [kbFrame CGRectValue];
    
    CGFloat height = keyboardFrame.size.height;
    
    NSLog(@"Updating constraints.");
    // Because the "space" is actually the difference between the bottom lines of the 2 views,
    // we need to set a negative constant value here.
    self.keyboardHeight.constant = -height;
    
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.keyboardHeight.constant = 0;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (IBAction)dismissKeyboard:(id)sender {
    [self.textView resignFirstResponder];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)appendString:(NSString*)string {
    self.textView.text = [self.textView.text stringByAppendingString:[NSString stringWithFormat:@"\n%@", string]];
    [self scrollTextViewToBottom:self.textView];

}

- (IBAction)sendMessage:(id)sender {
    if ([self.message.text isEqualToString:@""]) {
        return;
    }
    NSString *user = self.username.text;
    if ([user isEqualToString:@""]) {user = @"anonymous";}
    [self.channel pushEvent:@"new:msg" payload:@{@"user":user, @"body":self.message.text}];
    self.message.text = @"";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.message) {
        [self sendMessage:textField];
        return NO;
    }
    return YES;
}

-(void)scrollTextViewToBottom:(UITextView *)textView {
    if(textView.text.length > 0) {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}

- (void)resizeToolbarItems:(CGSize)size {
    float toolbarWidth = size.width;
    float usernameWidth = self.username.frame.size.width;
    float sendButtonWidth = 80;
    [self.message setFrame:CGRectMake(self.message.frame.origin.x, self.username.frame.origin.y + usernameWidth + 20, toolbarWidth - sendButtonWidth - usernameWidth, self.message.frame.size.height)];
    
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [self resizeToolbarItems:size];
}

@end