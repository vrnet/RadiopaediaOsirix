//
//  RadiopaediaFilter.m
//  Radiopaedia
//
//  Copyright (c) 2016 Jarrel. All rights reserved.
//

#import "RadiopaediaFilter.h"
#import "GTMOAuth2WindowController.h"
#import <OsiriXAPI/DicomStudy.h>
#import <OsiriXAPI/DicomSeries.h>
#import <OsiriXAPI/DicomImage.h>
#import <OsiriXAPI/browserController.h>
#import <OsiriXAPI/DCMPix.h>
#import "GTMOAuth2SignIn.h"
#import "Objective-Zip.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>
@implementation RadiopaediaFilter

/*  Section taken from UnImportantNotice
 
 Copyright (c) 2013, Spaltenstein Natural Image
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of Spaltenstein Natural Image nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL SPALTENSTEIN NATURAL IMAGE BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.*/
- (void) initPlugin
{
    
    Class AppControllerClass = objc_getClass("AppController");
    if (AppControllerClass == nil)
    {
        NSLog(@"UnImportantNoticeFilter could not find the AppControllerClass");
        return;
    }
    
    Class BrowserControllerClass = objc_getClass("BrowserController");
    if (BrowserControllerClass == nil)
    {
        NSLog(@"UnImportantNoticeFilter could not find the BrowserControllerClass");
        return;
    }
    
    // get rid of the dialog when the window opens
    Method importantMethod = class_getClassMethod(AppControllerClass, @selector(displayImportantNotice:));
    Method unImportantMethod = class_getClassMethod([RadiopaediaFilter class], @selector(displayUnImportantNotice:));
    if (importantMethod == NULL || unImportantMethod == NULL)
    {
        NSLog(@"UnImportantNoticeFilter could not find the important methods");
        return;
    }
    
    IMP unImportantImp = method_getImplementation(unImportantMethod);
    if (unImportantImp == NULL)
    {
        NSLog(@"UnImportantNoticeFilter could not find the unImportantImp");
        return;
    }
    
    method_setImplementation(importantMethod, unImportantImp);
    
    // get rid of the message in the DCMView
    Method isFDAClearedMethod = class_getClassMethod(AppControllerClass, @selector(isFDACleared));
    Method unImportantIsFDAClearedMethod = class_getClassMethod([RadiopaediaFilter class], @selector(isFDAClearedUnImportantNotice));
    if (isFDAClearedMethod == NULL || unImportantIsFDAClearedMethod == NULL)
    {
        NSLog(@"UnImportantNoticeFilter could not find the isFDACleared methods");
        return;
    }
    
    IMP isFDAClearedUnImportantNoticeImp = method_getImplementation(unImportantIsFDAClearedMethod);
    if (isFDAClearedUnImportantNoticeImp == NULL)
    {
        NSLog(@"UnImportantNoticeFilter could not find the isFDAClearedUnImportantNoticeImp");
        return;
    }
    
    const char* isFDAClearedUnImportantNoticeTypes = method_getTypeEncoding(isFDAClearedMethod);
    if (isFDAClearedUnImportantNoticeTypes) {
        if (class_addMethod(object_getClass(AppControllerClass), @selector(isFDAClearedUnImportantNotice), isFDAClearedUnImportantNoticeImp, isFDAClearedUnImportantNoticeTypes)) {
            Method unImportantIsFDAClearedMethodAppController = class_getClassMethod(AppControllerClass, @selector(isFDAClearedUnImportantNotice));
            method_exchangeImplementations(isFDAClearedMethod, unImportantIsFDAClearedMethodAppController);
        }
    }
    
    // get rid of the banner
    Method checkForBannerMethod = class_getInstanceMethod(BrowserControllerClass, @selector(checkForBanner:));
    Method checkForUnImportantBannerMethod = class_getInstanceMethod([RadiopaediaFilter class], @selector(checkForUnImportantBanner:));
    if (checkForBannerMethod == NULL || checkForUnImportantBannerMethod == NULL)
    {
        NSLog(@"UnImportantNoticeFilter could not find the important banner methods");
        return;
    }
    
    IMP checkForUnImportantBannerImp = method_getImplementation(checkForUnImportantBannerMethod);
    if (checkForUnImportantBannerImp == NULL)
    {
        NSLog(@"UnImportantNoticeFilter could not find the checkForUnImportantBannerImp");
        return;
    }
    
    method_setImplementation(checkForBannerMethod, checkForUnImportantBannerImp);
}

+ (void)displayUnImportantNotice:(id)sender
{
    NSLog(@"UnImportantNoticeFilter: short-circuited +[AppController displayImportantNotice:]");
}

+ (BOOL)isFDAClearedUnImportantNotice
{
    NSArray *symbols = [NSThread callStackSymbols];
    if ([symbols count] >=2) {
        NSString *secondFrame = [symbols objectAtIndex:1];
        if ([secondFrame rangeOfString:@"drawTextualData:annotationsLevel:fullText:onlyOrientation:"].location != NSNotFound) {
            static BOOL printedLog = NO;
            if (printedLog == NO) {
                NSLog(@"UnImportantNoticeFilter: short-circuited +[AppController isFDACleared] because it was called from -[DCMView drawTextualData:annotationsLevel:fullText:onlyOrientation:] (this message is printed only once)");
            }
            printedLog = YES;
            return YES;
        }
    }
    return [self  isFDAClearedUnImportantNotice];
}

- (void)checkForUnImportantBanner:(id)sender
{
    NSAutoreleasePool *pool = [NSAutoreleasePool new];
    NSImage *bannerImage = [[[NSImage alloc] init] autorelease];
    if( bannerImage) {
        [self performSelectorOnMainThread: @selector(installBanner:) withObject:bannerImage waitUntilDone:NO modes:[NSArray arrayWithObject:NSRunLoopCommonModes]];
    }
    [pool release];
    NSLog(@"UnImportantNoticeFilter: short-circuited -[BrowserController checkForBanner:]");
}

// END SECTION FROM UNIMPORTANT NOTICE

-(void) alert:(NSArray *)info
{
    
    NSAlert *myAlert = [NSAlert alertWithMessageText:[info objectAtIndex:0]
                                       defaultButton:[info objectAtIndex:1]
                                     alternateButton:[info objectAtIndex:2]
                                         otherButton:[info objectAtIndex:3]
                           informativeTextWithFormat:[info objectAtIndex:4]];
    [myAlert runModal];
}
- (void)viewController:(GTMOAuth2WindowController *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    if (error != nil) {
        
    } else {
        
        
        
        NSMutableDictionary *paramsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           [NSString stringWithFormat:@"%ld", (long)[self.detailsController.systemSelect indexOfSelectedItem]], @"system_id",
                                           nil];
       
        if ([self.detailsController.caseTitleField stringValue] != nil && [[self.detailsController.caseTitleField stringValue] length] > 0)
        {
            [paramsDict setObject:[self.detailsController.caseTitleField stringValue] forKey:@"title"];
        }
        if ([self.detailsController.ageField stringValue] != nil && [[self.detailsController.ageField stringValue] length] > 0)
        {
            [paramsDict setObject:[self.detailsController.ageField stringValue] forKey:@"age"];
        }
        if ([self.detailsController.genderSelect titleOfSelectedItem] != nil && ![[self.detailsController.genderSelect titleOfSelectedItem] isEqualToString:@"Unknown"])
        {
            [paramsDict setObject:[self.detailsController.genderSelect titleOfSelectedItem] forKey:@"gender"];
        }
        if ([self.detailsController.presentationField stringValue] != nil && [[self.detailsController.presentationField stringValue] length] > 0)
        {
            [paramsDict setObject:[self.detailsController.presentationField stringValue] forKey:@"presentation"];
        }
        if ([self.detailsController.discussionField stringValue] != nil && [[self.detailsController.discussionField stringValue] length] > 0)
        {
            [paramsDict setObject:[self.detailsController.discussionField stringValue] forKey:@"body"];
        }

        
        
        
        NSString *paramStr = [GTMOAuth2Authentication encodedQueryParametersForDictionary:paramsDict];
        NSMutableURLRequest *request  = [GTMOAuth2SignIn mutableURLRequestWithURL:[NSURL URLWithString:@"http://sandbox.radiopaedia.org/api/v1/cases"]
                                      paramString:paramStr];
        request.HTTPMethod = @"POST";
        
        
        [auth authorizeRequest:request completionHandler:^(NSError *err)
         {
             
             if (err == nil) {
                 // the request has been authorized
                 
                 if ([self.detailsController.caserIDField stringValue] != nil && [[self.detailsController.caserIDField stringValue] length] > 0)
                 {
                     self.caseId = [self.detailsController.caserIDField stringValue];
                     self.returnedCaseTitle = [self.detailsController.caseTitleField stringValue];
                 }
                 else
                 {
                     NSError *requestError = nil;
                     NSURLResponse *urlResponse = nil;
                     NSData *response1 =
                     [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:&urlResponse error:&requestError];
                     NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:response1 options: NSJSONReadingMutableContainers error: &requestError];
                     
                     NSString *caseId = [jsonArray objectForKey:@"id"];
                     self.caseId = caseId;
                     self.returnedCaseTitle = [jsonArray objectForKey:@"title"];
                 }
                 self.seriesNames = [NSMutableArray array];
                 self.queuedRequests = [NSMutableArray array];
                 NSUInteger i = 0;
                 for (NSMutableArray *seriesArray in self.selectedSeries) {
                     [self processSeriesArray:seriesArray with:self.caseId using:auth withDicom:[self.selectedStudies objectAtIndex:i]];
                     i++;
                 }
                 
                 // start processing queue of requests
                 [self startProcessingQueue];
             }
             
             else{
                 // Failed to authorize for some reason
                 NSAlert *myAlert = [NSAlert alertWithMessageText:@"Hello World!"
                                                    defaultButton:@"Hello"
                                                  alternateButton:nil
                                                      otherButton:nil
                                        informativeTextWithFormat:@"Failed %ld", (long)[error code]];
                 
                 [myAlert performSelectorOnMainThread:@selector(runModal) withObject:nil waitUntilDone:NO];
             }

             
         }];
        
    }
}

-(NSString *) parse:(NSString *)modality
{
    if ([modality isEqualToString:@"MR"])
    {
        return @"MRI";
    }
    else if ([modality isEqualToString:@"US"])
    {
        return @"Ultrasound";
    }
    else if ([modality isEqualToString:@"MG"])
    {
        return @"Mammography";
    }
    else if ([modality isEqualToString:@"XA"])
    {
        return @"DSA (angiography)";
    }
    else if ([modality isEqualToString:@"NM"])
    {
        return @"Nuclear medicine";
    }
    else if ([modality isEqualToString:@"CR"])
    {
        return @"X-ray";
    }
    else if ([modality isEqualToString:@"RF"])
    {
        return @"Fluoroscopy";
    }
    else if ([modality isEqualToString:@"CT"])
    {
        return @"CT";
    }
    else
    {
        return @""; // return nothing
    }
}
- (void) processSeriesArray:(NSMutableArray*) seriesArray with:(NSString *)caseId using:(GTMOAuth2Authentication *)auth withDicom:(DicomStudy *)study {
    
    
    
    NSMutableDictionary *paramsDict = [NSMutableDictionary dictionary];
    NSString *modality = [self parse:[study modality]];
    if (modality != nil && [modality length] > 0)
        [paramsDict setObject:modality forKey:@"modality"];
    
    NSString *paramStr = [GTMOAuth2Authentication encodedQueryParametersForDictionary:paramsDict];
    NSString *urlString = [NSString stringWithFormat:@"http://sandbox.radiopaedia.org/api/v1/cases/%@/studies", caseId];
    NSMutableURLRequest *request  = [GTMOAuth2SignIn mutableURLRequestWithURL:[NSURL URLWithString:urlString]
                                                                  paramString:paramStr];
    request.HTTPMethod = @"POST";
    
    [auth authorizeRequest:request completionHandler:^(NSError *err)
     {
         
         if (err == nil) {
             // the request has been authorized
             
             NSError *requestError = nil;
             NSURLResponse *urlResponse = nil;
             NSData *response1 =
             [NSURLConnection sendSynchronousRequest:request
                                   returningResponse:&urlResponse error:&requestError];
             NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:response1 options: NSJSONReadingMutableContainers error: &requestError];
             
             NSString *studyId = [jsonArray objectForKey:@"id"];
             NSUInteger seriesArrayIndex = [self.selectedSeries indexOfObject:seriesArray];
             
             // Post image stack (series)
             NSUInteger seriesIndex =0;
             for (DicomSeries *series in seriesArray)
             {
                 NSMutableDictionary *paramsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                      nil];
                 NSString *paramStr = [GTMOAuth2Authentication encodedQueryParametersForDictionary:paramsDict];
                 NSString *urlString = [NSString stringWithFormat:@"http://sandbox.radiopaedia.org/api/v1/cases/%@/studies/%@/images", caseId, studyId];
                 NSMutableURLRequest *request2  = [GTMOAuth2SignIn mutableURLRequestWithURL:[NSURL URLWithString:urlString]
                                                                              paramString:paramStr];
                 request2.HTTPMethod = @"POST";
                 
                 
                 NSString *contentType = [NSString stringWithFormat:@"application/zip"];
                 [request2 addValue:contentType forHTTPHeaderField: @"Content-Type"];
                 
                 NSData *data = [NSData dataWithContentsOfFile:[self.zipFiles[seriesArrayIndex] objectAtIndex:seriesIndex]];
                 request2.HTTPBody = data;
                 [auth authorizeRequest:request2 completionHandler:^(NSError *err)
                  {
                      if (err == nil) {
                          [self.queuedRequests addObject:request2];
                      }
                      else{
                      }
                      
                  }];
                 [self.seriesNames addObject:[series name]];
                 seriesIndex++;
             }
             
             
         }
         
         else{
             // Failed to authorize for some reason
             NSAlert *myAlert = [NSAlert alertWithMessageText:@"Error uploading study!"
                                                defaultButton:@"Ok"
                                              alternateButton:nil
                                                  otherButton:nil
                                    informativeTextWithFormat:@"Failed to upload %@: %@",[study name], [err description]];
             
             [myAlert runModal];
         }
         
         
     }];

    
}

- (long) filterImage:(NSString*) menuName
{
    self.patientAge = @"";
    self.patientSex = @"Unknown";
    self.patientAgeInt = 999999;
   /* NSString* message = [[NSUserDefaults standardUserDefaults] stringForKey:@"HelloWorld_Message"];
    if (!message) message = @"Define this message in the Hello World plugin's preferences";
    
    NSAlert *myAlert = [NSAlert alertWithMessageText:@"Hello World!"
                                       defaultButton:@"Hello"
                                     alternateButton:nil
                                         otherButton:nil
                           informativeTextWithFormat:@"%@", message];
    
    [myAlert runModal];*/
    
    /*
     
     Many thanks to wonderful blog at http://myfirstosirixplugin.blogspot.com.au/   !!!!
     
     */
    
    

  
    BrowserController *currentBrowser = [BrowserController currentBrowser];
    NSArray *selectedItems = [currentBrowser databaseSelection];
    
    if ([selectedItems count] == 0) {
        NSAlert *alert = [[[NSAlert alloc] init] autorelease];
        [alert setMessageText:@"No studies/series selected!"];
        [alert runModal];
        
        return 1;
    }
    
    self.selectedStudies = [NSMutableArray array];
    self.selectedSeries = [NSMutableArray array];
    self.zipFiles = [NSMutableArray array];
    for (id item in selectedItems) {
        if ([item isKindOfClass:[DicomStudy class]]) {
            DicomStudy *study = (DicomStudy*) item;
            
            [self.selectedStudies addObject:study];
            
            NSMutableArray *tempArray = [NSMutableArray array];
            [self.selectedSeries addObject:tempArray];
            
            for (DicomSeries *series in [study imageSeries])
            {
                [tempArray addObject:series];
            }
            
        } else if ([item isKindOfClass:[DicomSeries class]])
        {
            DicomSeries *series = (DicomSeries *)item;
            NSMutableArray *tempArray;
            
            if (![self.selectedStudies containsObject:[series study]])
              {
                  // insert new study and create temp array
                  [self.selectedStudies addObject:[series study]];
                  tempArray = [NSMutableArray array];
                  [self.selectedSeries addObject:tempArray];
              }
            else
            {
                // get previous temp array
                NSUInteger *i = [self.selectedStudies indexOfObject:[series study]];
                tempArray = [self.selectedSeries objectAtIndex:i];
            }
            
            [tempArray addObject:(DicomSeries*) item];
        }
    }
    
    
    // Process dicom series
    NSNumber *compressionFactor = [NSNumber numberWithFloat:0.5];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:compressionFactor
                                                           forKey:NSImageCompressionFactor];
    
    
    
    for (NSMutableArray *seriesArray in self.selectedSeries)
    {
    
        NSMutableArray *tempArray = [NSMutableArray array];
        [self.zipFiles addObject:tempArray];
        for (DicomSeries *series in seriesArray)
        {
            DicomStudy *study = [series study];
            NSTimeInterval t = [study.date timeIntervalSinceDate:study.dateOfBirth];
            int tempAge = (int)(t / 3600.0 / 24 / 365);
            if (tempAge > 0)
            {
                
                if(tempAge < self.patientAgeInt)
                {
                    self.patientAge = [NSString stringWithFormat:@"%d", tempAge];
                    self.patientAgeInt = tempAge;
                }
            }
            if ([study.patientSex isEqualToString:@"M"])
            {
                self.patientSex = @"Male";
            }
            else if ([study.patientSex isEqualToString:@"F"])
            {
                self.patientSex = @"Female";
            }
            NSString *uuidString = [[NSUUID UUID] UUIDString];
            NSString *filename =
            [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-radiopaedia.zip", uuidString]];
            
            
            
            
            OZZipFile *zipFile= [[OZZipFile alloc] initWithFileName:filename mode:OZZipFileModeCreate legacy32BitMode:YES];
            
            for (DicomImage *image in [series sortedImages])
            {
                NSImage *im = [image image];
                NSImageRep *imageRep;
                if (YES)
                {
                    //im = [image imageAsScreenCapture:NSMakeRect(0,0,image.storedWidth.floatValue,image.storedHeight.floatValue)]; // Horos image.image doesn't work this method however puts annotations on it
                    
                    DCMPix *pix = [[DCMPix alloc] initWithPath:image.completePath :0 :1 :nil :0 :[[image valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:image];
                    [pix pwidth]; //FOR SOME WEIRD REASON YOU NEED TO ACCESS THIS FIRST BEFORE pix image gives anything but nil on horos wtf?!?!?
                    NSData	*data = [[pix image] TIFFRepresentation];
                    im = [[[NSImage alloc] initWithData: data] autorelease];
                }
                imageRep = [[im representations] objectAtIndex:0];
                
                
                NSData *imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];
                NSString *imageName = [NSString stringWithFormat:@"%@.jpg", [[image instanceNumber] stringValue]];
                OZZipWriteStream *stream= [zipFile writeFileInZipWithName:imageName
                                                         compressionLevel:OZZipCompressionLevelBest];
                [stream writeData:imageData];
                [stream finishedWriting];       
            }
            [zipFile close];
            
            [tempArray addObject:filename];
        }
    }
    
    
    
    // Here we try to retrieve the cases
    self.detailsController = [[EnterDetailsWindowController alloc] initWithWindowNibName:@"EnterDetailsWindow"];
    //[self.detailsController showWindow:nil];
    self.detailsController.parent = self;
    // REMEMBER MEMORY ON XIB FILE SHOULD BE BUFFERED
    self.originalWindow = [NSApp keyWindow];
    [self.originalWindow beginSheet:self.detailsController.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseOK)
        {
            NSURL *tokenURL = [NSURL URLWithString:@"http://sandbox.radiopaedia.org/oauth/token"];
            
            // We'll make up an arbitrary redirectURI.  The controller will watch for
            // the server to redirect the web view to this URI, but this URI will not be
            // loaded, so it need not be for any actual web page.
            NSString *redirectURI = @"urn:ietf:wg:oauth:2.0:oob";
            
            GTMOAuth2Authentication *auth;
            auth = [GTMOAuth2Authentication authenticationWithServiceProvider:@"Radiopaedia"
                                                                     tokenURL:tokenURL
                                                                  redirectURI:redirectURI
                                                                     clientID:@"9c2d8456fb2798a7bf0406fa4c6a516f57d74b1b0abd13889e4bf831ba5a2735"
                                                                 clientSecret:@"4ace663418bbe8e4557d0df18452eca90cd768204f1a950984fcae359dc555b0"];
            auth.scope = @"cases";
            NSURL *authURL = [NSURL URLWithString:@"http://sandbox.radiopaedia.org/oauth/authorize"];
            
            
            self.windowController = [GTMOAuth2WindowController controllerWithAuthentication:auth
                                                                      authorizationURL:authURL
                                                                      keychainItemName:@"Radiopaedia Osirix"
                                                                        resourceBundle:nil];
            
            NSString *html = @"<html><body><div align=center>Loading sign-in page...</div></body></html>";
            [self.windowController setInitialHTMLString:html];
            [self.windowController signInSheetModalForWindow:self.originalWindow
                                               delegate:self
                                       finishedSelector:@selector(viewController:finishedWithAuth:error:)];
        }
    }];
   
    return 0;

}
-(void) startProgressBarFor:(NSURLConnection *)connection
{
    
}

-(void) startProcessingQueue
{
    // TODO count total bytes etc and adjust progress bar
    self.progressController = [[ProgressWindowController alloc] initWithWindowNibName:@"ProgressWindow"];
    [self.progressController showWindow:nil];
    [self continueProcessingQueue];

}
-(void) continueProcessingQueue
{
    NSURLRequest *request = [self.queuedRequests lastObject];
    NSString *seriesName = [self.seriesNames lastObject];
    [self.progressController.progressIndicator setDoubleValue:0.0];
    [self.progressController.seriesLabel setStringValue:seriesName];
    NSURLConnection *connection = [[NSURLConnection alloc]
                                   initWithRequest:request
                                   delegate:self
                                   startImmediately:YES];
    
    // NSDictionary *jsonArray = [NSJSONSerialization JSONObjectWithData:response2 options: NSJSONReadingMutableContainers error: &requestError];
    [self performSelectorOnMainThread:@selector(startProgressBarFor:) withObject:connection waitUntilDone:NO];
}
#pragma mark NSURLConnection delegate methods
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
    [self.progressController.progressIndicator incrementBy:(double)bytesWritten * 100.0 / (double)totalBytesExpectedToWrite];
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [self.queuedRequests removeLastObject];
    [self.seriesNames removeLastObject];
    if ([self.queuedRequests count] > 0)
    {
        [self continueProcessingQueue];
    }
    else
    {
        [self.progressController close];
        self.finishedWindowController = [[FinishedWindowController alloc] initWithWindowNibName:@"FinishedWindow"];
        self.finishedWindowController.parent = self;
        
        [self.originalWindow beginSheet:self.finishedWindowController.window completionHandler:^(NSModalResponse returnCode) {
           
        }];
    }
    /*
     <NSHTTPURLResponse: 0x7f88b9923040> { URL: http://sandbox.radiopaedia.org/api/v1/cases/110/studies/43979/images } { status code: 201, headers {
     Age = 0;
     "Cache-Control" = "max-age=0, private, must-revalidate";
     Connection = "keep-alive";
     "Content-Length" = 155;
     "Content-Type" = "application/json";
     Date = "Thu, 07 Apr 2016 21:17:18 GMT";
     Etag = "\"3043e56510ae52e1d05e6830ca72bc39\"";
     Location = "http://sandbox.radiopaedia.org/cases/110/images/23422";
     Status = "201 Created";
     "X-Powered-By" = TrikeApps;
     "X-UA-Compatible" = "IE=Edge,chrome=1";
     } }
     
     */ 

}


@end
