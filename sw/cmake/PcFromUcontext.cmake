include(CheckIncludeFile)
include(CheckCSourceCompiles)

check_include_file("ucontext.h" HAVE_UCONTEXT_H)
check_include_file("sys/ucontext.h" HAVE_SYS_UCONTEXT_H)

set(UCONTEXT_INCLUDES)

if (HAVE_UCONTEXT_H)
  set(UCONTEXT_INCLUDES "${UCONTEXT_INCLUDES}\n#include <ucontext.h>")
endif()

if (HAVE_SYS_UCONTEXT_H)
  set(UCONTEXT_INCLUDES "${UCONTEXT_INCLUDES}\n#include <sys/ucontext.h>")
endif()

foreach (pc_field          
         "uc_mcontext.gregs[REG_EIP]"
         "uc_mcontext.gregs[REG_RIP]"
         "uc_mcontext.sc_ip"
         "uc_mcontext.uc_regs->gregs[PT_NIP]"
         "uc_mcontext.gregs[R15]"
         "uc_mcontext.arm_pc"
         "uc_mcontext.mc_eip"
         "uc_mcontext.mc_rip"
         "uc_mcontext.__gregs[_REG_EIP]"
         "uc_mcontext.__gregs[_REG_RIP]"
         "uc_mcontext->ss.eip"
         "uc_mcontext->__ss.__eip"
         "uc_mcontext->ss.rip"
         "uc_mcontext->__ss.__rip"
         "uc_mcontext->ss.srr0"
         "uc_mcontext->__ss.__srr0")
  
  message (STATUS "Checking PC fetch from ucontext: ${pc_field}")
  
  check_c_source_compiles("
  #define _GNU_SOURCE 1
  ${UCONTEXT_INCLUDES}
  int main(int argc, char** argv) {
    ucontext_t ctx;
    return ctx.${pc_field} == 0;
  }" 
  CompilePCFromUContext)
  
  if (CompilePCFromUContext)
    unset(CompilePCFromUContext CACHE)  
    message (STATUS "Found uncontext field: ${pc_field}") 
    set(PC_FROM_UCONTEXT ${pc_field})
    break()
  else()
    unset(CompilePCFromUContext CACHE) 
  endif() 
 endforeach()
 
 if (NOT PC_FROM_UCONTEXT) 
   message (FATAL_ERROR "Failed to detect ucontext structure.")
 endif()
 
 
add_definitions(
  -DPC_FROM_UCONTEXT=${PC_FROM_UCONTEXT}
)
 