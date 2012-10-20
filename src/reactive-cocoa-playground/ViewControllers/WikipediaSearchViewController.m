//
//  WikipediaSearchViewController.m
//  reactive-cocoa-playground
//
//  Created by Prabir Shrestha on 10/19/12.
//  Copyright (c) 2012 Prabir Shrestha. All rights reserved.
//

#import "WikipediaSearchViewController.h"
#import <ReactiveCocoa.h>
#import <BlocksKit.h>

@interface WikipediaSearchViewController ()

@end

@implementation WikipediaSearchViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.activityIndicator.hidden = YES;
    
    RACSubject *webViewLoadSubject = [RACSubject subject];
    self.webView.didFinishLoadBlock = ^( UIWebView *webView){
        [webViewLoadSubject sendNext:webView];
        [webViewLoadSubject sendCompleted];
    };
    self.webView.didFinishWithErrorBlock  = ^(UIWebView *webView, NSError *error) {
        [webViewLoadSubject sendError:error];
    };
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    tapGestureRecognizer.cancelsTouchesInView = NO;
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    RACSubscribable *keys =
    [[[self.searchTextField
     rac_subscribableForControlEvents:UIControlEventEditingChanged]
     throttle:0.5] // seconds
     select:^id(UITextField *x) {
         return x.text;
     }];
    
    [[keys
      deliverOn:[RACScheduler mainQueueScheduler]]
      subscribeNext:^(NSString *searchText) {
          self.activityIndicator.hidden = NO;
          [self.activityIndicator startAnimating];
          self.searchingForLabel.text = [NSString stringWithFormat:@"Searching for ... %@", searchText];
          
          NSURLRequest *request = [NSURLRequest
                                   requestWithURL:[NSURL URLWithString:
                                                   [NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", searchText]]];
          [self.webView loadRequest:request];
      }];
    
    [[keys
      deliverOn:[RACScheduler mainQueueScheduler]]
      subscribeNext:^(NSString *x) {
         NSLog(@"%@", x);
     }];
    
    
    void (^disableWebLoadAnimation)() = ^() {
        self.activityIndicator.hidden = YES;
        [self.activityIndicator stopAnimating];
    };
    
    [webViewLoadSubject
     subscribeNext:^(id x) {
         disableWebLoadAnimation();
     }
     error:^(NSError *error) {
         disableWebLoadAnimation();
     }];    
}

- (void)dismissKeyboard {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSearchTextField:nil];
    [self setSearchingForLabel:nil];
    [self setWebView:nil];
    [self setActivityIndicator:nil];
    [super viewDidUnload];
}

@end
