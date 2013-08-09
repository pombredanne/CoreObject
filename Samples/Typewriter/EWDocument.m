#import "EWAppDelegate.h"
#import "EWDocument.h"
#import "EWUndoManager.h"
#import "EWTypewriterWindowController.h"
#import "EWBranchesWindowController.h"
#import "EWPickboardWindowController.h"
#import "EWHistoryWindowController.h"
#import <EtoileFoundation/Macros.h>

#import <CoreObject/CoreObject.h>

@implementation EWDocument

- (id)init
{
    SUPERINIT;
    
    ASSIGN(_persistentRoot, [[[NSApp delegate] editingContext] insertNewPersistentRootWithEntityName: @"Anonymous.TypewriterDocument"]);
    [_persistentRoot commit];
    
    EWUndoManager *myUndoManager = [[[EWUndoManager alloc] init] autorelease];
    [myUndoManager setDelegate: self];
    [self setUndoManager: (NSUndoManager *)myUndoManager];
    
//        [[NSNotificationCenter defaultCenter] addObserver: self
//                                                 selector: @selector(storePersistentRootMetadataDidChange:)
//                                                     name: COStorePersistentRootMetadataDidChangeNotification
//                                                   object: store_];
    
    return self;
}

- (void) dealloc
{
//    [[NSNotificationCenter defaultCenter] removeObserver: self
//                                                    name: COStorePersistentRootMetadataDidChangeNotification
//                                                  object: store_];

    [_persistentRoot release];
    [super dealloc];
}

- (void)makeWindowControllers
{
    EWTypewriterWindowController *windowController = [[[EWTypewriterWindowController alloc] initWithWindowNibName: [self windowNibName]] autorelease];
    [self addWindowController: windowController];
}

- (NSString *)windowNibName
{
    return @"EWDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
}


- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning NO.
    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.
    // If you override either of these, you should also override -isEntireFileLoaded to return NO if the contents are lazily loaded.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return YES;
}

- (void)saveDocument:(id)sender
{
    NSLog(@"save");
}

- (IBAction) branch: (id)sender
{
    COBranch *branch = [[_persistentRoot editingBranch] makeBranchWithLabel: @"Untitled"];
    [_persistentRoot setCurrentBranch: branch];
    [_persistentRoot commit];
    
    [self reloadFromStore];
}
- (IBAction) showBranches: (id)sender
{
    [[EWBranchesWindowController sharedController] show];
}
- (IBAction) history: (id)sender
{
    [[EWHistoryWindowController sharedController] show];
}
- (IBAction) pickboard: (id)sender
{
    [[EWPickboardWindowController sharedController] show];
}

- (void) recordNewState: (id <COItemGraph>)aTree
{
//    
//    
//    CORevisionID *token = [[_persistentRoot currentBranch] currentRevisionID];
//    
//    CORevisionID *newState = [CORevisionID stateWithTree: aTree];
//    CORevisionID *token2 = [store_ addState: newState parentState: token];
//    
//    [store_ setCurrentVersion: token2 forBranch: [[_persistentRoot currentBranch] UUID] ofPersistentRoot: [_persistentRoot UUID]];
//    
//    ASSIGN(_persistentRoot, [store_ persistentRootWithUUID: [_persistentRoot UUID]]);
}

- (void) validateCanLoadStateToken: (CORevisionID *)aToken
{
//    COBranch *editingBranchObject = [_persistentRoot branchForUUID: [self editingBranch]];
//    if (editingBranchObject == nil)
//    {
//        [NSException raise: NSInternalInconsistencyException
//                    format: @"editing branch %@ must be one of the persistent root's branches", editingBranch_];
//    }
//    
//    if (![[editingBranchObject allCommits] containsObject: aToken])
//    {
//        [NSException raise: NSInternalInconsistencyException
//                    format: @"the given token %@ must be in the current editing branch's list of states", aToken];
//    }
}

- (void) persistentSwitchToStateToken: (CORevisionID *)aToken
{
//    [store_ setCurrentVersion: aToken
//                    forBranch: [self editingBranch]
//             ofPersistentRoot: [self UUID]];
//    [self reloadFromStore];
}

// Doesn't write to DB...
- (void) loadStateToken: (CORevisionID *)aToken
{
    [self validateCanLoadStateToken: aToken];
         
    COBranch *editingBranchObject = [_persistentRoot editingBranch];

    [editingBranchObject setCurrentRevision: [CORevision revisionWithStore: [self store]
                                                                revisionID: aToken]];
    
    CORevisionID *state = [[self store] fullStateForToken: aToken];
    id <COItemGraph> tree = [state tree];

    NSArray *wcs = [self windowControllers];
    for (EWTypewriterWindowController *wc in wcs)
    {
        [wc loadDocumentTree: tree];
    }
}

- (void) setPersistentRoot: (COPersistentRoot*) aMetadata
{
    assert(aMetadata != nil);
    
    ASSIGN(_persistentRoot, aMetadata);
    [self loadStateToken: [[_persistentRoot currentBranch] currentRevisionID]];
    
    for (NSWindowController *wc in [self windowControllers])
    {
        [wc synchronizeWindowTitleWithDocumentName];
    }
}

- (NSString *)displayName
{
    NSString *branchName = [[_persistentRoot currentBranch] label];
    
    // FIXME: Get proper persistent root name
    return [NSString stringWithFormat: @"Untitled (on branch '%@')",
            branchName];
}

- (void) reloadFromStore
{
    // Reads the UUID of _persistentRoot, and uses that to reload the rest of the metadata
    
    ETUUID *uuid = [self UUID];
    
    //[self setPersistentRoot: [store_ persistentRootWithUUID: uuid]];
}

- (ETUUID *) editingBranch
{
    return [[_persistentRoot editingBranch] UUID];
}

- (COPersistentRoot *) currentPersistentRoot
{
    return _persistentRoot;
}

- (ETUUID *) UUID
{
    return [_persistentRoot persistentRootUUID];
}

- (COSQLiteStore *) store
{
    return [[NSApp delegate] store];
}

- (void) storePersistentRootMetadataDidChange: (NSNotification *)notif
{
    NSLog(@"did change: %@", notif);
}

- (void) switchToBranch: (ETUUID *)aBranchUUID
{
    [_persistentRoot setCurrentBranch: [_persistentRoot branchForUUID: aBranchUUID]];
    [_persistentRoot commit];
    [self reloadFromStore];
}

- (void) deleteBranch: (ETUUID *)aBranchUUID
{
    [_persistentRoot deleteBranch: [_persistentRoot branchForUUID: aBranchUUID]];
    [_persistentRoot commit];
    [self reloadFromStore];
}

/* EWUndoManagerDelegate */

- (void) undo
{
}
- (void) redo
{
}

- (BOOL) canUndo
{
    return NO;
}
- (BOOL) canRedo
{
    return NO;
}

- (NSString *) undoMenuItemTitle
{
    return @"Undo unavailable";
}
- (NSString *) redoMenuItemTitle
{
    return @"Redo unavailable";
}

@end