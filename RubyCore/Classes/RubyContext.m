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

typedef NS_OPTIONS(int, RBBlockFlags) {
  BlockFlagsHasCopyDisposeHelpers = (1 << 25),
  BlockFlagsHasSignature          = (1 << 30)
};

typedef struct RBBlock {
  __unused Class isa;
  RBBlockFlags flags;
  __unused int reserved;
  void (__unused *invoke)(struct RBBlock *block, ...);
  struct {
    unsigned long int reserved;
    unsigned long int size;
    // requires AspectBlockFlagsHasCopyDisposeHelpers
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
    // requires AspectBlockFlagsHasSignature
    const char *signature;
    const char *layout;
  } *descriptor;
  // imported variables
} *RBBlockRef;

static void gcRunloopCallout(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *state) {
//  mrb_garbage_collect(state);
}

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
    [self attachGCToCurrentThread];
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

- (void)attachGCToCurrentThread {
  CFRunLoopRef runloop = [[NSRunLoop currentRunLoop] getCFRunLoop];
  CFRunLoopObserverContext ctx = {0, currentContext, NULL, NULL, NULL};
  CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopBeforeWaiting, YES, 0, &gcRunloopCallout, &ctx);
  CFRunLoopAddObserver(runloop, observer, kCFRunLoopCommonModes);
}

#pragma mark - subscript
- (id)objectAtIndexedSubscript:(NSString *)idx {
  return nil;
}

- (void)setObject:(id)obj atIndexedSubscript:(NSString *)idx {
  
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
