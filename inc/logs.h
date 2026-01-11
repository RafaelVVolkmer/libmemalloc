/*
 * SPDX-FileCopyrightText: 2024-2025 Rafael V. Volkmer
 * SPDX-FileCopyrightText: <rafael.v.volkmer@gmail.com>
 * SPDX-License-Identifier: MIT
 */

/** ============================================================================
 *  @addtogroup Logs
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
 *  @version    v1.0.00
 *  @date       23.08.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ========================================================================== */

#pragma once

/* < C++ Compatibility > */
#ifdef __cplusplus
extern "C"
{
#endif

/** ============================================================================
 *          P R I V A T E  P R E - I N C L U D E  D E F I N E S
 * ========================================================================== */

/** ============================================================================
 *  @def        _GNU_SOURCE
 *  @brief      Enable GNU extensions on POSIX systems
 *
 *  @details    Defining _GNU_SOURCE before including any headers
 *              activates GNU-specific library features and extensions
 *              in glibc and other GNU-compatible C libraries. This
 *              enables additional APIs beyond the standard C/POSIX
 *              specifications, such as nonstandard functions, constants,
 *              and structures.
 * ========================================================================== */
#if !defined(_WIN32) && !defined(_WIN64)
  #if defined(__STDC_HOSTED__) && (__STDC_HOSTED__ == 1)
    #ifndef _GNU_SOURCE
      #define _GNU_SOURCE
    #endif
  #endif
#endif

/** ============================================================================
 *  @def        _POSIX_C_SOURCE
 *  @brief      Expose POSIX extensions for clock_gettime and
 *              pthread mutex initializer.
 *  @note       This macro should be defined before including system headers
 *              in translation units that require POSIX extensions.
 * ========================================================================== */
#if !defined(_WIN32) && !defined(_WIN64)
  #if defined(__STDC_HOSTED__) && (__STDC_HOSTED__ == 1)
    #if defined(__unix__) || defined(__unix) || defined(__APPLE__) \
      || defined(__linux__)
      #ifndef _POSIX_C_SOURCE
        #define _POSIX_C_SOURCE 200809UL
      #endif
    #endif
  #endif
#endif

/** ============================================================================
 *  @def        LOG_LEVEL
 *  @brief      Logging verbosity threshold for this module
 *
 *  @details    Sets the minimum severity of log messages that will be
 *              compiled into this translation unit. Only log calls at or
 *              below the specified level are enabled:
 *                - LOG_LEVEL_NONE    (0): disable all logging
 *                - LOG_LEVEL_ERROR   (1): errors only
 *                - LOG_LEVEL_WARNING (2): warnings and errors
 *                - LOG_LEVEL_INFO    (3): info, warnings, and errors
 *                - LOG_LEVEL_DEBUG   (4): debug, info, warnings, and errors
 *  @brief      Default log level if not defined.
 * ========================================================================== */
#ifndef LOG_LEVEL
  #define LOG_LEVEL LOG_LEVEL_DEBUG
#endif

/** ============================================================================
 *                      P U B L I C  I N C L U D E S
 * ========================================================================== */

/*< Dependencies >*/
#include <errno.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

/** ============================================================================
 *              P U B L I C  S T R U C T U R E S  &  T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @enum       LogLevel
 *  @typedef    log_level_t
 *
 *  @brief      Defines log levels for the logging system.
 *
 *  @par Fields:
 *    @li @b LOG_LEVEL_NONE    – Disables all logs
 *    @li @b LOG_LEVEL_ERROR   – Enables only error logs
 *    @li @b LOG_LEVEL_WARNING – Enables error and warning logs
 *    @li @b LOG_LEVEL_INFO    – Enables info, warning, and error logs
 *    @li @b LOG_LEVEL_DEBUG   – Enables all logs
 * ========================================================================== */
typedef enum LogLevel
{
  LOG_LEVEL_NONE    = (uint8_t)(0u), /**< Disables all logs */
  LOG_LEVEL_ERROR   = (uint8_t)(1u), /**< Enables error logs */
  LOG_LEVEL_WARNING = (uint8_t)(2u), /**< Enables warning logs */
  LOG_LEVEL_INFO    = (uint8_t)(3u), /**< Enables info logs */
  LOG_LEVEL_DEBUG   = (uint8_t)(4u)  /**< Enables all logs */
} log_level_t;

/** ============================================================================
 *              P U B L I C  D E F I N E S  &  M A C R O S
 * ========================================================================== */

/** ============================================================================
 *  @def        LOG_PRINTF
 *  @brief      Compiler-specific printf abstraction (variadic).
 *
 *  Uses __builtin_fprintf when available; falls back to fprintf otherwise.
 *  Intended usage matches fprintf:
 *
 *      LOG_PRINTF(stream, "fmt %d\n", value);
 * ========================================================================== */
#if defined(__has_builtin)
  #if __has_builtin(__builtin_fprintf)
    #define LOG_PRINTF(...) __builtin_fprintf(__VA_ARGS__)
  #else
    #define LOG_PRINTF(...) fprintf(__VA_ARGS__)
  #endif
#else
  #if defined(__GNUC__)
    #define LOG_PRINTF(...) __builtin_fprintf(__VA_ARGS__)
  #else
    #define LOG_PRINTF(...) fprintf(__VA_ARGS__)
  #endif
#endif

/** ============================================================================
 *  @def        LOG_VPRINTF
 *  @brief      Compiler-specific vprintf abstraction.
 *
 *  Uses __builtin_vfprintf when available; falls back to vfprintf otherwise.
 *  Intended usage matches vfprintf:
 *
 *      LOG_VPRINTF(stream, "fmt %d\n", args);
 * ========================================================================== */
#if defined(__has_builtin)
  #if __has_builtin(__builtin_vfprintf)
    #define LOG_VPRINTF(...) __builtin_vfprintf(__VA_ARGS__)
  #else
    #define LOG_VPRINTF(...) vfprintf(__VA_ARGS__)
  #endif
#else
  #if defined(__GNUC__)
    #define LOG_VPRINTF(...) __builtin_vfprintf(__VA_ARGS__)
  #else
    #define LOG_VPRINTF(...) vfprintf(__VA_ARGS__)
  #endif
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
#define COLOR_RED      "\033[0;31m"
#define COLOR_YELLOW   "\033[0;33m"
#define COLOR_BLUE     "\033[0;34m"
#define COLOR_GREEN    "\033[0;32m"
#define COLOR_RESET    "\033[0m"

/** ============================================================================
 *  @def        ATTR_PRINTF
 *  @brief      Macro to apply printf-style format checking on custom
 *              functions when supported by the compiler.
 *
 *  Expands to GCC/Clang's __attribute__((format(printf, ...))) when
 *  available, otherwise to nothing.
 * ========================================================================== */
#ifndef ATTR_PRINTF
  #if defined(__has_attribute)
    #if __has_attribute(format)
      #define ATTR_PRINTF(fmt_idx, var_idx) \
        __attribute__((format(printf, fmt_idx, var_idx)))
    #else
      #define ATTR_PRINTF(fmt_idx, var_idx)
    #endif
  #elif defined(__GNUC__)
    #define ATTR_PRINTF(fmt_idx, var_idx) \
      __attribute__((format(printf, fmt_idx, var_idx)))
  #else
    #define ATTR_PRINTF(fmt_idx, var_idx)
  #endif
#endif

/** ============================================================================
 *              P U B L I C  F U N C T I O N S  P R O T O T Y P E S
 * ========================================================================== */

/** ============================================================================
 *  @brief  Internal logging implementation: thread‐safe, prints timestamp,
 *          optional ANSI color, severity prefix, formatted message,
 *          and source location.
 *
 *  This function:
 *    - Checks if the given @p level is within the configured LOG_LEVEL.
 *      Returns -EIO if the level is too verbose.
 *    - Locks a static mutex to serialize access from multiple threads.
 *    - Retrieves the current time (seconds and nanoseconds) and formats
 *      a timestamp `[HH:MM:SS.mmm]`.
 *    - Selects stderr for WARNING or ERROR levels, stdout otherwise.
 *    - If the output is a TTY, emits the provided @p color codes around
 *      the @p prefix; otherwise emits only the prefix text.
 *    - Formats the user message using @p fmt and variadic arguments.
 *    - Appends the source location `(at file:line:func())`.
 *    - Unlocks the mutex and returns status.
 *
 *  @param[in]  level   Log severity (ERROR, WARNING, INFO, DEBUG).
 *  @param[in]  color   ANSI color sequence for interactive terminals.
 *  @param[in]  prefix  Text prefix for the log level (e.g. "[ERROR]").
 *  @param[in]  file    Source file name (__FILE__) of the call.
 *  @param[in]  func    Function name (__func__) of the call.
 *  @param[in]  line    Line number (__LINE__) of the call.
 *  @param[in]  fmt     printf-style format string for the log message.
 *  @param[in]  ...     Arguments corresponding to @p fmt.
 *
 *  @return Integer status code indicating initialization result.
 *
 *  @retval EXIT_SUCCESS: Message was successfully logged.
 *  @retval -EIO:         The specified @p level is more verbose than LOG_LEVEL.
 * ========================================================================== */
static inline int LOG_output(log_level_t level,
                             const char *color,
                             const char *prefix,
                             const char *file,
                             const char *func,
                             int         line,
                             const char *fmt,
                             ...) ATTR_PRINTF(7, 8);

/** ============================================================================
 *  @brief  Internal logging implementation: thread‐safe, prints timestamp,
 *          optional ANSI color, severity prefix, formatted message,
 *          and source location.
 *
 *  This function:
 *    - Checks if the given @p level is within the configured LOG_LEVEL.
 *      Returns -EIO if the level is too verbose.
 *    - Locks a static mutex to serialize access from multiple threads.
 *    - Retrieves the current time (seconds and nanoseconds) and formats
 *      a timestamp `[HH:MM:SS.mmm]`.
 *    - Selects stderr for WARNING or ERROR levels, stdout otherwise.
 *    - If the output is a TTY, emits the provided @p color codes around
 *      the @p prefix; otherwise emits only the prefix text.
 *    - Formats the user message using @p fmt and variadic arguments.
 *    - Appends the source location `(at file:line:func())`.
 *    - Unlocks the mutex and returns status.
 *
 *  @param[in]  level   Log severity (ERROR, WARNING, INFO, DEBUG).
 *  @param[in]  color   ANSI color sequence for interactive terminals.
 *  @param[in]  prefix  Text prefix for the log level (e.g. "[ERROR]").
 *  @param[in]  file    Source file name (__FILE__) of the call.
 *  @param[in]  func    Function name (__func__) of the call.
 *  @param[in]  line    Line number (__LINE__) of the call.
 *  @param[in]  fmt     printf-style format string for the log message.
 *  @param[in]  ...     Arguments corresponding to @p fmt.
 *
 *  @return Integer status code indicating initialization result.
 *
 *  @retval EXIT_SUCCESS: Message was successfully logged.
 *  @retval -EIO:         The specified @p level is more verbose than LOG_LEVEL.
 * ========================================================================== */
static inline int LOG_output(log_level_t level,
                             const char *color,
                             const char *prefix,
                             const char *file,
                             const char *func,
                             int         line,
                             const char *fmt,
                             ...)
{
  int ret = EXIT_SUCCESS;

  FILE *out = (FILE *)NULL;

  static pthread_mutex_t log_mutex = PTHREAD_MUTEX_INITIALIZER;

  struct timespec ts;
  struct tm      *ptm = (struct tm *)NULL;

  time_t now = 0;

  long msec = 0u;

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

  out  = (level <= LOG_LEVEL_WARNING) ? stderr : stdout;
  msec = ts.tv_nsec / 1000000L;

  LOG_PRINTF(out,
             "[%02d:%02d:%02d.%03ld] ",
             ptm->tm_hour,
             ptm->tm_min,
             ptm->tm_sec,
             msec);

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
 *  @def        LOG_ERROR(...)
 *  @brief      Logs an error message (red).
 *
 *  Usage:
 *      LOG_ERROR("Message\n");
 *      LOG_ERROR("Message: %d\n", code);
 * ========================================================================== */
#define LOG_ERROR(...)        \
  LOG_output(LOG_LEVEL_ERROR, \
             COLOR_RED,       \
             PREFIX_ERROR,    \
             __FILE__,        \
             __func__,        \
             __LINE__,        \
             __VA_ARGS__)

/** ============================================================================
 *  @def        LOG_WARNING(...)
 *  @brief      Logs a warning message (yellow).
 * ========================================================================== */
#define LOG_WARNING(...)        \
  LOG_output(LOG_LEVEL_WARNING, \
             COLOR_YELLOW,      \
             PREFIX_WARNING,    \
             __FILE__,          \
             __func__,          \
             __LINE__,          \
             __VA_ARGS__)

/** ============================================================================
 *  @def        LOG_INFO(...)
 *  @brief      Logs an info message (blue).
 * ========================================================================== */
#define LOG_INFO(...)        \
  LOG_output(LOG_LEVEL_INFO, \
             COLOR_BLUE,     \
             PREFIX_INFO,    \
             __FILE__,       \
             __func__,       \
             __LINE__,       \
             __VA_ARGS__)

/** ============================================================================
 *  @def        LOG_DEBUG(...)
 *  @brief      Logs a debug message (green).
 * ========================================================================== */
#define LOG_DEBUG(...)        \
  LOG_output(LOG_LEVEL_DEBUG, \
             COLOR_GREEN,     \
             PREFIX_DEBUG,    \
             __FILE__,        \
             __func__,        \
             __LINE__,        \
             __VA_ARGS__)

/* < C++ Compatibility End > */
#ifdef __cplusplus
}
#endif

/** @} */
/* < End of header file > */
