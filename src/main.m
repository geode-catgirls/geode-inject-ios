#import "utils/utils.h"
#include <objc/runtime.h>
#import <dlfcn.h>
#import <spawn.h>

extern char** environ;
int ptrace(int, pid_t, caddr_t, int);

@implementation NSObject (modif_AppController)
- (BOOL)mrow_application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {
	NSLog(@"mrow call didFinishLaunchingWithOptions!");
	init_loadGeode();
	return [self mrow_application:application didFinishLaunchingWithOptions:launchOptions];
}
@end

__attribute__((constructor)) static void entry(int argc, char** argv, char* envp[]) {
	NSLog(@"mrow INIT");
	if (argc > 1 && strcmp(argv[1], "--jit") == 0) {
		NSLog(@"mrow exiting");
		ptrace(0, 0, 0, 0);
		exit(0);
	} else {
		NSLog(@"mrow crac");
		pid_t pid;
		char* modified_argv[] = { argv[0], "--jit", NULL };
		int ret = posix_spawnp(&pid, argv[0], NULL, NULL, modified_argv, envp);
		if (ret == 0) {
			waitpid(pid, NULL, WUNTRACED);
			ptrace(11, pid, 0, 0);
			kill(pid, SIGTERM);
			wait(NULL);
		}
	}
	init_bypassDyldLibValidation();
	init_fixCydiaSubstrate();

	Class appCtrl = NSClassFromString(@"AppController");
	if (appCtrl) {
		{
			SEL orig = @selector(application:didFinishLaunchingWithOptions:);
			SEL swizzled = @selector(mrow_application:didFinishLaunchingWithOptions:);
			Method origMethod = class_getInstanceMethod(appCtrl, orig);
			Method swzMethod = class_getInstanceMethod([NSObject class], swizzled);
			if (origMethod && swzMethod) {
				class_addMethod(appCtrl, swizzled, method_getImplementation(swzMethod), method_getTypeEncoding(swzMethod));
				method_exchangeImplementations(origMethod, class_getInstanceMethod(appCtrl, swizzled));
				NSLog(@"mrow swizzle (AppController) application:didFinishLaunchingWithOptions");
			}
		}
	}
}
