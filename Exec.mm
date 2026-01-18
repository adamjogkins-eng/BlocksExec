#import <UIKit/UIKit.h>

// Bridge to the logic you extracted from Delta
extern "C" void execute_lua(const char* script);

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
        // 1. Floating '𝔅' Anchor
        self.anchorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.anchorBtn.frame = CGRectMake(40, 60, 55, 55);
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

        // 2. Emerald Menu
        self.mainContainer = [[UIView alloc] initWithFrame:CGRectMake(80, 100, 360, 220)];
        self.mainContainer.backgroundColor = [UIColor colorWithRed:0.02 green:0.02 blue:0.02 alpha:0.98];
        self.mainContainer.layer.cornerRadius = 18;
        self.mainContainer.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.2 alpha:1.0].CGColor;
        self.mainContainer.layer.borderWidth = 1.5;
        self.mainContainer.hidden = YES;
        [self addSubview:self.mainContainer];

        // Emerald Header
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, 200, 25)];
        title.text = @"BLOCKZ EXEC V1";
        title.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1.0];
        title.font = [UIFont fontWithName:@"AvenirNext-Bold" size:16];
        [self.mainContainer addSubview:title];

        // Editor
        self.editor = [[UITextView alloc] initWithFrame:CGRectMake(15, 45, 330, 120)];
        self.editor.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.05 alpha:1.0];
        self.editor.textColor = [UIColor colorWithRed:0.5 green:1.0 blue:0.7 alpha:1.0];
        self.editor.font = [UIFont fontWithName:@"Menlo" size:11];
        self.editor.layer.cornerRadius = 10;
        self.editor.text = @"-- BlockzExec Loaded\nprint('Hello Emerald!')";
        [self.mainContainer addSubview:self.editor];

        // Action Buttons
        UIButton *exec = [UIButton buttonWithType:UIButtonTypeSystem];
        exec.frame = CGRectMake(15, 175, 160, 35);
        [exec setTitle:@"EXECUTE" forState:UIControlStateNormal];
        exec.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.3 alpha:1.0];
        [exec setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        exec.layer.cornerRadius = 8;
        [exec addTarget:self action:@selector(runLua) forControlEvents:UIControlEventTouchUpInside];
        [self.mainContainer addSubview:exec];

        UIButton *clear = [UIButton buttonWithType:UIButtonTypeSystem];
        clear.frame = CGRectMake(185, 175, 160, 35);
        [clear setTitle:@"CLEAR" forState:UIControlStateNormal];
        clear.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        [clear setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        clear.layer.cornerRadius = 8;
        [clear addTarget:self action:@selector(clearText) forControlEvents:UIControlEventTouchUpInside];
        [self.mainContainer addSubview:clear];
    }
    return self;
}

- (void)toggleUI {
    self.mainContainer.hidden = !self.mainContainer.hidden;
}

- (void)handleAnchorPan:(UIPanGestureRecognizer *)p {
    CGPoint trans = [p translationInView:self];
    self.anchorBtn.center = CGPointMake(self.anchorBtn.center.x + trans.x, self.anchorBtn.center.y + trans.y);
    [p setTranslation:CGPointZero inView:self];
}

- (void)runLua {
    execute_lua([self.editor.text UTF8String]);
}

- (void)clearText {
    self.editor.text = @"";
}
@end

static void __attribute__((constructor)) load() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(12 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *win = [UIApplication sharedApplication].keyWindow;
        BlockzUI *ui = [[BlockzUI alloc] initWithFrame:win.bounds];
        [win addSubview:ui];
    });
}
