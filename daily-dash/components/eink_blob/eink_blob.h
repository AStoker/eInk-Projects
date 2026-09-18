#pragma once

// Fetches a panel-ready image blob over HTTP and blits it straight into the
// display, a row at a time. See IMAGE-PIPELINE.md for the format.
//
// The point of the format is that this file is the whole of the image path on
// the device: no decoder, no scaler, no palette, and never more than one row of
// the picture in RAM. The ESP32 on this board has ~130 KB of heap and no PSRAM,
// and the panel's own frame buffer already claims 30 KB of it.

#include "esphome/core/component.h"
#include "esphome/components/display/display.h"
#include "esphome/components/http_request/http_request.h"

#include <string>

namespace esphome {
namespace eink_blob {

// The logical, portrait canvas -- the picture the right way up as the frame
// stands on a desk. The panel's own memory is 400x300 landscape; ESPHome's
// `rotation:` turns one into the other on the way through draw_pixel_at(), so
// nothing upstream has to know which way the glass is mounted.
static const uint16_t BLOB_W = 300;
static const uint16_t BLOB_H = 400;
static const uint16_t BLOB_STRIDE = 38;  // ceil(300 / 8), last 4 bits padding
static const uint8_t BLOB_HEADER_LEN = 13;
static const uint8_t BLOB_MAGIC[5] = {'E', 'I', 'N', 'K', '1'};

class EinkBlob : public Component {
 public:
  void set_parent(http_request::HttpRequestComponent *parent) { this->parent_ = parent; }
  void set_timeout_ms(uint32_t ms) { this->timeout_ms_ = ms; }

  float get_setup_priority() const override { return setup_priority::AFTER_WIFI; }
  void dump_config() override;

  // Streams the blob at `url` onto `it`. Returns false and leaves `it`
  // untouched-beyond-whatever-was-drawn on any failure, so the caller can fall
  // back to drawing something of its own.
  bool draw(display::Display &it, const std::string &url);

  // Small GET for the revision string. Returns "" on failure, which the caller
  // must treat as "unknown", not as "changed" -- otherwise an app that is down
  // spends a 17 s refresh on every wake.
  std::string fetch_text(const std::string &url, size_t max_len = 64);

 protected:
  http_request::HttpRequestComponent *parent_{nullptr};
  uint32_t timeout_ms_{15000};
};

}  // namespace eink_blob
}  // namespace esphome
