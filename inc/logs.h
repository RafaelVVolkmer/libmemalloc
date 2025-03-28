/** ===============================================================
 *  @addtogroup Libmemalloc
 *  @{
 * 
 *  @brief      Logging macros and config for the libmemalloc.
 *
 *  @file       logs.h
 *
 *  @details    This header provides logging utilities for 
 *              libmemalloc, including macros for log levels 
 *              - error, warning, info, debug - and formatted output 
 *              with function, file, and line details. These tools 
 *              improve debugging and tracing within the library.
 *
 *  @version    v1.0.00.00
 *  @date       24.05.2025
 *  @author     Rafael V. Volkmer <rafael.v.volkmer@gmail.com>
 * ================================================================ */

 #ifndef LOGS_H_
 #define LOGS_H_
 
 /*< C++ Compatibility >*/
 #ifdef __cplusplus
    extern "C" 
    {
 #endif

/** ===============================================================
 *          P U B L I C  S T R U C T U R E S  &  T Y P E S          
 * ================================================================ */

/** ============================================================== 
 *  @def        COLOR_RED
 *  @brief      ANSI escape code for red color.
 *  @details    Used for coloring ERROR messages.
 * =============================================================== */
#define COLOR_RED     "\033[0;31m"  

/** ============================================================== 
 *  @def        COLOR_YELLOW
 *  @brief      ANSI escape code for yellow color.
 *  @details    Used for coloring WARNING messages.
 * =============================================================== */
#define COLOR_YELLOW  "\033[0;33m"  

/** ============================================================== 
 *  @def        COLOR_BLUE
 *  @brief      ANSI escape code for blue color.
 *  @details    Used for coloring INFO messages.
 * =============================================================== */
#define COLOR_BLUE    "\033[0;34m"  

/** ============================================================== 
 *  @def        COLOR_GREEN
 *  @brief      ANSI escape code for green color.
 *  @details    Used for coloring DEBUG messages.
 * =============================================================== */
#define COLOR_GREEN   "\033[0;32m"  

/** ============================================================== 
 *  @def        COLOR_RESET
 *  @brief      ANSI escape code to reset color.
 *  @details    Resets the terminal color to default.
 * =============================================================== */
#define COLOR_RESET   "\033[0m"  

/** =============================================================
 *  @enum       LogLevel
 *  @typedef    log_level_t
 *  @package    Logs
 *  @brief      Defines log levels for the logging system.
 * ============================================================= */
typedef enum LogLevel
{
    LOG_LEVEL_NONE    = 0U,   /**< Disables all logs. */
    LOG_LEVEL_ERROR   = 1U,   /**< Enables only error logs. */
    LOG_LEVEL_WARNING = 2U,   /**< Enables error and warning logs. */
    LOG_LEVEL_INFO    = 3U,   /**< Enables info, warning, and error logs. */
    LOG_LEVEL_DEBUG   = 4U    /**< Enables all logs. */
} log_level_t;

/** ===============================================================
 *          P U B L I C  D E F I N E S  &  M A C R O S              
 * ================================================================ */

/** ============================================================== 
 *  @def        LOG_LEVEL
 *  @brief      Default log level if not defined.
 *  @details    Sets LOG_LEVEL to LOG_LEVEL_DEBUG by default.
 * =============================================================== */
#ifndef LOG_LEVEL
    #define LOG_LEVEL LOG_LEVEL_NONE
#endif
 
/** ============================================================== 
 *  @def        LOG_OUTPUT(level, prefix, fmt, ...)
 *  @brief      Outputs a log message if level is enabled.
 *
 *  @param[in] level  Log level to check against LOG_LEVEL.
 *  @param[in] prefix String prefix for the log type.
 *  @param[in] fmt    Format string for the log message.
 *  @param[in] ...    Additional arguments to be formatados.
 *
 *  @details    Prints to stdout with function, file, and line info.
 * =============================================================== */
#define LOG_OUTPUT(level, prefix, fmt, ...)                             \
    do                                                                  \
    {                                                                   \
        if ((level) <= LOG_LEVEL)                                       \
        {                                                               \
            __builtin_printf("%s: " fmt " at: %s() (%s:%d)\n",          \
                prefix, ##__VA_ARGS__, __func__, __FILE__, __LINE__);   \
        }                                                               \
    } while (0u)                                                        \

#ifdef __GNUC__
    /** ============================================================== 
     *  @def        LOG_ERROR(fmt, ...)
     *  @brief      Logs an error message (in red).
     * =============================================================== */
    #define LOG_ERROR(fmt, ...)             \
        LOG_OUTPUT(LOG_LEVEL_ERROR, COLOR_RED "[ERROR]" COLOR_RESET, fmt, ##__VA_ARGS__)
    
    /** ============================================================== 
     *  @def        LOG_WARNING(fmt, ...)
     *  @brief      Logs a warning message (in yellow).
     * =============================================================== */
    #define LOG_WARNING(fmt, ...)           \
        LOG_OUTPUT(LOG_LEVEL_WARNING, COLOR_YELLOW "[WARNING]" COLOR_RESET, fmt, ##__VA_ARGS__)
    
    /** ============================================================== 
     *  @def        LOG_INFO(fmt, ...)
     *  @brief      Logs an info message (in blue).
     * =============================================================== */
    #define LOG_INFO(fmt, ...)              \
        LOG_OUTPUT(LOG_LEVEL_INFO, COLOR_BLUE "[INFO]" COLOR_RESET, fmt, ##__VA_ARGS__)
    
    /** ============================================================== 
     *  @def        LOG_DEBUG(fmt, ...)
     *  @brief      Logs a debug message (in green).
     * =============================================================== */
    #define LOG_DEBUG(fmt, ...)             \
        LOG_OUTPUT(LOG_LEVEL_DEBUG, COLOR_GREEN "[DEBUG]" COLOR_RESET, fmt, ##__VA_ARGS__)
#else
    /** ============================================================== 
     *  @def        LOG_ERROR(fmt, ...)
     *  @brief      Logs an error message (in red).
     * =============================================================== */
    #define LOG_ERROR(fmt, ...)             \
        LOG_OUTPUT(LOG_LEVEL_ERROR, COLOR_RED "[ERROR]" COLOR_RESET, fmt, __VA_ARGS__)
    
    /** ============================================================== 
     *  @def        LOG_WARNING(fmt, ...)
     *  @brief      Logs a warning message (in yellow).
     * =============================================================== */
    #define LOG_WARNING(fmt, ...)           \
        LOG_OUTPUT(LOG_LEVEL_WARNING, COLOR_YELLOW "[WARNING]" COLOR_RESET, fmt, __VA_ARGS__)
    
    /** ============================================================== 
     *  @def        LOG_INFO(fmt, ...)
     *  @brief      Logs an info message (in blue).
     * =============================================================== */
    #define LOG_INFO(fmt, ...)              \
        LOG_OUTPUT(LOG_LEVEL_INFO, COLOR_BLUE "[INFO]" COLOR_RESET, fmt, __VA_ARGS__)
    
    /** ============================================================== 
     *  @def        LOG_DEBUG(fmt, ...)
     *  @brief      Logs a debug message (in green).
     * =============================================================== */
    #define LOG_DEBUG(fmt, ...)             \
        LOG_OUTPUT(LOG_LEVEL_DEBUG, COLOR_GREEN "[DEBUG]" COLOR_RESET, fmt, __VA_ARGS__)
#endif
 
/*< C++ Compatibility >*/
#ifdef __cplusplus
    }
#endif
 
#endif /* LOGS_H_ */

/** @} */

/*< end of header file >*/
 
