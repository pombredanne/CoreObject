#import <Foundation/Foundation.h>
#import <CoreObject/CoreObject.h>

@interface EWAppDelegate : NSObject
{
    /**
     * Each context has its own store
     */
    COEditingContext *_user1Ctx;
    COEditingContext *_user2Ctx;
}

- (COPersistentRoot *) user1PersistentRoot;
- (COPersistentRoot *) user2PersistentRoot;

- (IBAction)undoHistory:(id)sender;

@end
