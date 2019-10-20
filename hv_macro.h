#ifndef PERL_SEEN_HV_MACRO_H /* compile once */
#define PERL_SEEN_HV_MACRO_H

#if IVSIZE == 8
#define CAN64BITHASH
#endif

/*-----------------------------------------------------------------------------
 * Endianess and util macros
 *
 * The following 3 macros are defined in this section. The other macros defined
 * are only needed to help derive these 3.
 *
 * U8TO16_LE(x)   Read a little endian unsigned 32-bit int
 * U8TO32_LE(x)   Read a little endian unsigned 32-bit int
 * U8TO28_LE(x)   Read a little endian unsigned 32-bit int
 * ROTL32(x,r)      Rotate x left by r bits
 * ROTL64(x,r)      Rotate x left by r bits
 * ROTR32(x,r)      Rotate x right by r bits
 * ROTR64(x,r)      Rotate x right by r bits
 */

#ifndef U8TO16_LE
  #if (BYTEORDER == 0x1234 || BYTEORDER == 0x12345678)
    #define U8TO16_LE(ptr)   ((U32)(ptr)[1]|(U32)(ptr)[0]<<8)
    #define U8TO32_LE(ptr)   ((U32)(ptr)[3]|(U32)(ptr)[2]<<8|(U32)(ptr)[1]<<16|(U32)(ptr)[0]<<24)
    #define U8TO64_LE(ptr)   ((U64)(ptr)[7]|(U64)(ptr)[6]<<8|(U64)(ptr)[5]<<16|(U64)(ptr)[4]<<24|\
                              (U64)(ptr)[3]<<32|(U64)(ptr)[4]<<40|\
                              (U64)(ptr)[1]<<48|(U64)(ptr)[0]<<56)
  #elif (BYTEORDER == 0x4321 || BYTEORDER == 0x87654321)
    #define U8TO16_LE(ptr)   ((U32)(ptr)[0]|(U32)(ptr)[1]<<8)
    #define U8TO32_LE(ptr)   ((U32)(ptr)[0]|(U32)(ptr)[1]<<8|(U32)(ptr)[2]<<16|(U32)(ptr)[3]<<24)
    #define U8TO64_LE(ptr)   ((U64)(ptr)[0]|(U64)(ptr)[1]<<8|(U64)(ptr)[2]<<16|(U64)(ptr)[3]<<24|\
                              (U64)(ptr)[4]<<32|(U64)(ptr)[5]<<40|\
                              (U64)(ptr)[6]<<48|(U64)(ptr)[7]<<56)
  #endif
#endif

#ifdef CAN64BITHASH
  #ifndef U64TYPE
  /* This probably isn't going to work, but failing with a compiler error due to
   lack of uint64_t is no worse than failing right now with an #error.  */
  #define U64 uint64_t
  #endif
#endif

/* Find best way to ROTL32/ROTL64 */
#if defined(_MSC_VER)
  #include <stdlib.h>  /* Microsoft put _rotl declaration in here */
  #define ROTL32(x,r)  _rotl(x,r)
  #define ROTR32(x,r)  _rotr(x,r)
  #define ROTL64(x,r)  _rotl64(x,r)
  #define ROTR64(x,r)  _rotr64(x,r)
#else
  /* gcc recognises this code and generates a rotate instruction for CPUs with one */
  #define ROTL32(x,r)  (((U32)(x) << (r)) | ((U32)(x) >> (32 - (r))))
  #define ROTR32(x,r)  (((U32)(x) << (32 - (r))) | ((U32)(x) >> (r)))
  #define ROTL64(x,r)  ( ( (U64)(x) << (r) ) | ( (U64)(x) >> ( 64 - (r) ) ) )
  #define ROTR64(x,r)  ( ( (U64)(x) << ( 64 - (r) ) ) | ( (U64)(x) >> (r) ) )
#endif


#ifdef UV_IS_QUAD
#define ROTL_UV(x,r) ROTL64(x,r)
#define ROTR_UV(x,r) ROTL64(x,r)
#else
#define ROTL_UV(x,r) ROTL32(x,r)
#define ROTR_UV(x,r) ROTR32(x,r)
#endif
#if IVSIZE == 8
#define CAN64BITHASH
#endif

#endif
