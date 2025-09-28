var group___libmemalloc =
[
    [ "libmemalloc.c", "libmemalloc_8c.html", null ],
    [ "libmemalloc.h", "libmemalloc_8h.html", null ],
    [ "block_header_t", "structblock__header__t.html", [
      [ "canary", "structblock__header__t.html#a4bf7eef55074b8afa0aa5533d2da5d06", null ],
      [ "file", "structblock__header__t.html#a7800923f2b82407895d9bea9038bcd7c", null ],
      [ "fl_next", "structblock__header__t.html#a47740c34b4cb213e0123617ef86424a4", null ],
      [ "fl_prev", "structblock__header__t.html#a16d2f2ab5fba6039bc0d866925c599d7", null ],
      [ "free", "structblock__header__t.html#a1887e332e1371bc734d1d18178630587", null ],
      [ "line", "structblock__header__t.html#ad109a8f3a52c7e56e8e28cd49a171865", null ],
      [ "magic", "structblock__header__t.html#a7d59457a42eecdf01c0fc769c0429be8", null ],
      [ "marked", "structblock__header__t.html#a654b34f813df916058d9cc1ee256f027", null ],
      [ "next", "structblock__header__t.html#aaa54e46e5a8474f0c807305dc261bd04", null ],
      [ "prev", "structblock__header__t.html#a635c6d653e8d114cb528c9c4b144c11d", null ],
      [ "size", "structblock__header__t.html#a0f7cccc0c1922adaf4656efadd2cdaa2", null ],
      [ "var_name", "structblock__header__t.html#a980672b953020cecfd1dcc7e5bfaee16", null ]
    ] ],
    [ "mem_arena_t", "structmem__arena__t.html", [
      [ "bins", "structmem__arena__t.html#a95292ddb78cf299b50c5602dff22bf9e", null ],
      [ "num_bins", "structmem__arena__t.html#a1c6fb33e6b7ce607a162d2b915390d15", null ],
      [ "top_chunk", "structmem__arena__t.html#a777b6a59aa9d583320b3baa739a6496e", null ]
    ] ],
    [ "mmap_t", "structmmap__t.html", [
      [ "addr", "structmmap__t.html#a4c2aaec284318d3af8746a9ff039effb", null ],
      [ "next", "structmmap__t.html#ae9e8c0d75c25852e91494813342ec480", null ],
      [ "size", "structmmap__t.html#a6829cb09e7d351843d818f58552e17e2", null ]
    ] ],
    [ "gc_thread_t", "structgc__thread__t.html", [
      [ "gc_cond", "structgc__thread__t.html#a25f5fbdfae2bcdafb66e3e859d2344b9", null ],
      [ "gc_exit", "structgc__thread__t.html#a91719b53eb99d963d07f9fb210966bfc", null ],
      [ "gc_interval_ms", "structgc__thread__t.html#abb3a53fa2e193eee90728b9fe2d66ac8", null ],
      [ "gc_lock", "structgc__thread__t.html#a990abb01e5dc1f62d0c3393656312a5a", null ],
      [ "gc_running", "structgc__thread__t.html#a4f79c8d4e8708e35f9e9c349da181b65", null ],
      [ "gc_thread", "structgc__thread__t.html#a09fab33e3b06ebd8f10b8c9c2d4fe77a", null ],
      [ "gc_thread_started", "structgc__thread__t.html#adb6b8bd4be1d66cab34111b0987d5abc", null ],
      [ "main_thread", "structgc__thread__t.html#ab3a0de50979ee678096ff29da01af9b4", null ]
    ] ],
    [ "mem_allocator_t", "structmem__allocator__t.html", [
      [ "arenas", "structmem__allocator__t.html#acf9ba831053285626fc8dda2c693db07", null ],
      [ "free_lists", "structmem__allocator__t.html#a64944a78431e46bb8557b9ff07cbf124", null ],
      [ "gc_thread", "structmem__allocator__t.html#a04e38db7363434b17376426ff75921e2", null ],
      [ "heap_end", "structmem__allocator__t.html#a89169fae7690e6c03ae7497295d8a108", null ],
      [ "heap_start", "structmem__allocator__t.html#ae831d3516bdc9ac76ed6af36c5756be7", null ],
      [ "last_allocated", "structmem__allocator__t.html#a0129f049944df54604d51bbfb48176ec", null ],
      [ "last_brk_end", "structmem__allocator__t.html#a1390a8ee959ded33a2d36b21e19806cc", null ],
      [ "last_brk_start", "structmem__allocator__t.html#ad93d642a8fd7209de77de1865a8d4acb", null ],
      [ "metadata_size", "structmem__allocator__t.html#a38b67d7d6571b362988889757072206f", null ],
      [ "mmap_list", "structmem__allocator__t.html#a0f5301b0eb8a8efb7299960dbfe9aa3f", null ],
      [ "num_arenas", "structmem__allocator__t.html#aa436c6fa1bf7250087fee87eb9606e77", null ],
      [ "num_size_classes", "structmem__allocator__t.html#a3d9edab1f863b6f1f6842712e73e8c6d", null ],
      [ "stack_bottom", "structmem__allocator__t.html#a86338c8c7a96d574fd49451509a67394", null ],
      [ "stack_top", "structmem__allocator__t.html#a75895b02081348b494c934885e577404", null ]
    ] ],
    [ "__ALIGN", "group___libmemalloc.html#gaabc39bf362e54cf3bb45d3dfe4933ccb", null ],
    [ "__LIBMEMALLOC_API", "group___libmemalloc.html#gab530abfacb1e55f2317fe51a1dfc9f61", null ],
    [ "__LIBMEMALLOC_MALLOC", "group___libmemalloc.html#gaf415f4394a90cbf3b58ffb43c1d26122", null ],
    [ "__LIBMEMALLOC_REALLOC", "group___libmemalloc.html#gab2ea557d67d841f4f1a765a7ebb2ec4c", null ],
    [ "ALIGN", "group___libmemalloc.html#gabe7f8cd9a0ce69b71567a3870415be66", null ],
    [ "GC_INTERVAL_MS", "group___libmemalloc.html#ga78fc3a47b5647490189daf6d222121cc", null ],
    [ "PTR_ERR", "group___libmemalloc.html#gad279cb341b8fafacaef5650243902eee", null ],
    [ "allocation_strategy_t", "group___libmemalloc.html#ga36d2f4c096864df4566ad4ccbf9f1cc8", [
      [ "FIRST_FIT", "group___libmemalloc.html#gga36d2f4c096864df4566ad4ccbf9f1cc8a8dba223d467d98a5827105bfb9e1f7f9", null ],
      [ "NEXT_FIT", "group___libmemalloc.html#gga36d2f4c096864df4566ad4ccbf9f1cc8a509b34c444b7ee18d4187e9f942b8778", null ],
      [ "BEST_FIT", "group___libmemalloc.html#gga36d2f4c096864df4566ad4ccbf9f1cc8af78ff891c96ec23919b6c7068f25a05d", null ]
    ] ],
    [ "MEM_allocatorInit", "group___libmemalloc.html#ga29b089596d8875787349365defca54e3", null ],
    [ "MEM_allocCalloc", "group___libmemalloc.html#ga7b69c79c27b1d2b7984b828b97ff5541", null ],
    [ "MEM_allocFree", "group___libmemalloc.html#ga3cab92042cc5e42c0b275df4628f604c", null ],
    [ "MEM_allocMalloc", "group___libmemalloc.html#gaf47b919f35d0b68fb150fa7bcfc26e09", null ],
    [ "MEM_allocMallocBestFit", "group___libmemalloc.html#ga8188c29f62d50e0ac2817c97a5725eb2", null ],
    [ "MEM_allocMallocFirstFit", "group___libmemalloc.html#ga974e87377bc908b49153828daf968d7d", null ],
    [ "MEM_allocMallocNextFit", "group___libmemalloc.html#gab05eb289fbab89920c21abe7f8d9ff1b", null ],
    [ "MEM_allocRealloc", "group___libmemalloc.html#gaf8c7a8857b519e657735f716d4023b47", null ],
    [ "MEM_disableGc", "group___libmemalloc.html#gac52c90f06b2f9aee3f5350c46852dbaa", null ],
    [ "MEM_enableGc", "group___libmemalloc.html#gada7e498922ace7676e4b928e0c3fbfdd", null ],
    [ "MEM_memcpy", "group___libmemalloc.html#gaf0f38e83f3601cb880ea1feeb6deaf93", null ],
    [ "MEM_memset", "group___libmemalloc.html#gacfe1e6a057174df954033f59117b9cde", null ]
];