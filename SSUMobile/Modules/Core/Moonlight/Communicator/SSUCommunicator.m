//
//  SSUCommunicator.m
//  SSUMobile
//
//  Created by Eric Amorde on 9/10/15.
//  Copyright (c) 2015 Sonoma State University Department of Computer Science. All rights reserved.
//

#import "SSUCommunicator.h"
#import "SSULogging.h"

@import UIKit;

static const NSTimeInterval kTimeoutInterval = 10.0;
static NSString * const kMoonlightDateParameter = @"date";

@interface SSUCommunicator()

@property (nonatomic, strong) NSURLSession * session;

@end

@implementation SSUCommunicator

static inline NSString * URLEncodedDictionary(NSDictionary * dictionary) {
    NSMutableString * data = [NSMutableString new];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [data appendString:[NSString stringWithFormat:@"%@=%@&",key,obj]];
    }];
    
    return [data stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
}

static inline NSString * POSTURLEncodedDictionary(NSDictionary * dictionary) {
    NSMutableString * postData = [NSMutableString new];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [postData appendString:[NSString stringWithFormat:@"%@=%@&",key,obj]];
    }];
    
    return postData;
}

+ (NSURLSession *) session {
    static NSURLSession * _session = nil;
    if (_session) return _session;
    
    _session = [NSURLSession sharedSession];
    
    return _session;
}

+ (NSDateFormatter *) dateFormatter {
    static NSDateFormatter * dateFormatter = nil;
    if (dateFormatter != nil) return dateFormatter;
    
    dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterNoStyle;
    dateFormatter.timeStyle = NSDateFormatterMediumStyle;
    dateFormatter.locale = [NSLocale currentLocale];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"America/Los_Angeles"];
    dateFormatter.dateFormat = @"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'";
    
    return dateFormatter;
}

#pragma mark - Network Indicator

+ (void) setNetworkActivityIndicatorVisible:(BOOL)visible {
    static int count = 0;
    count += (visible) ? 1 : -1;
    count = MAX(count,0);
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:(count > 0)];
}

#pragma mark - Making NSURLRequest objects

+ (NSMutableURLRequest *) formEncodedRequestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    NSString * postData = POSTURLEncodedDictionary(params);
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url
                                                            cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                        timeoutInterval:kTimeoutInterval];
    request.HTTPBody = [[postData stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] dataUsingEncoding:NSUTF8StringEncoding];
    [request setValue:[NSString stringWithFormat:@"%lu",(unsigned long)request.HTTPBody.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/x-www-form-urlencoded; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    
    return request;

}

+ (NSMutableURLRequest *) postRequestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    NSMutableURLRequest * request = [self formEncodedRequestWithURL:url parameters:params];
    request.HTTPMethod = @"POST";
    return request;
}

+ (NSMutableURLRequest *) putRequestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    NSMutableURLRequest * request = [self formEncodedRequestWithURL:url parameters:params];
    request.HTTPMethod = @"PUT";
    return request;
}

+ (NSMutableURLRequest *) updateRequestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    NSMutableURLRequest * request = [self formEncodedRequestWithURL:url parameters:params];
    request.HTTPMethod = @"UPDATE";
    return request;
}

+ (NSMutableURLRequest *) deleteRequestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    NSMutableURLRequest * request = [self formEncodedRequestWithURL:url parameters:params];
    request.HTTPMethod = @"DELETE";
    return request;
}

+ (NSMutableURLRequest *) getRequestWithURL:(NSURL *)url parameters:(NSDictionary *)params {
    NSURL * fullURL = url;
    if (params != nil) {
        NSURLComponents * components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
        NSString * parameters = URLEncodedDictionary(params);
        // Check if parameters already exist
        if (components.query.length) {
            parameters = [parameters stringByAppendingFormat:@"&%@", parameters];
        }
        components.query = parameters;
        fullURL = components.URL;
    }
    return [NSMutableURLRequest requestWithURL:fullURL
                                   cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                               timeoutInterval:kTimeoutInterval];
}

#pragma mark - Convenience

+ (void) getURL:(NSURL *)url completion:(SSUCommunicatorCompletion)completion {
    NSURLRequest * request = [self getRequestWithURL:url parameters:nil];
    [self performRequest:request completion:completion];
}

+ (void) getJSONFromURL:(NSURL *)url completion:(SSUCommunicatorJSONCompletion)completion {
    [self getJSONFromURL:url sinceDate:nil params:nil completion:completion];
}

+ (void) getJSONFromURL:(NSURL *)url sinceDate:(NSDate *)date completion:(SSUCommunicatorJSONCompletion)completion {
    [self getJSONFromURL:url sinceDate:date params:nil completion:completion];
}

+ (void) getJSONFromURL:(NSURL *)url sinceDate:(NSDate *)date params:(NSDictionary *)params completion:(SSUCommunicatorJSONCompletion)completion {
    if (completion == NULL) {
        // Downloading it without doing anything with it is worthless
        // (or it should be! no side effects with GETs please)
        SSULogDebug(@"Ignoring GET request for which no completion block is specified");
        return;
    }
    if (date != nil) {
        NSMutableDictionary * newParams = [params mutableCopy];
        newParams[kMoonlightDateParameter] = [[self dateFormatter] stringFromDate:date];
        params = newParams;
    }
    NSURLRequest * request = [self getRequestWithURL:url parameters:params];
    [self performJSONRequest:request completion:completion];
}

+ (void) postURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorCompletion)completion {
    NSURLRequest * request = [self postRequestWithURL:url parameters:params];
    [self performRequest:request completion:completion];
}

+ (void) postJSONURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorJSONCompletion)completion {
    NSURLRequest * request = [self postRequestWithURL:url parameters:params];
    [self performJSONRequest:request completion:completion];
}

+ (void) putURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorCompletion)completion {
    NSURLRequest * request = [self putRequestWithURL:url parameters:params];
    [self performRequest:request completion:completion];
}

+ (void) putJSONURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorJSONCompletion)completion {
    NSURLRequest * request = [self putRequestWithURL:url parameters:params];
    [self performJSONRequest:request completion:completion];
}

+ (void) updateURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorCompletion)completion {
    NSURLRequest * request = [self updateRequestWithURL:url parameters:params];
    [self performRequest:request completion:completion];
}

+ (void) updateJSONURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorJSONCompletion)completion {
    NSURLRequest * request = [self updateRequestWithURL:url parameters:params];
    [self performJSONRequest:request completion:completion];
}

+ (void) deleteURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorCompletion)completion {
    NSURLRequest * request = [self deleteRequestWithURL:url parameters:params];
    [self performRequest:request completion:completion];
}

+ (void) deleteJSONURL:(NSURL *)url parameters:(NSDictionary *)params completion:(SSUCommunicatorJSONCompletion)completion {
    NSURLRequest * request = [self deleteRequestWithURL:url parameters:params];
    [self performJSONRequest:request completion:completion];
}

#pragma mark - Perform Request

+ (void) performRequest:(NSURLRequest *)request completion:(SSUCommunicatorCompletion)completion {
    [self setNetworkActivityIndicatorVisible:YES];
    NSURLSessionTask * task = [self.session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        [self setNetworkActivityIndicatorVisible:NO];
        completion(response, data, error);
    }];
    [task resume];
}

+ (void) performJSONRequest:(NSURLRequest *)request completion:(SSUCommunicatorJSONCompletion)completion {
    [self performRequest:request completion:^(NSURLResponse *response, NSData *data, NSError *error) {
        id json = [self serializeJSON:data];
        completion(response, json, error);
   }];
}

#pragma mark - Helper

+ (id) serializeJSON:(NSData *)data {
    NSError * error;
    if (data == nil) {
        SSULogError(@"Received nil data for json serialization");
        return nil;
    }
    id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (error) {
        SSULogError(@"Error while attempting to serialize JSON object: %@", error);
    }
    return json;
}

@end
