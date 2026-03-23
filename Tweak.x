#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// Xotiraga patch qilish funksiyasi
void apply_weak_patch(uintptr_t address, uint32_t value) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = vm_page_size;

    if (vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        *(uint32_t *)address = value;
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

%ctor {
    // 60 soniya kutish
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        uintptr_t target = slide + 0x15E6680; 

        // Bypassni yoqish
        apply_weak_patch(target, 0xD65F03C0);

        // Xabarnoma chiqarish (Eng xavfsiz usul)
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WEAK" 
                                                                           message:@"Weak ishladi" 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            // Xatoni butunlay yo'qotish uchun UIWindow-ni to'g'ridan-to'g'ri topish
            id delegate = [[UIApplication sharedApplication] delegate];
            if ([delegate respondsToSelector:@selector(window)]) {
                UIWindow *window = [delegate performSelector:@selector(window)];
                [window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        });
    });
}
