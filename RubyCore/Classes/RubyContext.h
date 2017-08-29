//
//  RubyContext.h
//  Pods
//
//  Created by stephenw on 2017/8/25.
//
//

#import <Foundation/Foundation.h>
#import <MRuby/mruby.h>

NS_ASSUME_NONNULL_BEGIN

@protocol RBGemProvider <NSObject>

@required

/**
 register your gem with original ruby vm intepreter

 @param vm original vm pointer
 */
- (void)doRegisterWithVM:(mrb_state *)vm;

@optional
/**
 do something to clear your instance when GC start up

 @param vm original vm pointer
 */
- (void)willDisposeWithVM:(mrb_state *)vm;

@end

@interface RubyContext : NSObject

/**
 execute ruby byte code

 @param path byte code file path
 */
- (void)executeByteCodeSource:(NSString *)path;

/**
 register custom gem

 @param provider a class conforms RBGemProvider protocol
 */
- (void)registerGemProvider:(Class)provider;

/// subscript support
- (nullable id)objectAtIndexedSubscript:(NSString *)idx;
- (void)setObject:(id)obj atIndexedSubscript:(NSString *)idx;

@end

NS_ASSUME_NONNULL_END
