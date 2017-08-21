#import "RNDocumentPicker.h"

#if __has_include(<React/RCTConvert.h>)
#import <React/RCTConvert.h>
#import <React/RCTBridge.h>
#else // back compatibility for RN version < 0.40
#import "RCTConvert.h"
#import "RCTBridge.h"
#endif

#import <Foundation/Foundation.h>

#define IDIOM    UI_USER_INTERFACE_IDIOM()
#define IPAD     UIUserInterfaceIdiomPad

#define TEMP_FOLDER @"react-native-document-picker/"

@interface RNDocumentPicker () <UIDocumentMenuDelegate,UIDocumentPickerDelegate>
@end


@implementation RNDocumentPicker {
    NSMutableArray *composeViews;
    NSMutableArray *composeCallbacks;
}

@synthesize bridge = _bridge;

- (instancetype)init
{
    if ((self = [super init])) {
        composeCallbacks = [[NSMutableArray alloc] init];
        composeViews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(show:(NSDictionary *)options
                  callback:(RCTResponseSenderBlock)callback) {
    
    NSArray *allowedUTIs = [RCTConvert NSArray:options[@"filetype"]];
    UIDocumentMenuViewController *documentPicker = [[UIDocumentMenuViewController alloc] initWithDocumentTypes:(NSArray *)allowedUTIs inMode:UIDocumentPickerModeImport];
    
    [composeCallbacks addObject:callback];
    
    
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication]delegate] window] rootViewController];
    while (rootViewController.modalViewController) {
        rootViewController = rootViewController.modalViewController;
    }
    
    if ( IDIOM == IPAD ) {
        NSNumber *top = [RCTConvert NSNumber:options[@"top"]];
        NSNumber *left = [RCTConvert NSNumber:options[@"left"]];
        [documentPicker.popoverPresentationController setSourceRect: CGRectMake([left floatValue], [top floatValue], 0, 0)];
        [documentPicker.popoverPresentationController setSourceView: rootViewController.view];
    }
    
    [rootViewController presentViewController:documentPicker animated:YES completion:nil];
}


- (void)documentMenu:(UIDocumentMenuViewController *)documentMenu didPickDocumentPicker:(UIDocumentPickerViewController *)documentPicker {
    documentPicker.delegate = self;
    documentPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    
    UIViewController *rootViewController = [[[[UIApplication sharedApplication]delegate] window] rootViewController];
    
    while (rootViewController.modalViewController) {
        rootViewController = rootViewController.modalViewController;
    }
    if ( IDIOM == IPAD ) {
        [documentPicker.popoverPresentationController setSourceRect: CGRectMake(rootViewController.view.frame.size.width/2, rootViewController.view.frame.size.height - rootViewController.view.frame.size.height / 6, 0, 0)];
        [documentPicker.popoverPresentationController setSourceView: rootViewController.view];
    }
    
    [rootViewController presentViewController:documentPicker animated:YES completion:nil];
}

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentAtURL:(NSURL *)url {
    if (controller.documentPickerMode == UIDocumentPickerModeImport) {
        RCTResponseSenderBlock callback = [composeCallbacks lastObject];
        [composeCallbacks removeLastObject];
        
        NSError *error = nil;
        
        NSString *tmpFolder = TEMP_FOLDER;
        NSString *tmpFullPath = [NSTemporaryDirectory() stringByAppendingString:tmpFolder];
        NSString *tmpFilePath = [tmpFullPath stringByAppendingPathComponent:[url lastPathComponent]];
        NSURL *tempFile = [NSURL fileURLWithPath:tmpFilePath];
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:tmpFullPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:tmpFullPath withIntermediateDirectories:YES attributes:nil error:&error]; //Create folder
        else {
            if([[NSFileManager defaultManager] fileExistsAtPath:tmpFilePath])
                [[NSFileManager defaultManager]  removeItemAtPath:tmpFilePath error:&error];
        }
        [[NSFileManager defaultManager] copyItemAtURL:url toURL:tempFile error:&error];
        
        if(error == nil) {
            NSMutableDictionary* result = [NSMutableDictionary dictionary];
            [result setValue:tempFile.absoluteString forKey:@"uri"];
            [result setValue:tempFile.path forKey:@"path"];
            [result setValue:[tempFile lastPathComponent] forKey:@"fileName"];
            NSError *attributesError = nil;
            NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:tempFile.path error:&attributesError];
            if(!attributesError) {
                [result setValue:[fileAttributes objectForKey:NSFileSize] forKey:@"fileSize"];
            } else {
                NSLog(@"%@", attributesError);
            }
            callback(@[[NSNull null], result]);
        }
        else
            callback(@[@"Copy failed", [NSNull null]]);
    }
}


RCT_EXPORT_METHOD(clearTempFiles) {
    NSString *tmpFolder = TEMP_FOLDER;
    NSString *tmpFullPath = [NSTemporaryDirectory() stringByAppendingString:tmpFolder];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:tmpFullPath]){
        NSError *error = nil;
        for (NSString *file in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpFullPath error:&error])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", tmpFullPath, file] error:&error];
        }
    }
}

@end
