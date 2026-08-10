#import <Foundation/Foundation.h>

#if __has_include(<roothide.h>)
#import <roothide.h>
#define DODO_HAS_ROOTHIDE 1
#else
#define DODO_HAS_ROOTHIDE 0
#endif

NSString *DodoRootPath(NSString *path) {
    if (path.length == 0 || ![path hasPrefix:@"/"]) {
        return path;
    }
#if DODO_HAS_ROOTHIDE
    return jbroot(path);
#elif defined(ROOTLESS)
    return [@"/var/jb" stringByAppendingString:path];
#else
    return path;
#endif
}
