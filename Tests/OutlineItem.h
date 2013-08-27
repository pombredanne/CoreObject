#import <CoreObject/CoreObject.h>

@interface OutlineItem : COContainer

@property (readwrite, retain, nonatomic) NSString *label;
@property (readwrite, retain, nonatomic) NSArray *contents;
@property (readonly, nonatomic) OutlineItem *parentContainer;
@property (readonly, nonatomic) NSSet *parentCollections;

@end