/*
    Copyright (C) 2012 Eric Wasylishen

    Date:  December 2012
    License:  MIT  (see COPYING)
 */

#import "COItemGraph.h"
#import <EtoileFoundation/Macros.h>
#import <EtoileFoundation/ETUUID.h>
#import "COItem.h"
#import "COItem+JSON.h"
#import "COPath.h"

@implementation COItemGraph

- (instancetype) init
{
	SUPERINIT;
    itemForUUID_ = [[NSMutableDictionary alloc] init];
	return self;
}

- (id) initWithItemForUUID: (NSDictionary *) itemForUUID
              rootItemUUID: (ETUUID *)root
{
    SUPERINIT;
    itemForUUID_ = [itemForUUID mutableCopy];
    rootItemUUID_ = [root copy];
    return self;
}

- (id) initWithItems: (NSArray *)items
        rootItemUUID: (ETUUID *)root
{
    SUPERINIT;
    itemForUUID_ = [[NSMutableDictionary alloc] init];
    rootItemUUID_ = [root copy];
    
    for (COItem *item in items)
    {
        [itemForUUID_ setObject: item forKey: [item UUID]];
    }
    
    return self;
}

- (id) initWithItemGraph: (id<COItemGraph>)aGraph
{
    NSMutableArray *array = [NSMutableArray array];
    
    for (ETUUID *uuid in [aGraph itemUUIDs])
    {
        COItem *item = [aGraph itemForUUID: uuid];
        [array addObject: item];
    }
    
    return [self initWithItems: array rootItemUUID: [aGraph rootItemUUID]];
}

+ (COItemGraph *)itemGraphWithItemsRootFirst: (NSArray*)items
{
    NSParameterAssert([items count] >= 1);

    COItemGraph *result = [[self alloc] init];
    result->rootItemUUID_ = [[[items objectAtIndex: 0] UUID] copy];
    result->itemForUUID_ = [[NSMutableDictionary alloc] initWithCapacity: [items count]];
    
    for (COItem *item in items)
    {
        [result->itemForUUID_ setObject: item forKey: [item UUID]];
    }
    return result;
}

@synthesize rootItemUUID = rootItemUUID_;

- (COMutableItem *) itemForUUID: (ETUUID *)aUUID
{
    return [itemForUUID_ objectForKey: aUUID];
}

- (NSArray *) itemUUIDs
{
    return [itemForUUID_ allKeys];
}

- (NSArray *) items
{
	return [itemForUUID_ allValues];
}

- (NSString *)description
{
	NSMutableString *result = [NSMutableString string];
    
	[result appendFormat: @"[%@ root: %@\n", NSStringFromClass([self class]), rootItemUUID_];
	for (COItem *item in [itemForUUID_ allValues])
	{
		[result appendFormat: @"%@", item];
	}
	[result appendFormat: @"]"];
	
	return result;
}

- (void) insertOrUpdateItems: (NSArray *)items
{
    for (COItem *anItem in items)
    {
        [itemForUUID_ setObject: anItem
                         forKey: [anItem UUID]];
    }
}

/**
 * For debugging/testing only
 */
- (BOOL) isEqual:(id)object
{
    //NSLog(@"WARNING, COItemGraph should be compared for debugging only");
    
    if (![object isKindOfClass: [self class]])
    {
        return NO;
    }
    
    return COItemGraphEqualToItemGraph(self, object);
}

- (void) addItemGraph: (id<COItemGraph>)aGraph
{
    rootItemUUID_ = [aGraph rootItemUUID];
    for (ETUUID *uuid in [aGraph itemUUIDs])
    {
        COItem *item = [aGraph itemForUUID: uuid];
        if (item != nil)
        {
            [itemForUUID_ setObject: item forKey: uuid];
        }
    }
}

@end


/**
 * For debugging
 */
void COValidateItemGraph(id<COItemGraph> aGraph)
{
    if (nil == [aGraph itemForUUID: [aGraph rootItemUUID]])
    {
        [NSException raise: NSInvalidArgumentException
                    format: @"Graph root item is missing"];
    }
    
    NSSet *uuidSet = [NSSet setWithArray: [aGraph itemUUIDs]];
    
    for (ETUUID *uuid in [aGraph itemUUIDs])
    {
        COItem *item = [aGraph itemForUUID: uuid];
        
        for (NSString *key in [item attributeNames])
        {
            id value = [item valueForAttribute: key];
            COType type = [item typeForAttribute: key];
            
            // Check that the value conforms to the COType
            
            if (!COTypeValidateObject(type, value))
            {
                [NSException raise: NSInvalidArgumentException
                            format: @"Property value %@ for key %@ (type %@) of object %@ is not valid",
                                    value, key, COTypeDescription(type), uuid];
            }
            
            // Check that all inner references can be resolved
            
            if (COTypePrimitivePart(type) == kCOTypeReference
                || COTypePrimitivePart(type) == kCOTypeCompositeReference)
            {
                for (id subValue in
                     [value respondsToSelector: @selector(objectEnumerator)] ? value : [NSArray arrayWithObject: value])
                {
                    if ([subValue isKindOfClass: [ETUUID class]])
                    {
                        if (![uuidSet containsObject: subValue])
                        {
                            [NSException raise: NSInvalidArgumentException
                                        format: @"Object %@ has broken inner object reference %@", uuid, subValue];
                        }
                    }
                }
            }
        }
    }
}

id COItemGraphToJSONPropertyList(id<COItemGraph> aGraph)
{
    NSMutableDictionary *objectsDict = [NSMutableDictionary dictionary];
    for (ETUUID *uuid in [aGraph itemUUIDs])
    {
        COItem *item = [aGraph itemForUUID: uuid];
        id objectPlist = [item JSONPlist];
        [objectsDict setObject: objectPlist
                        forKey: [uuid stringValue]];
    }
    
    return @{@"objects" : objectsDict,
             @"rootObjectUUID" : [[aGraph rootItemUUID] stringValue]};
}

NSData *COItemGraphToJSONData(id<COItemGraph> aGraph)
{
    NSDictionary *graphDict = COItemGraphToJSONPropertyList(aGraph);    
    return [NSJSONSerialization dataWithJSONObject: graphDict options: 0 error: NULL];
}

COItemGraph *COItemGraphFromJSONPropertyLisy(id plist)
{
    id objectsPlist = [plist objectForKey: @"objects"];
    ETUUID *rootObjectUUID = [ETUUID UUIDWithString: [plist objectForKey: @"rootObjectUUID"]];
    NSMutableDictionary *itemForUUID = [NSMutableDictionary dictionary];
    
    for (NSString *uuidString in objectsPlist)
    {
        COItem *item = [[COItem alloc] initWithJSONPlist: [objectsPlist objectForKey: uuidString]];
        [itemForUUID setObject: item
                        forKey: [item UUID]];
    }
    
    COItemGraph *graph = [[COItemGraph alloc] initWithItemForUUID: itemForUUID
                                                     rootItemUUID: rootObjectUUID];
    return graph;
}

COItemGraph *COItemGraphFromJSONData(NSData *json)
{
    id plist = [NSJSONSerialization JSONObjectWithData: json options:0 error: NULL];
    return COItemGraphFromJSONPropertyLisy(plist);
}

/**
 * For debugging/testing only
 */
static BOOL COItemGraphEqualToItemGraphComparingItemUUID(id<COItemGraph> first, id<COItemGraph> second, ETUUID *aUUID)
{
    COItem *my = [first itemForUUID: aUUID];
    COItem *other = [second itemForUUID: aUUID];
    if (![my isEqual: other])
    {
        return NO;
    }
    
    if (![[my compositeReferencedItemUUIDs] isEqual: [other compositeReferencedItemUUIDs]])
    {
        return NO;
    }
    
    for (ETUUID *aChild in [my compositeReferencedItemUUIDs])
    {
        if (!COItemGraphEqualToItemGraphComparingItemUUID(first, second, aChild))
        {
            return NO;
        }
    }
    return YES;
}

BOOL COItemGraphEqualToItemGraph(id<COItemGraph> first, id<COItemGraph> second)
{
    if (![[first rootItemUUID] isEqual: [second rootItemUUID]])
    {
        return NO;
    }
    
    return COItemGraphEqualToItemGraphComparingItemUUID(first, second, [first rootItemUUID]);
}

static void
COItemGraphReachableUUIDsInternal(id<COItemGraph> aGraph, ETUUID *aUUID, NSMutableSet *result)
{
	if (![aUUID isKindOfClass: [ETUUID class]])
	{
		[NSException raise: NSInvalidArgumentException format: @"Expected ETUUID argument to COItemGraphReachableUUIDsInternal, got %@", aUUID];
	}
	
	if ([result containsObject: aUUID])
		return;
	
	[result addObject: aUUID];
	
    COItem *item = [aGraph itemForUUID: aUUID];
    for (id aChild in [item allInnerReferencedItemUUIDs])
    {
        COItemGraphReachableUUIDsInternal(aGraph, aChild, result);
    }
}

NSSet *
COItemGraphReachableUUIDs(id<COItemGraph> aGraph)
{
    NSMutableSet *result = [NSMutableSet new];
	if ([aGraph rootItemUUID] != nil)
	{
		COItemGraphReachableUUIDsInternal(aGraph, [aGraph rootItemUUID], result);
	}
	return result;
}
