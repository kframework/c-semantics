#include <inttypes.h>
#include <stdio.h>

struct tpacket3_hdr {
      uint32_t tp_next_offset;
      uint32_t tp_sec;
      uint32_t tp_nsec;
      uint32_t tp_snaplen;
      uint32_t tp_len;
      uint32_t tp_status;
      uint16_t tp_mac;
      uint16_t tp_net;

      union {
            uint32_t hv1;
      };
      uint8_t tp_padding[8];
};

      int
main(int argc, char **argv)
{
      struct tpacket3_hdr h;
      printf("%zu\n", sizeof(h.hv1));
      return 0;
}
