//
//  FVTwaatStreamingEngine.h
//  Twaat
//
//  Created by Florent Vilmart on 10-09-12.
//  Copyright 2010 twii.to organisation. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FVTwaatEngineGlobalHeader.h"
#import "OAToken.h"
#import "OAMutableURLRequest.h"
#import "OAConsumer.h"
#import "NSData+Base64.h"
#import "MGTwitterParserDelegate.h"
#import "MGTwitterStatusesYAJLParser.h"
#define TWITTER_STREAMING_DOMAIN @"stream.twitter.com/"
@protocol VFTwaatStreamingEngineDelegate

- (void)receivedObject:(NSDictionary *)dictionary responseType:(MGTwitterResponseType)responseType;

@end

@interface VFTwaatStreamingEngine : NSObject <MGTwitterParserDelegate>{
	NSMutableData *receivedData;

	
}
@property (retain) NSMutableURLRequest *request;
@property (retain) NSURLConnection *connection;
@property (retain) NSArray *trustedHosts;
@property (retain) OAToken *token;
@property (retain) NSMutableArray *followedIDs;
@property (retain) NSObject <VFTwaatStreamingEngineDelegate> *_delegate;
+(id) sharedInstance;
-(void) follow:(NSArray *) array;
-(void) addFollowedId:(NSString*)userId;
-(void) setFollowedId:(NSString*)userId;

@end
