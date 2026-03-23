#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// Xotiraga xavfsiz yozish (Patching) funksiyasi
void safe_patch_memory(uintptr_t address, uint32_t data) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = vm_page_size;

    // 1. Xotira sahifasiga yozish ruxsatini olamiz (Read + Write + Copy)
    kern_return_t err = vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY);
    
    if (err == KERN_SUCCESS) {
        // 2. Belgilangan offsetga RET (0xD65F03C0) buyrug'ini yozamiz
        *(uint32_t *)address = data;
        
        // 3. Xavfsizlik uchun ruxsatni asl holiga (Read + Execute) qaytaramiz
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

%ctor {
    // 60 soniya kutish (60 * NSEC_PER_SEC)
    // O'yin to'liq yuklanib, lobbiga kirib, hamma narsa tinchiganidan keyin ishlaydi
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(60 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        // O'yinning xotiradagi asosiy manzilini (Slide) olamiz
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // Sizning 4.3.0.20955 versiya uchun offsetingiz
        uintptr_t target_offset = slide + 0x15E6680; 

        // Patch qilish: Funksiyani to'xtatish (RET buyrug'i)
        safe_patch_memory(target_offset, 0xD65F03C0);
        
    });
}
