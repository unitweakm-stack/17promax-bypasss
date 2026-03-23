#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// Xotira patcher
void apply_weak_bypass(uintptr_t address, uint32_t value) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    if (vm_protect(task, page_start, vm_page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        *(uint32_t *)address = value;
        vm_protect(task, page_start, vm_page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// Anti-Ban hooklar
%hook UICKeyChainStore
- (id)stringForKey:(id)key { return nil; }
- (_Bool)setString:(id)string forKey:(id)key { return YES; }
%end

%hook UIDevice
- (id)uuid { return @""; }
- (id)uniqueIdentifier { return nil; }
%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        // ShadowTrackerExtra 4.3.0 Key Bypass
        apply_weak_bypass(slide + 0x15E6680, 0xD65F03C0);
    });
}
