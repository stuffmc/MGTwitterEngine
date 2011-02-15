//
//  FVTwaatStreamingEngine.m
//  Twaat
//
//  Created by Florent Vilmart on 10-09-12.
//  Copyright 2010 twii.to organisation. All rights reserved.
//

#import "VFTwaatStreamingEngine.h"


@implementation VFTwaatStreamingEngine
@synthesize request,connection,trustedHosts,followedIDs,token,_delegate;
static VFTwaatStreamingEngine *singleton=nil;

+(id) sharedInstance{
	@synchronized(self){
	if (singleton==nil) {
		singleton = [[FVTwaatStreamingEngine alloc] init];
	}
	}
	return singleton;
	
}

-(id)init
{
	if (self = [super init]) {
		self.trustedHosts = [NSArray arrayWithObject:@"stream.twitter.com"];
		self.followedIDs = [NSMutableArray arrayWithCapacity:0];
	}
	return self;
}

-(void) follow:(NSArray*) follwers{
	NSURL *finalURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@1/statuses/filter.json",TWITTER_STREAMING_DOMAIN]];
	self.request = [[OAMutableURLRequest alloc] initWithURL:finalURL
												   consumer:[[[OAConsumer alloc] initWithKey:CONSUMER_KEY
																					  secret:CONSUMER_SECRET] autorelease]
													  token:self.token
													  realm:nil
										  signatureProvider:nil];
	[self.request setCachePolicy:NSURLRequestReloadIgnoringCacheData ];
	[self.request setHTTPMethod:@"POST"];
	[self.request setHTTPShouldHandleCookies:NO];
	[self.request setValue:@"Twaat" forHTTPHeaderField:@"X-Twitter-Client"];
	[self.request setValue:@"1.0" forHTTPHeaderField:@"X-Twitter-Client-Version"];
	[self.request setValue:@"http://vfloz.wordpress.com" forHTTPHeaderField:@"X-Twitter-Client-URL"];
	[self.request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];	
	if (self.connection) {
		receivedData = [[NSMutableData data] retain];
	}
	self.followedIDs = [NSMutableArray arrayWithArray:follwers];
	NSString *following = [@"follow=" stringByAppendingString:[self.followedIDs componentsJoinedByString:@","]];
	NSData *data = [following dataUsingEncoding:NSUTF8StringEncoding];
	[self.request setValue:[NSString stringWithFormat:@"%d",data.length] forHTTPHeaderField:@"Content-Length"];
	[self.request setHTTPBody:data];
	[(OAMutableURLRequest*) self.request prepare];
	self.connection = [NSURLConnection connectionWithRequest:self.request delegate:self];
	if (self.connection) {
		receivedData = [[NSMutableData data] retain];
	}
}


-(void) setFollowedId:(NSString*)userId{
	if (self.followedIDs) {
		[self.followedIDs removeAllObjects];
		[self.followedIDs addObject:userId];
	}
	[self follow:self.followedIDs];
}

-(void) addFollowedId:(NSString*)userId{
	if (![self.followedIDs containsObject:userId]) {
		[self.followedIDs addObject:userId];
	}
	[self follow:self.followedIDs];
}


#pragma mark -
#pragma mark MGTwitterParserDelegate methods
- (void)parsingSucceededForRequest:(NSString *)identifier 
                    ofResponseType:(MGTwitterResponseType)responseType 
                 withParsedObjects:(NSArray *)parsedObjects
{
	
}
- (void)parsedObject:(NSDictionary *)dictionary forRequest:(NSString *)requestIdentifier 
	  ofResponseType:(MGTwitterResponseType)responseType{
	NSLog(@"%@",[dictionary description]);
	[_delegate receivedObject:dictionary responseType:responseType];
	
}
- (void)parsingFailedForRequest:(NSString *)requestIdentifier 
                 ofResponseType:(MGTwitterResponseType)responseType 
                      withError:(NSError *)error
{
}

#pragma mark -
#pragma mark NSURLConnection delegate methods
- (void)connectionDidFinishLoading:(NSURLConnection *)aconnection
{
	NSString *s = [[NSString alloc] initWithData:receivedData encoding:NSASCIIStringEncoding];
	NSLog(@"%@",s);
	[s release];
    [receivedData release];
	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"response received");
	[receivedData setLength:0];
	
}

- (void)connection:(NSURLConnection *)aconnection didReceiveData:(NSData *)data
{
	NSString *s = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	if (data.length>2) {
		#if YAJL_AVAILABLE
		[MGTwitterStatusesYAJLParser parserWithJSON:data delegate:self 
							   connectionIdentifier:@"" requestType:VFTwaatStreamingFollowRequest 
									   responseType:VFTwaatStreamingFollowResponse URL:[self.request URL] deliveryOptions:MGTwitterEngineDeliveryIndividualResultsOption];
		#elif USE_LIBXML
		[MGTwitterStatusesLibXMLParser parserWithJSON:data delegate:self 
							   connectionIdentifier:@"" requestType:VFTwaatStreamingFollowRequest 
									   responseType:VFTwaatStreamingFollowResponse URL:[self.request URL] deliveryOptions:MGTwitterEngineDeliveryIndividualResultsOption];
		#else
		[MGTwitterStatusesParser parserWithJSON:data delegate:self 
								 connectionIdentifier:@"" requestType:VFTwaatStreamingFollowRequest 
										 responseType:VFTwaatStreamingFollowResponse URL:[self.request URL] deliveryOptions:MGTwitterEngineDeliveryIndividualResultsOption];
		#endif
		NSLog(@"data: %@ end",s);
		//[receivedData appendData:data];
	}
	[s release];
}

- (void)connection:(NSURLConnection *)aconnection
  didFailWithError:(NSError *)error
{
    [aconnection release];
    [receivedData release];
	
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
	return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
		NSLog(@"Host: %@",challenge.protectionSpace.host);
		if ([self.trustedHosts containsObject:challenge.protectionSpace.host])
			[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
	
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


@end
