#import <UIKit/UIKit.h>
#import <dlfcn.h>

// Delta Engine Bridge
extern "C" void execute_lua(const char* script);

@interface BlockzUI : UIView <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIView *hubContainer;
@property (nonatomic, strong) UIButton *anchorBtn;
@property (nonatomic, strong) UITextView *editor;
@property (nonatomic, strong) UITableView *scriptTable;
@property (nonatomic, strong) NSMutableArray *scriptsArray;
@property (nonatomic, strong) NSMutableArray *filteredScripts;
@end

@implementation BlockzUI

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = YES;
        self.scriptsArray = [[NSMutableArray alloc] init];
        self.filteredScripts = [[NSMutableArray alloc] init];

        // 1. Floating '𝔅' Anchor
        self.anchorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        self.anchorBtn.frame = CGRectMake(60, 60, 55, 55);
        self.anchorBtn.backgroundColor = [UIColor colorWithRed:0.0 green:0.2 blue:0.1 alpha:0.9];
        [self.anchorBtn setTitle:@"𝔅" forState:UIControlStateNormal];
        self.anchorBtn.titleLabel.font = [UIFont fontWithName:@"Georgia" size:32];
        self.anchorBtn.layer.cornerRadius = 12;
        self.anchorBtn.layer.borderWidth = 2;
        self.anchorBtn.layer.borderColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0].CGColor;
        [self.anchorBtn addTarget:self action:@selector(toggleUI) forControlEvents:UIControlEventTouchUpInside];
        
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self.anchorBtn addGestureRecognizer:pan];
        [self addSubview:self.anchorBtn];

        // 2. Main Menu Container
        self.mainContainer = [[UIView alloc] initWithFrame:CGRectMake(120, 100, 360, 260)];
        self.mainContainer.backgroundColor = [UIColor colorWithRed:0.02 green:0.02 blue:0.02 alpha:0.98];
        self.mainContainer.layer.cornerRadius = 15;
        self.mainContainer.layer.borderColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.2 alpha:1.0].CGColor;
        self.mainContainer.layer.borderWidth = 1.5;
        self.mainContainer.hidden = YES;
        [self addSubview:self.mainContainer];

        // Header
        UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 150, 25)];
        title.text = @"BLOCKZ EXEC V1";
        title.textColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1.0];
        title.font = [UIFont boldSystemFontOfSize:14];
        [self.mainContainer addSubview:title];

        UIButton *hubBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        hubBtn.frame = CGRectMake(260, 10, 90, 25);
        [hubBtn setTitle:@"SCRIPT HUB" forState:UIControlStateNormal];
        [hubBtn setTitleColor:[UIColor colorWithRed:0.0 green:1.0 blue:0.4 alpha:1.0] forState:UIControlStateNormal];
        [hubBtn addTarget:self action:@selector(toggleHub) forControlEvents:UIControlEventTouchUpInside];
        [self.mainContainer addSubview:hubBtn];

        // Editor
        self.editor = [[UITextView alloc] initWithFrame:CGRectMake(10, 45, 340, 140)];
        self.editor.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0];
        self.editor.textColor = [UIColor colorWithRed:0.4 green:1.0 blue:0.6 alpha:1.0];
        self.editor.font = [UIFont fontWithName:@"Menlo" size:11];
        self.editor.layer.cornerRadius = 8;
        [self loadLocalScript]; // Load last saved session
        [self.mainContainer addSubview:self.editor];

        // Controls
        UIButton *exec = [UIButton buttonWithType:UIButtonTypeSystem];
        exec.frame = CGRectMake(10, 195, 165, 35);
        [exec setTitle:@"EXECUTE" forState:UIControlStateNormal];
        exec.backgroundColor = [UIColor colorWithRed:0.0 green:0.6 blue:0.3 alpha:1.0];
        [exec setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        exec.layer.cornerRadius = 8;
        [exec addTarget:self action:@selector(runManualLua) forControlEvents:UIControlEventTouchUpInside];
        [self.mainContainer addSubview:exec];

        UIButton *save = [UIButton buttonWithType:UIButtonTypeSystem];
        save.frame = CGRectMake(185, 195, 165, 35);
        [save setTitle:@"SAVE CODE" forState:UIControlStateNormal];
        save.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        [save setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        save.layer.cornerRadius = 8;
        [save addTarget:self action:@selector(saveLocalScript) forControlEvents:UIControlEventTouchUpInside];
        [self.mainContainer addSubview:save];

        // 3. Script Hub
        self.hubContainer = [[UIView alloc] initWithFrame:self.mainContainer.bounds];
        self.hubContainer.backgroundColor = [UIColor colorWithRed:0.03 green:0.03 blue:0.03 alpha:1.0];
        self.hubContainer.layer.cornerRadius = 15;
        self.hubContainer.hidden = YES;
        [self.mainContainer addSubview:self.hubContainer];

        UISearchBar *search = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 310, 45)];
        search.barStyle = UIBarStyleBlack;
        search.placeholder = @"Search Rscripts...";
        search.delegate = self;
        [self.hubContainer addSubview:search];

        UIButton *closeHub = [UIButton buttonWithType:UIButtonTypeSystem];
        closeHub.frame = CGRectMake(320, 10, 30, 25);
        [closeHub setTitle:@"X" forState:UIControlStateNormal];
        [closeHub addTarget:self action:@selector(toggleHub) forControlEvents:UIControlEventTouchUpInside];
        [self.hubContainer addSubview:closeHub];

        self.scriptTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 45, 360, 215)];
        self.scriptTable.backgroundColor = [UIColor clearColor];
        self.scriptTable.delegate = self;
        self.scriptTable.dataSource = self;
        [self.hubContainer addSubview:self.scriptTable];

        [self fetchScripts];
    }
    return self;
}

// MARK: - API & Storage
- (void)fetchScripts {
    for (int i = 1; i <= 6; i++) {
        NSString *urlStr = [NSString stringWithFormat:@"https://rscripts.net/api/v2/scripts?page=%d&orderBy=views&sort=desc", i];
        [[[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:urlStr] completionHandler:^(NSData *d, NSURLResponse *r, NSError *e) {
            if (d) {
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:d options:0 error:nil];
                if (json[@"scripts"]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.scriptsArray addObjectsFromArray:json[@"scripts"]];
                        self.filteredScripts = [self.scriptsArray mutableCopy];
                        [self.scriptTable reloadData];
                    });
                }
            }
        }] resume];
    }
}

- (void)saveLocalScript {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"last_script.txt"];
    [self.editor.text writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

- (void)loadLocalScript {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"last_script.txt"];
    NSString *saved = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    self.editor.text = saved ?: @"-- BlockzExec\nprint('Ready')";
}

- (void)runManualLua { execute_lua([self.editor.text UTF8String]); }
- (void)toggleUI { self.mainContainer.hidden = !self.mainContainer.hidden; }
- (void)toggleHub { self.hubContainer.hidden = !self.hubContainer.hidden; }

// MARK: - TableView & Search
- (NSInteger)tableView:(UITableView *)t numberOfRowsInSection:(NSInteger)s { return self.filteredScripts.count; }
- (UITableViewCell *)tableView:(UITableView *)t cellForRowAtIndexPath:(NSIndexPath *)ip {
    UITableViewCell *c = [t dequeueReusableCellWithIdentifier:@"c"] ?: [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"c"];
    c.backgroundColor = [UIColor clearColor];
    NSDictionary *data = self.filteredScripts[ip.row];
    c.textLabel.text = data[@"title"];
    c.textLabel.textColor = [UIColor whiteColor];
    c.detailTextLabel.text = [NSString stringWithFormat:@"Views: %@", data[@"views"]];
    c.detailTextLabel.textColor = [UIColor colorWithRed:0.0 green:0.8 blue:0.4 alpha:1.0];
    return c;
}

- (void)tableView:(UITableView *)t didSelectRowAtIndexPath:(NSIndexPath *)ip {
    NSString *raw = self.filteredScripts[ip.row][@"rawScript"];
    execute_lua([[NSString stringWithFormat:@"loadstring(game:HttpGet('%@'))()", raw] UTF8String]);
    self.hubContainer.hidden = YES;
}

- (void)searchBar:(UISearchBar *)sb textDidChange:(NSString *)txt {
    if (txt.length == 0) self.filteredScripts = [self.scriptsArray mutableCopy];
    else {
        self.filteredScripts = [[self.scriptsArray filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", txt]] mutableCopy];
    }
    [self.scriptTable reloadData];
}

// Utility
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)e {
    UIView *h = [super hitTest:p withEvent:e];
    return (h == self) ? nil : h;
}

- (void)handlePan:(UIPanGestureRecognizer *)p {
    CGPoint t = [p translationInView:self];
    p.view.center = CGPointMake(p.view.center.x + t.x, p.view.center.y + t.y);
    [p setTranslation:CGPointZero inView:self];
}
@end

static void __attribute__((constructor)) load() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindow *win = ((UIWindowScene *)scene).windows.firstObject;
                if (win) [win addSubview:[[BlockzUI alloc] initWithFrame:win.bounds]];
            }
        }
    });
}
