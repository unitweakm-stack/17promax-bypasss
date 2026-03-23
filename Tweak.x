#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        // 4.3.0 Anti-ban offset
        *(uint32_t *)(slide + 0x15E6680) = 0xD65F03C0; 
    });
}
