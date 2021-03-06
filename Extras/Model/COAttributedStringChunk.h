/**
	Copyright (C) 2013 Eric Wasylishen

	Date:  December 2013
	License:  MIT  (see COPYING)
 */

#import <CoreObject/CoreObject.h>

@class COAttributedString;

@interface COAttributedStringChunk : COObject
{
	NSString *text;
}

@property (nonatomic, readwrite, strong) NSString *text;
@property (nonatomic, readwrite, strong) NSSet *attributes;
@property (nonatomic, readonly, weak) COAttributedString *parentString;
/**
 * Returns an item graph that contains a copy of the receiver that has been trimmed to the given subrange as its root object.
 */
- (COItemGraph *) subchunkItemGraphWithRange: (NSRange)aRange;

@property (nonatomic, readonly) NSUInteger length;

/**
 * Returns a string like @"b,u" if the chunk is bold and underlined
 */
- (NSString *) attributesDebugDescription;

/**
 * Character index of the start of the chunk. Currently O(N)
 */
- (NSUInteger) characterIndex;

- (NSRange) characterRange;

@end
