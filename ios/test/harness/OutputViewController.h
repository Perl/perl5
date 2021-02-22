//  OutputViewController.h

#import <UIKit/UIKit.h>

@interface OutputViewController : UIViewController <UIGestureRecognizerDelegate>

// output view

@property CGFloat fontSize;
@property (weak, nonatomic) IBOutlet UITextView * outputTextView;
@property (retain) UIPinchGestureRecognizer * pinchGestRecognizer;
@property (retain) NSTimer * timer;
@property (retain) NSDate * startTime;

- (UIColor *) colorFromHexString: (NSString *) hexString;
- (NSArray *) processMultilineOutput: (NSString *) str;
- (void) scaleTextView: (UIPinchGestureRecognizer *) pinchGestRecognizer;
- (void) showDialog: (NSString *) title withMessage: (NSString *) message;
- (void) updateOutputText : (NSString *) output withColor: (UIColor *) color;
- (void) updateOutputTextView;

// harness

@property (retain) NSMutableAttributedString * outputText;
@property (retain) NSMutableString * scriptPath;

- (NSString *) applicationDocumentsDirectory;
- (NSString *) getLogFileName;
- (NSString *) boilerplateString;
- (void) handlePerlError: (NSError *) error;
- (void) initLog;
- (void) startPerlScript;
- (NSString *) stripPrefix: (NSString *) prefixPath file: (NSString *) file;
- (void) textToLogFile: (NSString *) notificationText;

// stdio redirection

@property (retain) NSPipe * stdoutPipe;
@property (retain) NSPipe * stderrPipe;
@property (retain) NSFileHandle * stdoutReadHandle;
@property (retain) NSFileHandle * stderrReadHandle;
@property (retain) NSNumber * stdoutSavedFd;
@property (retain) NSNumber * stderrSavedFd;
@property (retain) NSFileHandle * stdoutWriteHandle;
@property (retain) NSFileHandle * stderrWriteHandle;
@property (retain) NSFileHandle * sessionLogFileHandle;
@property (retain) id stdoutNotificationObserver;
@property (retain) id stderrNotificationObserver;
@property (retain, nonatomic) NSMutableString * stdoutOutput;
@property (retain, nonatomic) NSMutableString * stderrOutput;
@property (retain, nonatomic) NSString * sessionLogFileName;
@property (retain) NSString * bundlePath;
@property (retain) NSMutableString * lsof_string;

- (void (^) (NSNotification *)) handleStdoutNotification;
- (void (^) (NSNotification *)) handleStderrNotification;
- (void) processStderrNotification: (NSString *) notificationText;
- (void) processStdoutNotification:(NSString *) notificationText;
- (void) openConsolePipe: (NSPipe *) pipe filePtr:(FILE *) file usingBlock: ( void (^) (NSNotification *) ) block;
- (void) setupStdioRedirection;
- (void) cleanupStdioRedirection;

@end
