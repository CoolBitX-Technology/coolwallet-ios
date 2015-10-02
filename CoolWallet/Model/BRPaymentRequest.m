//
//  BRPaymentRequest.m
//  BreadWallet
//
//  Created by Aaron Voisine on 5/9/13.
//  Copyright (c) 2013 Aaron Voisine <voisine@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#import "BRPaymentRequest.h"
//#import "NSString+Base58.h"
//#import "NSMutableData+Bitcoin.h"

#define SATOSHIS           100000000

// BIP21 bitcoin URI object https://github.com/bitcoin/bips/blob/master/bip-0021.mediawiki
@implementation BRPaymentRequest

+ (instancetype)requestWithString:(NSString *)string
{
    return [[self alloc] initWithString:string];
}

+ (instancetype)requestWithData:(NSData *)data
{
    return [[self alloc] initWithData:data];
}

+ (instancetype)requestWithURL:(NSURL *)url
{
    return [[self alloc] initWithURL:url];
}

- (instancetype)initWithString:(NSString *)string
{
    if (! (self = [self init])) return nil;
    
    self.string = string;
    return self;
}

- (instancetype)initWithData:(NSData *)data
{
    return [self initWithString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
}

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithString:url.absoluteString];
}

- (void)setString:(NSString *)string
{
    self.paymentAddress = nil;
    self.label = nil;
    self.message = nil;
    self.amount = 0;
    self.r = nil;

    if (! string.length) return;

    NSString *s = [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                   stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    NSURL *url = [NSURL URLWithString:s];
    
    if (! url || ! url.scheme) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"bitcoin://%@", s]];
    }
    else if (! url.host && url.resourceSpecifier) {
        url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", url.scheme, url.resourceSpecifier]];
    }
    
    self.paymentAddress = url.host;
    
    //TODO: correctly handle unkown but required url arguments (by reporting the request invalid)
    for (NSString *arg in [url.query componentsSeparatedByString:@"&"]) {
        NSArray *pair = [arg componentsSeparatedByString:@"="];
        NSString *value = (pair.count > 1) ? [arg substringFromIndex:[pair[0] length] + 1] : nil;
        
        if ([pair[0] isEqual:@"amount"]) {
            self.amount = ([value doubleValue] + DBL_EPSILON)*SATOSHIS;
        }
        else if ([pair[0] isEqual:@"label"]) {
            self.label = [[value stringByReplacingOccurrencesOfString:@"+" withString:@"%20"]
                          stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([pair[0] isEqual:@"message"]) {
            self.message = [[value stringByReplacingOccurrencesOfString:@"+" withString:@"%20"]
                            stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
        else if ([pair[0] isEqual:@"r"]) {
            self.r = [[value stringByReplacingOccurrencesOfString:@"+" withString:@"%20"]
                      stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        }
    }
}

- (NSString *)string
{
    if (! self.paymentAddress) return nil;

    NSMutableString *s = [NSMutableString stringWithFormat:@"bitcoin:%@", self.paymentAddress];
    NSMutableArray *q = [NSMutableArray array];
    
    if (self.amount > 0) {
        [q addObject:[NSString stringWithFormat:@"amount=%.16g", (double)self.amount/SATOSHIS]];
    }

    if (self.label.length > 0) {
        [q addObject:[NSString stringWithFormat:@"label=%@",
         CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self.label, NULL, CFSTR("&="),
                                                                   kCFStringEncodingUTF8))]];
    }
    
    if (self.message.length > 0) {
        [q addObject:[NSString stringWithFormat:@"message=%@",
         CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self.message, NULL, CFSTR("&="),
                                                                   kCFStringEncodingUTF8))]];
    }

    if (self.r.length > 0) {
        [q addObject:[NSString stringWithFormat:@"r=%@",
         CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)self.r, NULL, CFSTR("&="),
                                                                   kCFStringEncodingUTF8))]];
    }
    
    if (q.count > 0) {
        [s appendString:@"?"];
        [s appendString:[q componentsJoinedByString:@"&"]];
    }
    
    return s;
}

- (void)setData:(NSData *)data
{
    self.string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (NSData *)data
{
    return [self.string dataUsingEncoding:NSUTF8StringEncoding];
}

- (void)setUrl:(NSURL *)url
{
    self.string = url.absoluteString;
}

- (NSURL *)url
{
    return [NSURL URLWithString:self.string];
}

/*
- (BOOL)isValid
{
    if (! [self.paymentAddress isValidBitcoinAddress] && (! self.r || ! [NSURL URLWithString:self.r])) return NO;

    return YES;
}
*/

@end
