/** ============================================================================
 *  @addtogroup Libmemalloc
 *  @{
 *
 *  @file       logs.h
 *  @brief      Logging macros and configuration for libmemalloc.
 *
 *  @details    Provides logging utilities for libmemalloc, including log level
 *              control (ERROR, WARNING, INFO, DEBUG), ANSI color output, and
 *              automatic file, function, and line reporting for each log entry.
 *              Supports GCC-specific built-in printing as well as standard
 *              printf for other compilers.
 *
 *  @version    v3.0.00.00
 *  @date       16.06.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

#ifndef LOGS_H_
#define LOGS_H_

/* < C++ Compatibility > */
#ifdef __cplusplus
    extern "C" {
#endif

/** ============================================================================
 *                      P U B L I C  I N C L U D E S                            
 * ========================================================================== */

/*< Dependencies >*/
#include <errno.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/** ============================================================================
 *              P U B L I C  S T R U C T U R E S  &  T Y P E S                  
 * ========================================================================== */

/** ============================================================================
 *  @enum       LogLevel
 *  @typedef    log_level_t
 *  @brief      Defines log levels for the logging system.
 * ========================================================================== */
typedef enum LogLevel
{
    LOG_LEVEL_NONE    = 0u,   /**< Disables all logs. */
    LOG_LEVEL_ERROR   = 1u,   /**< Enables only error logs. */
    LOG_LEVEL_WARNING = 2u,   /**< Enables error and warning logs. */
    LOG_LEVEL_INFO    = 3u,   /**< Enables info, warning, and error logs. */
    LOG_LEVEL_DEBUG   = 4u    /**< Enables all logs. */
} log_level_t;

/** ============================================================================
 *              P U B L I C  D E F I N E S  &  M A C R O S                      
 * ========================================================================== */

/** ============================================================================
 *  @def        LOG_LEVEL
 *  @brief      Default log level if not defined.
 * ========================================================================== */
#ifndef LOG_LEVEL
    #define LOG_LEVEL LOG_LEVEL_DEBUG
#endif

/** ============================================================================
 *  @def        _POSIX_C_SOURCE
 *  @brief      Expose POSIX extensions for clock_gettime and
 *              pthread mutex initializer.
 * ========================================================================== */
#ifndef _POSIX_C_SOURCE
    #define _POSIX_C_SOURCE 200809UL
#endif

/** ============================================================================
 *  @def        LOG_PRINTF
 *  @brief      Compiler-specific printf abstraction.
 * ========================================================================== */
#if defined(__GNUC__)
    #define LOG_PRINTF(file, format, ...)                               \
        __builtin_fprintf((FILE *)(file), (format), ##__VA_ARGS__)

    #define LOG_VPRINTF(file, format, args)                             \
        __builtin_vfprintf((FILE *)(file), (format), (args))
#else
    #define LOG_PRINTF(file, ...)                                       \
        fprintf(file, __VA_ARGS__)

    #define LOG_VPRINTF(file, fmt, args)                                \
        vfprintf(file, fmt, args)
#endif

/** ============================================================================
 *  @def        PREFIX_ERROR, PREFIX_WARNING, PREFIX_INFO, PREFIX_DEBUG
 *  @brief      Default text prefixes used before log messages.
 * ========================================================================== */
#define PREFIX_ERROR   "[ERROR]"
#define PREFIX_WARNING "[WARNING]"
#define PREFIX_INFO    "[INFO]"
#define PREFIX_DEBUG   "[DEBUG]"

/** ============================================================================
 *  @def        COLOR_RED, COLOR_YELLOW, COLOR_BLUE, COLOR_GREEN, COLOR_RESET
 *  @brief      ANSI escape sequences for colored output
 *              (red, yellow, blue, green), and reset.
 * ========================================================================== */
#define COLOR_RED     "\033[0;31m"
#define COLOR_YELLOW  "\033[0;33m"
#define COLOR_BLUE    "\033[0;34m"
#define COLOR_GREEN   "\033[0;32m"
#define COLOR_RESET   "\033[0m"

/** ============================================================================
 *  @def        ATTR_PRINTF
 *  @brief      Macro to apply GCC printf-style format checking on custom functions.
 * ========================================================================== */
#ifndef ATTR_PRINTF
    #define ATTR_PRINTF(fmt_idx, var_idx)                       \
        __attribute__((format (printf, fmt_idx, var_idx)))
#endif

/** ============================================================================
 *              P U B L I C  F U N C T I O N S  P R O T O T Y P E S             
 * ========================================================================== */

 /** ============================================================================
 *  @fn         LOG_output
 *  @brief      Internal logging implementation: thread-safe, prints timestamp,
 *              color (if interactive), prefix, formatted message, and source info.
 *
 *  @attr       ATTR_PRINTF(7, 8) Apply printf-style format checking on 
 *              fmt and varargs.
 *
 *  @param      level    Log severity (ERROR, WARNING, INFO, DEBUG).
 *  @param      color    ANSI color code to use for interactive terminals.
 *  @param      prefix   Text prefix for the log level (e.g. "[ERROR]").
 *  @param      file     Source file name (__FILE__) of the log call.
 *  @param      func     Function name (__func__) of the log call.
 *  @param      line     Line number (__LINE__) of the log call.
 *  @param      fmt      printf-style format string for the log message.
 *
 *  @return     EXIT_SUCCESS if message logged, -EIO if level > LOG_LEVEL
 * ========================================================================== */
static inline int LOG_output(log_level_t level,
                              const char *color,
                              const char *prefix,
                              const char *file,
                              const char *func,
                              int line,
                              const char *fmt, ...) ATTR_PRINTF(7, 8);

 /** ============================================================================
 *  @fn         LOG_output
 *  @brief      Internal logging implementation: thread-safe, prints timestamp,
 *              color (if interactive), prefix, formatted message, and source info.
 *
 *  @param      level    Log severity (ERROR, WARNING, INFO, DEBUG).
 *  @param      color    ANSI color code to use for interactive terminals.
 *  @param      prefix   Text prefix for the log level (e.g. "[ERROR]").
 *  @param      file     Source file name (__FILE__) of the log call.
 *  @param      func     Function name (__func__) of the log call.
 *  @param      line     Line number (__LINE__) of the log call.
 *  @param      fmt      printf-style format string for the log message.
 *
 *  @return     EXIT_SUCCESS if message logged, -EIO if level > LOG_LEVEL
 * ========================================================================== */
static inline int LOG_output(log_level_t level,
                              const char *color,
                              const char *prefix,
                              const char *file,
                              const char *func,
                              int line,
                              const char *fmt, ...)
{
    int ret = EXIT_SUCCESS;

    FILE *out = NULL;

    static pthread_mutex_t log_mutex  = PTHREAD_MUTEX_INITIALIZER;

    struct timespec ts;
    struct tm *ptm = NULL;
    time_t now = 0;

    if (level > LOG_LEVEL)
    {
        ret = -EIO;
        goto function_output;
    }

    pthread_mutex_lock(&log_mutex);

    memset(&ts, 0, sizeof(ts));

    clock_gettime(CLOCK_REALTIME, &ts);

    now = ts.tv_sec;
    ptm = localtime(&now);

    out = (level <= LOG_LEVEL_WARNING) ? stderr : stdout;
    LOG_PRINTF(out, "[%02d:%02d:%02d.%03ld] ",
            ptm->tm_hour, ptm->tm_min,
            ptm->tm_sec, ts.tv_nsec / 1000000u);

    if (isatty(fileno(out)))
        LOG_PRINTF(out, "%s%s%s ", color, prefix, COLOR_RESET);
    else
        LOG_PRINTF(out, "%s ", prefix);

    va_list args;
    va_start(args, fmt);
    LOG_VPRINTF(out, fmt, args);
    va_end(args);

    LOG_PRINTF(out, " (at %s:%d:%s())\n", file, line, func);
    pthread_mutex_unlock(&log_mutex);

function_output:
    return ret;
}

/** ============================================================================
 *  @def        LOG_ERROR(fmt, ...)
 *  @brief      Logs an error message (red).
 * ========================================================================== */
#define LOG_ERROR(fmt, ...)   LOG_output(LOG_LEVEL_ERROR, COLOR_RED,        \
                                        PREFIX_ERROR, __FILE__, __func__,   \
                                        __LINE__, fmt, ##__VA_ARGS__)       \

/** ============================================================================
 *  @def        LOG_WARNING(fmt, ...)
 *  @brief      Logs a warning message (yellow).
 * ========================================================================== */
#define LOG_WARNING(fmt, ...) LOG_output(LOG_LEVEL_WARNING,COLOR_YELLOW,    \
                                        PREFIX_WARNING, __FILE__, __func__, \
                                        __LINE__, fmt, ##__VA_ARGS__)       \

/** ============================================================================
 *  @def        LOG_INFO(fmt, ...)
 *  @brief      Logs an info message (blue).
 * ========================================================================== */
#define LOG_INFO(fmt, ...)    LOG_output(LOG_LEVEL_INFO, COLOR_BLUE,        \
                                        PREFIX_INFO, __FILE__, __func__,    \
                                        __LINE__, fmt, ##__VA_ARGS__)       \

/** ============================================================================
 *  @def        LOG_DEBUG(fmt, ...)
 *  @brief      Logs a debug message (green).
 * ========================================================================== */
#define LOG_DEBUG(fmt, ...)   LOG_output(LOG_LEVEL_DEBUG, COLOR_GREEN,      \
                                        PREFIX_DEBUG, __FILE__, __func__,   \
                                        __LINE__, fmt, ##__VA_ARGS__)       \

/* < C++ Compatibility End > */
#ifdef __cplusplus
    }
#endif

#endif /* LOGS_H_ */

/** @} */
/* < End of header file > */
