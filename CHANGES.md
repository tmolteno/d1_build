## Changelog

### Version 0.4

- Remove backticks in Dockerfile (thanks NexusXe)
- Add xradio driver code for the panel (work in progress - no firmware yet)


### Version 0.3

- Smaller builds by removing apt caches.
- Enable some modules for the LCD display (WIP)
- Stop copying the uncompressed kernel around in the Dockerfile.

### Version 0.2

- Move to github actions. Still debugging them.
- Change GCC version of the cross compiler to 10.2.1
- Kernel Version is 5.18rc1 (later versions have problems)
