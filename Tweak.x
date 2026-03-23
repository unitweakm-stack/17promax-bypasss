#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

void safe_patch_memory(uintptr_t address, uint32_t data) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = vm_page_size;
    kern_return_t err = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    if (err == KERN_SUCCESS) {
        *(uint32_t *)address = data;
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        uintptr_t target_offset = slide + 0x15E6680; 

        safe_patch_memory(target_offset, 0xD65F03C0);

        // Ekranda xabar chiqarish (Bypass ishlaganini bilish uchun)
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Weakvertual" 
                                                                       message:@"Anti-Ban Muvaffaqiyatli Yoqildi!" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
        
    });
}
