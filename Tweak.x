#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>

// Xotirani xavfsiz tahrirlash (Patch) funksiyasi
void apply_weak_bypass(uintptr_t address, uint32_t value) {
    mach_port_t task = mach_task_self();
    vm_address_t page_start = trunc_page(address);
    vm_size_t page_size = vm_page_size;

    if (vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_COPY) == KERN_SUCCESS) {
        *(uint32_t *)address = value;
        vm_protect(task, page_start, page_size, FALSE, VM_PROT_READ | VM_PROT_EXECUTE);
    }
}

// 1. Keychain blokirovkasi (Ban ma'lumotlarini saqlashni to'xtatadi)
%hook UICKeyChainStore
- (id)stringForKey:(id)key { return nil; }
- (id)dataForKey:(id)key { return nil; }
- (_Bool)setString:(id)string forKey:(id)key { return YES; }
- (_Bool)setData:(id)data forKey:(id)key { return YES; }
%end

// 2. Qurilma ma'lumotlarini yashirish (Device Ban-dan himoya)
%hook UIDevice
- (id)uuid { return @""; }
- (id)uniqueIdentifier { return nil; }
- (NSString *)name { return @"iPhone"; }
%end

// 3. Asosiy Bypass va Kod so'rashni o'chirish
%ctor {
    // O'yin binar fayli (App) yuklanishi uchun 4 soniya kutamiz
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
        
        // v4.3.0 uchun kod tekshiruvi va himoya nuqtasi
        // RET (0xD65F03C0) instruksiyasi funksiyani darrov yopadi
        apply_weak_bypass(slide + 0x15E6680, 0xD65F03C0);

        NSLog(@"[WEAK] Faqat Anti-Ban va Bypass muvaffaqiyatli ishga tushdi.");
    });
}
