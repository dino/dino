foreach(plugin ${PLUGINS})
  add_subdirectory(${plugin})
endforeach(plugin)
