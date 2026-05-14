#ifndef FIX_MDNS_H
#define FIX_MDNS_H

#ifndef __ASSEMBLER__
#include <stdint.h>
#include <string.h>
#include <stdbool.h>

// Configuration missing from our manual build
#ifndef CONFIG_MDNS_MAX_SERVICES
#define CONFIG_MDNS_MAX_SERVICES 10
#endif

// Since we enabled LWIP_IPV6=1, we should have the union ip_addr_t from lwip/ip_addr.h
// We just need to make sure we include the right things for mDNS

#include "lwip/ip_addr.h"
#include "lwip/def.h"

// mDNS expects these but they might be missing if some dual-stack parts are disabled
#ifndef IP_ADDR4
#define IP_ADDR4(ipaddr,a,b,c,d) IP4_ADDR(ip_2_ip4(ipaddr),a,b,c,d)
#endif

#ifndef IPADDR6_INIT
#define IPADDR6_INIT(a, b, c, d) { { .ip6 = { { a, b, c, d } } }, IPADDR_TYPE_V6 }
#endif

#define IP6_HLEN 40
#define UDP_HLEN 8

#endif

#endif
