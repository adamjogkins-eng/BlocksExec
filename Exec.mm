#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

typedef void (*lua_execute_t)(const char*);

@interface BlockzUI : UIView <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIButton *anchorBtn;
@property (nonatomic, strong) UITextView *editor;
// ... (Other properties stay the same)
@end

@implementation BlockzUI

// --- NEW: STEALTH SYMBOL LOOKUP ---
// This prevents the game from seeing a direct link to the lua function
- (void)stealthExecute:(NSString *)script {
    if (!script) return;

    static lua_execute_t func = NULL;
    
    // Only look up the function once to save battery and performance
    if (!func) {
        void *handle = dlopen(NULL, RTLD_NOW); // Search the main executable memory
        func = (lua_execute_t)dlsym(handle, "execute_lua");
        
        // If not found, try common internal naming variations
        if (!func) func = (lua_execute_t)dlsym(handle, "lual_loadstring");
        if (!func) func = (lua_execute_t)dlsym(handle, "rbx_execute");
    }

    if (func) {
        // High priority background thread to avoid UI Watchdog kills
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            func([script UTF8String]);
        });
    } else {
        NSLog(@"[Blockz] Error: Execution symbol not found in memory.");
    }
}

// ... (Rest of your UI logic and TableView methods)

- (void)runManualLua {
    [self stealthExecute:self.editor.text];
}

@end
