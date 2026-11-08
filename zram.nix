{
  config,
  lib,
  pkgs,
  ...
}: {
  # =========================================================================
  # ZRAM - compressed swap space backed by memory
  # Compresses memory pages to reduce physical memory usage and avoid frequent disk I/O
  # =========================================================================

  zramSwap = {
    enable = true;

    # Compression algorithm - zstd offers a good balance between ratio and speed
    algorithm = "zstd";

    # Memory percentage - use up to 100% of RAM as compressed swap
    # Actual footprint depends on the compression ratio (usually 30-50% of the original size)
    memoryPercent = 100;

    # Swap priority - above disk swap so zram is used first
    # Default is 5; disk swap defaults to -1 to -2
    priority = 5;
  };
}
