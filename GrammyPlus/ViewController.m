//
//  ViewController.m
//  GrammyPlus
//
//  Created by Tolga Yıldırım on 1/9/16.
//  Copyright © 2016 TolgaParty. All rights reserved.
//

#import "ViewController.h"
#import "NXOAuth2.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];	
    // Do any additional setup after loading the view, typically from a nib.
    self.logoutButton.enabled = false;
    self.refreshButton.enabled = false;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)loginPressed:(id)sender {
    [[NXOAuth2AccountStore sharedStore] requestAccessToAccountWithType:@"Instagram"];
    
    self.loginButton.enabled = false;
    self.logoutButton.enabled = true;
    self.refreshButton.enabled = true;
}


- (IBAction)logoutPressed:(id)sender {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    
    for (id account in instagramAccounts)
        [store removeAccount:account];
    self.loginButton.enabled = true;
    self.logoutButton.enabled = false;
    self.refreshButton.enabled = false;
    
}


- (IBAction)refreshPressed:(id)sender {
    
    self.refreshButton.enabled = false;
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *instagramAccounts = [store accountsWithAccountType:@"Instagram"];
    
    if ([instagramAccounts count] == 0){
        NSLog(@"No logged in account");
        return;
        
    }
    
    NXOAuth2Account *account = instagramAccounts[0];
    NSString *token = account.accessToken.accessToken;
    
    NSString *urlString = [@"https://api.instagram.com/v1/users/self/media/recent/?access_token=" stringByAppendingString:token];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLSession *urlSession = [NSURLSession sharedSession];
    
    [[urlSession dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error){
            NSLog(@"Error: Couldn't finish request: %@", error);
            self.refreshButton.enabled = true;
            return;
        }
        
        NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
        if (httpResp.statusCode < 200 || httpResp.statusCode >=300){
            NSLog(@"Error: Got status code %ld", (long)httpResp.statusCode);
            self.refreshButton.enabled = true;
            return;
        }
        
        NSError *parsError;
        
        id pkg = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parsError];
        if (!pkg){
            NSLog(@"Error: Couldn't parse response %@", parsError);
            self.refreshButton.enabled = true;
            return;
        }
        
        
        NSString *imagesURLStr = pkg[@"data"][0][@"images"][@"standard_resolution"][@"url"];
        NSURL *imageURL = [NSURL URLWithString:imagesURLStr];
        [[urlSession dataTaskWithURL:imageURL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            
            if (error){
                NSLog(@"Error: Couldn't finish request: %@", error);
                self.refreshButton.enabled = true;
                return;
            }
            
            NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)response;
            if (httpResp.statusCode < 200 || httpResp.statusCode >=300){
                NSLog(@"Error: Got status code %ld", (long)httpResp.statusCode);
                self.refreshButton.enabled = true;
                return;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [UIImage imageWithData:data];
            });
            
            
        }] resume];
        
        
        
        
    }] resume];
    
    self.refreshButton.enabled = true;
    
}

@end














