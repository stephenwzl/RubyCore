//
//  RubyContext.m
//  Pods
//
//  Created by stephenw on 2017/8/25.
//
//

#import "RubyContext.h"
#import <MRuby/mruby.h>
#import <MRuby/mruby/irep.h>
#import <MRuby/mruby/proc.h>
#import <MRuby/mruby/dump.h>

@interface RubyContext()

{
  mrb_state *currentContext;
  mrb_irep *irep;
}

@property (nonatomic, strong) NSMutableDictionary *gems;

@end

@implementation RubyContext

- (instancetype)init {
  if (self = [super init]) {
    currentContext = mrb_open();
    irep = NULL;
  }
  return self;
}

- (void)executeByteCodeSource:(NSString *)path {
  if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
    return;
  }
  [self recreateIREPWithFilePath:path];
  mrb_run(currentContext, mrb_proc_new(currentContext, irep), mrb_top_self(currentContext));
}

- (void)registerGemProvider:(Class)provider {
  NSAssert(![provider conformsToProtocol:@protocol(RBGemProvider)], @"provider must conforms to protocol RBGemProvider");
  NSString *gemName = NSStringFromClass(provider);
  if ([[self.gems allKeys] containsObject:gemName]) {
    return;
  }
  id gem = [provider new];
  [gem doRegisterWithVM:currentContext];
  self.gems[gemName] = gem;
}

#pragma mark - helper
- (void)recreateIREPWithFilePath:(NSString *)path {
  if (irep) {
    mrb_irep_free(currentContext, irep);
  }
  FILE *fp = fopen(path.UTF8String, "rb");
  irep = mrb_read_irep_file(currentContext, fp);
}

- (NSMutableDictionary *)gems {
  if (!_gems) {
    _gems = [NSMutableDictionary new];
  }
  return _gems;
}

- (void)dealloc {
  
  //destroy the vm
  if (currentContext) {
    if (irep) {
      mrb_irep_free(currentContext, irep);
    }
    // TODO: calls when GC start up
    [self.gems enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
      if ([obj respondsToSelector:@selector(willDisposeWithVM:)]) {
        [obj willDisposeWithVM:currentContext];
      }
    }];
    mrb_close(currentContext);
  }
}

@end
