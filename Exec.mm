#import <UIKit/UIKit.h>
#import <dlfcn.h>

// We define the function pointer instead of using extern to avoid linker errors
typedef void (*execute_lua_t)(const char* script);

@interface BlockzUI : UIView
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIButton *anchorBtn;
@property (nonatomic, strong) UITextView *editor;
@property (nonatomic, assign) CGPoint lastPoint;
@end

@implementation BlockzUI

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Emerald Floating Anchor
        self.anchorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.anchorBtn.frame = CGRectMake(50, 50, 55, 55);
        self.anchorBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.25 blue:0.1 alpha:0.95];
        [self.anchorBtn setTitle:@"𝔅" forState:UIControlStateNormal];
        self.anchorBtn.titleLabel.font = [UIFont fontWithName:@"Georgia" size:32];
        self.anchorBtn.layer.cornerRadius = 12;
        self.anchorBtn.layer.borderWidth = 2;
        self.anchorBtn.layer.borderColor = [UIColor colorWithRed:0.3 green:0.9 blue:0.5 alpha:1.0].CGColor;
        [self.anchorBtn addTarget:self action:@selector(toggleUI) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleAnchorPan:)];
        [self.anchorBtn addGestureRecognizer:pan];
        [self addSubview:self.anchorBtn];

        // Main Menu
        self.mainContainer = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 360, 220)];
        self.mainContainer.backgroundColor = [UIColor colorWithRed:0.02 green:0.02 blue:0.02 alpha:0.98];
        self.mainContainer.layer.cornerRadius = 18;
        self.mainContainer.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.2 alpha:1.0].CGColor;
        self.mainContainer.layer.borderWidth = 1.5;
        self.mainContainer.hidden = YES;
        [self addSubview:self.mainContainer];

        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 200, 25)];
        title.text = @"BLOCKZ EXEC V1";
        title.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1.0];
        title.font = [UIFont fontWithName:@"AvenirNext-Bold" size:16];
        [self.mainContainer addSubview:title];

        self.editor = [[UITextView alloc] initWithFrame:CGRectMake(15, 45, 330, 120)];
        self.editor.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0];
        self.editor.textColor = [UIColor colorWithRed:0.5 green:1.0 blue:0.7 alpha:1.0];
        self.editor.layer.cornerRadius = 10;
        self.editor.text = @"print('BlockzExec Weak-Linked Emerald Ready')";
        [self.mainContainer addSubview:self.editor];

        UIButton *exec = [UIButton buttonWithType:UIButtonTypeSystem];
        exec.frame = CGRectMake(15, 175, 160, 35);
        [exec setTitle:@"EXECUTE" forState:UIControlStateNormal];
        exec.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.3 alpha:1.0];
        [exec setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        exec.layer.cornerRadius = 8;
        [exec addTarget:self action:@selector(runLua) forControlEvents:UIControlEventTouchUpInside];
        [self.mainContainer addSubview:exec];
        
        UIPanGestureRecognizer *panMain = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleMainPan:)];
        [self.mainContainer addGestureRecognizer:panMain];
    }
    return self;
}

- (void)toggleUI { self.mainContainer.hidden = !self.mainContainer.hidden; }

- (void)handleAnchorPan:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:self];
    self.anchorBtn.center = CGPointMake(self.anchorBtn.center.x + t.x, self.anchorBtn.center.y + t.y);
    [p setTranslation:CGPointZero inView:self];
}

- (void)handleMainPan:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:self];
    self.mainContainer.center = CGPointMake(self.mainContainer.center.x + t.x, self.mainContainer.center.y + t.y);
    [p setTranslation:CGPointZero inView:self];
}

- (void)runLua {
    // Manually finding the function in the loaded libRobloxLib
    void* handle = dlopen("libRobloxLib.dylib", RTLD_LAZY);
    if (handle) {
        execute_lua_t exec = (execute_lua_t)dlsym(handle, "execute_lua");
        if (exec) {
            exec([self.editor.text UTF8String]);
        }
        dlclose(handle);
    }
}
@end

static void __attribute__((constructor)) load() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                win = ((UIWindowScene *)scene).windows.firstObject;
                break;
            }
        }
        if (win) {
            BlockzUI *ui = [[BlockzUI alloc] initWithFrame:win.bounds];
            [win addSubview:ui];
        }
    });
}
