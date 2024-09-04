KERNEL_RELEASE  ?= $(shell uname -r)
KERNEL_DIR      ?= /lib/modules/$(KERNEL_RELEASE)/build
obj-m           += tcp_nbbr.o

ccflags-y := -std=gnu11 -w

.PHONY: all clean load unload

all:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KERNEL_DIR) M=$(PWD) clean

load:
	sudo insmod tcp_nbbr.ko

unload:
	sudo rmmod tcp_nbbr

