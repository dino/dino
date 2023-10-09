if(WIN32)
    add_link_options("-Wl,--export-all-symbols")
endif(WIN32)

foreach(plugin ${PLUGINS})
  add_subdirectory(${plugin})
endforeach(plugin)
