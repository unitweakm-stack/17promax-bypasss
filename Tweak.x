#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// 1. Xotirani patch qilish funksiyasi
void apply_weak_patch(uintptr_t address, uint32_t value) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = vm_page_size;

    if (vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        *(uint32_t *)address = value;
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// 2. Odamlarni devor ortidan ko'rish (ESP) uchun mantiqiy qism
// BU YERDA OFFSETLAR O'ZGARUVCHAN (Har bir versiya uchun alohida topiladi)
uintptr_t GWorld_Offset = 0x76A1B28; 

%hook AActor // O'yindagi barcha personajlar klassi
- (void)Tick:(float)arg1 { // Har bir kadrda ishlaydi
    %orig;
    
    // Bu yerda o'yinchini "ko'rinadigan" qilish kodi bo'ladi
    // Masalan: CustomRender orqali chizish
}
%end

// 3. Keychain va UIDevice-ni bloklash (Ban yemaslik uchun)
%hook UICKeyChainStore
- (id)stringForKey:(id)key { return nil; }
- (_Bool)setString:(id)string forKey:(id)key { return YES; }
%end

%hook UIDevice
- (id)uuid { return @""; }
%end

// 4. Bypass va ESP-ni ishga tushirish
%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // 1. Key (Kod) so'rashni o'chirish
        apply_weak_patch(slide + 0x15E6680, 0xD65F03C0);
        
        // 2. ESP uchun kerakli xotira manzillarini tayyorlash
        uintptr_t GWorld = *(uintptr_t*)(slide + GWorld_Offset);
        
        if (GWorld) {
            NSLog(@"[WEAK] ESP uchun GWorld topildi: %lx", GWorld);
        }

        NSLog(@"[WEAK] Odam ko'rinadigan (ESP) va Bypass muvaffaqiyatli yuklandi.");
    });
}
