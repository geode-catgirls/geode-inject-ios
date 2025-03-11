#include <Foundation/Foundation.h>
#include <dlfcn.h>

#include <stdlib.h>

#if __has_include("./../geode_download.h")
#include "./../geode_download.h"
#else
#warning geode_download.h not found - create a file called geode_download.h with the following content:
#warning #define GEODE_DOWNLOAD_URL @"https://your-url-to-download/Geode.ios.dylib"
#error aborting compilation - see info above
#endif

#import <UIKit/UIKit.h>

// what the actual fuck is this entire function.
// no like seriously who tf came up with objc and the ios sdk
void showAlert(NSString* tiddies, NSString* meows, bool remeowbutton) {
	dispatch_async(dispatch_get_main_queue(), ^{
		UIViewController* currentFucker = [[[UIApplication sharedApplication] windows].firstObject rootViewController];

		UIAlertController* alert = [UIAlertController alertControllerWithTitle:tiddies message:meows preferredStyle:UIAlertControllerStyleAlert];

		UIAlertAction* fuckoff = [UIAlertAction actionWithTitle:@"go away" style:UIAlertActionStyleDefault handler:nil];
		[alert addAction:fuckoff];

		if (remeowbutton) {
			UIAlertAction* restart = [UIAlertAction actionWithTitle:@"restart" style:UIAlertActionStyleDefault handler:^(UIAlertAction* _) { exit(0); }];
			[alert addAction:restart];
		}

		[currentFucker presentViewController:alert animated:YES completion:nil];
	});
}

void init_loadGeode(void) {
	NSLog(@"mrow init_loadGeode");

	NSArray* paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString* applicationSupportDirectory = [paths firstObject];

	NSString* geode_dir = [applicationSupportDirectory stringByAppendingString:@"/GeometryDash/game/geode"];
	NSString* geode_lib = [geode_dir stringByAppendingString:@"/Geode.ios.dylib"];
	NSString* geode_env = [geode_dir stringByAppendingString:@"/geode.env"];

	bool is_dir;
	NSFileManager* fm = [NSFileManager defaultManager];
	if (![fm fileExistsAtPath:geode_dir isDirectory:&is_dir]) {
		NSLog(@"mrow creating geode dir !!");
		if (![fm createDirectoryAtPath:geode_dir withIntermediateDirectories:YES attributes:nil error:NULL]) {
			NSLog(@"mrow failed to create folder!!");
		}
	}

	NSLog(@"mrow PATH %@", applicationSupportDirectory);
	NSLog(@"mrow geode dir: %@", geode_dir);
	NSLog(@"mrow Geode lib path: %@", geode_lib);

	bool geode_exists = [fm fileExistsAtPath:geode_lib];

	if (!geode_exists) {
		NSLog(@"mrow geode dylib DOES NOT EXIST! downloading...");
		NSURL* url = [NSURL URLWithString:GEODE_DOWNLOAD_URL];
		NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
		NSURLSession* session = [NSURLSession sessionWithConfiguration:configuration];

		NSURLSessionDownloadTask* downloadTask = [session downloadTaskWithURL:url completionHandler:^(NSURL* location, NSURLResponse* response, NSError* error) {
			if (error) {
				showAlert(@"error", @"waaaaaaaa", false);
				NSLog(@"mrow FAILED to download Geode: %@", error);
			} else {
				// NSFileManager *fileManager = [NSFileManager defaultManager];
				NSError* moveError = nil;
				if ([fm moveItemAtURL:location toURL:[NSURL fileURLWithPath:geode_lib] error:&moveError]) {
					NSLog(@"mrow SUCCESS - downloaded Geode!");
					showAlert(@"Downloaded Geode", @"Successfully downloaded Geode.ios.dylib\nRestart the game to use Geode.", true);
				} else {
					showAlert(@"Geode Error", @"failed to download Geode: failed to save file", false);
					NSLog(@"mrow FAILED to download Geode: failed to save file: %@", moveError);
				}
			}
		}];
		[downloadTask resume];
	}

	if ([fm fileExistsAtPath:geode_env]) {
		NSLog(@"mrow loading geode launch arguments from %@", geode_env);
		NSString* envContent = [NSString stringWithContentsOfFile:geode_env encoding:NSUTF8StringEncoding error:nil];
		if (envContent) {
			NSArray* lines = [envContent componentsSeparatedByString:@"\n"];
			for (NSString* envDef in lines) {
				NSArray* parts = [envDef componentsSeparatedByString:@"="];
				if (parts.count < 2 || [envDef hasPrefix:@"#"]) {
					NSLog(@"mrow: skipping invalid env line %@", envDef);
					continue;
				}

				NSString* key = parts[0];
				NSString* val = [[parts subarrayWithRange:NSMakeRange(1, parts.count - 1)] componentsJoinedByString:@"="];
				if ([val hasPrefix:@"\""] && [val hasSuffix:@"\""]) {
					val = [[val substringToIndex:[val length] - 1] substringFromIndex:1];
					NSLog(@"mrow stripped quotes from env val: %@", val);
				}

				NSLog(@"mrow setting env %@ to %@", key, val);
				setenv([key UTF8String], [val UTF8String], 1);
			}
		}

		NSLog(@"mrow deleting temporary geode env file at %@", geode_env);
		NSError* removeError;
		[fm removeItemAtPath:geode_env error:&removeError];
		if (removeError) {
			NSLog(@"mrow failed to delete: %@", removeError);
		}
	}

	NSLog(@"mrow trying to load Geode library from %@", geode_lib);

	dlopen([geode_lib UTF8String], RTLD_LAZY);

	NSLog(@"mrow inhibiting screen sleep (in 1s)");
	[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer* meow) { [UIApplication sharedApplication].idleTimerDisabled = YES; }];
}
