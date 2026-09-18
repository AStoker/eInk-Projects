#include "eink_blob.h"

#include "esphome/core/application.h"
#include "esphome/core/log.h"

#include <cstring>

namespace esphome {
namespace eink_blob {

static const char *const TAG = "eink_blob";

void EinkBlob::dump_config() {
  ESP_LOGCONFIG(TAG, "eInk blob fetcher:");
  ESP_LOGCONFIG(TAG, "  Canvas: %ux%u, stride %u", BLOB_W, BLOB_H, BLOB_STRIDE);
  ESP_LOGCONFIG(TAG, "  Timeout: %" PRIu32 " ms", this->timeout_ms_);
}

// Reads exactly `len` bytes, or fails. HttpContainer::read() returns whatever
// happens to have arrived, so a single call is not a read of a fixed-size
// record -- a short read here is normal mid-transfer, not an error.
static bool read_exact(http_request::HttpContainer *container, uint8_t *buf, size_t len) {
  size_t got = 0;
  while (got < len) {
    int n = container->read(buf + got, len - got);
    if (n <= 0)
      return false;
    got += (size_t) n;
  }
  return true;
}

bool EinkBlob::draw(display::Display &it, const std::string &url) {
  if (this->parent_ == nullptr) {
    ESP_LOGE(TAG, "No http_request parent");
    return false;
  }

  ESP_LOGD(TAG, "Fetching %s", url.c_str());
  auto container = this->parent_->get(url);
  if (container == nullptr) {
    ESP_LOGW(TAG, "Request failed");
    return false;
  }
  if (container->status_code < 200 || container->status_code >= 300) {
    ESP_LOGW(TAG, "HTTP %d", container->status_code);
    container->end();
    return false;
  }

  uint8_t header[BLOB_HEADER_LEN];
  if (!read_exact(container.get(), header, sizeof(header))) {
    ESP_LOGW(TAG, "Short read on header");
    container->end();
    return false;
  }

  // Validate before drawing anything. A wrong-sized or truncated blob painted
  // blindly is 17 s of refresh spent on garbage that then sits there until the
  // next wake.
  if (memcmp(header, BLOB_MAGIC, sizeof(BLOB_MAGIC)) != 0) {
    ESP_LOGW(TAG, "Bad magic");
    container->end();
    return false;
  }
  const uint16_t w = header[5] | (header[6] << 8);
  const uint16_t h = header[7] | (header[8] << 8);
  const uint16_t stride = header[9] | (header[10] << 8);
  const uint8_t planes = header[11];
  if (w != BLOB_W || h != BLOB_H || stride != BLOB_STRIDE || planes != 2) {
    ESP_LOGW(TAG, "Unexpected geometry: %ux%u stride %u planes %u", w, h, stride, planes);
    container->end();
    return false;
  }

  const Color white = Color(255, 255, 255);
  const Color black = Color(0, 0, 0);
  const Color red = Color(255, 0, 0);

  // One row of each plane, interleaved in the file, so the whole picture never
  // exists in RAM -- only these 76 bytes.
  uint8_t row[BLOB_STRIDE * 2];
  bool ok = true;

  for (uint16_t y = 0; y < BLOB_H; y++) {
    if (!read_exact(container.get(), row, sizeof(row))) {
      ESP_LOGW(TAG, "Short read at row %u", y);
      ok = false;
      break;
    }
    const uint8_t *black_row = row;
    const uint8_t *red_row = row + BLOB_STRIDE;

    for (uint16_t x = 0; x < BLOB_W; x++) {
      const uint8_t mask = 0x80 >> (x & 7);
      const bool is_black = (black_row[x >> 3] & mask) != 0;
      const bool is_red = (red_row[x >> 3] & mask) != 0;
      // Black wins a pixel claimed by both. The app should not emit that, but
      // a bit flip should not turn the panel a different colour than intended.
      it.draw_pixel_at(x, y, is_black ? black : (is_red ? red : white));
    }

    // 120,000 pixels is a few milliseconds of work, but the HTTP reads between
    // rows are not bounded by anything we control.
    if ((y & 0x1F) == 0)
      App.feed_wdt();
  }

  container->end();
  if (ok)
    ESP_LOGD(TAG, "Drew %ux%u", w, h);
  return ok;
}

std::string EinkBlob::fetch_text(const std::string &url, size_t max_len) {
  if (this->parent_ == nullptr)
    return "";

  auto container = this->parent_->get(url);
  if (container == nullptr)
    return "";
  if (container->status_code < 200 || container->status_code >= 300) {
    ESP_LOGW(TAG, "HTTP %d for %s", container->status_code, url.c_str());
    container->end();
    return "";
  }

  std::string out;
  uint8_t buf[32];
  while (out.size() < max_len) {
    int n = container->read(buf, sizeof(buf));
    if (n <= 0)
      break;
    out.append(reinterpret_cast<char *>(buf), (size_t) n);
  }
  container->end();

  // Trim whitespace so a trailing newline from the app does not read as a
  // different revision than the same string without one.
  const char *ws = " \t\r\n";
  const size_t first = out.find_first_not_of(ws);
  if (first == std::string::npos)
    return "";
  const size_t last = out.find_last_not_of(ws);
  return out.substr(first, last - first + 1);
}

}  // namespace eink_blob
}  // namespace esphome
