#pragma once

#if defined(WIN32) && defined(BUILD_SHARED_LIBS)
    #if defined(_MSC_VER)
        #pragma warning(disable: 4251)
    #endif
    #if defined(matio_EXPORT)
        #define MATIO_EXPORT __declspec(dllexport)
    #else
        #define MATIO_EXPORT __declspec(dllimport)
    #endif
#else
    #define MATIO_EXPORT
#endif
