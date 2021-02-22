//  OutputViewController.m

#import <QuartzCore/QuartzCore.h>
#import <CamelBones/CamelBones.h>
#import "OutputViewController.h"

#define OUTPUT_VIEW_CAPACITY 104857601

static dispatch_queue_t stdoutQueue = nil;
static dispatch_queue_t stderrQueue = nil;
static dispatch_queue_t logFileQueue = nil;

@implementation OutputViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.startTime = [NSDate date];
    _outputText =  [[[self outputTextView] attributedText] mutableCopy];

    _fontSize = 13;
    [[self outputTextView] setFont:[UIFont fontWithName:@"CourierNewPSMT" size:_fontSize]];
    [[self outputTextView] setTextColor:[self colorFromHexString: @"#28FE14"]];
    [[self outputTextView] scrollRangeToVisible:NSMakeRange([[self outputTextView].text length], 0)];

    _pinchGestRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(scaleTextView:)];
    _pinchGestRecognizer.delegate = self;
    [[self outputTextView] addGestureRecognizer:_pinchGestRecognizer];

    stdoutQueue = dispatch_queue_create("net.pytm.perla.stdout", DISPATCH_QUEUE_SERIAL);
    stderrQueue = dispatch_queue_create("net.pytm.perla.stderr", DISPATCH_QUEUE_SERIAL);
    logFileQueue = dispatch_queue_create("net.pytm.perla.logFile", DISPATCH_QUEUE_SERIAL);

    self.bundlePath      = [[NSBundle mainBundle] resourcePath];
    self.scriptPath  = [NSMutableString stringWithString:@""];
    self.stdoutOutput    = [[NSMutableString alloc ]initWithCapacity:OUTPUT_VIEW_CAPACITY];
    self.stderrOutput    = [[NSMutableString alloc ]initWithCapacity:OUTPUT_VIEW_CAPACITY];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    _sessionLogFileName = [self getLogFileName];
    [self initLog];
    _sessionLogFileHandle = [NSFileHandle fileHandleForWritingAtPath:self.sessionLogFileName];
    [self updateOutputText: [self boilerplateString] withColor:[self colorFromHexString: @"#28FE14"]];

    [self setupStdioRedirection];
    self.scriptPath = [NSMutableString stringWithFormat:@"%@/t/harness", [self applicationDocumentsDirectory]];
    [self startPerlScript];

    _timer = [NSTimer scheduledTimerWithTimeInterval:.2
        target:self
        selector:@selector(updateOutputTextView)
        userInfo:nil
        repeats:YES];

    // Do any additional setup after loading the view, typically from a nib.
}

- (void (^) (NSNotification *)) handleStdoutNotification
{
    return ^(NSNotification * notification)
    {
        dispatch_async(stdoutQueue, ^{
            @try
            {
                NSString * notificationText = [[NSString alloc] initWithData: [self.stdoutReadHandle availableData] encoding: NSUTF8StringEncoding];
                if (!notificationText) return;
                [self textToLogFile: notificationText];
                [self processStdoutNotification: notificationText];
            }
            @catch (NSException * exception)
            {
                NSLog(@"handleStdoutNotification() threw wxception: %@", [exception description]);
            }
        });
    };
}

- (void (^) (NSNotification *)) handleStderrNotification
{
    return ^(NSNotification * notification)
    {
        dispatch_async(stderrQueue, ^{
            NSString * notificationText;
            @try
            {
               notificationText = [[NSString alloc] initWithData: [self.stderrReadHandle availableData] encoding: NSUTF8StringEncoding];
                if (!notificationText) return;
                [self textToLogFile: notificationText];
                [self processStderrNotification: notificationText];
            }
            @catch (NSException * exception)
            {
                NSLog(@"handleStderrNotification() threw wxception: %@", [exception description]);
            }
        });
    };
}

- (void) processStderrNotification: (NSString *) notificationText
{
    NSArray * texts = [self processMultilineOutput: notificationText];
    for (id text in texts)
    {
        if ( text != nil)
        {
            NSString * eolTerminated = [NSString stringWithFormat: @"%@\n", text];
            [[self stderrOutput] appendString: text];
            [self updateOutputText: eolTerminated withColor: [self colorFromHexString: @"#FF2C38"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self stderrReadHandle] waitForDataInBackgroundAndNotify];
            });
        }
    }
}

- (void) processStdoutNotification: (NSString *) notificationText
{
    NSArray * texts = [self processMultilineOutput: notificationText];
    for (id text in texts)
    {
        if ( text != nil)
        {
            NSString * eolTerminated = [NSString stringWithFormat: @"%@\n", text];
            [[self stdoutOutput] appendString:eolTerminated];
            [self updateOutputText: eolTerminated withColor:[self colorFromHexString: @"#28FE14"]];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[self stdoutReadHandle] waitForDataInBackgroundAndNotify];
            });
        }
    }
}

- (NSString *) boilerplateString
{
    return [NSString stringWithFormat: @"Running on iOS: %@\nBundle: %@\nDocuments: %@\n",
        [[UIDevice currentDevice] systemVersion],
        [self applicationDocumentsDirectory],
        self.bundlePath
    ];
}

- (NSArray *) processMultilineOutput: (NSString *) str
{
    NSMutableArray * items = [[str componentsSeparatedByString: @"\n"] mutableCopy];
    if ([items.lastObject isEqualToString: @""])
    {
        [items removeLastObject];
    }
    return (NSArray *) items;
}

- (void) textToLogFile: (NSString *) notificationText
{
    dispatch_async(logFileQueue, ^{
        [self.sessionLogFileHandle seekToEndOfFile];
        [self.sessionLogFileHandle writeData:[notificationText dataUsingEncoding:NSUTF8StringEncoding]];
        [self.sessionLogFileHandle synchronizeFile];
    });
}

- (UIColor *) colorFromHexString: (NSString *) hexString
{
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString: hexString];
    [scanner setScanLocation: 1]; // get passed '#'
    [scanner scanHexInt: &rgbValue];
    return [UIColor colorWithRed: ((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) updateOutputText: (NSString *) output withColor: (UIColor * _Nonnull) color
{
    UIFont * font = [UIFont fontWithName: @"CourierNewPSMT" size: self.fontSize];
    NSDictionary * attrsDictionary = [NSDictionary dictionaryWithObject: font forKey:NSFontAttributeName];
    NSMutableAttributedString * newOutput = [[NSMutableAttributedString alloc]initWithString: output attributes: attrsDictionary];
    NSRange range = [output rangeOfString: output];
    [newOutput addAttribute:NSForegroundColorAttributeName value: color range: range];
    @synchronized (self)
    {
        [[self outputText] appendAttributedString: newOutput];
    }
}

- (void) updateOutputTextView
{
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
        @synchronized (self)
        {
            [[self outputTextView] setAttributedText: [self outputText]];
        }
        [[self outputTextView] scrollRangeToVisible: NSMakeRange( [[self outputTextView].text length], 0 )];

    }];
}

- (void) showDialog: (NSString *) title withMessage: (NSString *) message
{
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle: title message: message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction * defaultAction = [UIAlertAction actionWithTitle: @"OK" style:UIAlertActionStyleDefault handler: ^(UIAlertAction * _Nonnull action) {
            //button click event
        }];
        [alert addAction: defaultAction];
        [self presentViewController: alert animated: YES completion: nil];
    }];
}

-(void) initLog
{
    NSError *error;
    [[self boilerplateString] writeToFile: self.sessionLogFileName atomically: YES encoding: NSUTF8StringEncoding error: &error];
    if (error) {
        [self showDialog: @"Error" withMessage: [error localizedDescription]];
        return;
    }
}

- (void) scaleTextView:(UIPinchGestureRecognizer *) pinchGestRecognizer
{
     [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
         CGFloat scale = pinchGestRecognizer.scale;
         CGFloat size;
         if (scale > 1) {
             size = self.outputTextView.font.pointSize + .25f;
            if (size > 26) size = 26.0f;
         }
         else if (scale < 1) {
             size = self.outputTextView.font.pointSize - .25f;
             if (size < 10) size = 8.0f;
         }
         else return;

         self.fontSize = size;
         self.outputTextView.font = [UIFont fontWithName: self.outputTextView.font.fontName size: self.fontSize];
         if (scale < 0) scale = .1f;
         [self textViewDidChange:self.outputTextView scale: scale];
    }];
}

- (void)textViewDidChange: (UITextView *) textView scale: (CGFloat) scale
{
    textView.contentScaleFactor = scale;
    textView.layer.contentsScale = scale;
    CGSize textSize = textView.contentSize;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^ {
        textView.frame = CGRectMake(CGRectGetMinX(textView.frame), CGRectGetMinY(textView.frame), textSize.width, textSize.height);
    }];
}

- (void) startPerlScript
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, (unsigned long) NULL), ^(void) {
        @autoreleasepool {
            NSError * error = nil;
            NSArray * options = @[];
            [[CBPerl alloc] initWithFileName:self.scriptPath withAbsolutePwd:@"" withDebugger:0 withOptions:options withArguments:nil error: &error completion:nil];
            [self handlePerlError:error];
            [self cleanupStdioRedirection];
            NSTimeInterval timeInterval = -[self.startTime timeIntervalSinceNow];
            [self updateOutputText: [NSString stringWithFormat:@"Execution took: %f s.", timeInterval] withColor:[self colorFromHexString: @"#28FE14"]];
            [self updateOutputTextView];
            [self.timer invalidate];
        }
    });
}

- (void) handlePerlError: (NSError *) error
{
    if (error) {
        NSDictionary * userInfo = [error userInfo];
        NSString * perlOutput = [userInfo objectForKey:@"reason"];
        [[self stderrOutput] appendString:perlOutput];

        [self updateOutputText:perlOutput withColor:[UIColor redColor]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[self stderrReadHandle] waitForDataInBackgroundAndNotify];
        });
    }
}

- (NSString *) stripPrefix: (NSString *) prefixPath file: (NSString *) file
{
    if (!file) return nil;
    NSRange range = NSMakeRange(prefixPath.length, file.length - prefixPath.length);
    return [file substringWithRange: range];
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = paths.firstObject;
    if ([basePath rangeOfString:@"/private"].location == 0) {
        basePath = [self stripPrefix: @"/private" file: self.scriptPath];
    }
    return basePath;
}

- (void) openConsolePipe: (NSPipe *) pipe filePtr: (FILE *) file usingBlock: (void (^) (NSNotification *)) block
{
    int file_fd = fileno(file);
    int saved_fd = dup(file_fd);
    [self.lsof_string appendFormat:@"%d = dup(%d)\n", saved_fd, file_fd];

    int orig_fd = [[pipe fileHandleForWriting] fileDescriptor];
    [self.lsof_string appendFormat:@"original fd: %d\n", orig_fd];
    int close_r = close(file_fd);
    if (close_r != 0) {
        NSLog(@"Could not close fd %d", file_fd);
    }
    [self.lsof_string appendFormat:@"closed %d\n", file_fd];

    int dup_fd = dup2(orig_fd, file_fd);
    [self.lsof_string appendFormat:@"%d = dup2(%d, %d)\n", dup_fd, [[pipe fileHandleForWriting] fileDescriptor], file_fd];
    if (dup_fd < 0) {
        NSLog(@"Could not dup2 fd %d", file_fd);
    }
    close_r = close(orig_fd);
    if (close_r != 0) {
        NSLog(@"Could not close fd %d", orig_fd);
    }

    NSFileHandle * rfh;
    switch (file_fd) {
        case STDOUT_FILENO:
            self.stdoutReadHandle = [pipe fileHandleForReading];
            rfh = self.stdoutReadHandle;
            self.stdoutWriteHandle = [[pipe fileHandleForWriting] initWithFileDescriptor: dup_fd closeOnDealloc:YES];
            self.stdoutSavedFd = [NSNumber numberWithInt:saved_fd];
            break;
        case STDERR_FILENO:
            self.stderrReadHandle = [pipe fileHandleForReading];
            rfh = self.stderrReadHandle;
            self.stderrWriteHandle = [[pipe fileHandleForWriting] initWithFileDescriptor: dup_fd closeOnDealloc:YES];
            self.stderrSavedFd = [NSNumber numberWithInt:saved_fd];
            break;
    }
    id observer = [[NSNotificationCenter defaultCenter]
        addObserverForName:NSFileHandleDataAvailableNotification
        object:rfh
        queue:[NSOperationQueue mainQueue]
        usingBlock:block];

    switch (file_fd) {
        case STDOUT_FILENO:
            self.stdoutNotificationObserver = observer;
            break;
        case STDERR_FILENO:
            self.stderrNotificationObserver = observer;
            break;
    }

    [rfh waitForDataInBackgroundAndNotify];
}

- (void) closeConsolePipe: pipe
{
    if (pipe != nil) {

        NSFileHandle * readFileHandle = [pipe fileHandleForReading];
        NSFileHandle * writeFileHandle = [pipe fileHandleForWriting];

        int wfd = [writeFileHandle fileDescriptor];

        switch (wfd) {
            case STDOUT_FILENO:
                [[NSNotificationCenter defaultCenter] removeObserver:self.stdoutNotificationObserver name:NSFileHandleDataAvailableNotification object:readFileHandle];
                break;
            case STDERR_FILENO:
                [[NSNotificationCenter defaultCenter] removeObserver:self.stderrNotificationObserver name:NSFileHandleDataAvailableNotification object:readFileHandle];
                break;
            default:
                [self showDialog:@"Error" withMessage:[NSString stringWithFormat: @"Wrong file descriptor: %d", wfd]];
                return;
        }

        [self.lsof_string appendFormat:@"close %d\n", [readFileHandle fileDescriptor]];
        [readFileHandle closeFile];
        [self.lsof_string appendFormat:@"close %d\n", [writeFileHandle fileDescriptor]];
        [writeFileHandle closeFile];

        int restore_fd;
        switch (wfd) {
            case STDOUT_FILENO:
                self.stdoutPipe = nil;
                self.stdoutReadHandle = nil;
                self.stdoutWriteHandle = nil;
                self.stdoutNotificationObserver = nil;
                restore_fd = [self.stdoutSavedFd intValue];
                break;
            case STDERR_FILENO:
                self.stderrPipe = nil;
                self.stderrReadHandle = nil;
                self.stderrWriteHandle = nil;
                self.stderrNotificationObserver = nil;
                restore_fd = [self.stderrSavedFd intValue];
                break;
            default:
                [self showDialog:@"Error" withMessage:[NSString stringWithFormat: @"Wrong file descriptor: %d", wfd]];
                return;
        }

        int new_fd = dup2(restore_fd, wfd);
        [self.lsof_string appendFormat:@"%d = dup2(%d, %d)\n", new_fd, restore_fd, wfd];
        int close_r = close(restore_fd);
        if (close_r != 0) {
            NSLog(@"Could not close fd %d", restore_fd);
        }

        [self.lsof_string appendFormat:@"closed %d\n", restore_fd];
    }
}

- (void) setupStdioRedirection
{
    self.stdoutPipe = [NSPipe pipe];
    [self openConsolePipe: self.stdoutPipe filePtr:stdout usingBlock:[self handleStdoutNotification]];
    self.stderrPipe = [NSPipe pipe];
    [self openConsolePipe: self.stderrPipe filePtr:stderr usingBlock:[self handleStderrNotification]];
}

- (void) cleanupStdioRedirection
{
    [self closeConsolePipe: self.stdoutPipe];
    [self closeConsolePipe: self.stderrPipe];
}

- (NSString * _Nonnull) getLogFileName
{
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone localTimeZone];
    [dateFormatter setDateFormat:@"yyyyMMdd-HHmmssSSS"];
    [dateFormatter setTimeZone:timeZone];
    NSString *timeStamp = [dateFormatter stringFromDate:[NSDate date]];
    NSString * _Nonnull logFileName = [NSString stringWithFormat:@"%@/SESSION-%@.txt", [self applicationDocumentsDirectory], timeStamp];
    return logFileName;
}

@end
