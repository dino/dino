find_library(GstWebrtcDsp_LIBRARY gstwebrtcdsp PATH_SUFFIXES gstreamer-1.0)

if(GstWebrtcDsp_LIBRARY_FOUND)
    find_package(Gst)
    set(GstWebrtcDsp_VERSION ${Gst_VERSION})
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GstWebrtcDsp
    REQUIRED_VARS GstWebrtcDsp_LIBRARY
    VERSION_VAR GstWebrtcDsp_VERSION)
