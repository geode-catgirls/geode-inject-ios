#import "utils/utils.h"
#import <dlfcn.h>
#import <spawn.h>

extern char** environ;
int ptrace(int, pid_t, caddr_t, int);

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

	init_loadGeode();
}
