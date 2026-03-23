#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// 1. Xotiraga xavfsiz yozish funksiyasi (Crash-ga qarshi)
void patch_memory_safe(uintptr_t address, uint32_t data) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = vm_page_size;

    // Xotiraga yozish ruxsatini olamiz
    kern_return_t err = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (err == KERN_SUCCESS) {
        // Offsetga yangi qiymatni (RET) yozamiz
        *(uint32_t *)address = data;
        
        // Ruxsatni asl holiga qaytaramiz
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// 2. Ekranda yozuv chiqarish funksiyasi
void show_success_msg() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"WEAK BYPASS" 
                                                                       message:@"Weak ishladi" 
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        UIViewController *root = window.rootViewController;
        
        while (root.presentedViewController) {
            root = root.presentedViewController;
        }
        [root presentViewController:alert animated:YES completion:nil];
    });
}

// 3. Asosiy ishga tushish qismi
%ctor {
    // 60 soniya (1 minut) kutamiz - lobbi to'liq yuklanishi uchun
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // O'yinning xotiradagi manzilini aniqlaymiz
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // 4.3.0 versiya uchun siz bergan offset
        uintptr_t target_addr = slide + 0x15E6680; 

        // Patch qilish (RET buyrug'i: 0xD65F03C0)
        patch_memory_safe(target_addr, 0xD65F03C0);

        // Muvaffaqiyatli xabarni ko'rsatish
        show_success_msg();
        
    });
}
