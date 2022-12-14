#import <Foundation/Foundation.h>

@interface YouTubeExtractor : NSObject
+ (NSMutableDictionary *)youtubeiAndroidPlayerRequest :(NSString *)videoID;
+ (NSMutableDictionary *)youtubeiAndroidSearchRequest :(NSString *)searchQuery;
+ (NSMutableDictionary *)youtubeiAndroidTrendingRequest;
+ (NSMutableDictionary *)youtubeiiOSPlayerRequest :(NSString *)videoID;
+ (NSMutableDictionary *)returnYouTubeDislikeRequest :(NSString *)videoID;
+ (NSMutableDictionary *)sponsorBlockRequest :(NSString *)videoID;
@end