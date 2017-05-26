//
//  SSUWebViewController.h
//  SSUMobile
//
//  Copyright (c) 2015 Sonoma State University Department of Computer Science. All rights reserved.
//

@import WebKit;

#import "SSUWebViewController.h"
#import "MBProgressHUD.h"
#import <Masonry/Masonry.h>

static NSString * const kStoryboardName = @"SSUWebViewController";

@interface SSUWebViewController () <WKNavigationDelegate>

@property (nonatomic) WKWebView * webview;
@property (nonatomic) IBOutlet UIToolbar * toolbar;
@property (nonatomic) IBOutlet UIBarButtonItem * backButton;
@property (nonatomic) IBOutlet UIBarButtonItem * forwardButton;

@property (nonatomic) MBProgressHUD * progressHUD;

@end

@implementation SSUWebViewController

+ (SSUWebViewController *) webViewController {
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:kStoryboardName
                                                           bundle:[NSBundle bundleForClass:self]];
    id viewController = [storyboard instantiateInitialViewController];
    NSAssert([viewController isKindOfClass:[self class]], @"Expecting web view");
    return viewController;
}

- (instancetype) init {
    return [SSUWebViewController webViewController];
}

- (WKWebView *) webview {
    if (_webview) return _webview;
    
    _webview = [[WKWebView alloc] initWithFrame:CGRectZero];
    
    [self.view addSubview:_webview];
    [_webview mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(self.toolbar.mas_top);
    }];
    
    return _webview;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem * actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(didPressActionButton:)];
    self.navigationItem.rightBarButtonItem = actionButton;
    
    [self updateNavigationButtons];
    
    self.webview.navigationDelegate = self;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.htmlToShow != nil) {
        [self.webview loadHTMLString:self.htmlToShow baseURL:nil];
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else if (self.urlToLoad != nil) {
        NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:self.urlToLoad];
        request.timeoutInterval = 10;
        [self.webview loadRequest:request];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webview stopLoading];
}

- (void) updateNavigationButtons {
    self.backButton.enabled = self.webview.canGoBack;
    self.forwardButton.enabled = self.webview.canGoForward;
}

#pragma mark - IBActions

- (IBAction)didPressBackButton:(UIBarButtonItem *)sender {
    if ([self.webview canGoBack]) {
        [self.webview goBack];
    }
}

- (IBAction)didPressForwardButton:(id)sender{
    if ([self.webview canGoForward]) {
        [self.webview goForward];
    }
}

- (void) didPressActionButton:(UIBarButtonItem *)sender {
    UIAlertController * controller = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [controller addAction:[UIAlertAction actionWithTitle:@"Open in Safari" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if ([[UIApplication sharedApplication] canOpenURL:self.urlToLoad])
            [[UIApplication sharedApplication] openURL:self.urlToLoad];
    }]];
    [controller addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
    [self presentViewController:controller animated:YES completion:NULL];
}

#pragma mark - UIWebView

- (void) webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [self.progressHUD showAnimated:YES];
    [self.view bringSubviewToFront:self.progressHUD];
    
    [self updateNavigationButtons];
}

- (void) webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.progressHUD hideAnimated:YES afterDelay:1.0];
    [self updateNavigationButtons];
}

- (void) webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorNotConnectedToInternet) {
        self.progressHUD.label.text = @"No Internet access";
        self.progressHUD.mode = MBProgressHUDModeText;
        [self.progressHUD hideAnimated:YES afterDelay:1.0];
    }
    else if ([error.userInfo[NSURLErrorFailingURLStringErrorKey] isEqualToString:self.urlToLoad.path]){
        self.progressHUD.label.text = @"Failed to load webpage";
        self.progressHUD.mode = MBProgressHUDModeText;
        [self.progressHUD hideAnimated:YES afterDelay:1.0];
    }
    else if (!self.webview.loading) {
        // The url that failed is some sort of image or embedded video, so ignore it
        [self.progressHUD hideAnimated:YES];
    }
}


#pragma mark - Properties

- (void)setUrlToLoad:(NSURL *)urlToLoad {
    _urlToLoad = urlToLoad;
    if (self.view.window) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:self.urlToLoad]];
    }
}

- (void)setHtmlToShow:(NSString *)htmlToShow {
    _htmlToShow = htmlToShow;
    if (self.view.window) {
        [self.webview loadHTMLString:htmlToShow baseURL:nil];
    }
}

- (MBProgressHUD *) progressHUD {
    if (_progressHUD) {
        return _progressHUD;
    }
    
    _progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    _progressHUD.label.text = @"Loading";
    
    return _progressHUD;
}

@end
